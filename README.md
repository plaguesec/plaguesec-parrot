# <img align="left" src="https://raw.githubusercontent.com/PlagueSec/PlagueSecOS/master/pictures/plaguesec.svg"> PlagueSecurity Operating System 

A Customed Operating System for Security Researchers and Penetration Testers. Based on [Parrot](https://parrotsec.org/)

&nbsp;


### Plague Security Editions
[Plague Security Live Build ISO](https://github.com/plaguesec/plaguesec-os)  
Plague Security Raspberry PI Editon (Soon)  
Plague Security Tablet (Soon)  

&nbsp;

&nbsp;

&nbsp;

### Available ISO Variants
- Clean (KDE)
- KDE
- XFCE

## Release Package
You can download the release package which is more stable than the updated repository, after downloading just follow the instruction below but exclude `git clone https://github.com/PlagueSec/plaguesec-os.git` command since we already have the release downloaded.

### Instruction for building an ISO on a Parrot System
Download the Release File
```
$ wget https://github.com/plaguesec/plaguesec-os/archive/refs/tags/vx.x.x.zip
$ unzip plaguesec-os-x.x.x.zip
$ cd plaguesec-os-x.x.x
```
Now we need to install the requirements to build the operating system
```
$ sudo apt install -y git simple-cdd cdebootstrap curl live-build
```
Now let us Build The Operating System
```
$ sudo ./build.sh --variant (clean, kde, xfce) -v 
```

## Updated Package (Unstable) 
Clone the Repository
```
$ git clone https://github.com/plaguesec/plaguesec-os.git
$ cd plaguesec-os
```
Now we need to install the requirements to build the operating system
```
$ sudo apt install -y git simple-cdd cdebootstrap curl live-build
```
Now let us Build The Operating System
```
$ sudo ./build.sh --variant (clean, kde, xfce) -v 
```

### Help Screen
You can see all the available command-line options by doing `--help`:

```
  --distribution <Distro>
  --proposed-updates
  --arch <amd64 / i386>
  --verbose
  --debug
  --salt
  --installer
  --live
  --variant <xfce / kde / clean>
  --version <5.0>
  --subdir
  --get-image-path
  --no-clean
  --clean
  --help
```
## Contributing
Contributions are welcome create a pull request to this repo and I will review your code. Please consider to submit your pull request to the dev branch. Please make sure you clone in a linux machine since using windows might break the permissions of each file. Thank you!

## Temporary Download Link
[XFCE](https://drive.google.com/file/d/1-msJ9-MPiiMIAnC9G22NdEEiGdS8GByy/view?usp=sharing)  
[KDE](https://drive.google.com/file/d/1nlII4wAhVv6hNKnIGtyCdX2usNAT0iAh/view?usp=sharing)

## Official Platforms
[Plague Security Official Website](https://plaguesec.com)

[Plague Security Official Facebook](https://www.facebook.com/PlagueSec-104041125002327)

## Credits
#### Based Operating System  
[Parrot](https://parrotsec.org/)

#### Themes  
[Fluent KDE](https://github.com/vinceliuice/Fluent-kde)  
[Yaru Dark](https://github.com/ubuntu/yaru)

#### Icon Themes  
[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)  
