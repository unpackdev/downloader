// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
Contract that's primarily responsible for generating the metadata, including the image itself in SVG.
Parts of the SVG is encapsulated into custom re-usable components specific to this collection.
*/

/*
Little Martians have the following randomised components.

1) 1 of 10 hardcoded shells.
2) Degree of blur + random seed. 
3) Step pattern with 2 vars + random seed.
4) Background pattern
5) Foreground pattern with colour shifting + alpha slope
*/
contract CollectionDescriptor {

    function generateName(uint nr) public pure returns (string memory) {
        return string(abi.encodePacked('Little Martian #', substring(toString(nr),0,8)));
    }

    function generateTraits(uint256 tokenId) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 index = uint256(toUint8(hash,0))*100/256; // 0 - 100
        string memory ceramicType = '{"trait_type": "Ceramic Shell", "value":';
        string memory ceramicValue = "";

        if(index < 10) { ceramicValue = '"Type One"}'; }
        if(index < 20) { ceramicValue = '"Type Two"}'; }
        if(index < 30) { ceramicValue = '"Type Three"}'; }
        if(index < 40) { ceramicValue = '"Type Four"}'; }
        if(index < 50) { ceramicValue = '"Type Five"}'; }
        if(index < 60) { ceramicValue = '"Type Six"}'; }
        if(index < 70) { ceramicValue = '"Type Seven"}'; }
        if(index < 80) { ceramicValue = '"Type Eight"}'; }
        if(index < 90) { ceramicValue = '"Type Nine"}'; }
        if(index < 100) { ceramicValue = '"Type Ten"}'; }

        return string(abi.encodePacked(
            '"attributes": [',
            ceramicType,
            ceramicValue,
            ']'
        ));
    }

    function generateImage(uint256 tokenId) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 fillI = uint256(toUint8(hash,1));
        string memory fill = 'none';
        if(fillI < 128) { fill = 'white'; }
        return string(
            abi.encodePacked(
                '<svg width="480" height="460" viewBox="0 0 480 460" xmlns="http://www.w3.org/2000/svg">',
                '<style type="text/css">.c{fill:white}</style>',
                '<rect width="480" height="460" fill="black"/>',
                generatePath(hash),
                generateBlur(hash),
                generateSteps(hash),
                generateTurbs1(hash),
                generateTurbs2(hash),
                svgRect("0.7", "blur", fill),
                svgRect("0.5", "steps", 'none'),
                svgRect("1", "turb1", 'none'),
                svgRect("0.7", "turb2", 'none'),
                generateFace(hash),
                '</svg>'
            )
        );
    }

    function generatePath(bytes memory hash) public pure returns (string memory) {
        uint256 index = uint256(toUint8(hash,0))*100/256; // 0 - 100
        string memory path;

        if(index < 10) { path = "M189 49c-23 7-35 24-40 32-12 16-15 31-17 41-6 26 1 29-2 73-1 13-2 21-1 35s4 26 5 33l14 42 11 28 6 12c1 3 5 11 18 27l13 15c14 9 29 6 31 5 9-2 15-7 20-11 10-8 15-17 24-35 6-10 9-16 11-23 6-17 2-20 8-35 6-14 11-13 14-26 2-8 1-11 4-21 3-8 5-9 5-15 0-7-2-8-4-17-2-11 1-13 0-27-2-11-4-12-3-17 2-9 8-11 11-19 4-10 0-21-2-27-2-4-3-6-22-30l-16-18c-4-3-10-9-19-14-3-2-13-7-27-10-8-1-24-4-42 2z"; }
        else if(index < 20) { path = "M240 23c17 3 25 5 35 11 13 8 19 17 29 33a197 197 0 0135 106c2 21 2 31 0 40-3 9-8 16-10 31l-2 14c0 4-3 18-10 31-3 7-9 13-22 27-13 12-17 15-21 24-3 6-2 9-6 15-4 7-8 12-14 17-9 10-11 9-22 19-9 9-8 10-14 14-8 6-17 9-25 10-14 1-25-7-45-23-10-8-40-32-43-57l-1-11-3-29c-3-22-8-23-9-37 0-13 3-13 7-38 4-20 1-21 5-53 3-24 4-20 5-34 1-22-1-32 4-48l8-18c2-3 8-14 20-25 6-5 20-17 41-22 18-5 33-2 58 3z"; }
        else if(index < 30) { path = "M188 21c3-1 43 1 60 4 33 6 70 47 79 65 2 5 17 60 17 81 0 15-4 3-4 44 0 24-6 40-16 61-9 26-7 34-18 60a113 113 0 01-50 63c-12 7-23 14-40 13-18-1-33-17-37-24-21-37-41-65-45-73-3-8-21-33-25-67-1-12 5-37 4-56-1-29-7-39-4-50 8-26 6-16 11-42 4-20 8-52 26-64 15-12 32-14 42-15z"; }
        else if(index < 40) { path = "M71 93v21l1 24c3 22 5 23 9 48l2 13c4 12 13 20 15 23 9 8 21 30 45 74 9 18 13 26 22 36 9 8 16 13 27 20 18 12 45 28 78 32a57 57 0 0049-18c8-9 11-18 16-37 6-21 9-31 6-40-2-6-5-10-6-18l2-18c2-10 6-26 5-42 0-14-5-26-7-33l-10-22c-6-18-2-21-8-32-5-9-8-9-17-22-8-12-9-18-14-25-9-17-23-25-38-33-35-20-69-20-82-19-15 1-36 2-58 16-3 2-35 24-37 52z"; }
        else if(index < 50) { path = "M147 43c6-6 14-14 27-18 15-6 30-4 49-1a129 129 0 0193 52c8 13 15 35 15 57 0 17-6 24-7 52v25c-1 6-2 16-15 54l-10 29c-5 20-11 27-14 39-7 23-14 36-21 43-22 24-47 32-53 34-12 4-23-1-32-5-10-5-9-6-23-23-12-15-13-12-20-23-10-13-11-22-18-49-10-40-16-37-18-59-2-25 8-24 6-55 0-20-1-24 1-44 1-10 3-34 7-53 2-8 15-36 33-55z"; }
        else if(index < 60) { path = "M135 47c-6 10-14 23-22 52-2 11-4 19-5 38-1 11-6 20-10 31-9 29-9 27-11 39-1 8 1 36 4 55l6 29c4 25 3 28 7 41a216 216 0 0027 58c10 15 14 21 28 25 6 2 15 7 26 6 10-1 25-3 42-11 2-2 11-6 24-17 9-8 28-25 43-54 14-26 8-31 24-55 11-18 16-18 19-31 6-18 2-16 6-41 4-16 1-30 1-43 1-13-2-15-2-31 0-29-2-35-5-47-9-34-51-59-81-68-42-14-101-7-121 24z"; }
        else if(index < 70) { path = "M92 75c7-14 15-21 17-23a179 179 0 01104-22c11 1 28 3 49 13 8 4 19 9 31 21 5 3 15 14 24 31l12 33 7 19 11 30c5 17 8 26 8 38 0 14-4 16-10 46-2 14-4 21-4 29-2 26 1 30-1 54-1 6-4 10-8 19-8 17-13 26-21 33-9 7-18 9-27 11-7 1-38 8-62-8-10-6-10-11-26-19l-16-8s-13-6-24-15c-6-4-18-16-39-71l-15-45c-11-29-15-36-17-52v-42c1-47 0-58 7-72z"; }
        else if(index < 80) { path = "M174 35c-8 8-7 13-22 30-11 13-15 14-19 22-6 13-2 18-8 33l-15 24c-20 29-22 33-24 39l-5 29c-2 17-1 20-2 41l-5 45-2 35c1 13 2 39 21 58 8 9 17 13 22 15 15 6 28 6 36 6 18 0 30-4 44-9 16-5 25-8 35-16s10-12 25-33c13-16 20-26 31-36 18-17 25-15 39-32 9-10 14-20 17-25 6-14 8-23 14-43 12-43 13-38 15-48 3-30-9-54-17-69-5-11-20-39-51-59-9-6-35-23-71-23-16 0-41 0-58 16z"; }
        else if(index < 90) { path = "M223 17c-11 0-42 2-72 23-36 25-63 73-57 111 1 8 5 22 2 42-3 15-7 18-9 31-3 13 0 27 6 53 5 20 9 39 19 62l12 24c8 21 7 25 13 34 2 3 12 17 30 21 15 3 28-2 42-8l19-11a443 443 0 0067-81c9-16 16-27 23-43l15-48c11-33 16-50 17-62 3-20 5-39-2-61-11-37-41-56-52-63-9-7-35-24-73-24z"; }
        else if(index < 100) { path = "M194 15c-18 2-20 0-45 4-29 4-31 6-47 12-2 2-25 12-35 35-4 9-5 17-5 22-5 66 24 136 24 136 21 49 32 41 48 85 6 16 11 34 27 52 10 11 19 16 36 27 35 22 54 35 79 30 15-3 27-12 31-15 3-3 17-14 25-34 9-24 2-37 5-76l6-42c6-43 9-52 4-67-4-12-7-10-14-30-6-14-6-19-11-36l-14-34c-10-20-18-37-34-50-32-25-74-20-80-19z"; }

        return string(abi.encodePacked(
            '<clipPath id="m"> <path d="',path,'"/></clipPath>'
        ));
    }

    function generateFace(bytes memory hash) public pure returns (string memory) {
        uint256 index = uint256(toUint8(hash,0))*100/256; // 0 - 100
        string memory path;

        if(index < 10) { path = "M182 223c0-3-4-5-7-6-5-1-8 1-14 3-12 4-19 2-19 4s8 6 17 6c11 1 23-3 23-7zM235 227c0-2 9-5 14-6s11-2 18-1c7 2 16 7 15 10 0 3-9 3-10 4-7 0-10-2-18-4-12-3-18-1-19-3z M241 300c0 2-3 3-4 3-13 6-10 8-21 12-7 3-15 5-25 4-4 0-12-1-18-7-6-5-10-14-10-14 13-9 16-15 16-15l3-6c4-10 2-11 5-19l5-11v-2c6-16 3-31 3-31-1-3-3-14-10-19l-2-2a39 39 0 00-15-5c-2-1-9-2-16 0-8 1-11 4-13 3-1-1 1-8 6-12 8-7 20-4 27-2 5 1 12 2 19 8a40 40 0 0114 31v19c-2 12-2 18-6 26l-5 10c-12 21-14 25-12 29 1 6 7 9 8 10 11 4 23-4 24-5 9-6 9-13 15-14 6 0 12 5 12 9z M174 338c1-2 3-1 27-2h14c4 2 6 4 9 3s2-5 5-7c4-3 7-1 14 1 12 2 17 0 18 1 1 4-15 14-32 19-8 3-16 5-25 4-17-3-31-15-30-19z"; }
        else if(index < 20) { path = "M326 200c-1 1-9-6-29-12-23-7-32-5-35-4-3 0-11 3-18 10a38 38 0 00-10 26c0 6 2 6 5 18 1 4 4 16 5 31 1 13-1 13 1 21s5 11 5 18c-1 2-1 8-5 13-7 10-21 10-22 10-10 0-9-5-28-12-9-3-25-11-24-18 1-4 10-12 7-12l8 13c6 9 16 17 27 18 7 1 19 0 24-7 3-7-2-12-6-30s0-17-4-48c-2-13-4-19-2-28 1-5 3-14 11-21 6-5 21-14 40-11 28 5 51 23 50 25zM131 175c16-14 51-8 60-3 3 2 0 1 0 0 0 0-3-9-18-13-4-2-19-2-31 7-6 4-9 6-11 9zM125 210c2-5 20-5 33-3 3 0 16 0 22 11l1 6c1 8 3 10 3 10-4 1-9-5-17-8h-16c-13 0-27-10-26-16z M257 236c0-5 14-10 26-10 19 1 36 14 34 17 0 2-3 1-13 3l-18 3c-13 0-29-7-29-13zM151 355c1-2 5 2 15 4 11 1 21-1 24-1 7-2 10-4 14-2 5 2 5 7 9 7s6-6 12-7l8 2c11 4 20 0 20 1 1 2-10 13-32 21-10 4-14 2-20 2-11 1-20-2-23-4-17-7-27-23-27-23z"; }
        else if(index < 30) { path = "M152 205s25 10 37 1c3-2-5-9-8-11-7-3-10-6-14-5-12 2-17 12-15 15zM265 214c-2-2 6-9 17-14 5-2 9-2 11-2 13 0 21 12 21 12 0 3-9 4-10 4-8 2-7-3-15-4-13-2-22 6-24 4zM191 289c-3 1-6 8-3 13s10 6 14 9c2 1 6 4 15 4 6-1 6-4 13-6l14-4c7-2 10-3 10-8s-5-9-5-9 2 7-1 12c-3 4-11 2-19 5-11 5-8 6-18 5-7 0-17-4-21-8-3-3 1-13 1-13zM184 351c-1 1 10 11 26 16l13 2c3 0 10 0 18-5 6-3 12-9 11-11s-8 1-21 4c-8 2-17 3-26 2-13-2-21-9-21-8zM252 175c1 1 10-10 25-12 13-3 26 2 28 3 7 3 12 7 13 6 1-2-4-9-11-14-14-9-32-2-34-1-14 6-21 17-21 18zM144 168c1 2 14-12 30-10 18 2 17 13 26 9 0 0 1-3-4-7-11-5-15-11-34-4-11 4-20 10-18 12zM213 215c1-5 3 27 2 38l-5 18c-1 4-5 5-5 5 2-4 4-6 6-16 2-17 1-40 2-45z"; }
        else if(index < 40) { path = "M159 239c0-2 7 0 14-4l4-4 6-7 5-11s4 6 4 11c1 7-5 16-14 19s-19-3-19-4zM270 199c-1-2 6-9 13-12l10-3c7-5 8-12 10-11 2 0 3 9 0 15-4 5-9 7-18 9-4 1-14 4-15 2zM134 218c1 0 3-9 13-16l1-2 16-7c13-5 12-12 21-13 7-1 12 1 12 1s-8-6-15-6c-8 0-8 3-21 10-10 6-9 1-15 6-10 9-13 27-12 27z M305 141s-11-9-23-6c-3 1-5 2-21 18l-13 14c-4 6-11 14-12 26-2 16 7 30 17 45l10 13 2 2 10 10c8 6 16 9 17 9 5 2 7 2 7 4 1 2-3 5-8 9-10 10-8 14-14 18l-20 2c-8 1-8 2-12 1-6-1-15-5-14-7l14 3c14 2 28-3 29-4 7-7 12-14 13-18 1-6-12-3-26-17-6-6-12-12-17-20-9-13-12-24-13-27-4-16-2-28-2-31 1-10 5-16 13-24 5-5 5-9 15-17s10-10 14-12c15-6 34 8 34 9zM245 345s7-11 15-14c4-2 5-1 14-3 7-2 10-3 14-6l8-9c6-7 6-9 9-10 3-2 9-6 11-4 2 1 2 3 0 16l-4 16c-5 8-12 11-18 14-8 3-14 4-19 4-9 1-30-4-30-4z"; }
        else if(index < 50) { path = "M126 216l7-6c3-3 6-4 10-4 9-1 7 0 12 1l4 2s4 4 2 4-8 7-15 7c-15 1-20-4-20-4z M124 172c0 1 6-5 12-6 13-1 24 2 33 11l1 1c10 11 10 25 10 28l-4 18-6 28c-1 14 1 21-4 27l-6 6c-5 5-8 6-8 8 0 4 4 6 5 7l9 6 9 5c4 1 6-4 13-6s9 2 18 0c7-1 13-5 12-6l-17 1c-19 1-16 5-23 6-10 0-19-8-20-10-1-6 5-10 10-17 4-5 4-15 5-25 3-24 4-21 7-34 3-10 3-15 2-22-2-17-2-24-17-32-9-5-23-9-32-2-5 4-10 7-9 8zM234 219l10-7c4-2 9-1 13-1 4 1 9 1 16 6l3 5c4 5 9 3 9 4s-4 2-9 2c-4 0-7 0-12-2-6-1-11-5-17-6-11-2-13-1-13-1zM294 190c0 1-4-6-11-11-8-5-15-6-25-6-11-1-21-1-29 5l-5 5c-1-1 1-6 5-9 7-7 19-6 32-4 10 1 16 2 22 6 8 6 11 14 11 14zM236 339c0 4-11 6-20 14l-6 4c-3 2-6 2-7 2-13 1-18 2-23 0-10-3-9-2-12-5l-10-7-9-6c-1-1-5-1-4-2l4-2c6-3 5-1 10-3 4-2 7-3 10-2 5 0 3 2 8 2 4 1 6-2 12-3 4-1 7-1 17 1 19 3 29 5 30 7z"; }
        else if(index < 60) { path = "M120 168c0-4 13-5 18-5h13l11-2c2 2 0 8-5 13-7 7-19 4-21 4-8-2-17-7-16-10z M122 126c1 1 10-8 25-7 8 0 14-1 19 1 7 3 13 9 17 15l3 12c1 5 1 11-2 19l-10 28-7 25c-4 14-13 20-16 25-5 8-7 7-9 14-2 3-3 8-1 13 3 4 3 3 9 6l10 7c4 2 7 4 11 3 3 0 3-2 8-3 1-1 6-3 13-2 8 2 9 7 14 7 6 0 12-8 10-10-1-2-1 6-10 5-12-1-12-6-21-6s-12 3-19 2c-6-1-18-6-19-12-1-1-2-7 5-17l9-13c6-7 8-11 12-24 5-16 1-10 5-20l13-31c2-7 1-17-3-27-4-8-6-13-12-17-7-4-17-10-30-8-15 2-25 13-24 15zM128 316c2-3 12-2 17-2l9 2s3 5 7 6c4 2 5-1 10-1 5-1 9 0 14 1 4 1 7 2 15 7l28 15-17 9c-10 3-18 3-25 3-18-1-29-7-32-8-9-5-15-11-17-13-1-1-13-14-9-19zM241 192c0-3 6-6 11-7 6-2 12-1 14-1 7 1 12 4 16 7 7 4 11 8 14 11s8 8 7 9-9-6-23-11c-8-3-16-4-21-5-12-2-17-1-18-3zM316 163s-3-12-13-21l-4-3c-2-2-7-9-18-12l-15-1c-7 0-17 6-17 6 2-2 2-5 13-9 6-2 14-3 24 1 11 4 13 6 19 11 11 11 12 27 11 28z"; }
        else if(index < 70) { path = "M329 180s4 0-11-4l-14-3c-3 0-11 1-17 6-1 0-7 5-6 7 1 1 6 0 15-1l17 1c11 0 17-4 16-6z M321 138s-18-5-31-2c-4 1-9 1-20 9-13 10-16 13-17 23-2 9-2 17 2 25 3 8 0 4 10 21 8 13 12 17 12 23 1 10-3 13-1 22 0 2 3 14 10 15h1c6 1 13-1 14-2 4-4 2-11 3-11 2 0 4 8 0 15-2 4-4 4-15 13l-13 8-17 1c-12 0-13 4-19 3-8-2-15-9-15-16 0-3 6-7 4-7s1 16 9 18c7 1 6-3 12-2 6 0 13-1 20-6 2-1 6-4 6-7 2-7-2-10-6-20-3-8 3-12 1-24-1-8-6-9-12-21-8-16-11-17-14-27-1-3-3-21 2-30 3-6 2-9 12-16 7-5 12-8 20-10 15-3 19-1 25-1 9 1 17 6 17 6zM199 193c0-3-7-5-12-4-6 1-8 5-13 9-4 4-11 8-22 10 3 2 6 4 11 4 7 1 18 0 27-5 8-4 10-10 9-14zM190 156c-1 1-2-1-5-3 0 0-5-3-12-4-13-2-25 7-28 9-9 6-12 13-14 12s-1-9 4-16c8-14 27-14 30-15 5 0 11 0 16 4 7 4 10 13 9 13zM319 324s1 11-3 16c-2 3-6 5-17 9-15 5-23 8-33 7-9-1-15-4-22-7-2-1-7-3-7-5 0-1 13 5 25 0 6-3 8-7 15-7h10c4-1 6-4 10-7 7-6 22-6 22-6z"; }
        else if(index < 80) { path = "M118 152c0-2 8-3 15-4 9-1 13 0 15 1 5 1 7 4 7 5 2 1 4 4 4 8l-5 7s-2-7-7-10c-4-3-7 1-16-1-6-1-14-4-13-6z M143 103c1 1 8-3 17-3 24 1 25 28 25 39-1 11 0 18-8 25-9 8-7 3-18 18-6 7-6 11-12 18-5 7-29 23-35 32-3 5-4 9-4 15-1 12 18 16 22 20 9 7 11 12 20 14 7 3 14 5 21-1 5-4 7-10 5-12-2-3-12 12-22 9-7-2 0 0-17-14-11-9-17-6-20-17-2-11 7-18 21-28 12-8 12-11 16-15 7-10 6-13 13-22 9-11 25-11 25-38 0-10-2-18-3-25-1-9-7-14-11-19-5-5-14-9-22-7s-14 9-13 11zM230 199c1-3 5-6 9-7 2 0 12-3 21 0 10 3 12 8 17 14 7 9 2 22 5 24 2 1-7-7-16-13-7-5-6-4-17-8-9-5-19-4-19-10zM300 164s-3-10-14-18c-3-2-13-10-26-10-17 0-27 11-29 9-1-2 7-14 19-18 14-4 25 3 28 4 18 10 23 33 22 33zM164 332c1 4-12 10-25 11-3 0-12 0-21-5-8-4-12-10-14-14-4-6-6-19-6-19l12 2 15 5c4 7 6 7 6 7 2 2 4-1 8 0 4 0 6 2 9 4 10 8 16 7 16 9z"; }
        else if(index < 90) { path = "M103 206c2-2 7 4 16 5 12 1 22-2 22-2s-3 6-9 10c-1 1-10 6-19 2-7-4-12-13-10-15z M106 164c0 4 30-7 43 12 8 11 7 36 2 49-3 9-11 20-14 39v1c-4 20-9 29-10 30-3 3-6 10-6 18v2c2 8 8 12 10 14a31 31 0 0019 7c3 0 9 0 17-3 5-1 16-6 16-8-1-4-36 17-52-3-10-13 5-27 14-66 3-11 16-33 17-53 1-19-2-29-15-38-17-12-41-5-41-1zM261 241l-8-4c-6-4-11-15-28-11-5 1-11 7-11 9 0 1 3 3 12 5 8 2 12-3 21 2 6 3 14-1 14-1zM277 205c-1 2-8-9-21-13-11-2-22 0-28 2l-13 3c-1-1 8-9 20-12 2-1 16-4 29 4 10 6 14 15 13 16zM195 370c1 2-7 11-19 13-9 3-17 0-23-2-7-2-16-5-18-12 0-2 0-6 2-7s4 4 11 6c5 2 7 0 14 1l9 3c12 5 23-3 24-2z"; }
        else if(index < 100) { path = "M313 128c0 1-14-6-31-1a46 46 0 00-30 52c0 3 4 9 10 20 10 18 11 17 15 26 9 18 7 20 14 30 2 3 10 7 12 16l1 1c2 10-8 21-10 23a60 60 0 01-35 18c-12 3-27 6-36-2-7-6-9-16-7-17 2-2 6 2 13 6 16 6 32 2 38 1 9-3 18-5 23-14 0-1 5-10 1-17l-19-39c-5-10-31-43-32-61-1-5-2-12 5-25 1-3 9-20 28-25 21-6 40 6 40 8z M328 172c1-3-5-9-12-10-3-1-8-3-20 1-8 3-13 8-15 11-5 5-9 10-7 12 2 1 8-8 19-10 7-1 8 2 18 1 3 0 16-1 17-5zM198 201c-1-6-11-11-18-9-7 1-6 7-16 14-9 6-14 4-20 11-2 3-6 9-4 11 2 3 8-1 26-6 13-3 17-3 23-8 3-2 10-7 9-13zM197 156c-1 2-12-6-31-5-14 1-25 7-27 8-11 6-16 13-18 11-2-1 0-12 7-18 5-5 9-3 24-7 13-5 13-7 19-7 15 0 28 15 26 18zM322 315s3 18-3 28c-5 9-12 13-16 15-4 3-15 9-31 9-10 0-10-4-31-8l-16-4c0-3 11-4 27-14 10-6 13-7 20-7 6 0 8 3 12 1 4-1 4-5 9-9l12-6c13-2 14-7 17-5z"; }

        return string(abi.encodePacked(
            '<path class="c" d="',path,'"/>'
        ));
    }

    function generateBlur(bytes memory hash) public pure returns (string memory) {
        uint256 blurDegree = uint256(toUint8(hash,2))/64; // 1 - 4
        uint256 blurSeed = uint256(toUint8(hash,3));

        return string(abi.encodePacked(
            svgFilter('blur'), 
            '<feTurbulence baseFrequency="',generateDecimalString(5,blurDegree+1),'" seed="',toString(blurSeed),'" result="turbs"/>',
            '<feSpecularLighting surfaceScale="200" result="out" specularExponent="20">',
            '<fePointLight x="216" y="17" z="200"/>',
            '</feSpecularLighting>',
            '<feGaussianBlur in="out" stdDeviation="4" result="blurred"/>',
            '<feComposite in="SourceGraphic" in2="blurred" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"/>',
            '</filter>'
        ));
    }

    function generateSteps(bytes memory hash) public pure returns (string memory) {
        uint256 stepsDegree = uint256(toUint8(hash,4))/64; // 1 - 4
        uint256 stepsInterDegree = 1+uint256(toUint8(hash,5))*100/256/10;
        uint256 stepsSeed = uint256(toUint8(hash,6));
        uint256 stepsScale = 80+uint256(toUint8(hash,7))/2;
        return string(abi.encodePacked(
            svgFilter('steps'), 
            '<feTurbulence baseFrequency="',generateDecimalString(stepsInterDegree,stepsDegree+1),'" seed="',toString(stepsSeed),'" result="turbs"/>',
            '<feSpecularLighting surfaceScale="',toString(stepsScale),'" result="specOut" specularExponent="20">',
            '<fePointLight x="210" y="17" z="200"/>',
            '</feSpecularLighting>',
            '<feComposite in="SourceGraphic" in2="blurred" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"/>',
            '</filter>'
        ));
    }

    function generateTurbs1(bytes memory hash) public pure returns (string memory) {
        uint256 turbs1Degree = uint256(toUint8(hash,8))/128; // 0 - 2 (2 is very slightly rarer due to it ending at 2.965)
        uint256 turbs1InterDegree = 1+uint256(toUint8(hash,9))*100/256/10;
        uint256 turbs1Seed = uint256(toUint8(hash,10));
        return string(abi.encodePacked(
            svgFilter('turb1'), 
            '<feTurbulence baseFrequency="',generateDecimalString(turbs1InterDegree,turbs1Degree+2),'" seed="',toString(turbs1Seed),'" result="turbs"/>',
            '</filter>'
        ));
    }

    function generateTurbs2(bytes memory hash) public pure returns (string memory) {
        uint256 turbs2Degree = uint256(toUint8(hash,11))/64; // 0 - 3
        uint256 turbs2InterDegree = 1+uint256(toUint8(hash,12))*100/256/10;
        uint256 turbs2Seed = uint256(toUint8(hash,13));
        // do colour tempering next
        string memory redOffset = getColourOffset(hash, 14);
        string memory greenOffset = getColourOffset(hash, 15);
        string memory blueOffset = getColourOffset(hash, 16);

        uint256 alphaSlope = 1+uint256(toUint8(hash,17))/64;

        return string(abi.encodePacked(
            svgFilter('turb2'), 
            '<feTurbulence baseFrequency="',generateDecimalString(turbs2InterDegree,turbs2Degree+1),'" seed="',toString(turbs2Seed),'" result="turbs"/>',
            '<feComponentTransfer result="wave">',
            '<feFuncR type="gamma" offset="',redOffset,'"/>',
            '<feFuncG type="gamma" offset="',greenOffset,'"/>',
            '<feFuncB type="gamma" offset="',blueOffset,'"/>',
            '<feFuncA type="linear" slope="',toString(alphaSlope),'"/>',
            '</feComponentTransfer>',
            '</filter>'
        ));
    }

    function getColourOffset(bytes memory hash, uint256 hashIndex) public pure returns (string memory) {
        uint256 shift = uint256(toUint8(hash,hashIndex))/128; // 0 or 1. Positive or Negative
        uint256 change = uint256(toUint8(hash,hashIndex))*100/256; // 0 - 99 
        string memory sign = "";
        if(shift == 1) { sign = "-"; }
        return string(abi.encodePacked(
            sign,generateDecimalString(change,1)
        ));
    }

    function svgRect(string memory opacity, string memory filter, string memory fill) public pure returns (string memory) {
        return string(abi.encodePacked('<rect width="100%" height="200%" clip-path="url(#m)" opacity="',opacity,'" filter="url(#',filter,')" fill="',fill,'"/>'));
    }

    function svgFilter(string memory id) public pure returns (string memory) {
        return string(abi.encodePacked('<filter id="',id,'" width="100%" height="100%">'));
    }

    function svgFeTurbulence(string memory seed, string memory baseFrequency) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<feTurbulence type="turbulence" seed="',seed,'" baseFrequency="',baseFrequency,'" result="turbs"/>'
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