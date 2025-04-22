# Fetch all tags from the remote
git fetch --tags

# # Loop through all tags
for tag in $(git tag); do
  # Check if the tag starts with "v"
  if [[ $tag == v* ]]; then
    # Remove the "v" prefix
    new_tag=${tag#v}
    
    # Create the new tag
    git tag $new_tag $tag
    
    # Delete the old tag locally
    git tag -d $tag
    
    # Delete the old tag remotely
    git push origin :refs/tags/$tag
    
    # Push the new tag to the remote
    git push origin $new_tag
  fi
done