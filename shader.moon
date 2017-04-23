
{graphics: g} = love

class LutShader
  shader: -> [[
    extern Image lut;

    // from https://github.com/mattdesl/glsl-lut/blob/master/index.glsl
    vec4 lookup(vec4 textureColor, Image lookupTable) {
      float blueColor = textureColor.b * 63.0;

      vec2 quad1;
      quad1.y = floor(floor(blueColor) / 8.0);
      quad1.x = floor(blueColor) - (quad1.y * 8.0);

      vec2 quad2;
      quad2.y = floor(ceil(blueColor) / 8.0);
      quad2.x = ceil(blueColor) - (quad2.y * 8.0);

      vec2 texPos1;
      texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
      texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

      vec2 texPos2;
      texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
      texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

      lowp vec4 newColor1 = Texel(lookupTable, texPos1);
      lowp vec4 newColor2 = Texel(lookupTable, texPos2);

      lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
      return newColor;
    }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      vec4 c = Texel(texture, texture_coords);
      return lookup(c, lut);
    }
  ]]

  send: =>
    @shader\send "lut", @lookup_image

  new: (@lookup_image) =>
    @shader = g.newShader @shader!

  render: (fn) =>
    g.setShader @shader
    @send!
    fn!
    g.setShader!

{ :LutShader }
