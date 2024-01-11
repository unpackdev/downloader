// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Graphics2D.sol";
import "./Matrix.sol";
import "./Ellipse.sol";
import "./Stroke.sol";
import "./CustomPath.sol";
import "./ColorMath.sol";
import "./DrawContext.sol";

import "./Textures.sol";
import "./RenderUniverseArgs.sol";

library Texture4Factory {
    function createTexture() external pure returns (TextureData memory texture) {    

        texture.vertices = new VertexData[][](20);
        texture.colors = new uint32[](20);

        {
            CustomPath memory poly1 = CustomPathMethods.create(8);
            CustomPathMethods.moveTo(poly1, 7620234051584, 4179123765248);
            CustomPathMethods.lineTo(poly1, 5570246475776, 3122664046592);
            CustomPathMethods.lineTo(poly1, 7915813994496, 3204664262656);

            Stroke memory polyStroke1 = StrokeMethods.create(CustomPathMethods.vertices(poly1), 2147483648 /* 0.5 */, 200, 200);
            polyStroke1.lineCap = LineCap.Round;
            polyStroke1.lineJoin = LineJoin.Round;

            texture.vertices[0] = CustomPathMethods.vertices(poly1);
            texture.vertices[1] = StrokeMethods.vertices(polyStroke1);

            CustomPath memory poly2 = CustomPathMethods.create(8);
            CustomPathMethods.moveTo(poly2, 8940808044544, 4338354749440);
            CustomPathMethods.lineTo(poly2, 7620234051584, 4179123765248);
            CustomPathMethods.lineTo(poly2, 7915813994496, 3204664262656);
            CustomPathMethods.lineTo(poly2, 8940808044544, 4338354749440);

            Stroke memory polyStroke2 = StrokeMethods.create(CustomPathMethods.vertices(poly2), 2147483648 /* 0.5 */, 200, 200);
            polyStroke2.lineCap = LineCap.Round;
            polyStroke2.lineJoin = LineJoin.Round;

            texture.vertices[2]  = CustomPathMethods.vertices(poly2);
            texture.vertices[3] = StrokeMethods.vertices(polyStroke2);
        }

        {
            CustomPath memory line1 = CustomPathMethods.create(8);
            CustomPathMethods.moveTo(line1, 0, 3816800387072);
            CustomPathMethods.lineTo(line1, 5570246475776, 3122664046592);

            Stroke memory stroke1 = StrokeMethods.create(CustomPathMethods.vertices(line1), 1073741824 /* 0.25 */, 200, 200);
            stroke1.lineCap = LineCap.Round;
            stroke1.lineJoin = LineJoin.Round;
            
            CustomPath memory line2 = CustomPathMethods.create(8);
            CustomPathMethods.moveTo(line2, 9534827397120, 4708305993728);
            CustomPathMethods.lineTo(line2, 8940808044544, 4338354749440);

            Stroke memory stroke2 = StrokeMethods.create(CustomPathMethods.vertices(line2), 1073741824 /* 0.25 */, 200, 200);
            stroke2.lineCap = LineCap.Round;
            stroke2.lineJoin = LineJoin.Round;

            texture.vertices[4] = StrokeMethods.vertices(stroke1);
            texture.vertices[5] = StrokeMethods.vertices(stroke2);
        }
        
        {
            texture.vertices[6] = EllipseMethods.vertices(EllipseMethods.create(4335486107648, 5130699145216, 22883586048, 22883586048));
            texture.vertices[7] = EllipseMethods.vertices(EllipseMethods.create(4801739358208, 5074443567104, 22883586048, 22883586048));
            texture.vertices[8] = EllipseMethods.vertices(EllipseMethods.create(5267992346624, 5019141668864, 22883586048, 22883586048));
            texture.vertices[9] = EllipseMethods.vertices(EllipseMethods.create(5734245335040, 4962886090752, 22883586048, 22883586048));
            texture.vertices[10] = EllipseMethods.vertices(EllipseMethods.create(6200498323456, 4906631036928, 22883586048, 22883586048));
            texture.vertices[11] = EllipseMethods.vertices(EllipseMethods.create(6666751311872, 4851328614400, 22883586048, 22883586048));
            texture.vertices[12] = EllipseMethods.vertices(EllipseMethods.create(7133004300288, 4795073036288, 22883586048, 22883586048));
            texture.vertices[13] = EllipseMethods.vertices(EllipseMethods.create(7599257288704, 4739771138048, 22883586048, 22883586048));
            texture.vertices[14] = EllipseMethods.vertices(EllipseMethods.create(8065510801408, 4683515559936, 22883586048, 22883586048));
            texture.vertices[15] = EllipseMethods.vertices(EllipseMethods.create(8531763789824, 4628213661696, 22883586048, 22883586048));
            texture.vertices[16] = EllipseMethods.vertices(EllipseMethods.create(4569089703936, 4348843655168, 31464931328, 31464931328));
            texture.vertices[17] = EllipseMethods.vertices(EllipseMethods.create(5966894989312, 4181030076416, 31464931328, 31464931328));
            texture.vertices[18] = EllipseMethods.vertices(EllipseMethods.create(4335486107648, 3678545117184, 39092793344, 39092793344));
            texture.vertices[19] = EllipseMethods.vertices(EllipseMethods.create(4102836191232, 2952944680960, 46720655360, 39092793344));
        }

        texture.colors[0] = 3221225471;
        texture.colors[1] = 4278190080;
        texture.colors[2] = 2147483647;
        texture.colors[3] = 4278190080;
        texture.colors[4] = 2130706432;
        texture.colors[5] = 2130706432;
        texture.colors[6] = 4294967295;
        texture.colors[7] = 4294967295;
        texture.colors[8] = 4294967295;
        texture.colors[9] = 4294967295;
        texture.colors[10] = 4294967295;
        texture.colors[11] = 4294967295;
        texture.colors[12] = 4294967295;
        texture.colors[13] = 4294967295;
        texture.colors[14] = 4294967295;
        texture.colors[15] = 4294967295;
        texture.colors[16] = 4294967295;
        texture.colors[17] = 4294967295;
        texture.colors[18] = 4294967295;
        texture.colors[19] = 4294967295;

    }
}