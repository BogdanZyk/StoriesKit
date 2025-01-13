# StoriesKit

`StoriesKit` is a highly customizable SwiftUI view designed to create an social app story interface. **SwiftUI iOS 16+**

## Features

- **Story Grouping**: Display multiple groups of stories.
- **Customizable Styles**: Configure corner radius, scaling, animation duration, overlay opacity, timer progress view.
- **Swipe Gestures**: Navigate between stories with smooth animations.
- **Callbacks**: Handle events like reaching the end of stories or completing a story group.
- **Progress Indicators**: Fully customizable progress bar for story groups.

---

### Example of stories with pictures and video 
[![Preview](http://img.youtube.com/vi/X71W0H79Wh4/0.jpg)](https://www.youtube.com/watch?v=X71W0H79Wh4)

---

## Example Usage

```swift

struct ContentView: View {
    @State var index: Int = 0
    let groups: [AnyStoryGroup] = [
        .init(pages: (0...1).map({ Page(name: "\($0)") })),
        .init(pages: (0...5).map({ Page(name: "\($0)") })),
        .init(pages: (0...4).map({ Page(name: "\($0)") })),
        .init(pages: (0...6).map({ Page(name: "\($0)") }))
    ]

    var body: some View {
        StoriesView(groups: groups, startIndex: index)
            .style(
                .init(cornerRadius: 30, scaleFactor: 0.95, opacityOverlay: 0.1, animationDuration: 0.35)
            )
            .makeProgressBar { progress, group in
                progress.padding()
            }
            .onChangeGroupIndex($index)
            .onEndGroup { group in
                print("on end group", group.id)
            }
            .onReachedAllStories {
                print("on reached all stories", $0)
            }
    }
}

struct Page: StoryPageable {
    var duration: TimeInterval = 5
    let name: String
    var id: String { name }
    let color: Color = .yellow

    var content: some View {
        ZStack {
            color
                .allowsHitTesting(false) //use allowsHitTesting for background and non-tap elements, for story control buttons to work
            VStack {
                Text(name)
                Button("Button") {
                    print("send")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

```
#### use **`.allowsHitTesting(false)`** for background and non-tap elements, for story control buttons to work
---

## Public API

### `StoriesView`

#### Initializer

```swift
public init(groups: [AnyStoryGroup], startIndex: Int = 0)
```

- **`groups`**: Array of `AnyStoryGroup` representing story groups.
- **`startIndex`**: Initial index for the displayed story group. Default is `0`.

#### Modifiers

- **`makeProgressBar`**

  ```swift
  public func makeProgressBar<Content: View>(@ViewBuilder _ view: @escaping (StoryProgressView, AnyStoryGroup?) -> Content) -> Self
  ```

  Customize the progress bar for each story group.

  - **`view`**: Closure that returns a custom SwiftUI `View` for the progress bar.

- **`style`**

  ```swift
  public func style(_ style: StoryCardStyle) -> Self
  ```

  Apply a custom style to the story cards.

  - **`style`**: An instance of `StoryCardStyle`.

- **`onReachedAllStories`**

  ```swift
  public func onReachedAllStories(_ action: @escaping (PageReachedDirection) -> Void) -> Self
  ```

  Add a callback triggered when all stories are reached.

  - **`action`**: Closure that accepts `PageReachedDirection` (`.start` or `.end`).

- **`onEndGroup`**

  ```swift
  public func onEndGroup(_ action: @escaping (AnyStoryGroup) -> Void) -> Self
  ```

  Add a callback triggered when a story group is completed.

  - **`action`**: Closure receiving the completed `AnyStoryGroup`.

- **`onChangeGroupIndex`**

  ```swift
  public func onChangeGroupIndex(_ currentIndex: Binding<Int>) -> Self
  ```

---
  
### `EnvironmentValues`

#### Properties

- **`stackPageState`**: A dictionary storing the state of each stack page in a paged view. The key is a hashable identifier for a page, and the value is the corresponding `StackPageState` for that page.

- **`storyInPause`**: A binding to a Boolean value indicating whether a story is currently paused. `true` if the story timer is paused, and `false` if it is playing.

### `StackPageState`

An enumeration representing the state of a stack page within a paged view.

#### Cases

- **`isShowing`**: The page is currently visible and being displayed.
- **`beforeSwitch`**: The page is in a transitional state before switching to a new page.
- **`inSwiped`**: The page is located during a swipe.
- **`hidden`**: The page is hidden and not currently visible.


