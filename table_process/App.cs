using System;
using System.IO;
using System.Net.Sockets;
using System.Windows.Forms;
using Microsoft.Surface;
using Microsoft.Surface.Core;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace RawImageVisualizer
{
    public struct Blob
    {
       public  uint pixelCount;
       public  uint minX;
       public  uint minY;
       public  uint maxX;
       public  uint maxY;

        /// <summary>
        /// New blob from inital pixel x and y
        /// </summary>
        public Blob(uint x, uint y)
        {
            pixelCount = 0;
            minX = x;
            maxX = x;

            minY = y;
            maxY = y;
        }
    }

    /// <summary>
    /// This is the main type for your application.
    /// </summary>
    public class App : Microsoft.Xna.Framework.Game
    {
        private readonly GraphicsDeviceManager graphics;
        private TouchTarget touchTarget;
        private bool applicationLoadCompleteSignalled;
        private SpriteBatch foregroundBatch;
        private Texture2D touchSprite;
        private uint[] spriteData;
        private readonly Vector2 spriteOrigin = new Vector2(0f, 0f);
        byte[] udpBuffer = new byte[9];

        // normalizedImageUpdated is accessed from differet threads. Mark it
        // volatile to make sure that every read gets the latest value.
        private volatile bool normalizedImageUpdated;

        private ImageMetrics normalizedMetrics;
        volatile public byte[] normalizedImage;

        private const uint sensor_width = 960;
        private const uint sensor_height = 540;
        private const uint sensor_count = sensor_width * sensor_height;

        private uint bestX = 0;
        private uint bestY = 0;
        private bool foundLight = false;
        





        // Blobing
        volatile private byte[] blobMembership = new byte[960 * 540];  // Holds the index of the blob the sensor is part of
        volatile private Blob[] blobs = new Blob[255];
        volatile private byte[] mergeTable = new byte[256];
        volatile private uint blobCount = 0;
        private const byte blobThreshhold = 180;
        private const byte NULL_BLOB = 0xff;
        public readonly uint[] colors = new uint[] { 0xffffffff, 0xffd50000, 0xff00ff00, 0xff0000ff, 0xffffff00, 0xff00ffff, 0xff900090 };

        private volatile uint frameCount = 0;

        // debug display options
        private bool showMetrics = true;
        private bool showBlobs = false;
        private bool showBlobBounds = true;

        // For Scaling the RawImage back to full screen.
        private float scale;

        // Something to lock to deal with asynchronous frame updates
        private readonly object syncObject = new object();

        private UdpClient udp;

        // Blend state used when drawing the raw image data on the screen.  Results
        // in a black background with image data shown in the color used to clear the display.
        private readonly BlendState textureBlendState = new BlendState
                                                            {
                                                                AlphaDestinationBlend = Blend.One,
                                                                AlphaSourceBlend = Blend.SourceAlpha,
                                                                ColorDestinationBlend = Blend.InverseSourceAlpha,
                                                                ColorSourceBlend = Blend.SourceAlpha
                                                            };

        /// <summary>
        /// Default constructor.
        /// </summary>
        public App()
        {
            graphics = new GraphicsDeviceManager(this);
            graphics.GraphicsProfile = GraphicsProfile.HiDef;

            for (int i = 0; i < sensor_width * sensor_height; ++i)
                blobMembership[i] = NULL_BLOB;

            udp = new UdpClient();
            udp.Connect("127.0.0.1", 1337);
        }

        public uint SensorIdx(uint x, uint y)
        {
            return x + y * sensor_width;
        }

        /// <summary>
        /// Allows the app to perform any initialization it needs to before starting to run.
        /// This is where it calls to loads amd Initializes SurfaceInput TouchTarget.  
        /// Calling base.Initialize will enumerate through any components
        /// and initialize them as well.
        /// </summary>
        protected override void Initialize()
        {
            IsMouseVisible = true; // easier for debugging not to "lose" mouse
            SetWindowOnSurface();
            InitializeSurfaceInput();

            // Subscribe to surface window availability events
            ApplicationServices.WindowInteractive += OnWindowInteractive;
            ApplicationServices.WindowNoninteractive += OnWindowNoninteractive;
            ApplicationServices.WindowUnavailable += OnWindowUnavailable;
            graphics.IsFullScreen = true;

            base.Initialize();
        }

        /// <summary>
        /// This is called when the user can interact with the application's window.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void OnWindowInteractive(object sender, EventArgs e)
        {
            // Turn raw image back on again
            touchTarget.EnableImage(ImageType.Normalized);
        }

        /// <summary>
        /// This is called when the user can see but not interact with the application's window.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void OnWindowNoninteractive(object sender, EventArgs e)
        {
        }

        /// <summary>
        /// This is called when the application's window is not visible or interactive.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void OnWindowUnavailable(object sender, EventArgs e)
        {
            // If the app isn't active, there's no need to keep the raw image enabled
            //touchTarget.DisableImage(ImageType.Normalized);
        }

        /// <summary>
        /// Moves and sizes the window to cover the input surface.
        /// </summary>
        private void SetWindowOnSurface()
        {
            System.Diagnostics.Debug.Assert(Window != null && Window.Handle != IntPtr.Zero,
                "Window initialization must be complete before SetWindowOnSurface is called");
            if (Window == null || Window.Handle == IntPtr.Zero)
                return;

            // Get the window sized right.
            Program.InitializeWindow(Window);
            // Set the graphics device buffers.
            graphics.PreferredBackBufferWidth = Program.WindowSize.Width;
            graphics.PreferredBackBufferHeight = Program.WindowSize.Height;
            graphics.ApplyChanges();
            // Make sure the window is in the right location.
            Program.PositionWindow();
        }

        /// <summary>
        /// Initializes the surface input system. This should be called after any window
        /// initialization is done, and should only be called once.
        /// </summary>
        private void InitializeSurfaceInput()
        {
            System.Diagnostics.Debug.Assert(Window != null && Window.Handle != IntPtr.Zero,
                "Window initialization must be complete before InitializeSurfaceInput is called");
            if (Window == null || Window.Handle == IntPtr.Zero)
                return;
            System.Diagnostics.Debug.Assert(touchTarget == null,
                "Surface input already initialized");
            if (touchTarget != null)
                return;

            // Create a target for surface input.
            touchTarget = new TouchTarget(Window.Handle, EventThreadChoice.OnBackgroundThread);
            touchTarget.EnableInput();

            // Enable the normalized raw-image.
            touchTarget.EnableImage(ImageType.Normalized);

            // Hook up a callback to get notified when there is a new frame available
            touchTarget.FrameReceived += OnTouchTargetFrameReceived;
        }

        /// <summary>
        /// Handler for the FrameReceived event. 
        /// Here we get the rawimage data from FrameReceivedEventArgs object.
        /// </summary>
        /// <remarks>
        /// When a frame is received, this event handler gets the normalized image 
        /// from the TouchTarget. The image is copied into the touch sprite in the 
        /// Update method. The reason for this separation is that this event handler is 
        /// called from a background thread and Update is called from the main thread. It 
        /// is not safe to get the normalized image from the TouchTarget in the Update 
        /// method because TouchTarget and Update run on different threads. It is 
        /// possible for TouchTarget to change the image while Update is accessing it.
        /// 
        /// To address the threading issue, the raw image is retrieved here, on the same 
        /// thread that updates and uses it on the main thread. It is stored in a variable 
        /// that is available to both threads, and access to the variable is controlled 
        /// through lock statements so that only one thread can use the image at a time.
        /// </remarks>
        /// <param name="sender">TouchTarget that received the frame</param>
        /// <param name="e">Object containing information about the current frame</param>
        private void OnTouchTargetFrameReceived(object sender, FrameReceivedEventArgs e)
        {
            // Lock the syncObject object so normalizedImage isn't changed while the Update method is using it

            lock (syncObject)
            {
                if (normalizedImage == null)
                {
                    // get rawimage data for a specific area
                    if (e.TryGetRawImage(
                            ImageType.Normalized,
                            0, 0,
                            1920, 1080,
                            out normalizedImage,
                            out normalizedMetrics))
                    {
                        scale = (InteractiveSurface.PrimarySurfaceDevice == null)
                                    ? 1.0f
                                    : (float)InteractiveSurface.PrimarySurfaceDevice.WorkingAreaWidth / normalizedMetrics.Width;
                    }

                    spriteData = new uint[normalizedMetrics.Width * normalizedMetrics.Height];
                }
                else
                {
                    // get the updated rawimage data for the specified area
                    e.UpdateRawImage(
                        ImageType.Normalized,
                        normalizedImage,
                        0, 0,
                        1920, 1080);
                }

                frameCount += 1;

                bestX = 0;
                bestY = 0;
                foundLight = false;
                uint bestPixelCount = 0;
                // reset blobcount and blob merge
                blobCount = 0;
                for (uint y = 1; y < sensor_height; y++)
                {
                    for (uint x = 1; x < sensor_width; x++)
                    {
                        uint i = SensorIdx(x, y);
                        blobMembership[i] = NULL_BLOB;

                        if (normalizedImage[i] < blobThreshhold)
                            continue;

                        byte downBlobId = blobMembership[SensorIdx(x, y - 1)];
                        byte backBlobId = blobMembership[SensorIdx(x - 1, y)];

                        // if either is not NULL_BLOB make the sensor a member of one
                        if (downBlobId != NULL_BLOB || downBlobId != NULL_BLOB)
                        {
                            byte blobId = Math.Min(downBlobId, backBlobId);
                            blobMembership[SensorIdx(x, y)] = blobId;
                            // update blob

                            blobs[blobId].maxX = Math.Max(x, blobs[blobId].maxX);
                            blobs[blobId].minX = Math.Min(x, blobs[blobId].minX);

                            blobs[blobId].maxY = Math.Max(y, blobs[blobId].maxY);
                            blobs[blobId].minY = Math.Min(y, blobs[blobId].minY);
                            blobs[blobId].pixelCount += 1;

                            // if neither is NULL_BLOB, map higher index to lower index
                            if (downBlobId != backBlobId && downBlobId != NULL_BLOB && backBlobId != NULL_BLOB)
                            {
                                while(blobId != mergeTable[blobId])
                                {
                                    blobId = mergeTable[blobId];
                                }
                                mergeTable[Math.Max(downBlobId, backBlobId)] = blobId;
                            }
                        }
                        else
                        {
                            // start new blob
                            if (blobCount == 255)
                                continue;

                            blobMembership[SensorIdx(x,y)] = (byte)blobCount;
                            blobs[blobCount] = new Blob(x, y);
                            mergeTable[blobCount] = (byte)blobCount;
                            blobCount += 1;
                        }
                    }
                }

                // iter backwards if things fuck up
                for (uint revBlobId = 0; revBlobId < blobCount; revBlobId++)
                {
                    byte blobId = (byte)(blobCount - revBlobId - 1);
                    byte mergeTo = mergeTable[blobId];
                    if (blobId == mergeTo) continue;
                    for (uint x = blobs[blobId].minX; x <= blobs[blobId].maxX; x++)
                    {
                        for (uint y = blobs[blobId].minY; y <= blobs[blobId].maxY; y++)
                        {
                            if(blobMembership[SensorIdx(x, y)] == blobId) {
                                blobMembership[SensorIdx(x, y)] = mergeTo;
                            }
                        }
                    }
                
                    blobs[mergeTo].maxX = Math.Max(blobs[mergeTo].maxX, blobs[blobId].maxX);
                    blobs[mergeTo].maxY = Math.Max(blobs[mergeTo].maxY, blobs[blobId].maxY);
                    blobs[mergeTo].minX = Math.Min(blobs[mergeTo].minX, blobs[blobId].minX);
                    blobs[mergeTo].minY = Math.Min(blobs[mergeTo].minY, blobs[blobId].minY);
                
                    blobs[mergeTo].pixelCount += blobs[blobId].pixelCount;
                    blobs[blobId].pixelCount = 0;                    
                }

                //for (int i = 0; i < normalizedMetrics.Width * normalizedMetrics.Height; ++i)
                //{
                //    spriteData[i] = 0xff000000;
                //    if (showMetrics)
                //    {
                //        spriteData[i] = 0xff000000 | ((uint)normalizedImage[i] << 0) | ((uint)normalizedImage[i] << 8) | ((uint)normalizedImage[i] << 16);
                //    
                //    }
                //    if (blobMembership[i] != NULL_BLOB && showBlobs)
                //    {
                //        spriteData[i] = colors[blobMembership[i] % colors.Length];
                //    }
                //}

                if (showBlobBounds)
                {
                    {
                        for (int bi = 0; bi < blobCount; bi++)
                        {
                            if (blobs[bi].pixelCount == 0) continue;

                            //spriteData[SensorIdx(blobs[bi].maxX, blobs[bi].maxY)] = 0xff0000ff;
                            //spriteData[SensorIdx(blobs[bi].minX, blobs[bi].minY)] = 0xff0000ff;
                            //spriteData[SensorIdx(blobs[bi].maxX, blobs[bi].minY)] = 0xff0000ff;
                            //spriteData[SensorIdx(blobs[bi].minX, blobs[bi].maxY)] = 0xff0000ff;

                            uint centerX = (blobs[bi].minX + blobs[bi].maxX) / 2;
                            uint centerY = (blobs[bi].maxY + blobs[bi].minY) / 2;
                            //spriteData[SensorIdx(centerX, centerY)] = 0xffff00ff;

                            if(blobs[bi].pixelCount > bestPixelCount && blobs[bi].pixelCount >= 100)
                            {
                                bestPixelCount = blobs[bi].pixelCount;
                                bestX = centerX;
                                bestY = centerY;
                                foundLight = true;
                            }
                        }
                    }
                }

                normalizedImageUpdated = true;
           
            }
        }
        

        /// <summary>
        /// Load your graphics content.
        /// </summary>
        protected override void LoadContent()
        {
            foregroundBatch = new SpriteBatch(graphics.GraphicsDevice);
        }

        /// <summary>
        /// Unload your graphics content.
        /// </summary>
        protected override void UnloadContent()
        {
            Content.Unload();
        }

        /// <summary>
        /// Allows the app to run logic such as updating the world,
        /// checking for collisions, gathering input and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            lock (syncObject)
            {
                if (normalizedImageUpdated)
                {
                    normalizedImageUpdated = false;
                    if (foundLight)
                    {
                        float relativeX = ((float)bestX) / ((float)sensor_width);
                        float relativeY = ((float)bestY) / ((float)sensor_height);

                        udpBuffer[0] = 1;

                        byte[] relativeXBytes = BitConverter.GetBytes(relativeX);
                        udpBuffer[1] = relativeXBytes[0];
                        udpBuffer[2] = relativeXBytes[1];
                        udpBuffer[3] = relativeXBytes[2];
                        udpBuffer[4] = relativeXBytes[3];

                        byte[] relativeYBytes = BitConverter.GetBytes(relativeY);
                        udpBuffer[5] = relativeYBytes[0];
                        udpBuffer[6] = relativeYBytes[1];
                        udpBuffer[7] = relativeYBytes[2];
                        udpBuffer[8] = relativeYBytes[3];

                        udp.Send(udpBuffer, 9);
                    }
                    else
                    {
                        udpBuffer[0] = 0;
                        udp.Send(udpBuffer, 1);
                    }
                }
            }
            


            //// Lock the syncObject object so the normalized image and metrics aren't updated while this method is using them
            //lock (syncObject)
            //{
            //    // Don't bother if the app isn't visible, or if the image hasn't been updates since the last update
            //    if (normalizedImageUpdated) //&&
            //        //(ApplicationServices.WindowAvailability != WindowAvailability.Unavailable))
            //    {
            //        if (normalizedMetrics != null)
            //        {
            //            if (touchSprite == null)
            //            {
            //                // Creating a Sprite from the rawimage metrics data
            //                touchSprite = new Texture2D(graphics.GraphicsDevice,
            //                                              normalizedMetrics.Width,
            //                                              normalizedMetrics.Height,
            //                                              true,
            //                                              SurfaceFormat.Color);
            //            }
            //
            //            // Texture2D requires that the texture is not set on the device when updating it, so set it null               
            //            graphics.GraphicsDevice.Textures[0] = null;
            //
            //            // Setting the Texture2D with normalized rawimage data.
            //            touchSprite.SetData<uint>(spriteData,
            //                                      0,
            //                                      normalizedMetrics.Width * normalizedMetrics.Height);
            //        }
            //    }
            //    // reset the flag
            //    normalizedImageUpdated = false;
            //}


            base.Update(gameTime);

        }
        /// <summary>
        /// This is called when the app should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            //if (!applicationLoadCompleteSignalled)
            //{
            //    // Dismiss the loading screen now that we are starting to draw
            //    ApplicationServices.SignalApplicationLoadComplete();
            //    applicationLoadCompleteSignalled = true;
            //}
            //
            //// This controls the color of the image data.
            //graphics.GraphicsDevice.Clear(Color.Black);
            //
            //foregroundBatch.Begin(SpriteSortMode.Immediate, textureBlendState);
            //// draw the sprite of RawImage
            //if (touchSprite != null)
            //{
            //    // Adds the rawimage sprite to Spritebatch for drawing.
            //    foregroundBatch.Draw(touchSprite, spriteOrigin, null, Color.White,
            //       0f, spriteOrigin, scale, SpriteEffects.FlipVertically, 0f);
            //}
            //foregroundBatch.End();
            //
            base.Draw(gameTime);
        }

        #region IDisposable
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                // Release  managed resources.
                if (touchSprite != null)
                    touchSprite.Dispose();
                
                if (foregroundBatch != null)
                    foregroundBatch.Dispose();
                
                if (touchTarget != null)
                    touchTarget.Dispose();
                

                IDisposable graphicsDispose = graphics as IDisposable;
                if (graphicsDispose != null)
                    graphicsDispose.Dispose();
            }

            // Release unmanaged Resources.
            base.Dispose(disposing);
        }

        #endregion
    }

}
