package alife

import fmt  "core:fmt"
import math "core:math"
import rand "core:math/rand"
import rl   "vendor:raylib"

//--------------------------------------@engine
vec2i :: [2]i32

Ni :: vec2i{0, -1}
Si :: vec2i{0,  1}
Wi :: vec2i{-1, 0}
Ei :: vec2i{1,  0}

king_dirs := [8]vec2i {
	Ni + Wi, Ni, Ni + Ei,
	Wi, Ei,
	Si + Wi, Si, Si + Ei,
}

WINDOW_WIDTH  :: f32(1200.0)
WINDOW_HEIGHT :: f32(800.0)

//--------------------------------------@simulation

simulation_width : i32 = i32(math.floor(WINDOW_WIDTH  / SIMULATION_VISUAL_SCALE)) // in pixels
simulation_height: i32 = i32(math.floor(WINDOW_HEIGHT / SIMULATION_VISUAL_SCALE)) // in pixels

SIMULATION_VISUAL_SCALE :: f32(3.0)
ALIVE_COLOR :: rl.DARKGREEN
DEAD_COLOR  :: rl.BLACK

tick_count: u32 = 0
ticks_per_cycle: u32 = SPEEDS[speed_index]
ticks_to_update :: u32(10)

SPEEDS: [5]u32 = {0, 1, 3, 6, 10}
speed_index: i32 = 1

// https://en.wikipedia.org/wiki/Conway's_Game_of_Life#Rules
underpopulation: i32 = 2
overpopulation : i32 = 3
reproduction   : i32 = 3
is_conway: bool = true


main :: proc() {
	rl.InitWindow(i32(WINDOW_WIDTH), i32(WINDOW_HEIGHT), "Alife")
	defer rl.CloseWindow()

	rl.SetWindowState({.WINDOW_UNDECORATED})
	rl.SetTargetFPS(60)

	icon_bytes := #load("beetle.png")
	window_icon := rl.LoadImageFromMemory(".png", raw_data(icon_bytes), i32(len(icon_bytes)))
	defer rl.UnloadImage(window_icon)

	// GUI Initialization
	FONT_SIZE :: 14

	mode_selection: i32 = 0
	show_gui := true

	font_bytes := #load("courier_prime.ttf")
	font := rl.LoadFontFromMemory(".ttf", raw_data(font_bytes), i32(len(font_bytes)), FONT_SIZE, nil, 0)
	rl.GuiSetFont(font)

	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 16, FONT_SIZE)

	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 19, i32(rl.ColorToInt(rl.BLACK)))

	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 0, i32(rl.ColorToInt(rl.DARKGREEN)))
	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 1, i32(rl.ColorToInt(rl.DARKGREEN)))
	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 2, i32(rl.ColorToInt(rl.WHITE)))

	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 3, i32(rl.ColorToInt(rl.LIME)))
	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 4, i32(rl.ColorToInt(rl.DARKGREEN)))
	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 5, i32(rl.ColorToInt(rl.WHITE)))

	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 6, i32(rl.ColorToInt(rl.LIME)))
	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 7, i32(rl.ColorToInt(rl.LIME)))
	rl.GuiSetStyle(rl.GuiControl.DEFAULT, 8, i32(rl.ColorToInt(rl.WHITE)))
	//

	image := rl.GenImageColor(simulation_width, simulation_height, DEAD_COLOR)
	defer rl.UnloadImage(image)

	texture := rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(texture)

	pixel_count := simulation_width * simulation_height
	pixels_data := ([^]rl.Color)(image.data)[:pixel_count]

	new_pixels_data := make([]rl.Color, pixel_count)
	defer delete(new_pixels_data)

	// Initiate some Alive Cells
	initial_alive_cells_amount := pixel_count / 10
	for i in 0..< initial_alive_cells_amount {
		rand_index := i32(rand.uint32_max(u32(pixel_count)))
		pixels_data[rand_index] = ALIVE_COLOR
	}
	rl.UpdateTexture(texture, image.data)


	for !rl.WindowShouldClose() {
		tick_count += ticks_per_cycle 

		if rl.IsKeyPressed(.SPACE) do show_gui = !show_gui

		if tick_count >= ticks_to_update {

			copy(new_pixels_data, pixels_data)

			if is_conway {
				for x: i32 = 0; x < simulation_width; x += 1 {
					for y: i32 = 0; y < simulation_height; y += 1 {
						coord: vec2i = {x, y}
						alive_count: i32 = 0
						for dir in king_dirs {
							neighbor_coord := coord + dir

							if !coord_in_bounds(neighbor_coord) do continue

							if pixels_data[coord_to_index(neighbor_coord)] == ALIVE_COLOR do alive_count += 1
						}

						if pixels_data[coord_to_index(coord)] == ALIVE_COLOR {
							if alive_count < underpopulation do new_pixels_data[coord_to_index(coord)] = DEAD_COLOR // rule 1
							// rule 2 is implicit
							if alive_count > overpopulation do new_pixels_data[coord_to_index(coord)] = DEAD_COLOR // rule 3
						} else {
							if alive_count == reproduction do new_pixels_data[coord_to_index(coord)] = ALIVE_COLOR // rule 4
						}
					}
				}
			} else {
				for y: i32 = simulation_height - 1; y >= 0; y -= 1 {
					for x: i32 = 0; x < simulation_width; x += 1 {
						coord: vec2i = {x, y}

						up_neighbord := coord + Ni

						if !coord_in_bounds(up_neighbord) do continue

						if pixels_data[coord_to_index(up_neighbord)] == ALIVE_COLOR &&
						pixels_data[coord_to_index(coord)] == DEAD_COLOR {
							new_pixels_data[coord_to_index(coord)] = ALIVE_COLOR
							new_pixels_data[coord_to_index(up_neighbord)] = DEAD_COLOR
						}
					}
				}
			}

			copy(pixels_data, new_pixels_data)

			rl.UpdateTexture(texture, image.data)

			tick_count = 0
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

			rl.ClearBackground(rl.BLACK)

			rl.DrawTexturePro( // Main simulation canvas
				texture, 
				{0, 0, f32(simulation_width), f32(simulation_height)}, 
				{0, 0, f32(simulation_width) * SIMULATION_VISUAL_SCALE, f32(simulation_height) * SIMULATION_VISUAL_SCALE}, 
				{0, 0}, 
				0, 
				rl.WHITE
			)

			// GUI Render
			if !show_gui do continue

			ITEM_HEIGHT :: f32(26)
			ITEM_PADDING :: f32(2)
			item_index: f32 = 0

			base_rect: rl.Rectangle = {0, 0, 300, ITEM_HEIGHT * 6}
			rl.DrawRectangleRec(base_rect, rl.BLACK)

				// Underpopulation
			underpopulation_label_rect: rl.Rectangle = {base_rect.x, ITEM_HEIGHT * item_index + (item_index * ITEM_PADDING), base_rect.width / 2, ITEM_HEIGHT}
			rl.GuiLabel(underpopulation_label_rect, "Underpopulation")

			underpopulation_rect: rl.Rectangle = underpopulation_label_rect
			underpopulation_rect.x += underpopulation_label_rect.width
			rl.GuiSpinner(
				underpopulation_rect,
				nil, 
				&underpopulation,
				0, 8,
				false	
			)

			item_index += 1

				// Overpopulation
			overpopulation_label_rect: rl.Rectangle = {base_rect.x, ITEM_HEIGHT * item_index + (item_index * ITEM_PADDING), base_rect.width / 2, ITEM_HEIGHT}
			rl.GuiLabel(overpopulation_label_rect, "Overpopulation")

			overpopulation_rect: rl.Rectangle = overpopulation_label_rect 
			overpopulation_rect.x += overpopulation_label_rect.width
			rl.GuiSpinner(
				overpopulation_rect,
				nil, 
				&overpopulation,
				0, 8,
				false	
			)

			item_index += 1

				// Reproduction
			reproduction_label_rect: rl.Rectangle = {base_rect.x, ITEM_HEIGHT * item_index + (item_index * ITEM_PADDING), base_rect.width / 2, ITEM_HEIGHT}
			rl.GuiLabel(reproduction_label_rect, "Reproduction")

			reproduction_rect: rl.Rectangle = reproduction_label_rect
			reproduction_rect.x += reproduction_label_rect.width
			rl.GuiSpinner(
				reproduction_rect,
				nil, 
				&reproduction,
				0, 8,
				false	
			)

			item_index += 1

				// Mode
			rl.GuiToggleGroup(
				{base_rect.x, ITEM_HEIGHT * item_index + (item_index * ITEM_PADDING), base_rect.width / 2 - 1, ITEM_HEIGHT},
				"Celular;Gravity",
				&mode_selection
			)

			if mode_selection == 0 do is_conway = true
			else do is_conway = false

			item_index += 1

				// Speed
			rl.GuiToggleGroup(
				{base_rect.x, ITEM_HEIGHT * item_index + (item_index * ITEM_PADDING), base_rect.width / len(SPEEDS) - 1.5, ITEM_HEIGHT},
				"|>;>;>>;>>>;>>>>", 
				&speed_index
			)

			ticks_per_cycle = SPEEDS[speed_index]
			item_index += 1

				// Spawn More
			if rl.GuiButton({base_rect.x, ITEM_HEIGHT * item_index + (item_index * ITEM_PADDING), base_rect.width, ITEM_HEIGHT}, "Spawn...") {
				for i in 0..< initial_alive_cells_amount {
					rand_index := i32(rand.uint32_max(u32(pixel_count)))
					pixels_data[rand_index] = ALIVE_COLOR
				}
			}

				// Close GUI
			if rl.GuiButton({base_rect.x + base_rect.width + 3, base_rect.y, ITEM_HEIGHT, ITEM_HEIGHT}, "x") do show_gui = false

			/* 
			GUI "System" is not ideal, worth checking for future projects:
				- Many magic numbers 
				- Awkward manual work when modifying layout/style
			*/
	}
}

//--------------------------------------@helpers

coord_to_index :: proc(coord: vec2i) -> i32 { 
	return (coord.y * simulation_width) + coord.x 
}

coord_in_bounds :: proc(coord: vec2i) -> bool {
	if coord.x < 0 || coord.x >= simulation_width  do return false
	if coord.y < 0 || coord.y >= simulation_height do return false
	return true
}
