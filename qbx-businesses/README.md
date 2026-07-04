# qbx-businesses

Player-owned business system for **Qbox** servers. Players can buy shops, hire employees, manage stock and prices, run delivery missions, and earn business income.

## Features

- **Buy a business** — Purchase predefined shop locations from the register
- **Employee clock-in** — Hired staff clock in/out at the business
- **Boss management** — Withdraw/deposit funds, set prices, hire/fire employees, view transactions
- **Customer shopping** — Players buy items from owned businesses (integrates with ox_inventory)
- **Business income** — Sales revenue goes to the business bank account
- **Stock delivery missions** — Clocked-in employees drive to a warehouse and return to restock
- **Configurable business types** — Add new shop types and locations in config files

## Dependencies

| Resource | Required |
|----------|----------|
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Yes |
| [ox_lib](https://github.com/CommunityOx/ox_lib) | Yes |
| [oxmysql](https://github.com/CommunityOx/oxmysql) | Yes |
| [ox_target](https://github.com/CommunityOx/ox_target) | Recommended |
| [ox_inventory](https://github.com/CommunityOx/ox_inventory) | Recommended |

## Installation

1. Copy `qbx-businesses` into your server's `resources` folder (e.g. `resources/[qbx]/qbx-businesses`).

2. Import the database schema:

```bash
mysql -u USER -p DATABASE < qbx-businesses/sql/install.sql
```

3. Add to `server.cfg` **after** core dependencies:

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_target
ensure ox_inventory
ensure qbx-businesses
```

4. Restart the server.

## Configuration

### Global settings — `shared/config.lua`

- Purchase/payment account types (`cash` / `bank`)
- Profit margin on sales
- Employee wages and intervals
- Delivery mission settings (vehicle, stock amount, cooldown)
- Interaction distance and blip settings

### Business types — `shared/businesses.lua`

Each type defines:

- Default purchase price
- Stock items (item name, label, default price, max stock, delivery cost)
- Warehouse pickup location for delivery missions

Example:

```lua
['convenience_store'] = {
    label = 'Convenience Store',
    defaultPurchasePrice = 75000,
    deliveryPickup = vector4(849.41, -902.53, 25.25, 90.0),
    stock = {
        { item = 'water_bottle', label = 'Water', defaultPrice = 3, maxStock = 100, deliveryCost = 1 },
    },
},
```

### Business locations — `shared/businesses.lua`

Each location defines interaction points:

| Field | Purpose |
|-------|---------|
| `id` | Unique database key |
| `type` | References a business type |
| `shop` | Customer purchase zone |
| `management` | Boss terminal |
| `clockIn` | Employee clock-in / delivery start |
| `deliverySpawn` | Delivery vehicle spawn |
| `blip` | Map blip position |

## In-game usage

| Action | Where |
|--------|-------|
| Buy business | Shop register (when for sale) |
| Browse shop | Shop register (when owned) |
| Manage business | Management terminal (owner only) |
| Clock in/out | Clock-in point |
| Start delivery | Clock-in point (while clocked in) |
| `/business` | Quick menu for owned businesses |

## Item names

Stock items must exist in **ox_inventory** (or your items config). Default examples use common Qbox item names like `water_bottle`, `sandwich`, `beer`, `lockpick`. Update `shared/businesses.lua` to match your server's item list.

## Adding a new business

1. Add or reuse a type in `BusinessTypes`.
2. Add a location entry to `BusinessLocations` with coordinates for your map.
3. Restart the resource — the database row is created automatically on start.

## License

MIT
