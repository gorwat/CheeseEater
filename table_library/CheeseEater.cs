using System;
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
        private const byte blobThreshhold = 180;
        private const byte NULL_BLOB = 0xff;

        private static TouchTarget touchTarget;

        private static ImageMetrics normalizedMetrics;
        volatile private static byte[] normalizedImage;

        private static uint bestX = 0;
        private static uint bestY = 0;
        private static bool foundLight = false;

        volatile private static byte[] blobMembership = new byte[960 * 540];  // Holds the index of the blob the sensor is part of
        volatile private static Blob[] blobs = new Blob[255];
        volatile private static byte[] mergeTable = new byte[256];
        volatile private static uint blobCount = 0;

        private static readonly object syncObject = new object();

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
        public static bool isOn()
        {
            return foundLight;
        }

        [DllExport]
        public static float getX()
        {
            return ((float)bestX) / ((float)sensorWidth);
        }

        [DllExport]
        public static float getY()
        {
            return ((float)bestY) / ((float)sensorHeight);
        }

        private static uint SensorIdx(uint x, uint y)
        {
            return x + y * sensorWidth;
        }

        private static void OnTouchTargetFrameReceived(object sender, FrameReceivedEventArgs e)
        {
            // Lock the syncObject object so normalizedImage isn't changed while the Update method is using it
            lock (syncObject)
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

                bestX = 0;
                bestY = 0;
                foundLight = false;
                uint bestPixelCount = 0;
                // reset blobcount and blob merge
                blobCount = 0;
                for (uint y = 1; y < sensorHeight; y++)
                {
                    for (uint x = 1; x < sensorWidth; x++)
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
                            if (blobCount == 255)
                                continue;

                            blobMembership[SensorIdx(x, y)] = (byte)blobCount;
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
                            if (blobMembership[SensorIdx(x, y)] == blobId)
                            {
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

                for (int bi = 0; bi < blobCount; bi++)
                {
                    if (blobs[bi].pixelCount == 0) continue;

                    uint centerX = (blobs[bi].minX + blobs[bi].maxX) / 2;
                    uint centerY = (blobs[bi].maxY + blobs[bi].minY) / 2;

                    if (blobs[bi].pixelCount > bestPixelCount && blobs[bi].pixelCount >= 100)
                    {
                        bestPixelCount = blobs[bi].pixelCount;
                        bestX = centerX;
                        bestY = centerY;
                        foundLight = true;
                    }
                }
            }
        }
    }
}
