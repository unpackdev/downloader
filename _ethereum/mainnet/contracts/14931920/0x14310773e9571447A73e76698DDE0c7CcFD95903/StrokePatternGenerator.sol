// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * 
 * A custom library for the project Auto Strokes.
 *                          
 *                             𝔟𝔶 🅐🅙🅡🅔🅩🅘🅐
 *
 */
 
import "./Strings.sol";

library StrokePatternGenerator {

    function getNumberOfStrokesToPrint(uint8 variationIndicator) public pure returns (uint8) { 
        if (variationIndicator == 1 || variationIndicator == 6 ||variationIndicator == 11 ||variationIndicator == 16 ||variationIndicator == 21 ||variationIndicator == 26 || variationIndicator == 31) {
            return 30;
            }
        else if (variationIndicator == 2|| variationIndicator == 7 ||variationIndicator == 12 ||variationIndicator == 17 ||variationIndicator == 22 ||variationIndicator == 27 ||variationIndicator == 32) {
            return 60;
            }
        else if (variationIndicator == 3|| variationIndicator == 8 ||variationIndicator == 13 ||variationIndicator == 18 ||variationIndicator == 23 ||variationIndicator == 28 ||variationIndicator == 33) {
            return 90;
            }
        else if (variationIndicator == 4|| variationIndicator == 9 ||variationIndicator == 14 ||variationIndicator == 19 ||variationIndicator == 24 ||variationIndicator == 29 ||variationIndicator == 34) {
            return 120;
            }    
        return 150;
    }

    function getStrokeOriginParameters(uint8 variationIndicator, uint256 tokenId, string memory secretSeed) public view returns (string memory, string memory, string memory, string memory, string memory) { 
        string memory x;
        string memory y;
        uint256 xInt;
        uint256 yInt;

        if (variationIndicator == 1 || variationIndicator == 2 ||variationIndicator == 3 ||variationIndicator == 4 ||variationIndicator == 5) {
            x = Strings.toString(getOriginOrdinate(tokenId, 1, secretSeed));
            return (x, x, getOriginIndLineTag('0', '0', '350', '350'),'Major Diagonal', 'Strokes originates on major diagonal. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }
        else if (variationIndicator == 6 ||variationIndicator == 7 ||variationIndicator == 8 || variationIndicator == 9 || variationIndicator == 10) {
           xInt = getOriginOrdinate(tokenId, 2, secretSeed);
           yInt = 350 - xInt;
           return (Strings.toString(xInt), Strings.toString(yInt), getOriginIndLineTag('350', '0', '0', '350'),'Minor Diagonal','Strokes originates on minor diagonal. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }
        else if (variationIndicator == 11|| variationIndicator == 12 ||variationIndicator == 13 ||variationIndicator == 14 ||variationIndicator == 15) {
            y = Strings.toString(getOriginOrdinate(tokenId, 3, secretSeed));
            return ('175', y, getOriginIndLineTag('175', '0', '175', '350'),'Vertical', 'Strokes originates on a vertical line. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }
        else if (variationIndicator == 16|| variationIndicator == 17 ||variationIndicator == 18 ||variationIndicator == 19 ||variationIndicator == 20) {
            x = Strings.toString(getOriginOrdinate(tokenId, 4, secretSeed));
            return (x, '175', getOriginIndLineTag('0', '175', '350', '175'),'Horizontal', 'Strokes originates on a horizontal line. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }
        else if (variationIndicator == 21|| variationIndicator == 22 ||variationIndicator == 23 || variationIndicator == 24 || variationIndicator == 25) {

           uint256 decision =  getDecisionFactor(tokenId, 5, secretSeed);

            if(decision == 1) {
              yInt =  getYOrdinateRect(tokenId, 6, secretSeed);
              y = Strings.toString(yInt);


              if(yInt == 50 || yInt == 300) {
                   x = Strings.toString(getXOrdinateRect(tokenId, 7, secretSeed));
                }
                else {
                   xInt = getDecisionFactor(tokenId, 8, secretSeed);
                   if (xInt == 1) {
                       x = '40';
                   }
                   else {
                       x = '310';
                   }
                }
            }
            else {
            xInt = getXOrdinateRect(tokenId, 6, secretSeed);
            x = Strings.toString(xInt);

                if(xInt == 40 || xInt == 310) {
                    y = Strings.toString(getYOrdinateRect(tokenId, 7, secretSeed));
                }
                else {
                   yInt = getDecisionFactor(tokenId,8, secretSeed);
                   if (yInt == 1) {
                       y = '50';
                   }
                   else {
                       y = '300';
                   }
                }
            }
            return (x, y, getRectOriginIndLineTag(),'Rectangle','Strokes originates on a rectangle. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');    
            }
        else if (variationIndicator == 26|| variationIndicator == 27 ||variationIndicator == 28 || variationIndicator == 29 || variationIndicator == 30) {
            return ('175', '175', '','Center','Strokes originates at the center. Refresh the metadata and observe the change of stroke pattern and color.');    
            }    
         else {
            x = Strings.toString(getOriginOrdinate(tokenId, 9, secretSeed));
            y = Strings.toString(getOriginOrdinate(tokenId, 10, secretSeed));
            return (x, y, '','Anywhere', 'Strokes can originate anywhere on the viewbox. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }            
    }

    function getOriginBehaviour(uint8 variationIndicator) public pure returns (string memory) { 
         if (variationIndicator == 26|| variationIndicator == 27 ||variationIndicator == 28 || variationIndicator == 29 || variationIndicator == 30) {
            return "Fixed";
         }
         else {
             return "Varying";
         }
    }

    function getStrokePattern(string memory code, string memory xOrdinate, string memory yOrdinate, uint8 occurence, string memory secretSeed) public view returns (string memory) {
        string[65] memory stroke;
        stroke[0] = '<line x1="';
        stroke[1] = xOrdinate;
        stroke[2] = '" y1="';
        stroke[3] = yOrdinate;
        stroke[4] ='" x2="';
        stroke[5] =  Strings.toString(getToOrdinate(1, occurence, secretSeed));
        stroke[6] = '" y2="';
        stroke[7] =  Strings.toString(getToOrdinate(2, occurence, secretSeed));
        stroke[8] = '" style="stroke:#';
        stroke[9] = getStrokeColorCode(code, 2, 8);

        stroke[10] = getStrokeCommonTag(xOrdinate, yOrdinate);
        stroke[11] =  Strings.toString(getToOrdinate(3, occurence, secretSeed));
        stroke[12] = '" y2="';
        stroke[13] =  Strings.toString(getToOrdinate(4, occurence, secretSeed));
        stroke[14] = '" style="stroke:#';
        stroke[15] = getStrokeColorCode(code, 8, 14);

        stroke[16] =  stroke[10];
        stroke[17] =  Strings.toString(getToOrdinate(5, occurence, secretSeed));
        stroke[18] = '" y2="';
        stroke[19] =  Strings.toString(getToOrdinate(6, occurence, secretSeed));
        stroke[20] = '" style="stroke:#';
        stroke[21] = getStrokeColorCode(code, 14, 20);

        stroke[22] =  stroke[10];
        stroke[23] =  Strings.toString(getToOrdinate(7, occurence, secretSeed));
        stroke[24] = '" y2="';
        stroke[25] =  Strings.toString(getToOrdinate(8, occurence, secretSeed));
        stroke[26] = '" style="stroke:#';
        stroke[27] = getStrokeColorCode(code, 20, 26);

        stroke[28] =  stroke[10];
        stroke[29] =  Strings.toString(getToOrdinate(9, occurence, secretSeed));
        stroke[30] = '" y2="';
        stroke[31] =  Strings.toString(getToOrdinate(10, occurence, secretSeed));
        stroke[32] = '" style="stroke:#';
        stroke[33] = getStrokeColorCode(code, 26, 32);        

        stroke[34] =  stroke[10];
        stroke[35] =  Strings.toString(getToOrdinate(11, occurence, secretSeed));
        stroke[36] = '" y2="';
        stroke[37] =  Strings.toString(getToOrdinate(12, occurence, secretSeed));
        stroke[38] = '" style="stroke:#';
        stroke[39] = getStrokeColorCode(code, 32, 38);    

        stroke[40] =  stroke[10];
        stroke[41] =  Strings.toString(getToOrdinate(13, occurence, secretSeed));
        stroke[42] = '" y2="';
        stroke[43] =  Strings.toString(getToOrdinate(14, occurence, secretSeed));
        stroke[44] = '" style="stroke:#';
        stroke[45] = getStrokeColorCode(code, 38, 44);     

        stroke[46] =  stroke[10];
        stroke[47] =  Strings.toString(getToOrdinate(15, occurence, secretSeed));
        stroke[48] = '" y2="';
        stroke[49] =  Strings.toString(getToOrdinate(16, occurence, secretSeed));
        stroke[50] = '" style="stroke:#';
        stroke[51] = getStrokeColorCode(code, 44, 50);            
             
        stroke[52] = stroke[10];
        stroke[53] =  Strings.toString(getToOrdinate(17, occurence, secretSeed));
        stroke[54] = '" y2="';
        stroke[55] =  Strings.toString(getToOrdinate(18, occurence, secretSeed));
        stroke[56] = '" style="stroke:#';
        stroke[57] = getStrokeColorCode(code, 50, 56);                

        stroke[58] = stroke[10];
        stroke[59] =  Strings.toString(getToOrdinate(19, occurence, secretSeed));
        stroke[60] = '" y2="';
        stroke[61] =  Strings.toString(getToOrdinate(20, occurence, secretSeed));
        stroke[62] = '" style="stroke:#';
        stroke[63] = getStrokeColorCode(code, 56, 62);  
        stroke[64] = '"/>';

        string memory output = string(abi.encodePacked(stroke[0], stroke[1], stroke[2], stroke[3], stroke[4], stroke[5], stroke[6], stroke[7], stroke[8], stroke[9], stroke[10]));
        output = string(abi.encodePacked(output, stroke[11], stroke[12], stroke[13], stroke[14], stroke[15], stroke[16], stroke[17], stroke[18], stroke[19], stroke[20]));
        output = string(abi.encodePacked(output, stroke[21], stroke[22], stroke[23], stroke[24], stroke[25], stroke[26], stroke[27], stroke[28], stroke[29], stroke[30]));
        output = string(abi.encodePacked(output, stroke[31], stroke[32], stroke[33], stroke[34], stroke[35], stroke[36], stroke[37], stroke[38], stroke[39], stroke[40]));
        output = string(abi.encodePacked(output, stroke[41], stroke[42], stroke[43], stroke[44], stroke[45], stroke[46], stroke[47], stroke[48], stroke[49], stroke[50]));
        output = string(abi.encodePacked(output, stroke[51], stroke[52], stroke[53], stroke[54], stroke[55], stroke[56], stroke[57], stroke[58], stroke[59], stroke[60]));
        output = string(abi.encodePacked(output, stroke[61], stroke[62], stroke[63], stroke[64]));

        return output;
    }

    function getStrokeCommonTag(string memory xOrdinate, string memory yOrdinate) internal pure returns (string memory) {
        string[5] memory common;
        common[0] = '"/><line x1="';
        common[1] = xOrdinate;
        common[2] = '" y1="';
        common[3] = yOrdinate;
        common[4] ='" x2="';
        return string(abi.encodePacked(common[0], common[1], common[2], common[3], common[4]));
    }

    function getOriginIndLineTag(string memory x1, string memory y1, string memory x2, string memory y2) internal pure returns (string memory) {
        string[20] memory originIndLine;
        originIndLine[0] = '<line stroke-dasharray="3,10" x1="';
        originIndLine[1] = x1;
        originIndLine[2] = '" y1="';
        originIndLine[3] = y1;
        originIndLine[4] = '" x2="';
        originIndLine[5] = x2;
        originIndLine[6] = '" y2="';
        originIndLine[7] = y2;
        originIndLine[8] = '" opacity="0.05" style="stroke:white"/>';
        return string(abi.encodePacked(originIndLine[0], originIndLine[1], originIndLine[2], originIndLine[3], originIndLine[4], originIndLine[5], originIndLine[6], originIndLine[7], originIndLine[8]));
    }

    function getRectOriginIndLineTag() internal pure returns (string memory){
        return '<line stroke-dasharray="3,10" x1="40" y1="50" x2="310" y2="50" opacity="0.05" style="stroke:white"/><line stroke-dasharray="3,10" x1="40" y1="50" x2="40" y2="300" opacity="0.05" style="stroke:white"/><line stroke-dasharray="3,10" x1="310" y1="50" x2="310" y2="300" opacity="0.05" style="stroke:white"/><line stroke-dasharray="3,10" x1="40" y1="300" x2="310" y2="300" opacity="0.05" style="stroke:white"/>';
    }
    
    function getStrokeColorCode(string memory code, uint8 startIndex, uint8 endIndex) internal pure returns(string memory) {
     bytes memory codebytes = bytes(code);
     bytes memory result = new bytes(endIndex-startIndex);
       for(uint256 i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = codebytes[i];
        }return string(result);
    }

    function getToOrdinate(uint8 factor, uint256 occurence, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(factor, occurence, secretSeed, block.timestamp))) % 350;
    }

    function getOriginOrdinate(uint256 tokenId, uint8 factor, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, secretSeed, block.timestamp, block.difficulty))) % 350;
    }

    function getXOrdinateRect(uint256 tokenId, uint8 factor, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, secretSeed, block.timestamp, block.difficulty))) % 271 + 40;
    }

    function getYOrdinateRect(uint256 tokenId, uint8 factor, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, secretSeed, block.timestamp, block.difficulty))) % 251 + 50;
    }

    function getDecisionFactor(uint256 tokenId, uint8 factor, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, secretSeed, block.timestamp, block.difficulty))) % 2 + 1;
    }
}