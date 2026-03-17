using System;
using System.IO;
using System.Threading.Tasks;
using Windows.Media.Capture;
using Windows.Graphics.Imaging;
using Windows.Storage;

class CameraCapture
{
    static async Task Main(string[] args)
    {
        try
        {
            if (args.Length < 1)
            {
                Console.Error.WriteLine("Usage: CameraCapture.exe <output_path>");
                Environment.Exit(1);
            }

            string outputPath = args[0];
            Console.WriteLine("Initializing camera capture...");
            
            // Create MediaCapture object
            var mediaCapture = new MediaCapture();
            
            // Initialize with default camera
            var cameraSettings = new MediaCaptureInitializationSettings
            {
                StreamingCaptureMode = StreamingCaptureMode.Video,
                PhotoCaptureSource = PhotoCaptureSource.VideoPreview
            };
            
            Console.WriteLine("Attempting to initialize camera...");
            await mediaCapture.InitializeAsync(cameraSettings);
            
            Console.WriteLine("Camera initialized successfully");
            
            // Take photo
            var photoProperties = ImageEncodingProperties.CreateJpeg();
            
            var storageFolder = await StorageFolder.GetFolderFromPathAsync(Path.GetDirectoryName(outputPath));
            var storageFile = await storageFolder.CreateFileAsync(
                Path.GetFileName(outputPath),
                CreationCollisionOption.ReplaceExisting);
            
            Console.WriteLine("Capturing photo...");
            await mediaCapture.CapturePhotoToStorageFileAsync(photoProperties, storageFile);
            
            Console.WriteLine("SUCCESS: Photo captured to " + outputPath);
            mediaCapture.Dispose();
            Environment.Exit(0);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("ERROR: " + ex.Message);
            Console.Error.WriteLine("Stack: " + ex.StackTrace);
            Environment.Exit(1);
        }
    }
}
