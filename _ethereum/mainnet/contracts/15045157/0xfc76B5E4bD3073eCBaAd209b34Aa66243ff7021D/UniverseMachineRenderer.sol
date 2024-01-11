// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) Joshua Davis. All rights reserved. */
pragma solidity ^0.8.13;

import "./ColorMath.sol";
import "./Graphics2D.sol";
import "./Matrix.sol";
import "./Ellipse.sol";
import "./IImageEncoder.sol";
import "./IImageRenderer.sol";

import "./RenderArgs.sol";
import "./Parameters.sol";
import "./IUniverseMachineRenderer.sol";
import "./IUniverseMachineParameters.sol";
import "./UniverseMachineParameters.sol";
import "./Textures.sol";
import "./Texture0.sol";
import "./Texture1.sol";
import "./Texture2.sol";
import "./Texture3.sol";
import "./Texture4.sol";
import "./Texture5.sol";

import "./UniverseMachineGrid.sol";
import "./UniverseMachineSkeleton.sol";
import "./UniverseMachineUniverse.sol";
import "./UniverseMachineStars.sol";
import "./UniverseMachineMats.sol";

import "./Ownable.sol";
import "./ERC165Checker.sol";

/*
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//                                            ,,╓╓╥╥╥╥╥╥╥╥╖╓,                                             //
//                                      ╓╥H╢▒░░▄▄▄▄██████▄▄▄▄░░▒▒H╖,                                      //
//                                 ,╓H▒░░▄████████████████████████▄░░▒H╖                                  //
//                              ╓╥▒░▄██████████████████████████████████▄░▒b,                              //
//                           ╓║▒░▄████████████████████████████████████████▄░▒H╓                           //
//                        ╓╥▒░▄██████████████████████████████████████████████▄░▒╥,                        //
//                      ╓╢░▄████▓███████████████████████████████████████████████▄░▒╖                      //
//                    ╥▒░████▓████████████████████████████████████████████████████▄░▒╖                    //
//                  ╥▒░████▓█████████████████████████████████████████████████████████░▒╖                  //
//                ╥▒░████▓████████████████████████████████████████████████████████▓████░▒╖                //
//              ╓▒░█████▓███████████████████████████████████████████████████████████▓████░▒╖              //
//            ,║▒▄████▓███████████████████░'▀██████████████████░]█████████████████████▓███▄▒▒             //
//           ╓▒░█████▓████████████████████▒  ░███████████████▀   ███████████████████████▓███░▒╖           //
//          ╥▒▄█████▓█████████████████████░    └▀▀▀▀▀▀▀▀██▀░    ;████████████████████████▓███▄▒╥          //
//         ╢▒██████▓██████████████████████▌,                    ░█████████████████████████████▌▒▒         //
//        ▒▒██████▓████████████████████████▌     ,, ,╓, ,,     ¿████████████████████████████████▒▒        //
//       ╢▒██████▓█████████████████████████▌    ▒██▒█░█░██░   .█████████████████████████████▓███▌▒▒       //
//      ]▒▐█████▓███████████████████████████▒       ░▀▀        ██████████████████████████████████░▒┐      //
//      ▒░██████▓███████████████████████████                   ▐█████████████████████████████▓████▒▒      //
//     ]▒▐█████▓███████████████████████████░                   ░█████████████████████████████▓████░▒L     //
//     ▒▒██████▓██████████████████████████▌                     ░████████████████████████████▓████▌▒▒     //
//     ▒▒█████▓███████████████████████████░                      ▐███████████████████████████▓█████▒▒     //
//     ▒▒█████▓███████████████████████████▒                      ░███████████████████████████▓████▌▒▒     //
//     ▒▒█████▓███████████████████████████▒                      ▒██████████████████████████▓█████▌▒[     //
//     ]▒░████▓███████████████████████████░                      ▐██████████████████████████▓█████░▒      //
//      ▒▒████▓███████████████████████████▌                      ▐█████████████████████████▓█████▌▒▒      //
//      ╙▒░████▓██████████████████████████▌                      ▐███████████████████████████████░▒       //
//       ╙▒░███▓███████████████████████████░                    ░███████████████████████████████░▒`       //
//        ╙▒░███▓██████████████████████████▌                   ,█████████████████████████▓█████░▒╜        //
//         ╙▒░███▓██████████████████████████░                 ,▐████████████████████████▓█████░▒`         //
//          ╙▒░███▓███████████████████████████░             ;▄██████████████████████████████▀░▒           //
//            ╢▒▀███▓█████████████████████████▄█▌▄▄███▄▄▄,░▄▄▄███████████████████████▓█████░▒╜            //
//             ╙▒░▀███▓█████████████████████████████████████████████████████████████▓████▀░▒`             //
//               ╙▒░████▓█████████████████████████████████████████████████████████▓████▀░▒╜               //
//                 ╨▒░███████████████████████████████████████████████████████████▓███▀░▒╜                 //
//                   ╙▒░▀██████████████████████████████████████████████████████▓███▀░▒╜                   //
//                     ╙▒░▀█████████████████████████████████████████████████▓████▀░▒╜                     //
//                       `╨▒░▀████████████████████████████████████████████████▀▒░╨`                       //
//                          ╙▒░░▀██████████████████████████████████████████▀░░▒╜                          //
//                             ╙╣░░▀████████████████████████████████████▀▒░▒╜                             //
//                                ╙╨▒░░▀████████████████████████████▀░░▒╜`                                //
//                                    ╙╨╢▒░░▀▀███████████████▀▀▀▒░▒▒╜`                                    //
//                                         `╙╙╨╨▒▒░░░░░░░░▒▒╨╨╜"`                                         //
//                                                                                                        //
//       ▄▄▄██▀▀▀▒█████    ██████  ██░ ██  █    ██  ▄▄▄      ▓█████▄  ▄▄▄    ██▒   █▓ ██▓  ██████         //
//         ▒██  ▒██▒  ██▒▒██    ▒ ▓██░ ██▒ ██  ▓██▒▒████▄    ▒██▀ ██▌▒████▄ ▓██░   █▒▓██▒▒██    ▒         //
//         ░██  ▒██░  ██▒░ ▓██▄   ▒██▀▀██░▓██  ▒██░▒██  ▀█▄  ░██   █▌▒██  ▀█▄▓██  █▒░▒██▒░ ▓██▄           //
//      ▓██▄██▓ ▒██   ██░  ▒   ██▒░▓█ ░██ ▓▓█  ░██░░██▄▄▄▄██ ░▓█▄   ▌░██▄▄▄▄██▒██ █░░░██░  ▒   ██▒        //
//       ▓███▒  ░ ████▓▒░▒██████▒▒░▓█▒░██▓▒▒█████▓  ▓█   ▓██▒░▒████▓  ▓█   ▓██▒▒▀█░  ░██░▒██████▒▒        //
//       ▒▓▒▒░  ░ ▒░▒░▒░ ▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░▒▓▒ ▒ ▒  ▒▒   ▓▒█░ ▒▒▓  ▒  ▒▒   ▓▒█░░ ▐░  ░▓  ▒ ▒▓▒ ▒ ░        //
//       ▒ ░▒░    ░ ▒ ▒░ ░ ░▒  ░ ░ ▒ ░▒░ ░░░▒░ ░ ░   ▒   ▒▒ ░ ░ ▒  ▒   ▒   ▒▒ ░░ ░░   ▒ ░░ ░▒  ░ ░        //
//       ░ ░ ░  ░ ░ ░ ▒  ░  ░  ░   ░  ░░ ░ ░░░ ░ ░   ░   ▒    ░ ░  ░   ░   ▒     ░░   ▒ ░░  ░  ░          //
//       ░   ░      ░ ░        ░   ░  ░  ░   ░           ░  ░   ░          ░  ░   ░   ░        ░          //
//                                                          ░                  ░                          //
//     ██▓███   ██▀███   ▄▄▄     ▓██   ██▓  ██████ ▄▄▄█████▓ ▄▄▄     ▄▄▄█████▓ ██▓ ▒█████   ███▄    █     //
//    ▓██░  ██▒▓██ ▒ ██▒▒████▄    ▒██  ██▒▒██    ▒ ▓  ██▒ ▓▒▒████▄   ▓  ██▒ ▓▒▓██▒▒██▒  ██▒ ██ ▀█   █     //
//    ▓██░ ██▓▒▓██ ░▄█ ▒▒██  ▀█▄   ▒██ ██░░ ▓██▄   ▒ ▓██░ ▒░▒██  ▀█▄ ▒ ▓██░ ▒░▒██▒▒██░  ██▒▓██  ▀█ ██▒    //
//    ▒██▄█▓▒ ▒▒██▀▀█▄  ░██▄▄▄▄██  ░ ▐██▓░  ▒   ██▒░ ▓██▓ ░ ░██▄▄▄▄██░ ▓██▓ ░ ░██░▒██   ██░▓██▒  ▐▌██▒    //
//    ▒██▒ ░  ░░██▓ ▒██▒ ▓█   ▓██▒ ░ ██▒▓░▒██████▒▒  ▒██▒ ░  ▓█   ▓██▒ ▒██▒ ░ ░██░░ ████▓▒░▒██░   ▓██░    //
//    ▒▓▒░ ░  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░  ██▒▒▒ ▒ ▒▓▒ ▒ ░  ▒ ░░    ▒▒   ▓▒█░ ▒ ░░   ░▓  ░ ▒░▒░▒░ ░ ▒░   ▒ ▒     //
//    ░▒ ░       ░▒ ░ ▒░  ▒   ▒▒ ░▓██ ░▒░ ░ ░▒  ░ ░    ░      ▒   ▒▒ ░   ░     ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░    //
//    ░░         ░░   ░   ░   ▒   ▒ ▒ ░░  ░  ░  ░    ░        ░   ▒    ░       ▒ ░░ ░ ░ ▒     ░   ░ ░     //
//                ░           ░  ░░ ░           ░                 ░  ░         ░      ░ ░           ░     //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

contract UniverseMachineRenderer is Ownable, IERC165, IUniverseMachineRenderer {
    using ERC165Checker for address;

    IImageEncoder public encoder;
    bool public encoderLocked = false;

    function setEncoder(IImageEncoder _encoder) external onlyOwner {
        encoder = IImageEncoder(_encoder);
    }

    function lockEncoder() external onlyOwner {
        require(
            address(encoder).supportsInterface(type(IImageEncoder).interfaceId),
            "Not IImageEncoder"
        );
        encoderLocked = true;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IUniverseMachineRenderer).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function image(Parameters memory p)
        external
        view
        override
        returns (string memory)
    {
        require(address(encoder) != address(0), "No encoder");
        return encoder.imageUri(render_impl(p));
    }

    function render(
        uint256 tokenId,
        int32 seed,
        address parameters
    ) external view override returns (uint8[] memory) {
        Parameters memory p = IUniverseMachineParameters(parameters)
            .getParameters(tokenId, seed);
        return render_impl(p);
    }

    function render_impl(Parameters memory p)
        private
        pure
        returns (uint8[] memory)
    {
        Graphics2D memory g = Graphics2DMethods.create(1674, 2400);

        (Matrix memory scaled, Matrix memory m) = createMatrices();

        RenderUniverseTextures memory t;
        {
            t.t0 = Texture0Factory.createTexture();
            t.t1 = Texture1Factory.createTexture();
            t.t2 = Texture2Factory.createTexture();
            t.t3 = Texture3Factory.createTexture();
            t.t4 = Texture4Factory.createTexture();
        }
        VertexData[][] memory t5 = Texture5Factory.createTexture();

        VertexData[][] memory skeleton = UniverseMachineSkeletonFactory.create(p);
        RenderUniverseArgs[] memory universe = UniverseMachineUniverseFactory.create(p, m);
        RenderStar[] memory stars = UniverseMachineStarsFactory.create(p, m);
        VertexData[][] memory mats = UniverseMachineMatsFactory.createMats(g);
        
        DrawContext memory f;
        f.transformed = new VertexData[](500);

        renderBackground(g, p);
        g.buffer = UniverseMachineGrid.renderGrid(g, f, p, scaled);
        g.buffer = UniverseMachineSkeleton.renderSkeleton(g, f, scaled, skeleton);
        g.buffer = UniverseMachineUniverse.renderUniverse(g, f, p.whichTex, universe, t, scaled);
        g.buffer = UniverseMachineStars.renderStars(g, f, t5, stars);
        g.buffer = UniverseMachineMats.renderMats(g, f, p, mats);
        
        return g.buffer;
    }

    function renderBackground(Graphics2D memory g, Parameters memory parameters)
        private
        pure
    {
        uint32 c = uint32(parameters.starPositions[0].c % parameters.cLen);

        uint32 background = ColorMath.toColor(
            255,
            parameters.myColorsR[c],
            parameters.myColorsG[c],
            parameters.myColorsB[c]
        );
        
        Graphics2DMethods.clear(g, background);
    }

    function createMatrices()
        internal
        pure
        returns (Matrix memory scaled, Matrix memory m)
    {
        Matrix memory canvasCorner = MatrixMethods.newTranslation(
            365072220160,
            365072220160
        );
        Matrix memory origin = MatrixMethods.newTranslation(
            3231962890240,
            4784593567744
        );
        scaled = MatrixMethods.mul(
            MatrixMethods.mul(
                MatrixMethods.newScale(
                    2992558336 /* 0.6967592592592593 */
                ),
                origin
            ),
            canvasCorner
        );
        m = MatrixMethods.mul(origin, canvasCorner);
        return (scaled, m);
    }
}
