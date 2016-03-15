//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ViewController.h"
#import "DownloadViewController.h"
#import "FirebaseStorage.h"

@import Firebase.Auth;

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *takePicButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadPicButton;
@property (weak, nonatomic) IBOutlet UITextView *urlTextView;

@property (strong, nonatomic) FIRStorageReference *storageRef;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // [START configurestorage]
  FIRFirebaseApp *app = [FIRFirebaseApp app];
  self.storageRef = [[FIRStorage storageWithApp:app] reference];
  // [END configurestorage]

  // [START storageauth]
  // Using Firebase Storage requires the user be authenticated. Here we are using
  // anonymous authentication.
  if (![FIRAuth auth].currentUser) {
    [[FIRAuth auth] signInAnonymouslyWithCallback:^(FIRUser * _Nullable user, NSError * _Nullable error) {
      if (error) {
        _urlTextView.text = error.description;
        _takePicButton.enabled = NO;
        _downloadPicButton.enabled = NO;
      } else {
        _takePicButton.enabled = YES;
        _downloadPicButton.enabled = YES;
        _urlTextView.text = @"";
      }
    }];
  }
  // [END storageauth]
}

# pragma mark - Image Picker

- (IBAction)didTapTakePicture:(id)sender {
  UIImagePickerController * picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
  } else {
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  }

  [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [picker dismissViewControllerAnimated:YES completion:NULL];

  UIImage *image = info[UIImagePickerControllerOriginalImage];
  NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
  _urlTextView.text = @"Beginning Upload";

  // [START uploadimage]
  FIRStorageMetadata *metadata = [FIRStorageMetadata new];
  metadata.contentType = @"image/jpeg";
  FIRStorageUploadTask *upload = [[_storageRef childByAppendingPath:@"myimage.jpg"]
                                  putData:imageData
                                  metadata:metadata];


  // [END uploadimage]

  // [START oncomplete]
  [upload observeStatus:FIRTaskStatusSuccess
      withCallback:^(FIRStorageUploadTask *task) {
        _urlTextView.text = @"Upload Succeeded!";
        [self onSuccesfulUpload];
      }];
  // [END oncomplete]

  // [START onfailure]
  [upload observeStatus:FIRTaskStatusFailure
      withErrorCallback:^(FIRStorageUploadTask *task, NSError *error) {
        if (error) {
          NSLog(@"Error uploading: %@", error);
        }
        _urlTextView.text = @"Upload Failed";
      }];
  // [END onfailure]
}

- (void)onSuccesfulUpload {
  NSLog(@"Retrieving metadata");
  _urlTextView.text = @"Fetching Metadata";
  // [START getmetadata]
  [[_storageRef childByAppendingPath:@"myimage.jpg"]
    downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
      if (error) {
        NSLog(@"Error retrieving metadata: %@", error);
        _urlTextView.text = @"Error Fetching Metadata";
        return;
      }

      _urlTextView.text = [URL absoluteString];
      NSLog(@"Uplodaded and retrieved URL: %@", URL);
    }];
  // [END getmetadata]
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
}


@end