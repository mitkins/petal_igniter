defmodule PetalIgniter.Components do
  @components [
    %{
      module: Accordion,
      file: "accordion.ex",
      test_file: "accordion_test.exs",
      css_file: "accordion.css"
    },
    %{
      module: Alert,
      file: "alert.ex",
      test_file: "alert_test.exs",
      css_file: "alert.css"
    },
    %{
      module: Avatar,
      file: "avatar.ex",
      test_file: "avatar_test.exs",
      css_file: "avatar.css"
    },
    %{
      module: Badge,
      file: "badge.ex",
      test_file: "badge_test.exs",
      css_file: "badge.css"
    },
    %{
      module: Breadcrumbs,
      file: "breadcrumbs.ex",
      test_file: "breadcrumbs_test.exs",
      css_file: "breadcrumbs.css"
    },
    %{
      module: Button,
      file: "button.ex",
      test_file: "button_test.exs",
      css_file: "button.css"
    },
    %{
      module: ButtonGroup,
      file: "button_group.ex",
      test_file: "button_group_test.exs",
      css_file: "button_group.css"
    },
    %{
      module: Card,
      file: "card.ex",
      test_file: "card_test.exs",
      css_file: "card.css"
    },
    %{
      module: Container,
      file: "container.ex",
      test_file: "container_test.exs",
      css_file: "container.css"
    },
    %{
      module: Dropdown,
      file: "dropdown.ex",
      test_file: "dropdown_test.exs",
      css_file: "dropdown.css"
    },
    %{
      module: Field,
      file: "field.ex",
      test_file: "field_test.exs",
      css_file: nil
    },
    %{
      module: Form,
      file: "form.ex",
      test_file: "form_test.exs",
      css_file: "form.css"
    },
    %{
      module: Icon,
      file: "icon.ex",
      test_file: "icon_test.exs",
      css_file: nil
    },
    %{
      module: Input,
      file: "input.ex",
      test_file: "input_test.exs",
      css_file: nil
    },
    %{
      module: Link,
      file: "link.ex",
      test_file: "link_test.exs",
      css_file: nil
    },
    %{
      module: Loading,
      file: "loading.ex",
      test_file: "loading_test.exs",
      css_file: "loading.css"
    },
    %{
      module: Marquee,
      file: "marquee.ex",
      test_file: "marquee_test.exs",
      css_file: "marquee.css"
    },
    %{
      module: Menu,
      file: "menu.ex",
      test_file: "menu_test.exs",
      css_file: "menu.css"
    },
    %{
      module: Modal,
      file: "modal.ex",
      test_file: "modal_test.exs",
      css_file: "modal.css"
    },
    %{
      module: Pagination,
      file: "pagination.ex",
      test_file: "pagination_test.exs",
      css_file: "pagination.css"
    },
    %{
      module: PaginationInternal,
      file: "pagination_internal.ex",
      test_file: nil,
      css_file: nil
    },
    %{
      module: Progress,
      file: "progress.ex",
      test_file: "progress_test.exs",
      css_file: "progress.css"
    },
    %{
      module: Rating,
      file: "rating.ex",
      test_file: "rating_test.exs",
      css_file: "rating.css"
    },
    %{
      module: Skeleton,
      file: "skeleton.ex",
      test_file: "skeleton_test.exs",
      css_file: "skeleton.css"
    },
    %{
      module: SlideOver,
      file: "slide_over.ex",
      test_file: "slide_over_test.exs",
      css_file: "slide_over.css"
    },
    %{
      module: Stepper,
      file: "stepper.ex",
      test_file: "stepper_test.exs",
      css_file: "stepper.css"
    },
    %{
      module: Table,
      file: "table.ex",
      test_file: "table_test.exs",
      css_file: "table.css"
    },
    %{
      module: Tabs,
      file: "tabs.ex",
      test_file: "tabs_test.exs",
      css_file: "tabs.css"
    },
    %{
      module: Typography,
      file: "typography.ex",
      test_file: "typography_test.exs",
      css_file: "typography.css"
    },
    %{
      module: UserDropdownMenu,
      file: "user_dropdown_menu.ex",
      test_file: "user_dropdown_menu_test.exs",
      css_file: nil
    }
  ]

  @private_components [
    PaginationInternal
  ]

  def list(), do: @components

  def components() do
    @components
    |> Enum.filter(fn component -> component.file != nil end)
    |> Enum.map(fn component -> {component.module, component.file} end)
  end

  def public_components() do
    @components
    |> Enum.filter(fn component -> component.file != nil end)
    |> Enum.filter(fn component -> !(component.module in @private_components) end)
    |> Enum.map(fn component -> {component.module, component.file} end)
  end

  def tests() do
    @components
    |> Enum.filter(fn component -> component.test_file != nil end)
    |> Enum.map(fn component -> {component.module, component.test_file} end)
  end

  def css_files() do
    @components
    |> Enum.filter(fn component -> component.css_file != nil end)
    |> Enum.map(fn component -> component.css_file end)
  end
end
