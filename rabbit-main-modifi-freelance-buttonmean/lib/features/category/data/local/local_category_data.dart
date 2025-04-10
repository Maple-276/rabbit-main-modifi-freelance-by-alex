// Defines local data specific to categories not sourced from the API.

// Constant ID for the local Grocery category
const String groceryCategoryId = '101';

// JSON definition for the main Grocery category
final Map<String, dynamic> groceryCategoryJson = {
  "id": int.parse(groceryCategoryId),
  "name": "Grocery",
  "parent_id": 0,
  "position": 0, // Position 0 to appear first
  "status": 1,
  "created_at": "", 
  "updated_at": "",
  "image": "assets/image/grocery_icon.png", // Direct path
  "banner_image": "assets/image/grocery_banner.png" // Direct path
};

// JSON definitions for the local Grocery subcategories
final List<Map<String, dynamic>> localGrocerySubcategoriesJson = [
  {
    "id": 1011, 
    "name": "Chips", 
    "parent_id": int.parse(groceryCategoryId),
    "position": 1, 
    "status": 1, 
    "image": "assets/image/chips_icon.png", // Direct path
    "created_at": "", 
    "updated_at": "", 
    "banner_image": ""
  },
  {
    "id": 1012, 
    "name": "Chocolate", 
    "parent_id": int.parse(groceryCategoryId),
    "position": 2, 
    "status": 1, 
    "image": "assets/image/chocolate_icon.png", // Direct path
    "created_at": "", 
    "updated_at": "", 
    "banner_image": ""
  },
  {
    "id": 1013, 
    "name": "Beer", 
    "parent_id": int.parse(groceryCategoryId),
    "position": 3, 
    "status": 1, 
    "image": "assets/image/beer_icon.png", // Direct path
    "created_at": "", 
    "updated_at": "", 
    "banner_image": ""
  },
  // Add more local subcategories as needed
]; 