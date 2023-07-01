
void RenderMenu() {
  if(UI::BeginMenu(pluginName)) {
  if (UI::MenuItem("My first menu item!")) {
    print("You clicked me!!");
  }

        UI::EndMenu();
    }

}