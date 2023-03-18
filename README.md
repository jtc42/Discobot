#  <#Title#>

## Notes

```
ForEach(reccommendation.items) { item in
    switch item {
    case .album(let album):
        // TODO: Some way to either pass the VPageView onChange event to all AlbumCardView children (passing the new index as an arg, rather than having a binding), OR have the child AlbumCardViews populate a dictionary of preview links as soon as the top of the card is in view, and have the playback triggered directly in the VPageView onChange event (but would need to delay until we know we have the preview links asynchronously fetched. **Perhaps watch the value of the preview links dictionary binding and re-check preview playback**)
        AlbumCardView(album: album, playbackId: index, pageIndex: index, nowPlayingId: $nowPlayingId, currentIndex: $currentIndex, previewPlayer: previewPlayer)
    case .playlist:
        VStack {} // Todo
    case .station:
        VStack {} // Todo
    @unknown default:
        VStack {} // Todo
    }
}
```
