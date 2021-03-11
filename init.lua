local modname = minetest.get_current_modname()
local storage = minetest.get_mod_storage()
local S = minetest.get_translator("pull_cart")

--[[
things one might want to do in case of adaptation:
- make a crafting recipe for the cart
- change the physics overrides in '_attach' and '_detach' to be compatible with other mods
- implement protection/ownership system for server play
- more appropriate texture
- add an inventory_image
--]]

local pull_cart = {}
pull_cart.cart_number = tonumber(storage:get("cart_number") or 1)
pull_cart.players = {}

-- meant to be a multiplier, but with the current simple way of handling pysics overrides
-- it just flat out sets the speed to this value
local speed_multiplier = tonumber(minetest.settings:get("cart_speed_multiplier")) or 0.7
-- if you change this don't forget to also change the formspec
local cart_inv_size = 2*8
-- how far the cart stays behind the player
local distance_to_cart = 1.2

local function distance_2(v)
	return v.x*v.x + v.y*v.y + v.z*v.z
end

minetest.register_node(modname .. ":pull_cart", {
	description = S("Cart"),
	tiles = {"pull_cart_planks.png"},
	-- inventory_image = "insert_nice_image_here.png",
	paramtype = "light",
	sunlight_propagates = true,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-10/16, -2/16, -10/16, 10/16, 0/16, 12/16},

			{-10/16, 0/16, -10/16, -8/16, 8/16, -8/16},
			{8/16, 0/16, -10/16, 10/16, 8/16, -8/16},
			{-10/16, 0/16, 10/16, -8/16, 4/16, 12/16},
			{8/16, 0/16, 10/16, 10/16, 4/16, 12/16},

			{-8/16, 4/16, -10/16, 8/16, 8/16, -8/16},
			{-10/16, 4/16, -8/16, -8/16, 8/16, 24/16},
			{8/16, 4/16, -8/16, 10/16, 8/16, 24/16},

			{-10/16, -4/16, -1/16, 10/16, -2/16, 1/16},

			{10/16, -6/16, -5/16, 12/16, 0/16, 5/16},
			{10/16, -8/16, -3/16, 12/16, 2/16, 3/16},

			{-12/16, -6/16, -5/16, -10/16, 0/16, 5/16},
			{-12/16, -8/16, -3/16, -10/16, 2/16, 3/16},
		},
	},
	groups = {hand = 1},
	node_placement_prediction = "",
	on_place = function(itemstack, placer, pointed_thing)
		local cart = minetest.add_entity(pointed_thing.above, modname .. ":pull_cart")
		-- rotate cart to face placer
		local rot = cart:get_rotation()
		rot.y = minetest.dir_to_yaw(vector.subtract(placer:get_pos(), cart:get_pos()))
		cart:set_rotation(rot)

		itemstack:take_item()
		return itemstack
	end,
})

minetest.register_entity(modname .. ":pull_cart", {
	initial_properties = {
		visual = "item",
		visual_size = {x = 2/3, y = 2/3, z = 2/3},
		physical = true,
		collide_with_objects = true,
		static_save = true,
		wield_item = modname .. ":pull_cart",
	},

	_attach = function(self, player)
		self.puller = player
		local player_name = player:get_player_name()
		if pull_cart.players[player_name] then
			pull_cart.players[player_name]:_detach(player)
		end
		pull_cart.players[player_name] = self

		-- TODO: naturally this shouldn't touch the PO so directly
		local po = player:get_physics_override()
		po.speed = speed_multiplier
		po.jump = 0
		player:set_physics_override(po)
	end,

	_detach = function(self, player)
		self.puller = nil
		local player_name = player:get_player_name()
		pull_cart.players[player_name] = nil

		local rot = self.object:get_rotation()
		rot.x = -(math.pi / 8)
		self.object:set_rotation(rot)

		local po = player:get_physics_override()
		po.speed = 1
		po.jump = 1
		player:set_physics_override(po)
	end,

	-- attaches an object with the appearance of the item in the first inventory slot
	_update_cargo = function(self)
		self:_remove_children()

		local item_name = self.inv:get_stack("main", 1):get_name()
		if item_name ~= "" then
			local cargo = minetest.add_entity(self.object:get_pos(), modname .. ":pull_cart_cargo")
			cargo:set_attach(self.object, "", {x=0, y = 15, z=0})
			cargo:set_properties({wield_item = item_name})
		end
	end,

	_get_callbacks = function(self)
		return {
			on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
				self:_update_cargo()
			end,
		    on_put = function(inv, listname, index, stack, player)
				self:_update_cargo()
			end,
		    on_take = function(inv, listname, index, stack, player)
				self:_update_cargo()
			end,
		}
	end,

	_show_formspec = function(self, player)
		minetest.show_formspec(player:get_player_name(), modname .. ":inventory",
		"formspec_version[4]" ..
		"size[10.75,8.5]"..
		"container[0.5,0.5]"..
		"list[detached:" .. modname .. ":cart_" .. self.cart_number .. ";main;0,0;8,2;]" ..
		"list[current_player;main;0,2.75;8,4;]" ..
		"listring[]" ..
		"container_end[]" ..
		""
	)
	end,

	_remove_children = function(self)
		for _, child in pairs(self.object:get_children()) do
			child:remove()
		end
	end,

	_remove = function(self)
		local inv_content = self.inv:get_list("main")
		local pos = self.object:get_pos()

		for _, item in pairs(inv_content) do
			minetest.add_item(pos, item)
		end
		minetest.add_item(pos, {name = modname .. ":pull_cart"})

		storage:set_string("cart_" .. self.cart_number, "")
		self:_remove_children()
		self.object:remove()
	end,

	on_rightclick = function(self, clicker)
		if clicker:get_player_control().sneak then
			if self.puller then
				if self.puller:get_player_name() == clicker:get_player_name() then
					self:_detach(clicker)
				end
			else
				self:_attach(clicker)
			end
		else
			self:_show_formspec(clicker)
		end
	end,

	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		self:_remove()
	end,

	get_staticdata = function(self)
		return tostring(self.cart_number)
	end,

	on_activate = function(self, staticdata, dtime_s)
		self.puller = nil
		self.object:set_acceleration({x=0, y=-9.81, z=0})

		local rot = self.object:get_rotation()
		rot.x = -(math.pi / 8)
		self.object:set_rotation(rot)

		if staticdata == "" then
			self.cart_number = pull_cart.cart_number
			pull_cart.cart_number = pull_cart.cart_number + 1
			storage:set_int("cart_number", pull_cart.cart_number)

			local inv = minetest.create_detached_inventory(modname .. ":cart_" .. self.cart_number, self:_get_callbacks())
			inv:set_size("main", cart_inv_size)

			self.inv = inv
		else
			self.cart_number = tonumber(staticdata)
			local inv = minetest.get_inventory({type = "detached", name = modname .. ":cart_" .. self.cart_number})
			-- if the game was closed the inventories have to be made anew, instead of just reattached
			if not inv then
				inv = minetest.create_detached_inventory(modname .. ":cart_" .. self.cart_number, self:_get_callbacks())
				inv:set_size("main", cart_inv_size)
				local inv_content = minetest.deserialize(storage:get_string("cart_" .. self.cart_number))
				inv:set_list("main", inv_content)
			end

			self.inv = inv
		end

		self:_update_cargo()
	end,

	on_deactivate = function(self)
		local inv_content = self.inv:get_list("main")
		for k, v in pairs(inv_content) do
			inv_content[k] = v:to_string()
		end

		local inv_content = minetest.serialize(inv_content)
		storage:set_string("cart_" .. self.cart_number, inv_content)

		self:_remove_children()
	end,

	on_step = function(self, dtime, moveresult)
		if self.puller then

			local puller = self.puller
			local object = self.object
			local p_pos = puller:get_pos()
			p_pos.y = p_pos.y + 0.5
			local direction = vector.subtract(p_pos, object:get_pos())

			if distance_2(direction) > (2.5*2.5) then
				self:_detach(puller)
				return
			end

			local rot = object:get_rotation()
			rot.x = math.atan2(direction.y, distance_to_cart)
			rot.y = minetest.dir_to_yaw(direction)
			object:set_rotation(rot)

			direction.y = 0
			local direction = vector.normalize(direction)
			local o_pos = object:get_pos()
			local pos = vector.subtract(p_pos, vector.multiply(direction, distance_to_cart))
			pos.y = o_pos.y
			if minetest.registered_nodes[minetest.get_node(vector.round(pos)).name].walkable then
				pos.y = pos.y + 0.6
			end
			object:move_to(pos, true)
		end
	end,
})

minetest.register_entity(modname .. ":pull_cart_cargo", {
	initial_properties = {
		visual = "item",
		visual_size = {x = 2, y = 2, z = 2},
		physical = true,
		static_save = false,
		pointable = false,
	},
})

-- in case the player leaves while pulling a cart
minetest.register_on_leaveplayer(function(player, timed_out)
	if not player then return end
	local player_name = player:get_player_name()
	if pull_cart.players[player_name] then
		pull_cart.players[player_name]:_detach(player)
	end
end)
