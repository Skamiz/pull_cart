#about
Adds carts which can be pulled by the player.

Rightclick to acces inventory. The item in the first inventory slot is displayed
as visible cargo on the cart.
Shift + rightclick to start pulling the cart. While pulling the cart the players
movement speed is decreased and jumping prevented to incentivize the building of
infrastructure.
Punch it to pick it up. All items in the inventory will be dropped on the ground.

#settings
'cart_speed_multiplier' - afects the players movement speed while pulling a cart

#integration
This mod mainly intends to provide the mechanics of the pullable cart,
but doesn't try to integrate it into any one game. As such there are several
things left to be done of varying importance.

- make a crafting recipe for the cart
- change the physics overrides in '_attach' and '_detach' to be compatible with
other mods
- implement protection/ownership system for server play
- change texture used for cart
- add an inventory_image

#license
MIT License

Copyright (c) 2020 Skamiz Kazzarch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
