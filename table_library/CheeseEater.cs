using System;
using System.Threading;
using Microsoft.Surface.Core;

namespace Cheese_Eater_Library
{
    public struct Blob
    {
        public uint pixelCount;
        public uint minX;
        public uint minY;
        public uint maxX;
        public uint maxY;

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

    public class CheeseEater
    {
        private const uint sensorWidth = 960;
        private const uint sensorHeight = 540;
        private const uint sensorCount = sensorWidth * sensorHeight;
        private const byte brightnessThreshhold = 180;
        private const byte pixelCountThreshhold = 100;
        private const byte NULL_BLOB = 0xff;

        private static TouchTarget touchTarget;

        private static ImageMetrics normalizedMetrics;
        volatile private static byte[] normalizedImage;

        volatile private static byte[] blobMembership = new byte[960 * 540];  // Holds the index of the blob the sensor is part of
        volatile private static byte[] mergeTable = new byte[256];
        volatile private static Blob[] tmpBlobs = new Blob[255];

        volatile private static Blob[] validBlobs = new Blob[255];
        volatile private static uint validBlobCount = 0;

        private static Mutex mutex = new Mutex();

        [DllExport]
        public static void init(IntPtr hwnd)
        {
            // Create a target for surface input.
            touchTarget = new TouchTarget(hwnd, EventThreadChoice.OnBackgroundThread);
            touchTarget.EnableInput();

            // Enable the normalized raw-image.
            touchTarget.EnableImage(ImageType.Normalized);

            // Hook up a callback to get notified when there is a new frame available
            touchTarget.FrameReceived += OnTouchTargetFrameReceived;
        }

        [DllExport]
        public static uint accuireAccess()
        {
            mutex.WaitOne();
            return validBlobCount;
        }

        [DllExport]
        public static void releaseAccess()
        {
            mutex.ReleaseMutex();
        }

        [DllExport]
        public static float getX(uint i)
        {
            return (float)((validBlobs[i].maxX + validBlobs[i].minX) / 2) / ((float)sensorWidth);
        }

        [DllExport]
        public static float getY(uint i)
        {
            return (float)((validBlobs[i].maxY + validBlobs[i].minY) / 2) / ((float)sensorHeight);
        }

        [DllExport]
        public static float getSizeX(uint i)
        {
            return (float)(validBlobs[i].maxX - validBlobs[i].minX) / ((float)sensorWidth);
        }

        [DllExport]
        public static float getSizeY(uint i)
        {
            return (float)(validBlobs[i].maxY - validBlobs[i].minY) / ((float)sensorHeight);
        }

        private static uint SensorIdx(uint x, uint y)
        {
            return x + y * sensorWidth;
        }

        private static void OnTouchTargetFrameReceived(object sender, FrameReceivedEventArgs e)
        {
            if (normalizedImage == null)
            {
                // get rawimage data for a specific area
                e.TryGetRawImage(
                    ImageType.Normalized,
                    0, 0,
                    1920, 1080,
                    out normalizedImage,
                    out normalizedMetrics);
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

            uint tmpBlobCount = 0;
            for (uint y = 1; y < sensorHeight; y++)
            {
                for (uint x = 1; x < sensorWidth; x++)
                {
                    uint i = SensorIdx(x, y);
                    blobMembership[i] = NULL_BLOB;
                    if (normalizedImage[i] < brightnessThreshhold)
                        continue;
                    byte downBlobId = blobMembership[SensorIdx(x, y - 1)];
                    byte backBlobId = blobMembership[SensorIdx(x - 1, y)];
                    // if either is not NULL_BLOB make the sensor a member of one
                    if (downBlobId != NULL_BLOB || downBlobId != NULL_BLOB)
                    {
                        byte blobId = Math.Min(downBlobId, backBlobId);
                        blobMembership[SensorIdx(x, y)] = blobId;
                        // update blob
                        tmpBlobs[blobId].maxX = Math.Max(x, tmpBlobs[blobId].maxX);
                        tmpBlobs[blobId].minX = Math.Min(x, tmpBlobs[blobId].minX);
                        tmpBlobs[blobId].maxY = Math.Max(y, tmpBlobs[blobId].maxY);
                        tmpBlobs[blobId].minY = Math.Min(y, tmpBlobs[blobId].minY);
                        tmpBlobs[blobId].pixelCount += 1;
                        // if neither is NULL_BLOB, map higher index to lower index
                        if (downBlobId != backBlobId && downBlobId != NULL_BLOB && backBlobId != NULL_BLOB)
                        {
                            while (blobId != mergeTable[blobId])
                            {
                                blobId = mergeTable[blobId];
                            }
                            mergeTable[Math.Max(downBlobId, backBlobId)] = blobId;
                        }
                    }
                    else
                    {
                        // start new blob
                        if (tmpBlobCount == 255)
                            continue;
                        blobMembership[SensorIdx(x, y)] = (byte)tmpBlobCount;
                        tmpBlobs[tmpBlobCount] = new Blob(x, y);
                        mergeTable[tmpBlobCount] = (byte)tmpBlobCount;
                        tmpBlobCount += 1;
                    }
                }
            }
            
            // iter backwards if things fuck up
            for (uint revBlobId = 0; revBlobId < tmpBlobCount; revBlobId++)
            {
                byte blobId = (byte)(tmpBlobCount - revBlobId - 1);
                byte mergeTo = mergeTable[blobId];
                if (blobId == mergeTo) continue;
                for (uint x = tmpBlobs[blobId].minX; x <= tmpBlobs[blobId].maxX; x++)
                {
                    for (uint y = tmpBlobs[blobId].minY; y <= tmpBlobs[blobId].maxY; y++)
                    {
                        if (blobMembership[SensorIdx(x, y)] == blobId)
                        {
                            blobMembership[SensorIdx(x, y)] = mergeTo;
                        }
                    }
                }
                tmpBlobs[mergeTo].maxX = Math.Max(tmpBlobs[mergeTo].maxX, tmpBlobs[blobId].maxX);
                tmpBlobs[mergeTo].maxY = Math.Max(tmpBlobs[mergeTo].maxY, tmpBlobs[blobId].maxY);
                tmpBlobs[mergeTo].minX = Math.Min(tmpBlobs[mergeTo].minX, tmpBlobs[blobId].minX);
                tmpBlobs[mergeTo].minY = Math.Min(tmpBlobs[mergeTo].minY, tmpBlobs[blobId].minY);
                tmpBlobs[mergeTo].pixelCount += tmpBlobs[blobId].pixelCount;
                tmpBlobs[blobId].pixelCount = 0;
            }

            mutex.WaitOne();
            validBlobCount = 0;
            for (int bi = 0; bi < tmpBlobCount; bi++)
            {
                if (tmpBlobs[bi].pixelCount == 0) continue;
                
                if (tmpBlobs[bi].pixelCount >= pixelCountThreshhold)
                {
                    validBlobs[validBlobCount] = tmpBlobs[bi];
                    validBlobCount += 1;
                }
            }

            mutex.ReleaseMutex();
        }
    }
}
