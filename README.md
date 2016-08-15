# birthtime_touch

`birthtime_touch` is a simple command line tool that works similar to `touch`, but changes a file's creation time (its "birth time") instead of its access and modification times.

Usage:

    birthtime_touch --adjust (+|-)hhmmss file1 [file2 ...]

The following example adds 7 hours to the creation time of `aFile`:

    birthtime_touch --adjust +070000 aFile


# Limitations

`birthtime_touch` currently only runs on Mac OS X. The minimum required version is Mac OS X 10.6. `birthtime_touch` is known to work for files that are stored on HFS+ and MS-DOS filesystems.

The main problem why `birthtime_touch` does not work on all systems and for all filesystems, is that not all filesystems store a file's creation time, and for those that actually *do* store the creation time there is no standardized API to access/change that information.


# Known Bugs

`birthtime_touch` currently does not handle symbolic links correctly.


# Missing features

Generally `birthtime_touch` should adopt those features from `touch` for which it makes sense. Notably these are:

* Set creation time to the same time as a reference file
* Set creation time to a specifed time
* Extend `--adjust` so that days can be specified
* Prevent dereferencing of symbolic links

In addition the following things would also be nice:

* Support short command line options
* Provide a man page
* Run not only on Mac OS X, but also on Linux and Windows

The following filesystems are known to store file creation time, so supporting them in the future is at least a possibility.

* ext4
* Btrfs
* ZFS
* JFS
* UFS2
* NTFS. The open source filesystem driver `ntfs-3g` exposes creation time via extended file attributes.
* Samba


# Building from source

Install Xcode, then run

    ./build.sh
 
You can find all build results in the `build` subfolder. Because `birthtime_touch` is such a simple program, I didn't take the time to set up a proper Xcode project.


# References

The current implementation of `birthtime_touch` is based on [this StackOverflow answer](http://stackoverflow.com/a/16302660/1054378): It uses the Cocoa class `NSFileManager` for changing the file creation time. [Here is an alternative SO answer](http://stackoverflow.com/a/38885787/1054378) that shows how to achieve the same result with the Core Foundation function `CFURLSetResourcePropertyForKey`.

Other useful references that concern themselves with file creation time:

* http://unix.stackexchange.com/questions/7562/what-file-systems-on-linux-store-the-creation-time
* https://lwn.net/Articles/397442/
* http://unix.stackexchange.com/questions/91197/how-to-find-creation-date-of-file
* http://superuser.com/questions/387042/how-to-check-all-timestamps-of-a-file


# License

`birthtime_touch` is licensed under the GNU General Public License (GPLv3). See the file `COPYING`.


# Adjusting the times of a digital camera image

The motivation for writing `birthtime_touch` was to fix the creation time of image files after they are imported from a digital camera that had its time zone set up wrongly at the time when the images were shot. Here are the three commands that are necessary to add 7 hours to a single image file:

    birthtime_touch --adjust +070000 anImage.jpg
    touch -A +070000 anImage.jpg
    exiv2 --keep --adjust +07 ad anImage.jpg

The [Exiv2 utility](http://www.exiv2.org/) is necessary to fix the image file's Exif metadata. After these changes, the image file probably must be re-imported into the digital image library program (e.g. iPhoto).
