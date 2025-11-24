# Petal Igniter

Prototype to enable Igniter for Petal Components.

## Goals

The primary goal of this prototype is to achieve the following:

```bash
# From within an existing project
mix petal_components.install

# Or when creating a new app with Igniter:
mix igniter.new app_name --install petal_components
```

And if you want to install a subset of components:

```bash
mix petal_components.install -c button -c alert
```

A secondary goal of this prototype is to achieve backwards compatibility with the existing library. Though not strictly necessary, it does mean that users can use the updated version of Petal Components library without Igniter. It also means that GitHub Actions, accessibility and code coverage can continue with minimal adjustments.

NB - the investigation into backwards compatibility is more of an exploration than a recommendation.

## Simple Demo

In this repo, make a change to `priv/templates/component/button.ex`. Then run:

```bash
mix petal_components.install --lib
```

Changes will be reflected in `lib/petal_igniter/button.ex`. For more information about the `--lib` switch - see the Switches section (below)

You can check how your changes have affected the button component by running:

```bash
mix test
```

## Basic Premise

At it's heart, each component is broken down into 3 files - a component, a test and a css file. For example, when using Igniter to generate the button component inside a Phoenix web app, here are the default locations for each file:

* `lib/your_project_web/components/petal_components/button.ex`
* `test/your_project_web/components/petal_components/button_test.exs`
* `assets/css/petal_components/button.css`

Each file is generated from an EEx template. EEx templates can be found in this project under `/priv/templates` in one of three folders - `component`, `test` or `css`. For example, the source templates for the button conponent are:

* `priv/templates/components/button.ex`
* `priv/templates/test/button_test.exs`
* `priv/templates/css/button.css`

Taking a leaf from the Phoenix repo, EEx templates end in their relevant file extension (instead of `.eex`). The net effect of this is that, for the most part, syntax highlighting works for these files. Things get a little hairy for the `.css` templates. For example, template interpolation in `priv/templates/css/_default` causes Zed to report an error. But generally, it seems that benefit of syntax highlighting is worth it.

Speaking of css, I've broken up the contents of `assets/css/default.css`. Thanks to Tailwind 4, each component can have it's own css file that's imported into `default.css`. CSS that doesn't belong inside a component can be added to `default.css`. It also means that you could add css to a component file that does not necessarily belong to `@layer components { .. }`.

## Component Metadata

In some cases, there is no test or css file. Also, there is a file (`PaginationInternal.ex`) that needs to be included in the process but is not a component in its own right. `lib/petal_igniter/mix/components.ex` provides functions to return components, tests and css. There is a function called `public_components` that returns the full list without `PaginationInternal`.

## Igniter Tasks

Igniter tasks are as follows:

* `petal_components.install.ex` - this is the main mix task, curently it sets up depedencies, generates the main component files and composes sub-tasks
* `petal_components.css.ex` - generates component css files and other supporting files. Integrates Petal Components css with `app.css`
* `petal_components.test.ex` - generates test files for components and supporting test files
* `petal_components.use.ex` - generates `petal_components.ex` and integrates its use into the web application
* `petal.tailwind.install.ex` - a general Igniter task to install and configure Tailwind 4 for a web app
* `petal.heroicons.install.ex` - a general Igniter task to add heroicons dependency and install the Tailwind heroicons javascript plugin

You can call each Igniter task individually if you wish. Only `petal_components.install.ex` orchestrates the other tasks

## Switches

Here is a list of switches that are implemented in this solution and their description:

```bash
--lib
```

Tasks will generate files for a library instead of an app. This is used to generate the Petal Components library itself. Basically, this will omit the files/modifications required for a web app.

```bash
--component component_name

# Or

-c component_name
```

Use this to nominate specific components. Use the switch multiple times for multiple components

```bash
--do-deps
```

If you generate specific components, it will automatically generate dependant components too. For example, if you add the `button`, it will also generate `icon`, `link` and `loader` - unless you use the `--no-deps` option.

```bash
# Default
--js-lib alpine_js

# Alternative
--js-lib live_view_js
```

Controls whether a component generates Alpine.js or plain javascript. This is a breaking change - see notes below.

## Output

In the case of a web app, Igniter will generate Petal Components inside the users project. Giving them their own copy. They can adjust Petal Components as they see fit. If the user wishes, they could re-generate part or all of Petal Components over their existing project - the choice is theirs. For example, if there was a new component in a future release of Petal Components - they could selectively generate that one component.

In the case of the `--lib` option, files are generated for the Petal Components library. This means that the templates are "the one true source" for both the Petal Components library and the components generated inside a users web app. After updating a template, typically you'd run the following command:

```bash
mix petal_components.install --lib
```

This would update the generated/static files for the library - including the tests - and would be committed to the repo. This also means that GitHub Actions would work as they were originally designed.

## Major Changes

In this prototype, css has been re-organised. CSS for each component is in its own file. So instead of a singular monolith css file - component files are imported (into `default.css` for the Petal Components library or `petal_components.css` when it's generated for a web app). Thanks to Tailwind 4, imported files are ultimately merged into a single css file.

The other major change introduced by this prototype is the development process. What makes sense is that you'd alter the template files, run the Igniter task to generate changes, then test the code. But in reality what you'd probably do is work with the generated files, then retrospectively update the templates. Either way, this is a new chore - a trade off that gives us the ability to generate Petal Components in the users Phoenix app. 

## Breaking Changes

One of the goals of this prototype is to generate files for the library such that they are on-parity with their original counterparts. However, one complication was the `default_js_lib` mechanism that's built into `lib/petal_components.ex` (in the Petal Components repo). You either support this option at runtime or at generation time. Supporting both scenarios simultaneously is tedious. 

This prototype supports "at generation" time - which means when the library is generated it either supports Alpine or plain javascript - but not both. 

Personally, I'd prefer if it Petal Components supported plain javascript only - but the plain javascript code for the dropdown does not support persistance like it's Alpine counterpart. This is why it's set to Alpine by default.

## Limitations

As mentioned in Major Changes (above) - introduces new process for editing templates/generating code.

Accessibility code will live in the Petal Components library only. I.e. accessibility tests won't be generated in the users Phoenix app.

Heroicons v1 will stay in the Petal Components library (i.e. won't be generated)

## What's Missing/Future Work

Assuming that this prototype should be applied to Petal Components, the following work remains:

* Implement recommended practices for Igniter task documentation
* Improve tests for Igniter Tasks
* Merge work into Petal Components
* Rework Petal Development
* It needs some real world testing
