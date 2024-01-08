// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./DynaModel.sol";
import "./StringUtils.sol";

library DynaTraits {

    function getTraits(bool descTraitsEnabled, DynaModel.DynaParams memory dynaParams) internal pure returns (string memory) {

        string memory zoomTraits = string(abi.encodePacked("{\"trait_type\": \"zoom\", \"value\": \"", StringUtils.smallUintToString(dynaParams.zoom), "\"}")); 
        string memory tintColour = string(abi.encodePacked(StringUtils.smallUintToString(dynaParams.tintRed), " ", StringUtils.smallUintToString(dynaParams.tintGreen), " ", StringUtils.smallUintToString(dynaParams.tintBlue), " ", StringUtils.smallUintToString(dynaParams.tintAlpha))); 
        string memory tintTraits = string(abi.encodePacked("{\"trait_type\": \"tint colour\", \"value\": \"", tintColour, "\"}")); 
        string memory rotationTraits = string(abi.encodePacked("{\"trait_type\": \"rotation min\", \"value\": \"", StringUtils.smallUintToString(dynaParams.rotationMin), "\"}, {\"trait_type\": \"rotation max\", \"value\": \"", StringUtils.smallUintToString(dynaParams.rotationMax), "\"}")); 
        string memory widthTraits = string(abi.encodePacked("{\"trait_type\": \"stripe width min\", \"value\": \"", StringUtils.smallUintToString(dynaParams.stripeWidthMin), "\"}, {\"trait_type\": \"stripe width max\", \"value\": \"", StringUtils.smallUintToString(dynaParams.stripeWidthMax), "\"}"));
        string memory speedTraits = string(abi.encodePacked("{\"trait_type\": \"speed min\", \"value\": \"", StringUtils.smallUintToString(dynaParams.speedMin), "\"}, {\"trait_type\": \"speed max\", \"value\": \"", StringUtils.smallUintToString(dynaParams.speedMax), "\"}"));

        if (descTraitsEnabled) {
            string memory descriptiveTraits = getDescriptiveTraits(dynaParams);            
            return string(abi.encodePacked("\"attributes\": [", descriptiveTraits, zoomTraits, ", ", tintTraits, ", ", rotationTraits, ", ", widthTraits, ", ", speedTraits, "]"));
        } else {
            return string(abi.encodePacked("\"attributes\": [", zoomTraits, ", ", tintTraits, ", ", rotationTraits, ", ", widthTraits, ", ", speedTraits, "]"));
        }
    }

    function getDescriptiveTraits(DynaModel.DynaParams memory dynaParams) internal pure returns (string memory) {
        string memory form;

        if (dynaParams.rotationMin == dynaParams.rotationMax) {
            if (dynaParams.zoom > 50 && dynaParams.rotationMax % 90 == 0) {
                form = "perfect square";
            } else if ((dynaParams.rotationMax == 45 || dynaParams.rotationMax == 135) && dynaParams.zoom > 91) {
                form = "perfect diamond";
            } else if (dynaParams.zoom <= 50 && dynaParams.rotationMax == 90) {
                form = "horizontal stripes";
            } else if (dynaParams.zoom <= 50 && dynaParams.rotationMax % 180 == 0) {
                form = "vertical stripes";
            } else if (dynaParams.zoom <= 25) {
                form = "diagonal stripes";
            } else {
                form = "rotated square";
            }
        } else if (dynaParams.rotationMax - dynaParams.rotationMin < 30 && dynaParams.stripeWidthMin > 200 && dynaParams.zoom < 20) {
            form = "big fat stripes";
        } else if (dynaParams.stripeWidthMax < 60 && dynaParams.rotationMax - dynaParams.rotationMin < 30) {
            form = "match sticks";
        } else if (dynaParams.stripeWidthMax < 60 && dynaParams.rotationMax - dynaParams.rotationMin > 130 && dynaParams.zoom < 30) {
            form = "laser beams";
        } else if (dynaParams.stripeWidthMax < 60 && dynaParams.rotationMax - dynaParams.rotationMin > 130 && dynaParams.zoom > 80) {
            form = "birds nest";
        } else if (dynaParams.zoom > 60 && dynaParams.stripeWidthMin > 180 && dynaParams.rotationMax - dynaParams.rotationMin < 30 && dynaParams.rotationMax - dynaParams.rotationMin > 5 && (dynaParams.rotationMin > 160 || dynaParams.rotationMax < 30)) {
            form = "cluttered books";
        } else if (dynaParams.stripeWidthMin > 180 && dynaParams.rotationMax - dynaParams.rotationMin <= 30 && dynaParams.rotationMin > 75 && dynaParams.rotationMax < 105) {
            form = "stacked books";
        } else if (dynaParams.stripeWidthMin > 50 && dynaParams.stripeWidthMax < 150 && dynaParams.rotationMax - dynaParams.rotationMin < 50 && dynaParams.rotationMin > 35 &&  dynaParams.rotationMax < 145 && dynaParams.zoom > 55) {
            form = "broken ladder";
        } else if (dynaParams.stripeWidthMin > 200 && dynaParams.zoom > 70) {
            form = "giant pillars";
        } else if (dynaParams.stripeWidthMin > 70 && dynaParams.zoom < 20 && dynaParams.rotationMax - dynaParams.rotationMin < 60 && dynaParams.rotationMax - dynaParams.rotationMin > 10) {
            form = "ribbons";
        } else if (dynaParams.stripeWidthMax < 75 && dynaParams.zoom < 20 && dynaParams.rotationMax - dynaParams.rotationMin < 60 && dynaParams.rotationMax - dynaParams.rotationMin > 10) {
            form = "streamers";
        } else if (dynaParams.stripeWidthMin > 25 && dynaParams.stripeWidthMax < 200 && dynaParams.rotationMax - dynaParams.rotationMin < 15) {
            form = "jittery";
        } else if (dynaParams.stripeWidthMax < 40) {
            form = "twiglets";
        } else if (dynaParams.rotationMax - dynaParams.rotationMin < 60 && dynaParams.rotationMin >= 50 && dynaParams.rotationMax <= 130 && dynaParams.stripeWidthMax - dynaParams.stripeWidthMin >= 150) {
            form = "collapsing";
        } else if (dynaParams.stripeWidthMin > 200 && dynaParams.zoom > 50) {
            form = "blocky";
        } else if (dynaParams.rotationMax - dynaParams.rotationMin > 100 && dynaParams.stripeWidthMax < 150) {
            form = "wild";
        } else if (dynaParams.rotationMax - dynaParams.rotationMin < 100 && dynaParams.stripeWidthMin > 150) {
            form = "tame";
        } else if (dynaParams.stripeWidthMin > 150) {
            form = "thick";
        } else if (dynaParams.stripeWidthMax < 100) {
            form = "thin";
        } else {
            form = "randomish";
        }

        string memory colourWay; 

        if (dynaParams.tintAlpha > 127) {
            uint difference = 150;
            if (dynaParams.tintAlpha > 200 && dynaParams.tintRed < 50 && dynaParams.tintGreen < 50 && dynaParams.tintBlue < 50) {
                colourWay = "doom and gloom";
            } else if (dynaParams.tintAlpha > 200 && dynaParams.tintRed > 200 && dynaParams.tintGreen > 200 && dynaParams.tintBlue > 200) {
                colourWay = "seen a ghost";
            } else if (dynaParams.tintRed > dynaParams.tintGreen && dynaParams.tintRed - dynaParams.tintGreen >= difference && dynaParams.tintRed > dynaParams.tintBlue && dynaParams.tintRed - dynaParams.tintBlue >= difference) {
                colourWay = "reds";
            } else if (dynaParams.tintGreen > dynaParams.tintRed && dynaParams.tintGreen - dynaParams.tintRed >= difference && dynaParams.tintGreen > dynaParams.tintBlue && dynaParams.tintGreen - dynaParams.tintBlue >= difference) {
                colourWay = "greens";
            } else if (dynaParams.tintBlue > dynaParams.tintRed && dynaParams.tintBlue - dynaParams.tintRed >= difference && dynaParams.tintBlue > dynaParams.tintGreen && dynaParams.tintBlue - dynaParams.tintGreen >= difference) {
                colourWay = "blues";
            } else if (dynaParams.tintRed > dynaParams.tintGreen && dynaParams.tintRed - dynaParams.tintGreen >= difference && dynaParams.tintBlue > dynaParams.tintGreen && dynaParams.tintBlue - dynaParams.tintGreen >= difference) {
                colourWay = "violets";
            } else if (dynaParams.tintRed > dynaParams.tintBlue && dynaParams.tintRed - dynaParams.tintBlue >= difference && dynaParams.tintGreen > dynaParams.tintBlue && dynaParams.tintGreen - dynaParams.tintBlue >= difference) {
                colourWay = "yellows";
            } else if (dynaParams.tintBlue > dynaParams.tintRed && dynaParams.tintBlue - dynaParams.tintRed >= difference && dynaParams.tintGreen > dynaParams.tintRed && dynaParams.tintGreen - dynaParams.tintRed >= difference) {
                colourWay = "cyans";
            } else {
                colourWay = "heavy tint";
            }
        } else if (dynaParams.tintAlpha == 0) {
            colourWay = "super dynamic";
        } else if (dynaParams.tintAlpha < 60) {
            colourWay = "light tint";
        } else {
            colourWay = "medium tint";
        }

        string memory speed;

        if (dynaParams.speedMax <= 25 && dynaParams.tintAlpha < 180) {
            speed = "call the police";
        } else if (dynaParams.speedMin == dynaParams.speedMax && dynaParams.speedMax < 30) {
            speed = "blinking";
        } else if (dynaParams.speedMin == dynaParams.speedMax && dynaParams.speedMax > 200) {
            speed = "slow pulse";
        } else if (dynaParams.speedMin == dynaParams.speedMax) {
            speed = "pulse";        
        } else if (dynaParams.speedMax < 50) {
            speed = "flickering";
        } else if (dynaParams.speedMax < 100) {
            speed = "zippy";
        } else if (dynaParams.speedMin > 200) {
            speed = "pedestrian";
        } else if (dynaParams.speedMin > 150) {
            speed = "sleepy";
        } else {
            speed = "shifting";
        }
        
        string memory descriptiveTraits;

        if (bytes(form).length != 0) {
            string memory formTrait = string(abi.encodePacked("{\"trait_type\": \"form\", \"value\": \"", form, "\"}")); 
            descriptiveTraits = string(abi.encodePacked(formTrait, ", ")); 
        }
        if (bytes(speed).length != 0) {
            string memory speedStringTrait = string(abi.encodePacked("{\"trait_type\": \"speed\", \"value\": \"", speed, "\"}")); 
            descriptiveTraits = string(abi.encodePacked(descriptiveTraits, speedStringTrait, ", ")); 
        }
        if (bytes(colourWay).length != 0) {
            string memory colourWayTrait = string(abi.encodePacked("{\"trait_type\": \"colour way\", \"value\": \"", colourWay, "\"}")); 
            descriptiveTraits = string(abi.encodePacked(descriptiveTraits, colourWayTrait, ", ")); 
        }

        return descriptiveTraits;
    }
}