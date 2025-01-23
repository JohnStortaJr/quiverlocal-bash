# quiverlocal
Tools for building local WordPress development environments in WSL (Windows Subsystem for Linux)

This tool should work in most Ubuntu/Debian environments, but it has not been fully tested.

## Background
There are tools available to create local WordPress environments on Windows and Linux platforms. The struggle I had was getting an environment that would run on WSL. This is the layer that allows you to run a Linux instance directly on your Windows machine. This was critical for me as I had little interest in developing in Windows and wanted the flexibility that WSL offered. Unfortunately, the tools I found for creating a WordPress environment did not work in WSL. 

So I decided to make my own.

## Approach
The first thing I needed to do was to fully document exactly how to create a local WordPress environmnet locally. I am not one to be content with relying on other tools to do the work. I first want to know how to do it myself and then I can use tools to make it easier.

WordPress is actually a very simple configuration. There is an underlying database with a number of core tables where all of the content is stored. There are then files in the form of configurations and php scripts that do all the management of that content. To setup a local environment you need a web server (like Apache), the WordPress files, and a database (MySQL).

After spending some time documenting all of the steps needed to build out an environment, I was ready to automate the process.

If you want to use the Python version which includes a more user-friendly, menu-driven interface, check out the [quiverlocal-python](https://github.com/JohnStortaJr/quiverlocal) repository.

## Bash Scripts
I have a background in Unix, so my initial plan was to create bash scripts for each of the different tasks. These would include the following.
- New Installation
- Import Existing Website
- Delete Website
- Add SSL Certificate to a Site

In the bash folder of this repository, you will find all of those scripts. Simply run each script and you will be prompted for the necessary inputs to complete the task.

Be aware that there are some limitations and there is not a ton of error-checking.
- The scripts just run with minimal error checking. If something goes wrong, the script will continue on with attempting the install.
- There are no checks to ensure the site to try to create is unique. Creating a site that already exists will cause errors.
- There are some checks to ensure database names and such do not have weird characters, but not much beyond that.
- In short, there is an expectation that the person running the scripts knows what they are doing and are just using the scripts to make it easier
- On the plus side, the uninstall script will remove all the files associated with a site so if you mess something up, just run that script and it will clean everything.

### install.bash
This is the basic script. It will prompt you for the site name along with some other key values. Upon confirming the configuration, the script will download and extract the latest WordPress files, create an empty MySQL database, and setup the configuration files for the web server. You must then connect to the new website so that WordPress can perform the initial configuration. Once that is complete, then the new site is ready to go.

### import.bash
This will create a new site using files that you provide. It will prompt you for the site name and other details as with a new installation, but you will also be asked to provide the path to the files you are importing and the data you are importing.

The Import Files should be a tar.gz of the site you are cloning. It should include the top-level directory. For example, if the file you are cloning is mysite.com, then the tar.gz should include mysite.com as the top-level, not just the files within that folder.

The Import Data should be an sql.gz export of the database you are cloning. phpMyAdmin provides a tool for exporting the data from a database. Make sure that you choose the gzip compression option.

As with a new install, this will create a new local site. The only difference is that instead of downloading the latest WordPress files, it will use the import files you provide as the WordPress source. And instead of an empty database that needs to be configured, it will import the data you provide and update the URL within the WordPress configuration. Once the import is complete, your site will be accessible locally.

### makerootcert.bash
For local development, a regular http site is generally sufficent. But there are situations where you need use https. In order for this to work, you need to setup your system as a Certificate Authority. I will save the details about this for a full tutorial, but the first step is you need to create a Root Certificate using this script. It will prompt you for a much of information. Where possible, I provide default values that are acceptable. 

Once the Root Certificate is created, you need to add the .pem file to your Trusted Hosts section within the Windows MMC tool. I will cover this more at a later time. 

### trustsite.bash
Once you are setup as a Certificate Authority, then you need to create a certificate that is signed by that Root certificate. I do not have a script for that and I will cover it all in a later tutorial. This script simply takes the certificate that you generated and adds it to the site configuration so that you can use https. 

If all the certificate steps are in place, then you will be able to access your local site using https.

### uninstall.bash
After confirming your choice to delete a site, this script will delete all files and databases with that name. Note that the scripts have no configuration database. It simply uses the name you provide and deletes those files and the database.


### Usage
Run the appropriate script based on what action you need to perform.
