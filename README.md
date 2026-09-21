# SatisfactionJS

SatisfactionJS is a small browser-native MVVM JavaScript framework for building modular web applications from HTML components.

It is designed to work without a build step: include one script file, declare components in HTML, and let SatisfactionJS load component templates, bind models, handle simple routing, share data, and manage component state.

> Documentation status: this README is written for SatisfactionJS `2.1.2.1229` and is based on the current `satisfaction.dev.js` public API.

## What it includes

- Native HTML component loading with `<component src="...">`.
- Optional client-side routing with `<route path="...">`.
- MVVM-style models with `{{property}}` templates.
- Commands with `command="{{methodName}}"`.
- Two-way input binding with `bind="{{property}}"`.
- Template multiplication from arrays.
- Component-scoped styles.
- Shared points for data exchange between components.
- In-memory and `localStorage` state helpers.
- JSON resources for static text replacement.
- Basic JavaScript and CSS dependency injection.
- Custom framework events for lifecycle hooks.

## Installation

Copy the framework file into your project and include it before your application starts.

```html
<script src="/satisfaction.dev.js"></script>
```

For production, use your minified build, for example:

```html
<script src="/versions/2.1.2.1229/satisfaction.min.js"></script>
```

The framework is browser-only and exposes global `sf_*` functions. It does not require npm, bundlers, or module imports.

## Minimal page

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SatisfactionJS App</title>
  <script src="/satisfaction.dev.js"></script>
</head>
<body onload="sf_initialize()" allow-routing>
  <route path="/" navigation-component-name="home"></route>
  <route path="/about" navigation-component-name="about"></route>

  <nav>
    <button navigation-component-name="home">Home</button>
    <button navigation-component-name="about">About</button>
  </nav>

  <main navigation-switch>
    <component name="home" src="/views/home.html" default></component>
    <component name="about" src="/views/about.html"></component>
  </main>
</body>
</html>
```

## Minimal component

`/views/home.html`

```html
<script>
component.setModel({
  title: "Home",
  count: 0,
  increment: function () {
    this.count.value++;
  }
}, "home-model");
</script>

<section template="home-model">
  <h1>{{title}}</h1>
  <p>Count: <span>{{count}}</span></p>
  <button command="{{increment}}">Increment</button>
</section>
```

## Initialization

Use `sf_initialize()` when the page is ready.

```html
<body onload="sf_initialize()" allow-routing>
```

`allow-routing` enables SatisfactionJS routing. Without it, default components still load, but route lookup and browser history routing are not enabled.

You may pass a setup callback. It runs before resources and default components are loaded.

```html
<body onload="sf_initialize(function () { sf_active_navigation_allowed = true; })" allow-routing>
```

## Components

A component is declared with the custom `<component>` element.

```html
<component name="profile" src="/views/profile.html"></component>
```

Useful attributes:

| Attribute | Meaning |
| --- | --- |
| `name` | Component name used by loaders, navigation, and state helpers. |
| `src` | URL of the HTML template loaded by XHR. |
| `default` | Loaded automatically during initialization or when a parent component is loaded. |
| `on` | JavaScript condition evaluated with `eval`; component loads when the condition is true. |
| `lazy` | Beta behavior: after the component has been loaded, an IntersectionObserver can unload it above the viewport and reload it when visible again. |
| `frozen` | Keeps the component element size while unloading, then unfreezes when loaded again. |

Inside component scripts, `component` is injected by the framework and points to the current component element.

```html
<script>
const button = component.find("open-button");
button.onclick = function () {
  component.find("details").load();
};
</script>
```

## Component methods

After a component is prepared, it has these methods:

| Method | Description |
| --- | --- |
| `component.find(name)` | Returns the first child element with the matching `name` attribute. If it is a component, defaults are attached to it. |
| `component.findClasses(className)` | Returns elements inside the component with the given CSS class. |
| `component.load(preloadSubcomponents = true, inputData = null)` | Loads or reloads this component. |
| `component.unload()` | Clears this component and dispatches unload/cleared events. |
| `component.reload(preloadSubcomponents = true, inputData = null)` | Unloads and loads the component again. |
| `component.hasLoaded()` | Returns whether the component has the `loaded` attribute. |
| `component.navigate(saveSearchParams = true, inputData = null)` | Navigates to this component by name. |
| `component.state(name)` | Reads state key `component.<componentName>.<name>`. |
| `component.setState(name, value, setLocalStorage = false)` | Writes state key `component.<componentName>.<name>`. |
| `component.parent()` | Returns the closest parent `<component>`. |
| `component.setModel(model, templateName)` | Applies a model to elements with `template="templateName"`. |
| `component.setMultiplier(array, templateName, display = 'block')` | Repeats a template for every object in an array. |
| `component.dispatch(eventName)` | Dispatches a SatisfactionJS event from the component. |
| `component.setEvent(eventName, handler)` | Adds a SatisfactionJS event listener to the component. |

## Routing

Routing is enabled only when `<body>` has `allow-routing`.

```html
<body onload="sf_initialize()" allow-routing>
  <route path="/" navigation-component-name="home"></route>
  <route path="/settings" navigation-component-name="settings"></route>
</body>
```

When the browser path matches a `<route>`, SatisfactionJS loads the component from `navigation-component-name`.

Navigation can be triggered with any element that has `navigation-component-name`:

```html
<button navigation-component-name="settings">Settings</button>
```

Use `navigation-switch` on a parent when only one child component should be visible at a time:

```html
<div navigation-switch>
  <component name="home" src="/views/home.html" default></component>
  <component name="settings" src="/views/settings.html"></component>
</div>
```

Wildcard route paths can match multiple child paths:

```html
<route path="/marketplace/board/*" navigation-component-name="marketplace-board"></route>
```

Exact routes take priority over wildcard routes, and the most specific wildcard wins when multiple templates match. A trailing `/*` matches both the base path and its descendants. Wildcard paths are matching templates only; navigating to a component does not write a path containing `*` into the browser URL.

## Active links

If `sf_active_navigation_allowed = true`, SatisfactionJS intercepts internal links with the `active` attribute.

```html
<script>
sf_active_navigation_allowed = true;
</script>

<a active href="/settings">Settings</a>
```

Only same-site links whose `href` starts with `/` are handled. Links with `target` other than `_self` are ignored.

## MVVM model

Use `component.setModel(model, templateName)`.

```html
<script>
component.setModel({
  name: "User",
  message: "Hello",
  send: function (eventInfo) {
    console.log(this.name.value, this.message.value);
  }
}, "message-form");
</script>

<form template="message-form">
  <input value="{{name}}" bind="{{name}}" bindEvent="input">
  <input value="{{message}}" bind="{{message}}" bindEvent="input">
  <button type="button" command="{{send}}">Send</button>
</form>
```

Important model behavior:

- Every non-function model field becomes an `sf_property_set` property object.
- Read and write model values with `.value`, `.get()`, or `.set(value)` after the model is applied.
- Function fields are commands and are called with `this` set to the model.
- A special `construct(targetElement)` function runs after bindings and commands are connected.

```javascript
this.name.value = "New name";
this.name.set("New name");
const current = this.name.get();
```

## Template syntax

Use `{{propertyName}}` in text content or attributes.

```html
<h1>{{title}}</h1>
<input value="{{title}}" bind="{{title}}" bindEvent="input">
```

For the current version, avoid multiple different model properties inside the same text node or attribute. Split them into separate elements.

Recommended:

```html
<p>Count: <span>{{count}}</span> / User: <span>{{name}}</span></p>
```

Avoid:

```html
<p>{{count}} / {{name}}</p>
```

## Visibility

`visible`, `invisible`, and `when` are updated from model values.

```html
<p visible="{{isReady}}">Ready</p>
<p invisible="{{isLoading}}">Not loading</p>
<p when="{{count}} > 3">Count is greater than three</p>
```

Add `transparent` to use `visibility: hidden` instead of `display: none`.

```html
<p visible="{{isReady}}" transparent>Space is preserved</p>
```

## Commands

A command is a model function connected with `command="{{functionName}}"`.

```html
<button command="{{save}}">Save</button>
```

The default command event is `click`. Use `commandEvent` to change it.

```html
<input command="{{search}}" commandEvent="input">
```

The command receives an `eventInfo` object with the element, event name, and model reference.

```javascript
save: function (eventInfo) {
  console.log(eventInfo.element);
  console.log(eventInfo.commandEvent);
  console.log(eventInfo.model);
}
```

## Bindings

`bind="{{propertyName}}"` writes the element value back to the model.

```html
<input value="{{email}}" bind="{{email}}" bindEvent="input">
```

The default binding event is `change`. Use `bindEvent="input"` for live typing updates.

## Multipliers

Use `component.setMultiplier(array, templateName, display)` to render an array.

```html
<script>
const messages = [
  { sender: "Anna", text: "Hello" },
  { sender: "Mark", text: "Hi" }
];

component.setMultiplier(messages, "message-item");
</script>

<div>
  <article template="message-item">
    <strong>{{sender}}</strong>
    <p>{{text}}</p>
    <button command="{{unset}}">Remove</button>
  </article>
</div>
```

When default multiplier functions are enabled, each model receives:

| Function | Description |
| --- | --- |
| `unset()` | Removes this rendered item and splices it from the array. |
| `getIndex()` | Returns the item index captured when it was rendered. |
| `getArray()` | Returns the source array. |

The array also receives helper methods:

| Function | Description |
| --- | --- |
| `array.synchronize()` | Rebuilds rendered items from the current array. |
| `array.values()` | Returns a shallow copy of the array. |
| `array.push(...items)` | Appends items and renders them. |
| `array.pop(index)` | Removes the last array item; DOM removal uses the passed template index. Prefer `unset()` or `synchronize()` for non-last removals. |

## Data exchange with points

A point is a simple publish/subscribe object.

```javascript
const point = sf_point_set("messages");

point.subscribe("message-list", function (message) {
  console.log(message);
});

point.share({ text: "Hello" });

const pointAgain = sf_point_get("messages");
```

You can also pass a point to another component:

```javascript
component.find("message-list").load(true, point);

// In the child component:
const sharedPoint = component.inputData;
```

## State manager

Use state for simple app values.

```javascript
sf_state_set("token", "abc", true); // also writes to localStorage
const token = sf_state_get("token");
sf_state_unset("token");
```

`localStorage` keys are prefixed with `sf_`. Values stored in `localStorage` are strings.

Component-scoped state:

```javascript
component.setState("tab", "profile", true);
const tab = component.state("tab");
```

This uses the key `component.<componentName>.tab` internally.

## Resources

Resources are JSON dictionaries loaded before default components.

```html
<resource name="App" src="/resources/en.json"></resource>
```

`/resources/en.json`

```json
{
  "Home.Title": "Home",
  "Home.Subtitle": "Welcome"
}
```

Use resource placeholders in component HTML:

```html
<h1>##Resource.App.Home.Title##</h1>
```

Resource keys with dots are literal JSON keys. The framework does not traverse nested JSON objects for `Home.Title`.

Conditional resources are supported with `on`, which is evaluated with `eval`.

```html
<resource name="App" src="/resources/lt.json" on="navigator.language.startsWith('lt')"></resource>
```

Useful resource settings:

```javascript
sf_resource_undefined_key_value = "";
sf_resource_callback_after = function () {
  console.log("Resources and default components are ready");
};
```

## Dependency injection

Use `sf_dependency_set(source, cacheAllowed)` to append JavaScript or CSS files to the document.

```javascript
sf_dependency_set("/lib/app.js", false);
sf_dependency_set("/styles/app.css", true);
```

When `cacheAllowed` is false, a `version-timestamp` query parameter is added. If `sf_dependency_stable_version` is set, that value is used; otherwise the current timestamp is used.

```javascript
sf_dependency_stable_version = "2.1.2.1229";
sf_dependency_set("/lib/app.js", false);
```

This helper appends files but does not wait until scripts finish loading.

## Styles in components

Component styles are scoped by default.

```html
<style>
.card { padding: 16px; }
</style>

<div class="card">Content</div>
```

SatisfactionJS rewrites class selectors in non-global `<style>` tags with a random postfix and applies the matching postfix class to elements inside the component.

Use `global` to skip scoping:

```html
<style global>
body { margin: 0; }
</style>
```

## Events

All SatisfactionJS DOM events are prefixed with `sf`.

| Constant | Actual DOM event | Trigger |
| --- | --- | --- |
| `SF_EVENT_MODEL_SET` | `sfmodelset` | A model is applied to an element. |
| `SF_EVENT_ROUTING_ROUTE_FOUND` | `sfroutefound` | A route is found. |
| `SF_EVENT_ROUTING_ROUTE_NOT_FOUND` | `sfroutenotfound` | A route is not found. |
| `SF_EVENT_COMPONENT_LOAD` | `sfload` | Component HTML is set and defaults are attached. |
| `SF_EVENT_COMPONENT_UNLOAD` | `sfunload` | Component unload starts. |
| `SF_EVENT_COMPONENT_ERROR` | `sferror` | Component XHR fails. |
| `SF_EVENT_COMPONENT_CLEARED` | `sfcleared` | Component children are removed. |
| `SF_EVENT_COMPONENT_NAVIGATION_IN` | `sfnavigationin` | Component is navigated into. |
| `SF_EVENT_COMPONENT_NAVIGATION_OUT` | `sfnavigationout` | Component is navigated away from. |
| `SF_EVENT_COMPONENT_RENDER` | `sfrender` | Component render is considered ready. |
| `SF_EVENT_COMPONENT_FINALIZED` | `sffinalized` | The requested component loading chain is finished. |

Preferred listener:

```javascript
component.setEvent(SF_EVENT_COMPONENT_RENDER, function () {
  console.log("Rendered");
});
```

Direct DOM listener:

```javascript
component.addEventListener("sfrender", function () {});
```

Dispatch custom framework event:

```javascript
component.dispatch("custom"); // dispatches "sfcustom"
```

## Configuration variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `sf_component_javascript_allowed` | `true` | Executes `<script>` tags inside loaded components. |
| `sf_component_javascript_builtin` | `true` | Keeps component `<script>` tags in DOM after execution. If false, removes them. |
| `sf_component_style_add_new_class` | `true` | Keeps original class names and adds scoped class names. If false, replaces matching class names. |
| `sf_component_lazy_loading_allowed` | `true` | Enables beta lazy observer setup for loaded components with `lazy`. |
| `sf_component_loading_indicator` | `null` | HTML shown inside a component while it is loading. |
| `sf_component_templates` | `{}` | In-memory cache of loaded component template HTML by source URL. |
| `sf_component_cache_control_header` | `"no-cache, no-store, max-age=0"` | Header sent with component XHR requests. |
| `sf_routing_allowed` | `false` | Set by `sf_initialize()` from `body[allow-routing]`. |
| `sf_active_navigation_allowed` | `false` | Enables interception of `<a active href="/...">` links. |
| `sf_disable_pop_state` | `false` | When true, popstate pushes a new history state instead of routing back. |
| `sf_model_multiplier_default_functions_allowed` | `true` | Adds default functions to multiplier item models. |
| `sf_state_ls_prefix` | `"sf_"` | Prefix for localStorage state keys. |
| `sf_resource_allowed` | `true` | Enables resource loading and replacement. Set false to skip resources. |
| `sf_resource_undefined_key_value` | `""` | Replacement value for missing resource keys. |
| `sf_resource_callback_after` | `null` | Optional callback after resources and default component setup. |
| `sf_resource_cache_control_header` | `"no-cache, no-store, max-age=0"` | Header sent with resource XHR requests. |
| `sf_event_prefix` | `"sf"` | Prefix for framework DOM events. |
| `sf_dependency_stable_version` | `null` | Stable cache-busting value for dependencies when cache is not allowed. |

## Global API reference

| Function | Purpose |
| --- | --- |
| `sf_initialize(callbackSetup = null)` | Initializes routing flag, optional setup callback, resources, default components, and popstate routing. |
| `sf_component_mount(containerElement, componentName, sourcePath)` | Creates and appends a `<component>` element. |
| `sf_component_load(componentNames, preloadSubcomponents = true, inputData = null, scopedElement = document.body)` | Loads one or more components by name. |
| `sf_component_unload(componentName, scopedElement = document.body)` | Unloads components by name. |
| `sf_component_navigate(componentName, saveSearchParams = true, inputData = null, scopedElement = document.body)` | Loads and navigates to a component by name. |
| `sf_routing_find_navigation_route(containerElement = document, path = window.location.pathname)` | Finds a route and navigates to its component. |
| `sf_routing_set_route_path(componentName, saveSearchParams = true)` | Updates browser URL using the route for a component. |
| `sf_property_set(defaultValue, raiseCallback = null)` | Creates a reactive property object. |
| `sf_model_set(targetElement, model)` | Applies a model directly to an element. |
| `sf_model_set_multiplier(templateElement, array, display = 'block')` | Renders one template per array item. |
| `sf_point_set(name = null)` | Creates a shared point, optionally stored by name. |
| `sf_point_get(name)` | Gets a named shared point. |
| `sf_state_get(name)` | Gets state from localStorage or memory. |
| `sf_state_set(name, value, setLocalStorage = false)` | Sets state in memory and optionally localStorage. |
| `sf_state_unset(name)` | Removes state from memory and localStorage. |
| `sf_resource_get(dictionaryNameKey, internalResourceKey, defaultValue = null)` | Reads a loaded resource value. |
| `sf_event_set(element, eventName, handler)` | Adds an `sf`-prefixed event listener. |
| `sf_event_dispatch(element, eventName, bubbles = true, cancelable = false)` | Dispatches an `sf`-prefixed event. |
| `sf_dependency_set(source, cacheAllowed = false)` | Appends a JS or CSS dependency. |
| `sf_random_string()` | Returns a 9-character random string. |
| `sf_sleep(milliseconds)` | Blocking busy-wait sleep. Avoid in UI code. |
| `sf_xpath_find(targetElement, xpathExpression)` | Evaluates XPath against a target element. |
| `sf_xpath_element(element)` | Builds an XPath-like path for an element. |
| `sf_hash(text)` | Returns a base-36 hash string. |
| `sf_element_freeze(element, display = 'block')` | Freezes an element size. |
| `sf_element_unfreeze(element, display = '')` | Removes frozen sizing. |


## Lower-level exposed functions

These functions are also global because the framework is not packaged as a module. They are mainly used internally by SatisfactionJS. Use them only when you intentionally need to extend or debug the framework.

| Function | Internal role |
| --- | --- |
| `sf_component_setup()` | Starts default component loading from `document.body`. |
| `sf_component_load_default(targetElement)` | Finds `component[default]` and `component[on]` inside a target and loads them. |
| `sf_component_claim_anonymous(componentElements)` | Assigns generated names to unnamed default/conditional components. |
| `sf_component_set(componentElement, content, sharedInputData = null)` | Inserts component HTML and applies defaults, styles, scripts, events, routing, and lazy/frozen handling. |
| `sf_component_set_lazy_loading(componentElement, thresholdValue = 0)` | Attaches the beta IntersectionObserver lazy behavior. |
| `sf_component_replace_resources_data(content)` | Replaces `##Resource.Dictionary.Key##` placeholders in component HTML. |
| `sf_component_set_defaults(componentElement)` | Attaches the component helper API to an element. |
| `sf_component_track_navigation(targetElement = null)` | Connects click handlers for elements with `navigation-component-name`; pass an explicit target element. |
| `sf_component_execute_js(componentElement)` | Executes `<script>` content inside a loaded component. |
| `sf_component_apply_styles(targetElement)` | Rewrites non-global component style classes and applies scoped classes. |
| `sf_patch_active_links(targetElement)` | Connects intercepted routing behavior for `<a active href="/...">`. |
| `sf_model_track_properties(targetElement, model)` | Converts model values into reactive property objects. |
| `sf_model_find_properties(targetElement)` | Marks text and attribute templates before model updates. |
| `sf_model_update_property(targetElement, bindableKey, value)` | Updates DOM text/attributes for a changed property. |
| `sf_model_update_visibility(targetElement, value)` | Applies display/visibility behavior for `visible`, `invisible`, and `when`. |
| `sf_model_track_commands(targetElement, model)` | Connects command attributes to model functions. |
| `sf_model_set_command_listener(targetElement, model, callbackFunction)` | Adds a command event listener to one element. |
| `sf_model_track_bindings(targetElement, model)` | Connects bind attributes to model properties. |
| `sf_model_set_binding_listener(targetElement, model, property)` | Adds a binding event listener to one element. |
| `sf_model_unset_multiplier_template(targetElement, arrayIndex)` | Removes rendered multiplier clones by `sf-template-index`. |
| `sf_model_set_multiplier_model(templateElement, model)` | Applies a model to a cloned multiplier item. |
| `sf_model_set_multiplier_template_clone(templateElement, index, display)` | Clones a multiplier template and assigns a generated template name. |
| `sf_model_set_multiplier_reset(targetElement)` | Removes existing multiplier clones. |
| `sf_resource_load_all(callback)` | Loads all `<resource name src>` JSON dictionaries and then runs the callback. |
| `sf_dependency_set_script(finalSource)` | Appends a `<script>` dependency to `document.head`. |
| `sf_dependency_set_stylesheet(finalSource)` | Appends a stylesheet dependency to `document.head`. |

## Security and compatibility notes

- Component HTML and resource conditions must be trusted. The framework uses `new Function` for component scripts and `eval` for `on` and `when` expressions.
- A strict Content Security Policy may block component scripts unless it allows the required script execution model.
- Components and resources are loaded by XHR. Serve the app over HTTP(S), not `file://`.
- Cross-origin component/resource URLs require correct CORS headers from the server.
- The dependency helper does not wait for script execution. Use a Promise-based loader when startup must block until dependencies are ready.
- In this version, multiple different `{{property}}` tokens in the same text node or attribute are not reliable. Split them into separate elements or attributes.
- `localStorage` state values are stored as strings.
- The `sfrender` event is dispatched immediately only when there are no images or all images are already loaded at the check time.

## Recommended production checklist

- Use a minified file such as `satisfaction.min.js` for production.
- Keep the public version number in the production path, for example `/versions/2.1.2.1229/satisfaction.min.js`.
- Serve JavaScript with the correct MIME type.
- Configure CORS only for origins that should be allowed to load your files, or use `Access-Control-Allow-Origin: *` only for public static framework files.
- Avoid untrusted component HTML because component scripts are executable.
- Keep component names unique when using routing and navigation switches.
- Test deep links directly in the browser; the server should return the app shell for routed paths.

## License

MIT License.
