// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
Contract that's primarily responsible for generating the metadata, including the image itself in SVG.
Parts of the SVG is encapsulated into custom re-usable components specific to this collection.
*/
contract SoulsDescriptor {

    function generateName(string memory soulType, uint soulNr) public pure returns (string memory) {
        return string(abi.encodePacked(soulType, ' Forgotten Soul #', substring(toString(soulNr),0,8)));
    }

    function generateTraits(uint256 tokenId, bool fullSoul) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));

        string memory paintingTraits = "";

        string memory paintingType = string(abi.encodePacked('{"trait_type": "Type", "value": "Fully Painted"},'));
        if(fullSoul == false) { paintingType = string(abi.encodePacked('{"trait_type": "Type", "value": "Sketch"},'));}

        (uint colour1, uint colour2, uint colour3) = generateColours(hash);
        string memory compositionType = getColourCompositionType(toUint8(hash,2));
        uint saturation = 60 - uint256(toUint8(hash,30))*55/255;

        string memory layersTrait = "";
        uint layers;

        bool colours;
        if(toUint8(hash,22) < 128 || fullSoul == true) { 
            paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Background"}, {"trait_type": "Colour 1", "value":"',toString(colour1),'" },')); 
            layers++;
            colours = true;
        }
        if(toUint8(hash,23) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Frame"},')); layers++; }
        if(toUint8(hash,24) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Back Splash"},')); layers++; }
        if(toUint8(hash,25) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Body"},')); layers++; }
        if(toUint8(hash,26) < 128 || fullSoul == true) { 
            paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Back Head"}, {"trait_type": "Colour 2", "value": "',toString(colour2),'" },')); 
            layers++; 
            colours = true;
        }
        if(toUint8(hash,27) < 128 || fullSoul == true) { 
            paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Front Head"}, {"trait_type": "Colour 3", "value": "',toString(colour3),'" },')); 
            layers++; 
            colours = true; 
        }
        if(toUint8(hash,28) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Rings"},')); layers++; }
        if(toUint8(hash,29) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Eyes"},')); layers++; }

        layersTrait = string(abi.encodePacked('{"trait_type": "Layers", "value": "',toString(layers),'"}'));

        string memory colourCompositionTrait;
        if(colours == true) { colourCompositionTrait = string(abi.encodePacked('{"trait_type": "Colour Composition Type", "value": "',compositionType,'" }, {"trait_type": "Saturation", "value": "',toString(saturation),'" },')); }

        return string(abi.encodePacked(
            '"attributes": [',
            paintingType,
            colourCompositionTrait,
            paintingTraits,
            layersTrait,
            ']'
        ));
    }

    function generateImage(uint256 tokenId, bool fullSoul) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));

        (uint colour1, uint colour2, uint colour3) = generateColours(hash);

        string memory background = "";
        string memory innerFrame = "";
        string memory backSplash = "";
        string memory body = "";
        string memory backHead = "";
        string memory frontHead = "";
        string memory rings = "";
        string memory eyes = "";

        // Hash Bytes used to this point-> 21
        if(toUint8(hash,22) < 128 || fullSoul == true) { background = generateBackground(hash, colour1); }
        if(toUint8(hash,23) < 128 || fullSoul == true) { innerFrame = generateInnerFrame(hash); }
        if(toUint8(hash,24) < 128 || fullSoul == true) { backSplash = generateBackSplash(hash); }
        if(toUint8(hash,25) < 128 || fullSoul == true) { body = generateBody(hash); }
        if(toUint8(hash,26) < 128 || fullSoul == true) { backHead = generateBackHead(hash, colour2); }
        if(toUint8(hash,27) < 128 || fullSoul == true) { frontHead = generateFrontHead(hash, colour3); }
        if(toUint8(hash,28) < 128 || fullSoul == true) { rings = generateRings(hash);}
        if(toUint8(hash,29) < 128 || fullSoul == true) { eyes = generateEyes(hash); }

        return string(
            abi.encodePacked(
                '<svg width="600" height="600" viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg">',
                '<rect x="0" y="0" width="600" height="600" fill="white" />',
                background,
                innerFrame,
                backSplash,
                body,
                backHead,
                frontHead,
                rings,
                eyes,
                '</svg>'
            )
        );
    }

    function generateColours(bytes memory hash) public pure returns (uint, uint, uint) {
        uint colour1 = uint256(toUint8(hash,1))*360/255; 
        uint colourCompositionByte = toUint8(hash,2);
        uint colour2;
        uint colour3;
        string memory compositionType = getColourCompositionType(colourCompositionByte);

        if(keccak256(bytes(compositionType)) == keccak256(bytes('Split Composition'))) {
            //split composition
            colour2 = (colour1+150) % 360;
            colour3 = (colour1+210) % 360;
        } else if(keccak256(bytes(compositionType)) == keccak256(bytes('Triad Composition'))) {
            // triad composition
            colour2 = (colour1+120) % 360;
            colour3 = (colour1+240) % 360;
        } else {
            // analogous composition
            colour2 = (colour1+30) % 360;
            colour3 = (colour1+90) % 360;
        }

        return (colour1, colour2, colour3);
    }

    function getColourCompositionType(uint compositionByte) public pure returns (string memory) {
        if(compositionByte >= 0 && compositionByte < 85) {
            return 'Split Composition';
        } else if(compositionByte >=85 && compositionByte < 170) {
            return 'Triad Composition';
        } else {
            return 'Analogous Composition';
        }
    }

    /* GENERATION FUNCTIONS (in order of layers) */

    // Layer 1 - Background.
    // Hash Bytes Used - 3,4,5
    function generateBackground(bytes memory hash, uint colour1) public pure returns (string memory) {
        uint backgroundFrequency = uint256(toUint8(hash,3))*1000/255; 
        uint backgroundSurfaceScale = uint256(toUint8(hash,4))*10/255;
        uint elevation = 50 + uint256(toUint8(hash,5))*90/255; 
        uint saturation = 60 - uint256(toUint8(hash,30))*55/255;
        return string(abi.encodePacked(
            svgFilter("backgroundDisplacement"),
            svgFeTurbulence("100",generateDecimalString(backgroundFrequency,2)),
            '<feMorphology in="turbulence" result="morphed" operator="erode" radius="1"></feMorphology>',
            '<feDiffuseLighting in="morphed" lighting-color="hsl(',toString(colour1),', ',toString(saturation),'%, 50%)" surfaceScale="',toString(backgroundSurfaceScale),'"><feDistantLight azimuth="45" elevation="',toString(elevation),'" /></feDiffuseLighting>',
            '</filter><rect x="0" y="0" width="600" height="600" style="filter: url(#backgroundDisplacement)" />'
        ));
    }

    // Layer 2 - Inner Frame
    // Hash Bytes Used - 6,7
    function generateInnerFrame(bytes memory hash) public pure returns (string memory) {
        uint frameFrequency = uint256(toUint8(hash,6))*1000/255; 
        uint frameSeed = uint256(toUint8(hash,6))*1000/255; // added in post. more variation.
        uint frameStrokeWidth = uint256(toUint8(hash,7))*40/255;

        return string(abi.encodePacked(
            svgFilter("frameDisplacement"),
            svgFeTurbulence(toString(frameSeed),generateDecimalString(frameFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="50" xChannelSelector="G" yChannelSelector="A"/></filter>',
            '<rect x="50" y="50" width="500" height="500" stroke="black" opacity="0.5" fill="white" stroke-width="',toString(frameStrokeWidth),'" style="filter: url(#frameDisplacement)"/>'
        ));
    }

    // Layer 3 - Back Splash
    // Hash Bytes Used - 8,9
    function generateBackSplash(bytes memory hash) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint backSplashFrequency = uint256(toUint8(hash,8))*1000/255; 
        uint backStrokeWidth = uint256(toUint8(hash,9))*40/255;

        return string(abi.encodePacked(
            '<defs>',
            '<linearGradient id="backSplashGrad" x2="0%" y2="100%">',
            '<stop offset="0%" stop-color="black" />',
            '<stop offset="50%" stop-color="white" />',
            '</linearGradient>',
            '</defs>',
            svgFilter("backSplash"),
            svgFeTurbulence("2000",generateDecimalString(backSplashFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="200" xChannelSelector="G" yChannelSelector="A"/></filter>',
            svgCircle("300","270",toString(170-radii),"url(#backSplashGrad)",toString(backStrokeWidth),"none", "filter: url(#backSplash)")
        ));
    }

    // Layer 4 - Body
    // Hash Bytes Used - 10
    function generateBody(bytes memory hash) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint bodyFrequency = uint256(toUint8(hash,10))*1000/255;  

        return string(abi.encodePacked(
            svgFilter("bodyDisplacement"),
            svgFeTurbulence("100",generateDecimalString(bodyFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="50" xChannelSelector="R" yChannelSelector="G"/> </filter>',
            svgCircle("300",toString(700-radii),toString(180-radii),"black","0","black","filter: url(#bodyDisplacement)")
        ));
    }

    // Layer 5 - Back Head
    // Hash Bytes Used - 11,12
    function generateBackHead(bytes memory hash, uint colour2) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint backHeadFrequency = uint256(toUint8(hash,11))*1000/255; 
        uint backHeadScale = uint256(toUint8(hash,12))*400/255;
        uint saturation = 60 - uint256(toUint8(hash,30))*55/255;

        string memory fill = string(abi.encodePacked('hsl(',toString(colour2),', ',toString(saturation),'%, 50%)'));

        return string(abi.encodePacked(
            svgFilter("headDisplacement"), 
            svgFeTurbulence("100",generateDecimalString(backHeadFrequency,3)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="',toString(backHeadScale),'" xChannelSelector="G" yChannelSelector="A"/> </filter>',
            svgCircle("300","270",toString(140-radii), "none", "0", fill, "filter: url(#headDisplacement)")
        ));
    }

    // Layer 6 - Front Head
    // Hash Bytes Used - 13,14
    function generateFrontHead(bytes memory hash, uint colour3) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint frontHeadFrequency = uint256(toUint8(hash,13))*1000/255; 
        uint frontHeadFrequency2 = uint256(toUint8(hash,14))*1000/255; // added in post. more variation.
        uint frontHeadScale = uint256(toUint8(hash,14))*400/255;
        uint saturation = 60 - uint256(toUint8(hash,30))*55/255;

        string memory fill = string(abi.encodePacked('hsl(',toString(colour3),', ',toString(saturation),'%, 50%)'));
        
        return string(abi.encodePacked(
            svgFilter("headDisplacement2"), 
            '<feTurbulence type="turbulence" seed="50" baseFrequency="',generateDecimalString(frontHeadFrequency,3),',',generateDecimalString(frontHeadFrequency2,3),'" numOctaves="5" result="turbulence"/>'
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="',toString(frontHeadScale),'" xChannelSelector="G" yChannelSelector="R"/> </filter>',
            svgCircle("300","270",toString(120-radii), "none", "0", fill, "filter: url(#headDisplacement2)")
        ));
    }

    // Layer 7 - Rings
    // Hash Bytes Used - 15,16,17,18,19,20
    function generateRings(bytes memory hash) public pure returns (string memory) {
        string memory ring1 = generateRing(hash, "ringDisplacement1", 15, 16, "grey", "R", "filter: url(#ringDisplacement1)");        
        string memory ring2 = generateRing(hash, "ringDisplacement2", 17, 18, "black", "G", "filter: url(#ringDisplacement2)");        
        string memory ring3 = generateRing(hash, "ringDisplacement3", 19, 20, "black", "B", "filter: url(#ringDisplacement3)");        

        return string(abi.encodePacked(ring1, ring2, ring3));
    }

    function generateRing(bytes memory hash, string memory id, uint seedIndex1, uint seedIndex2, string memory stroke, string memory xChannel, string memory style) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint ringSeed = uint256(toUint8(hash,seedIndex1))*1000/255;
        uint ringFrequency = uint256(toUint8(hash,seedIndex2))*1000/255;  

        return string(abi.encodePacked(
            svgFilter(id), 
            svgFeTurbulence(toString(ringSeed), generateDecimalString(ringFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="200" xChannelSelector="',xChannel,'" yChannelSelector="A" /> </filter>',
            svgCircle("300","270",toString(140-radii),stroke,"4","none",style)
        ));
    }

    // Layer 8 - Eyes
    // Hash Bytes Used - 21
    function generateEyes(bytes memory hash) public pure returns (string memory) {
        uint eyesFrequency = uint256(toUint8(hash,21))*1000/255; 
        uint eyesRadius = 25 - uint256(toUint8(hash,21))*15/255; 

        string memory eyeDisplacement = string(abi.encodePacked(
            svgFilter("eyeDisplacement"),
            svgFeTurbulence("100", generateDecimalString(eyesFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="100" xChannelSelector="R" yChannelSelector="G"/></filter>'
        ));

        string memory eyes = string(abi.encodePacked(
            svgCircle("250","270",toString(eyesRadius),"black","1","white","filter: url(#eyeDisplacement)"),
            svgCircle("320","270",toString(eyesRadius),"black","1","white","filter: url(#eyeDisplacement)")
        ));

        return string(abi.encodePacked(eyeDisplacement,eyes));
    }

    function svgCircle(string memory cx, string memory cy, string memory r, string memory stroke, string memory strokeWidth, string memory fill, string memory style) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<circle cx="',cx,'" cy="',cy,'" r="',r,'" stroke="',stroke,'" fill="',fill,'" stroke-width="',strokeWidth,'" style="',style,'"/>'
        ));
    }

    function svgFilter(string memory id) public pure returns (string memory) {
        return string(abi.encodePacked('<filter id="',id,'" width="300%" height="300%">'));
    }

    function svgFeTurbulence(string memory seed, string memory baseFrequency) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<feTurbulence type="turbulence" seed="',seed,'" baseFrequency="',baseFrequency,'" numOctaves="5" result="turbulence"/>'
        ));
    }

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol 
    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

        // from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function generateDecimalString(uint nr, uint decimals) public pure returns (string memory) {
        if(decimals == 1) { return string(abi.encodePacked('0.',toString(nr))); }
        if(decimals == 2) { return string(abi.encodePacked('0.0',toString(nr))); }
        if(decimals == 3) { return string(abi.encodePacked('0.00',toString(nr))); }
        if(decimals == 4) { return string(abi.encodePacked('0.000',toString(nr))); }
    }

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}