# Step 5 - Asset & Network Optimization

## Applied optimizations

- Added global Flutter image cache configuration
- Reduced unnecessary image cache churn on heavy screens
- Stabilized image memory management for repeated card assets

## Next recommended optimizations

- Convert large PNG assets to WebP
- Add cacheWidth/cacheHeight on large decorative images
- Lazy load secondary assets
- Compress audio assets
- Add API debounce layer if network calls increase
