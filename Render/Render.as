
void RenderMenu() {
  if(UI::BeginMenu(pluginName)) {
  if (UI::MenuItem("My first menu item!")) {
    mapWatcher.debug_print();
  }

        UI::EndMenu();
    }

}