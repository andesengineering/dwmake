###DWMAKE

DWMake is nothing more than some gnu makefiles with pre-defined targets, rules and definitions to create an environment for building C++ files efficiently in the Linux environment.  

##Configure

The following set-up can be modified to your preferences.  It uses a home bin directory and aliases 'make' to point to 'dwmake'.  The dwmake script calls /usr/bin/make if no .dwmake file exists in the current directory so the redefinition of 'make' is benign.

# Clone the repository

    git clone https://github.com/andesengineering/dwmake

# Create local bin directory and configure in your .bashrc

    $ mkdir ~/bin
    $ vi ~/.bashrc

Add the following lines to your .bashrc:

    HOME_BIN=${HOME}/bin

    if [[ ${PATH} != *"${HOME_BIN}"* ]]; then
        PATH=${PATH}:${HOME_BIN}
    fi

While you are editing .bashrc, add the following line as well to define the DWMAKE variable to point to the directory where you made the git clone:

    export DWMAKE=/path/to/dwmake


# Copy dwmake.sh from the clone directory to your home bin directory.  Notice that the .sh extension is dropped in the copy

    $ cp dwmake.sh ~/bin/dwmake

# Add this alias to your .bash_aliases file

   $ echo "alias make='dwmake'" >> ~/.bash_aliases

That's it.  You're ready to use dwmake.

## Create your first example

    $ mkdir hello
    $ vi hello.cpp

add:

    #include <iostream>
    
    int main( int argc, char **argv )
    {
        std::cout << "Hello, World!" << std::endl;
        return 0;
    }

# create a .dwmake file 

    $ vi .dwmake

add a single line

    EXEC = hello

just type 'make':

    $ make


## Predefined Target definitions

    EXEC
        e.g.   EXEC = hello

    DYNAMIC_LIBNAME
        e.g.   DYNAMIC_LIBNAME = MyLib   # Produces libMyLib.so

    STATIC_LIBNAME
        e.g.   STATIC_LIBNAME = MyLib   # Produces libMyLib.a


## Predefined Targets

        $ make 
        $ make clean
        $ make clobber

## Predefined definitions

        INC_FLAGS  - include paths
            e.g. INC_FLAGS = -I../include -I/usr/local/include

        DEF_FLAGS  - definition flags
            e.g. DEF_FLAGS = -DMY_DEFINITION

        LIBS       - libraries for linking (can include library paths
            e.g.  LIBS = -lX11 -L /usr/local/lib -lfl


## FAQ
