// -----------------------------------------------------------------------------
// Copyright 2016 Patrick Näf (herzbube@herzbube.ch)
//
// This file is part of birthtime_touch
//
// birthtime_touch is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// birthtime_touch is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with birthtime_touch. If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// Imports/includes
// -----------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#include <sys/stat.h>

// -----------------------------------------------------------------------------
// Constants
// -----------------------------------------------------------------------------
const char* version = "0.1";
const NSStringEncoding cStringEncoding = NSUTF8StringEncoding;

// -----------------------------------------------------------------------------
// Functions
// -----------------------------------------------------------------------------
void printUsageAndExit(int exitCode)
{
  const char* processName = [[[NSProcessInfo processInfo] processName] cStringUsingEncoding:cStringEncoding];

  fprintf(stderr, "Usage: %s --adjust (+|-)hhmmss file1 [file2 ...]\n", processName);
  fprintf(stderr, "       %s --help\n", processName);
  fprintf(stderr, "       %s --version\n", processName);

  exit(exitCode);
}

void printVersionAndExit()
{
  const char* processName = [[[NSProcessInfo processInfo] processName] cStringUsingEncoding:cStringEncoding];

  fprintf(stderr, "%s version %s\n", processName, version);

  exit(0);
}

// -----------------------------------------------------------------------------
// Main program
// -----------------------------------------------------------------------------
int main(int argc, char* argv[])
{
  if (1 == argc)
    printUsageAndExit(1);

  // Objective-C memory management
  @autoreleasepool
  {
    time_t timeDelta = 0;
    NSMutableDictionary* fileNamesToAdjust = [NSMutableDictionary dictionary];

    bool nextArgumentIsAdjust = false;
    bool adjustArgumentSpecified = false;

    NSArray* arguments = [[NSProcessInfo processInfo] arguments];
    arguments = [arguments subarrayWithRange:NSMakeRange(1, arguments.count - 1)];
    for (NSString* argument in arguments)
    {
      if (nextArgumentIsAdjust)
      {
        adjustArgumentSpecified = true;
        nextArgumentIsAdjust = false;

        if (argument.length != 7)
        {
          fprintf(stderr, "Illegal timespec for --adjust: must be 7 characters long\n");
          exit(1);
        }

        bool adjustOperationIsAddition;
        if ([argument hasPrefix:@"+"])
        {
          adjustOperationIsAddition = true;
        }
        else if ([argument hasPrefix:@"-"])
        {
          adjustOperationIsAddition = false;
        }
        else
        {
          fprintf(stderr, "Illegal timespec for --adjust: must begin with '+' or '-'\n");
          exit(1);
        }

        NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        NSRange firstNonNumberCharacter = [[argument substringFromIndex:1] rangeOfCharacterFromSet:nonNumbers];
        if (firstNonNumberCharacter.location != NSNotFound)
        {
          fprintf(stderr, "Illegal timespec for --adjust: must contain only numbers after initial '+' or '-'\n");
          exit(1);
        }

        int adjustHours = [[argument substringWithRange:NSMakeRange(1, 2)] integerValue];
        int adjustMinutes = [[argument substringWithRange:NSMakeRange(3, 2)] integerValue];
        int adjustSeconds = [[argument substringWithRange:NSMakeRange(5, 2)] integerValue];

        timeDelta = 3600 * adjustHours + 60 * adjustMinutes + adjustSeconds;
        if (0 == timeDelta)
        {
          fprintf(stderr, "Nothing to adjust\n");
          exit(0);
        }

        if (! adjustOperationIsAddition)
          timeDelta *= -1;
      }
      else
      {
        if ([argument isEqual:@"--adjust"])
        {
          nextArgumentIsAdjust = true;
        }
        else if ([argument isEqual:@"--help"])
        {
          printUsageAndExit(0);
        }
        else if ([argument isEqual:@"--version"])
        {
          printVersionAndExit();
        }
        else
        {
          if (! adjustArgumentSpecified)
          {
            fprintf(stderr, "--adjust must be specified before any file names\n");
            exit(1);
          }

          const char* fileName = [argument cStringUsingEncoding:cStringEncoding];
          struct stat st;
          if (stat(fileName, &st) != 0)
          {
            perror(fileName);
            exit(1);
          }

          time_t creationTimeSeconds = st.st_birthtimespec.tv_sec;
          time_t adjustedCreationTimeSeconds = creationTimeSeconds + timeDelta;
          NSDate* adjustedCreationTimeDate = [NSDate dateWithTimeIntervalSince1970:adjustedCreationTimeSeconds];

          fileNamesToAdjust[argument] = adjustedCreationTimeDate;
        }
      }
    }

    if (0 == fileNamesToAdjust.count)
    {
      fprintf(stderr, "No files specified\n");
      exit(1);
    }

    // At this point we know that the specified files exist and their directory
    // entries are readable, because a prior call to stat() has succeeded. It is
    // still possible, though, that changing the creation time fails, because
    // a file's directory entry is not writable.

    // TODO: What happens if the file system does not store file creation time?

    NSFileManager* fileManager = [NSFileManager defaultManager];

    for (NSString* fileNameToAdjust in fileNamesToAdjust)
    {
      NSDate* adjustedCreationTimeDate = fileNamesToAdjust[fileNameToAdjust];
      NSDictionary* attributes = @{NSFileCreationDate : adjustedCreationTimeDate};

      NSError* error = nil;
      BOOL success = [fileManager setAttributes:attributes ofItemAtPath:fileNameToAdjust error:&error];
      if (NO == success)
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Failed to set creation date: %@ (error code = %ld)", error.localizedDescription, static_cast<long>(error.code)];
        fprintf(stderr, "%s\n", [errorMessage cStringUsingEncoding:cStringEncoding]);
        NSError* underlyingError = error.userInfo[NSUnderlyingErrorKey];
        if (underlyingError != nil)
        {
          errorMessage = [NSString stringWithFormat:@"Underlying error: %@ (error code = %ld)", underlyingError.localizedDescription, static_cast<long>(underlyingError.code)];
          fprintf(stderr, "%s\n", [errorMessage cStringUsingEncoding:cStringEncoding]);
        }
        exit(1);
      }
    }
  }

  return 0;
}
