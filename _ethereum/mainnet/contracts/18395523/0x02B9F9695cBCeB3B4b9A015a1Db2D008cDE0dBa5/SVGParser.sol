pragma solidity ^0.8.0;

contract SVGParser {

    string colorA = "#006000";
    string colorB = "#EF4F24";

    string[6] darkColors;
    string[6] lightColors;

    constructor() {
        darkColors = [ "#060000","#600000","#006000","#000060","#F2BF00","#768F88"];    
        lightColors = ["#EF4F24","#EF4F24","#EF4F24","#EFBB00","#060000","#00402E"];    
    }

    function randColor(uint _seed, uint _bright) public view returns (string memory) {
        uint256 index = _seed % 6;
        return _bright == 0 ? darkColors[index] : lightColors[index];
    }

    function generateSVG(uint8[5][5] memory numbers) public view returns (string memory) {
        string memory svgHeader1 = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 220 240" style="enable-background:new 0 0 220 240;" xml:space="preserve"><style type="text/css">';
        string memory svgHeader2 = string(abi.encodePacked('.st0{fill:',randColor(numbers[0][0],0),';}.st1{fill:#F8F8F8;stroke:#000000;stroke-width:2;}.st2{font-family: \'Arial Black\', \'Helvetica Neue\', sans-serif; font-size: 20px;}.st3{fill:',randColor(numbers[0][0],1),';}.st4{font-family: \'Arial Black\', \'Helvetica Neue\', sans-serif; font-weight: 900; font-size: 24px;fill:',randColor(numbers[0][0],1),';}</style><rect class="st0" width="220" height="240" rx="5"/><text x="30" y="15" text-anchor="middle" dominant-baseline="central" class="st4">B</text><rect x="40" y="0" class="st0" width="40" height="40"/><text x="70" y="15" text-anchor="middle" dominant-baseline="central" class="st4">I</text><rect x="80" y="0" class="st0" width="40" height="40"/><text x="110" y="15" text-anchor="middle" dominant-baseline="central" class="st4">N</text><rect x="120" y="0" class="st0" width="40" height="40"/><text x="150" y="15" text-anchor="middle" dominant-baseline="central" class="st4">G</text><rect x="160" y="0" class="st0" width="40" height="40"/><text x="190" y="15" text-anchor="middle" dominant-baseline="central" class="st4">O</text>'));
        
        string memory svgBody = "";
        uint8[5] memory rowHeaders = [30, 70, 110, 150, 190];
        uint8[5] memory columnHeaders = [10, 50, 90, 130, 170];
        
        uint8 index = 0;
    for (uint8 i = 0; i < 5; i++) {
        for (uint8 j = 0; j < 5; j++) {
            if (i != 2 || j != 2) {
                string memory rect = string(abi.encodePacked(
                    '\n<rect x="',
                    uintToString(columnHeaders[j]),
                    '" y="',
                    uintToString(rowHeaders[i]),
                    '" class="st1" width="40" height="40"/>',
                    '<text x="',
                    uintToString(columnHeaders[j] + 20),
                    '" y="',
                    uintToString(rowHeaders[i] + 20),
                    '" text-anchor="middle" dominant-baseline="central" class="st2">',
                    uintToString(numbers[i][j]), // swapped i and j
                    '</text>'
                ));
                svgBody = string(abi.encodePacked(svgBody, rect));
                index++;
            }
        }
    }


        string memory svgFooter = '<polygon class="st3" points="110,116 113,126 124,126 116,133 118,143 110,137 101,143 103,133 95,126 106,126 "/></svg>';
        return string(abi.encodePacked(svgHeader1, svgHeader2, svgBody, svgFooter));
    }

    function uintToString(uint8 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint8 digits = 0;
        uint8 temp = value;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}