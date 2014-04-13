#JCCircularCollectionViewProxy

A portable proxy for `UICollectionViewDataSource` and `UICollectionViewDelegate` that creates the effect of a quasi-endless horizontally scrolling carousel with page preview.

##What?

Horizontally scrolling carousels are a very elegant and user-friendly component used in contemporary mobile user interfaces - see Facebook for iOS's advertising (*groan*) carousel for a commercial example. The feature of *endless* wrap-around add further value to the component by not requiring the user to page all the way back to the beginning; they simply page past the final item.

###UIScrollView

The *old skool* technique for achieving this was to use [`UIScrollView` with three or more pages and then manipulate the scrollview's `contentOffset` in order to create the illusion of endless scrolling](http://ilarump.blogspot.de/2011/02/creating-circular-and-infinite.html). This technique certainly works as desired and there are a few open-source implementations that are available to try. [1](https://github.com/malcommac/DMCircularScrollView), [2](https://github.com/malcommac/DMLazyScrollView) et al.

The major drawback to this method is you are effectively re-implementing a lot of the functionality of iOS5's secret little wonder, `UICollectionView`.

###UICollectionView

Right off the bat, `UICollectionView` is designed exactly for this *kind of* component. For the feature of endless scrolling there is not too much work necessary in order to manipulate the collection's data source to achieve this effect. The problem, though, is the feature of next/previous page preview. `UICollectionView` removes cells that go out of the collection's bounds and as such we can't use the technique of a narrower frame for the collection with `clipsToBounds` set to `NO`. How very unfortunate!

Since `UICollectionView` is such a great piece of (first party) kit, it would be preferrable to work around these issues rather than dropping down to the level of the pre-`UICollectionView` `UIScrollView` method. In order to achieve this in a portable manner I've created this library.

####UICollectionViewDataSource

In the case of this implementation, we create the illusion of endless cycling by creating an artifically *wide* primary data source. We multiply the *true* number of items in the collection's data source by a large constant. This means that the user can scroll to either end, but it's safe to assume most will have more to do with their day than try to achieve this. In any case, this is a method also suggested by Apple (*WWDC 2012 scrollviews?*).

####UICollectionViewDelegate

Page preview is a little more of a challenge since we can't inset the collection view's frame. Also, the collection's default paging implementation becomes unsuitable since we can't tell it to page by any width other than the width of the collection's frame. Instead we can set an appropriate left `sectionInset` and recreate the paging effect itself using `UIScrollViewDelegate`'s `-scrollViewWillEndDragging:withVelocity:targetContentOffset:` method.

This all boils down to needing to proxy both the collection's data source and delegate in order to achieve the desired effect.

#Usage



#TODO

* Furthe tweak constants in `-scrollViewWillEndDragging:withVelocity:targetContentOffset:` to better match `UIScrollView`'s native paging.

