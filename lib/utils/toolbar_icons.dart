/// Built-in toolbar glyphs the merchant can pick, plus SVG URL detection.
abstract class ToolbarGlyph {
  static const menu = 'menu';
  static const back = 'back';
  static const search = 'search';
  static const cart = 'shopping_cart_outlined';
  static const bag = 'bag';
  static const heart = 'favorite_border';
  static const star = 'star';
  static const bell = 'bell';
  static const person = 'person_outline';
  static const home = 'home';
  static const grid = 'grid_view';
  static const list = 'list';
  static const sort = 'sort';
  static const filter = 'filter';
  static const chevronDown = 'chevron_down';
  static const add = 'add';
  static const subtract = 'subtract';
  static const dismiss = 'dismiss';
  static const tag = 'tag';
  static const chat = 'chat';
  static const gift = 'gift';
  static const help = 'help';

  /// Shown in the builder icon picker.
  static const pickerIds = <String>[
    menu,
    back,
    search,
    cart,
    bag,
    heart,
    star,
    bell,
    person,
    home,
    grid,
    list,
    sort,
    filter,
    chevronDown,
    add,
    subtract,
    dismiss,
    tag,
    chat,
    gift,
    help,
  ];

  static String labelFor(String id) {
    switch (id) {
      case menu:
        return 'Menu';
      case back:
        return 'Back';
      case search:
        return 'Search';
      case cart:
        return 'Cart';
      case bag:
        return 'Bag';
      case heart:
        return 'Heart';
      case star:
        return 'Star';
      case bell:
        return 'Bell';
      case person:
        return 'Account';
      case home:
        return 'Home';
      case grid:
        return 'Grid';
      case list:
        return 'List';
      case sort:
        return 'Sort';
      case filter:
        return 'Filter';
      case chevronDown:
        return 'Chevron';
      case add:
        return 'Plus';
      case subtract:
        return 'Minus';
      case dismiss:
        return 'Close';
      case tag:
        return 'Tag';
      case chat:
        return 'Chat';
      case gift:
        return 'Gift';
      case help:
        return 'Help';
      default:
        return 'Icon';
    }
  }

  static String defaultForAction(String action) {
    switch (action) {
      case 'side_navigation':
        return menu;
      case 'back':
        return back;
      case 'cart':
        return cart;
      case 'wishlist':
        return heart;
      case 'search':
        return search;
      default:
        return menu;
    }
  }
}

bool isSvgNetworkUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return false;
  final uri = Uri.tryParse(t);
  final path = (uri?.path ?? t).toLowerCase();
  return path.endsWith('.svg') || t.toLowerCase().contains('image/svg');
}
