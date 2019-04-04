local physics_world = nil
local objects = {}
local goo_particles = {}
local goo_pool = {}
local world_width = 1024
local world_height = 768
local frame_time = 0
local frame_time_max = 0

function create_goo(x, y, r, g, b)
	local goo = {}
	goo.name = "GOO"
	goo.body = love.physics.newBody(
		physics_world,
		x,
		y,
		"dynamic"
	)
	goo.r = r
	goo.g = g
	goo.b = b
	goo.shape = love.physics.newCircleShape(20) 
	goo.fixture = love.physics.newFixture(goo.body, goo.shape)
	goo.fixture:setFriction(0.01)
	goo.fixture:setRestitution(0.1)
	goo.body:setLinearDamping(1)
	goo.body:setMass(0.1)
	return goo
end

function create_player()
	local player = {}
	player.name = "PLAYER"
	player.body = love.physics.newBody(
		physics_world,
		100,
		100,
		"dynamic"
	)

	player.body:setMass(100)
	player.body:setLinearDamping(1)
	player.shape = love.physics.newCircleShape(16)
	player.fixture = love.physics.newFixture(player.body, player.shape)
	player.fixture:setFriction(0.9)
	player.fixture:setRestitution(0.1)
	return player
end

function create_block(x, y, width, height)
	local block = {}
	block.name = "BLOCK"
	block.body = love.physics.newBody(
		physics_world,
		x,
		y,
		"static"
	)
	block.shape = love.physics.newRectangleShape(width, height)
	block.fixture = love.physics.newFixture(block.body, block.shape)
	return block
end

function love.load()
	for i = 1, 5000 do
		goo_pool[i] = {}
	end
	physics_world = love.physics.newWorld(0, 0, true)
	love.physics.setMeter(10)
	goo_shader = love.graphics.newShader("metaball.glsl")
	goo_image = love.graphics.newImage("blur.png")
	love.window.setMode(world_width, world_height, {vsync = true})
	goo_canvas1 = love.graphics.newCanvas()
	goo_canvas2 = love.graphics.newCanvas()
	player = create_player()
	table.insert(objects, player)
	block_thickness = 32
	table.insert(objects,
		create_block(
			world_width / 2,
			world_height - block_thickness / 2,
			world_width,
			block_thickness
		)
	)
	table.insert(objects,
		create_block(
			world_width / 2,
			block_thickness / 2,
			world_width,
			block_thickness
		)
	)
	table.insert(objects,
		create_block(
			block_thickness / 2,
			world_height / 2,
			block_thickness,
			world_height
		)
	)
	table.insert(objects,
		create_block(
			world_width - block_thickness / 2,
			world_height / 2,
			block_thickness,
			world_height
		)
	)
	for i = 1, 0 do
		local b = create_block(
			love.math.random(0, world_width),
			love.math.random(0, world_height),
			120,
			block_thickness
		)
		b.body:setAngle(math.rad(love.math.random(360)))
		table.insert(objects, b)
	end
end

function love.update(dt)
	local frame_start_time = os.clock()
	local fx = love.mouse.getX() - player.body:getX()
	local fy = love.mouse.getY() - player.body:getY()
	local m = math.sqrt(fx * fx + fy * fy)
	fx = (fx / m) * math.min(math.abs(m), 400)
	fy = (fy / m) * math.min(math.abs(m), 400)
	player.body:applyLinearImpulse(fx, fy)
	physics_world:update(dt)
	if love.mouse.isDown(1) then
		table.insert(
			goo_particles,
			create_goo(
				love.mouse.getX(),
				love.mouse.getY(),
				love.math.random(),
				love.math.random(),
				love.math.random()
			)
		)
	end
	frame_time = os.clock() - frame_start_time
	frame_time_max = math.max(frame_time, frame_time_max)
end

function draw_goo(goo_table)
-- draw to first canvas
	love.graphics.setCanvas(goo_canvas1)
	love.graphics.clear()
	love.graphics.setBlendMode("alpha")
	for i = 1, #goo_table do
		object = goo_table[i]
		love.graphics.setColor(object.r, object.g, object.b)
		love.graphics.draw(
			goo_image,
			object.body:getX(),
			object.body:getY(),
			0,
			1.2,
			1.2,
			goo_image:getWidth() / 2,
			goo_image:getHeight() / 2
		)
	end
	-- draw to second canvas (with shader)
	love.graphics.setColor(1, 1, 1)
	love.graphics.setCanvas(goo_canvas2)
	love.graphics.clear()
	love.graphics.setShader(goo_shader)
	love.graphics.setBlendMode("alpha")
	love.graphics.draw(goo_canvas1)
	-- draw to screen
	love.graphics.setShader()
	love.graphics.setCanvas()
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setColor(0.5, 1, 1)
	love.graphics.draw(goo_canvas2)
end

function love.draw()
	--love.graphics.setBackgroundColor(200, 100, 50)
	draw_goo(goo_particles)
	love.graphics.setBlendMode("alpha")
	for i = 1, #objects do
		object = objects[i]
		if object.name == "BLOCK" then
			love.graphics.setColor(0, 0, 0)
			love.graphics.polygon(
				"fill",
				object.body:getWorldPoints(object.shape:getPoints())
			)
		elseif object.name == "PLAYER" then
			love.graphics.setColor(255, 255, 255)
			love.graphics.circle(
				"fill",
				object.body:getX(),
				object.body:getY(),
				16
			)
			love.graphics.setColor(255, 255, 255, 100)
			local dx = love.mouse.getX() - object.body:getX()
			local dy = love.mouse.getY() - object.body:getY()
			for i = 1, 3 do
				love.graphics.circle(
					"line",
					object.body:getX() + (dx / 3) * i,
					object.body:getY() + (dy / 3) * i,
					1 + (2 * i)
				)
			end
			love.graphics.line(
				object.body:getX(),
				object.body:getY(),
				love.mouse.getX(),
				love.mouse.getY()
			)
		end
	end
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(string.format("%d ms (max %d)", frame_time * 1000, frame_time_max * 1000), 10, 10)
	love.graphics.print(string.format("%d", #goo_particles) .. " goos", 10, 26)
	love.graphics.print(string.format("%d", collectgarbage("count")) .. " garbage", 10, 42)
end