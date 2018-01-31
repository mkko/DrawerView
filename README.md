# DrawerView

DrawerView is a view for iOS that mimics the functionality of the drawer introduced in the Maps (iOS 10 →).

![Sample](Resources/sample.gif)

#### Ease of use

DrawerView is a simple view that you can add to your app. No need to restructure your views or view controllers to add support for it. This also makes it possible to have multiple drawers and switch between them the same way it is done in the iOS Maps.

#### Automatic support fro scroll views

DrawerView handles subview interaction so that it adds specialized support for scroll views. What this practically means is that you can add a scroll view (or a table view) inside it and the DrawerView will handle the transition from scrolling the subview to scrolling the drawer.

#### Customization

Well, this is the next thing I'll be working with.

## Installation

You can install DrawerView with Carthage and CocoaPods. For Carthage add the following into your `Cartfile`:

```
github "mkko/DrawerView"
```

With CocoaPods, add the following into your `Podfile`:

```
github "mkko/DrawerView"
```

## Usage

DrawerView tries automatically to occupy the view it will be added to. It uses autolayout to set its position, and thus you can attach views to it You can set it up with storyboards or programmatically

### Setting things up

#### Storyboard

The easiest way to create a drawer is to create a self-contained view in storyboard:

1. Create empty view in storyboards outside any view controllers.
2. Set a custom class of the view to `DrawerView`.
4. Connect the `containerView` IBOutlet to the view where you want it to occupy the space (e.g. the view controller root view).
5. Optionally implement `DrawerViewDelegate` to gain better control over the functionality.
5. Add your content to the view.

This method of setup is demonstrated in the included [Example](./Example).

#### Programmatically

Programmatic setup is pretty much the same as setting up any `UIView`: you create one, set it up with subviews and add it to some view. When adding the view into the parent, it will automatically set the 

### TODOs

- Make styling of the view possible.

