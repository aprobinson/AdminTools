#!/bin/bash

##---------------------------------------------------------------------------##
## Directions
##---------------------------------------------------------------------------##
# Calibre will automatically create a directory in your home directory
# called "Calibre Library" where it will store your books. Create a
# shared book directory where you can back up your books. The two
# variables below should be set to these locations on your system. Add a
# crontab entry that runs this script regularily to sync the two directories.
# (run every 5 min: */5 * * * * /home/etc/calibre_update.sh)

##---------------------------------------------------------------------------##
## Library Directories
##---------------------------------------------------------------------------##
my_calibre_lib="$HOME/Calibre Library"
shared_calibre_lib="/home/books"

##-------------------DO NOT MODIFY ANYTHING BELOW HERE-----------------------##
##---------------------------------------------------------------------------##
## Syncing Functions
##---------------------------------------------------------------------------##
# Get the simplified book name
# $1 = book_dir
function get_simplified_book_name {
    local local_book_dir=$1
    local local_simplified_book_name=$2
    
    local book_tag_num=`echo "$local_book_dir" | grep -o "([0-9.]\+)"`

    local simplified_book_name_result=${local_book_dir%$book_tag_num}
    
    echo "$simplified_book_name_result"
}

# Sync a book that already exists
# $1 = author_dir
# $2 = my_book_dir
function sync_existing_book {

    local local_author_dir=$1
    
    local local_book_dir=$2

    local simplified_book_name=$(get_simplified_book_name "$local_book_dir")
    
    # Get the shared book dir
    cd "$shared_calibre_lib/$local_author_dir"
        
    local shared_book_dir=""
    for tmp_shared_book_dir in * ; do
        local simplified_tmp_shared_book_name=$(get_simplified_book_name "$tmp_shared_book_dir")
        
        if [ "$simplified_tmp_shared_book_name" == "$simplified_book_name" ]; then
            shared_book_dir="$tmp_shared_book_dir"
        fi
    done
    
    # Check that the book output formats are synced
    cd "$shared_book_dir"
    local num_shared_book_files=`ls -l | wc -l`
    
    cd "$my_calibre_lib/$local_author_dir/$local_book_dir"
    local num_book_files=`ls -l | wc -l`
    
    echo "   My book files: $num_book_files"
    echo "   Shared book files: $num_shared_book_files"
    
    # Check if the book is fully synced
    if [ "$num_book_files" != "$num_shared_book_files" ]; then
        echo "   syncing...done."
        
        cp -r * "$shared_calibre_lib/$local_author_dir/$shared_book_dir/"
    else 
        echo "   already synced!"
    fi
    
    cd ../
}

# Sync the book
# $1 = author dir
# $2 = my_book_dir
function sync_shared_book_with_my_book {

    local local_author_dir=$1
    
    local local_book_dir=$2

    local simplified_book_name=$(get_simplified_book_name "$local_book_dir")

    echo " *$simplified_book_name..."
                
    local book_exists="false"
                
    cd "$shared_calibre_lib/$local_author_dir"
                
    for shared_book_dir in * ; do
        if [[ "$shared_book_dir" =~ "$simplified_book_name" ]]; then
            book_exists="true"
        fi
    done
                
    cd "$my_calibre_lib/$local_author_dir"
                
    # The book is possibly synced
    if [ $book_exists == "true" ]; then
        sync_existing_book "$local_author_dir" "$local_book_dir"
        
    # Copy my book to the shared library
    else
        echo "   not found in shared library! syncing...done."
        cp -r "$local_book_dir" "$shared_calibre_lib/$local_author_dir/$book_dir"
    fi # end if [ $book_exists == "true" ]
}

# Check if an author exists in the shared library
# $1 = my_author_dir
function sync_shared_authors_with_my_authors {

    local local_author_dir=$1
    
    # Check if this author exists in the shared library
    if [ -d "$local_author_dir" ]; then
        if [ -d "$shared_calibre_lib/$local_author_dir" ]; then
            echo "$local_author_dir found in shared library! Checking books..."

            # Move into the author directory
            cd "$local_author_dir"

            # Check each book by this author
            for book_dir in * ; do
                sync_shared_book_with_my_book "$local_author_dir" "$book_dir"
            done

            # This author is synced
            cd ../

        # This is a new author in the shared library
        else
            echo "$local_author_dir not found in shared library! Adding it now...done."
            cp -r "$local_author_dir" "$shared_calibre_lib/$local_author_dir"
        fi # end if[ -d "$shared_calibre_lib/$local_author_dir" ]
        
    fi # end if[ -d "$local_author_dir ]
}

##---------------------------------------------------------------------------##
## Sync my library with the shared library
##---------------------------------------------------------------------------##
cd "$my_calibre_lib"
calibredb add -r "$shared_calibre_lib"

##---------------------------------------------------------------------------##
## Sync the shared library with my library
##---------------------------------------------------------------------------##
for author_dir in * ; do
    echo ""

    sync_shared_authors_with_my_authors "$author_dir"
done

echo ""
echo "Library syncing completed!"
