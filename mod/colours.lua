-- Band colours. A startup setting selects one.
--
-- `body` is the surface itself, and it is nearly black in every option. The
-- bands must look like depth, not like paint. `highlight` is the colour that
-- the shader shows at the edges. The highlight is what makes the options
-- different: if you compare only the bodies, you cannot tell them apart.
--
-- `mirror` tints the reflected cells (about one in eight). They are a
-- mathematical property of this tiling, not a decoration.
--
-- Colour and band style are independent. Each colour works with the animated
-- liquid and with the flat void.
return {
  violet = { body = { 30, 19, 48 }, highlight = { 98, 60, 152 }, mirror = { 158, 104, 208 } },
  cold   = { body = { 23, 27, 34 }, highlight = { 62, 78, 93 },  mirror = { 82, 124, 166 } },
  oily   = { body = { 14, 26, 19 }, highlight = { 42, 85, 58 },  mirror = { 102, 180, 122 } },
  ember  = { body = { 29, 16, 11 }, highlight = { 120, 56, 24 }, mirror = { 216, 120, 56 } },
  ink    = { body = { 4, 4, 6 },    highlight = { 18, 18, 24 },  mirror = { 104, 104, 126 } },
}
