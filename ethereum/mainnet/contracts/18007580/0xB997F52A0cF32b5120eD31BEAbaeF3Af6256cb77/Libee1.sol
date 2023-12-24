// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Base64.sol";
import "./Ownable.sol";


interface ColorGenerator {
    function getRandomColor(uint256 tokenId) view external returns (string memory, uint8[3] memory);
    }

interface Libee {
    function generateURI(uint256 tokenId, uint256 randomNumber) view external returns (string memory);
}

interface OcOpepen{
    function transferOwnership (address newOwner) external;
    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external;
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function numberMinted(address owner) external view returns (uint256);
}

contract Libee1 is Ownable{

    uint256 public price = 0.015 ether; 
    uint256 public maxSupply = 548;
    uint256 public maxPerTransaction = 5;
    uint256 public totalAirdroppedTokens;
    bool public saleActive;
    mapping(uint256 => bool) public claimedTokens;
    address color_addr;
    ColorGenerator colorGenerator;
    address libee_addr;
    Libee libee;
    address OcO_addr;
    OcOpepen oco;

    function _setColorAddr(address _color_addr) public onlyOwner  {  
            color_addr = _color_addr;
        }

    function _setAddr(address _libee_addr) public onlyOwner  {  
            libee_addr = _libee_addr;
        }

    function _setOcoAddr(address _OcO_addr) public onlyOwner  {  
            OcO_addr = _OcO_addr;
        }

    function transferOcOOwnership(address newOwner) external onlyOwner {
            OcOpepen(OcO_addr).transferOwnership(newOwner);
        }

    function getColorAndVariables(uint256 tokenId, uint256 randomNumber) internal view returns (string memory color, string memory colorName) {
            uint8[3] memory rgb;
            randomNumber += tokenId;
            (colorName, rgb) = ColorGenerator(color_addr).getRandomColor(randomNumber);
            color = string(abi.encodePacked(
                "rgb(",
                uint2str(rgb[0]), ",",
                uint2str(rgb[1]), ",",
                uint2str(rgb[2]),
                ")"
            ));
            return (color, colorName);
        }

    function getColor (uint256 tokenId, uint256 randomNumber) internal view returns (string memory color) {
            (color,) = getColorAndVariables(tokenId, randomNumber);
            return color;
    }

    function generateURI(uint256 tokenId, uint256 randomNumber) view external returns (string memory) {
            string memory tokenURI;
            if (tokenId <= 250)
            {
                tokenURI = Libee(libee_addr).generateURI(tokenId, randomNumber);
            }
            else{   
            (, string memory colorName) = getColorAndVariables(30000, randomNumber);
            string memory baseSvg = generateBaseSvg(tokenId, randomNumber);
            string memory json = generateJson(tokenId, baseSvg, randomNumber, colorName);
            tokenURI = string(abi.encodePacked('data:application/json;base64,', json));          
            }
            return tokenURI;
        }


    function generateJson(uint256 tokenId, string memory baseSvg, uint256 randomNumber, string memory colorName) internal pure returns (string memory) {
            string memory numFilters;
            string memory typeName;

            if (tokenId % 10 == 0) {
                numFilters = "5";
            } else if (tokenId % 4 == 0) {
                numFilters = "7";
            } else if (tokenId % 3 == 0) {
                numFilters = "8";
            } else {
                numFilters = "6";
            }

            if (randomNumber % 3 == 0) {
                typeName = "spotLight";
            } else if (randomNumber % 4 == 0) {
                typeName = "glOriOus";
            } else {
                typeName = "planes";
            }
        string memory json = string(
            abi.encodePacked(
                '{"name": "OcOpepen #',
                uint2str(tokenId),
                '", "description": "OnChain Opepens generated, glitched and stored on the blockchain via 4 contracts/", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(baseSvg)),
                '", "attributes":['
                '{"trait_type":"Type", "value":"',
                typeName,
                '"},'
                '{"trait_type":"Eyes", "value":"No Blinkers"},'
                '{"trait_type":"Base color", "value":"',
                colorName,
                '"},'
                '{"trait_type":"Background Type", "value":"Solid"},'
                '{"trait_type":"Background Color", "value":"Black"},'
                '{"trait_type":"Number of Filters", "value":"',
                numFilters,
                '"},'
                '{"trait_type":"Stroke", "value":"No"}'
                ']}'
            )
        );

        return Base64.encode(bytes(json));
    }

    function spotLight(uint256 randomNumber) internal view returns (string memory) {
        return string(abi.encodePacked(
            '<radialGradient id="spotLight" width="0%" height="0%" r="100%">'
            '<animate attributeName="cx" values="50%;30%;50%;80%;10%;30%;50%;" dur="1s" repeatCount="indefinite"/>'
            '<animate attributeName="cy" values="10%;20%;50%;80%;80%;30%;10%;" dur="1s" repeatCount="indefinite"/>'
            '<animate attributeName="cx" values="10%;90%;50%;10%;90%;10%;" dur="3s" repeatCount="indefinite"/>'
            '<animate attributeName="cy" values="10%;10%;50%;90%;90%;10%;" dur="5s" repeatCount="indefinite"/>'
            '<animate attributeName="r" values="10%;20%;30%;100%;60%;20%;30%;10%;" dur="5s" repeatCount="indefinite"/>'
            '<stop offset="0%" style="stop-color: ', 
            getColor(100, randomNumber), 
            '; stop-opacity: 1">'
            '</stop>'
            '<stop offset="50%" style="stop-color: ', 
            getColor(2000, randomNumber), 
            '; stop-opacity: 1" >'
            '</stop>'
            '<stop offset="100%" style="stop-color: ', 
            getColor(30000, randomNumber), 
            '; stop-opacity: ', (randomNumber % 8 == 0) ? "0.01" : (randomNumber % 4 == 0) ? "0.1" : "1", '" >'
            '</stop>'
            '</radialGradient>'
        ));
    }

    function generateBaseSvg(uint256 tokenId, uint256 randomNumber) internal view returns (string memory) {
        
        string memory fillPattern = getFillPattern(randomNumber);
        uint256 randomNumber1 = randomNumber;
        string memory gFILTERS = gFilters(tokenId);
        string memory baseColor = getColor(30000, randomNumber);

        string memory baseSvg = string(abi.encodePacked(
        '<svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">'
        '<rect width="100%" height="100%" fill="black" stroke="none"/>'
        '<defs>',
        spotLight(randomNumber),

        '<filter id="feOffset" x="-100" y="-20" width="1000" height="1000">'
        '<feOffset in="SourceGraphic" dx="60" dy="60"/>'
        '<feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur2"/>'
        '<feMerge>'
        '<feMergeNode in="blur2"/>'
        '<feMergeNode in="SourceGraphic"/>'
        '</feMerge>'
        '</filter>'
        '<filter id="pixelate" width="0%" height="0%">'
        '<feComponentTransfer>'
        '<feFuncR type="discrete" tableValues="0 0 0 0 1 1 1 1" />'
        '<feFuncG type="discrete" tableValues="0 0 0 0 1 1 1 1" />'
        '<feFuncB type="discrete" tableValues="0 0 0 0 1 1 1 1" />'
        '</feComponentTransfer>'
        '<feComponentTransfer>'
        '<feFuncR type="discrete" tableValues="0 0 1 1 0 0 1 1" />'
        '<feFuncG type="discrete" tableValues="0 0 1 1 0 0 1 1" />'
        '<feFuncB type="discrete" tableValues="0 0 1 1 0 0 1 1" />'
        '</feComponentTransfer>'
        '</filter>'

        '<filter id="glow" width="0%" height="0%">'
        '<feGaussianBlur in="SourceGraphic" stdDeviation="0" result="blur"/>'
        '<feFlood flood-color="', 
        baseColor,
        '" result="glowColor"/>'
        '<feComposite in="glowColor" in2="blur" operator="in" result="glow"/>'
        '<feMerge>'
        '<feMergeNode in="glow"/>'
        '<feMergeNode in="SourceGraphic"/>'
        '</feMerge>'
        '</filter>'

        '<filter id="holographic" width="0%" height="0%">'
        '<feTurbulence type="turbulence" baseFrequency="0.1" numOctaves="6" result="turbulence"/>'
        '<feDisplacementMap in="SourceGraphic" in2="turbulence" scale="25" xChannelSelector="R" yChannelSelector="G" />'
        '<feColorMatrix type="matrix" values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 50 -5" />'
        '<feGaussianBlur stdDeviation="2" result="blur"/>'
        '<feMerge>'
        '<feMergeNode in="blur"/>'
        '<feMergeNode in="SourceGraphic"/>'
        '</feMerge>'
        '</filter>'

        '<filter id="borders" width="0%" height="0%">'
        '<feTurbulence type="turbulence" baseFrequency="0.09" numOctaves="0.4" result="turbulence"/>'
        '<feDisplacementMap in="SourceGraphic" in2="turbulence" scale="9" xChannelSelector="R" yChannelSelector="G" />'
        '<feColorMatrix type="matrix" values="1 1 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 15 -5"/>'
        '<feGaussianBlur stdDeviation="0.2" result="blur"/>'
        '<feComponentTransfer>'
        '<feFuncR type="linear" slope="1" intercept="0.2"/>'
        '<feFuncG type="linear" slope="1" intercept="0.5"/>'
        '<feFuncB type="linear" slope="1" intercept="0.8"/>'
        '</feComponentTransfer>'
        '<feMerge>'
        '<feMergeNode in="blur"/>'
        '<feMergeNode in="SourceGraphic"/>'
        '</feMerge>'
        '</filter>'

        '<filter id="oilPainting" width="0%" height="0%">'
        '<feMorphology operator="dilate" radius="5">'
        '<animate attributeName="radius" values="2;4;1;3;2;5;" dur="2s" repeatCount="indefinite"/>'
        '</feMorphology>'
        '<feColorMatrix type="matrix" values="1 1 1 1 0 0 1 0 0 0 0 0 1 0 0 0 0 0 20 -8" />'
        '</filter>'

        '<filter id="vanGoghOilPainting" width="0%" height="0%">'
        '<feColorMatrix type="matrix" values="0.9 0 0 0 0'
        '0 1.2 0 0 0'
        '0 0 0.8 0 0'
        '0 0 0 1 0"/>'
        '<feComponentTransfer>'
        '<feFuncR type="table" tableValues="0 0.2 0.5 0.7 1"/>'
        '<feFuncG type="table" tableValues="0 0.2 0.5 0.7 1"/>'
        '<feFuncB type="table" tableValues="0 0.2 0.5 0.7 1"/>'
        '</feComponentTransfer>'
        '<feGaussianBlur stdDeviation="5">'
        '<animate attributeName="stdDeviation" values="5;2;50;5;" dur="2s" repeatCount="indefinite"/>'
        '</feGaussianBlur>'
        '<feComposite operator="out" in2="SourceGraphic"/>'
        '</filter>'

        '<filter id="displacementFilter" width="0%" height="0%">'
        '<feTurbulence type="turbulence" baseFrequency="1" numOctaves="6" result="turbulence">'
        '<animate attributeName="baseFrequency" values="0.3;0.5;0.3" dur="2s" repeatCount="indefinite"/>'
        '</feTurbulence>'
        '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="5" xChannelSelector="R" yChannelSelector="G"/>'
        '</filter>'

        '<filter id="shadows" width="0%" height="0%">'
        '<feSpecularLighting in="SourceAlpha" result="specOut" specularConstant="5" specularExponent="10" lighting-color="',
        (randomNumber % 8 == 0) ? baseColor : 
            ((randomNumber % 3 == 0) ? getColor(2000, randomNumber) : getColor(1616, randomNumber)),
        '">'
        '<fePointLight x="0" y="0" z="0"/>'
        '</feSpecularLighting>'
        '<feComposite in="specOut" in2="SourceAlpha" operator="in" result="specOut"/>'
        '<feOffset dx="30" dy="0"/>'
        '<feMerge>'
        '<feMergeNode/>'
        '<feMergeNode in="SourceGraphic"/>'
        '</feMerge>'
        '</filter>'

        '<filter id="shadows1" width="0%" height="0%">'
        '<feSpecularLighting in="SourceAlpha" result="specOut" specularConstant="5" specularExponent="10" lighting-color="',
        (randomNumber % 8 == 0) ? baseColor : 
            ((randomNumber % 3 == 0) ? getColor(2000, randomNumber) : getColor(1818, randomNumber)),
        '">'
        '<fePointLight x="0" y="0" z="0"/>'
        '</feSpecularLighting>'
        '<feComposite in="specOut" in2="SourceAlpha" operator="in" result="specOut"/>'
        '<feOffset dx="-30" dy="0"/>'
        '<feMerge>'
        '<feMergeNode/>'
        '<feMergeNode in="SourceGraphic"/>'
        '</feMerge>'
        '</filter>'

        '<filter id="chaosRain" width="0%" height="0%">'
        '<feTurbulence type="turbulence" baseFrequency="1" numOctaves="5" result="turbulence"/>'
        '<feDisplacementMap in="SourceGraphic" in2="turbulence" scale="5"/>'
        '<feComposite in="flood" in2="turbulence" operator="in" result="coloredTurbulence"/>'
        '<feMorphology in="coloredTurbulence" operator="dilate" radius="0.3"/>'
        '</filter>'

        '<filter id="animatedSwirls" width="0%" height="0%">'
        '<feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="6" result="turbulence">'
        '<animate attributeName="baseFrequency" values="', (randomNumber1 % 2 == 0) ? "0.4;0.5;0.6;0.7;" : "0.04;0.05;0.06;", '" dur="4s" repeatCount="indefinite"/>'
        '</feTurbulence>'
        '<feDisplacementMap in="SourceGraphic" in2="turbulence" scale="', (randomNumber1 % 2 == 0) ? "30" : "-30", '"/>'
        '<feComposite in="flood" in2="turbulence" operator="in" result="coloredTurbulence"/>'
        '<feMerge>'
        '<feMergeNode in="coloredTurbulence"/>'
        '<feMergeNode in="SourceGraphic"/>'
        '</feMerge>'
        '</filter>'

        '<pattern id="glOriOus" width="10" height="10" patternUnits="userSpaceOnUse">'
        '<animate attributeName="height" values="10;15;17" dur="5s" repeatCount="indefinite"/>'
        '<animate attributeName="width" values="10;20;10" dur="5s" repeatCount="indefinite"/>'
        '<path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />'
        '<path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 5 3 0 016 0z" fill="', 
        baseColor, 
        '" >'
        '</path>'
        '</pattern>',

        planes(tokenId,randomNumber),
        '</defs>'

        '',  gFILTERS,  '" fill="', fillPattern, '">'
        '<path d="m74 74-.1 23c.1 25 .7 28.5 6.2 37.1C83.2 139 92.4 147 94.8 147c.7 0 1.2.5 1.2 1.1 0 .7-3.7 1-11.1.8l-11-.3v23c0 25.4.6 28.8 6.2 37.6 4 6.2 13.3 13.2 20.2 15.3 7.4 2.2 91.8 2.3 99 .1a38.6 38.6 0 0 0 19.3-13.9c6.8-9.2 7.5-12.6 7.5-39.1v-23l-11 .3c-7.4.2-11.1-.1-11.1-.8 0-.6.5-1.1 1.1-1.1 2.4 0 10.8-7.2 14.3-12.3a36.6 36.6 0 0 0 6.7-22.2 38.4 38.4 0 0 0-39.6-38.8c-8 .2-13.7 1.9-20.9 6.5A42.2 42.2 0 0 0 151.5 98c-.7 3.3-2.5 4.1-2.5 1.2 0-3.7-7.7-13.9-13.6-18.1-9-6.4-12.8-7.2-38.8-7.4-12.4-.1-22.6 0-22.6.3zm51.2 4.9a38.2 38.2 0 0 1 22.7 27.3l.8 4.8H76V94.2c0-9.3.3-17.2.8-17.6.4-.5 10.1-.6 21.7-.4 18.7.4 21.6.7 26.7 2.7zm75.5.3a38.3 38.3 0 0 1 22.2 27l.8 4.8h-72.4l.8-4.6A36.5 36.5 0 0 1 191 76.8c2.5.3 6.9 1.3 9.7 2.4zM111 131.4v17.3l-5.2-.9c-14-2.6-26-14.7-28.7-29.1l-.8-4.7H111v17.4zm36.9-12.7a37.8 37.8 0 0 1-28.7 29.1l-5.2.9V114h34.7l-.8 4.7zm38.1 12.7v17.3l-5.2-.9c-14-2.6-26-14.7-28.7-29.1l-.8-4.7H186v17.4zm36.9-12.8a37.2 37.2 0 0 1-29.1 29.3l-4.8.8V114h34.7l-.8 4.6zm-71.9 7.2c0 5.1 14.4 21.2 18.9 21.2.6 0 1.1.4 1.1 1s-7.7 1-21 1-21-.4-21-1 .5-1 1.1-1c4.4 0 16.9-13.8 18.5-20.3.7-3 2.4-3.7 2.4-.9zm-40 61.6v36.3l-4.7-.8a38.2 38.2 0 0 1-27.4-22.7c-2-5-2.3-8-2.7-25.9-.2-11.2-.2-20.9.2-21.8.4-1.3 3.3-1.5 17.6-1.5h17v36.4zm37.5.1v36l-17.2.3-17.3.2v-73l17.3.2 17.2.3v36zm37.5 0V224l-17.2-.2-17.3-.3-.3-35c-.1-19.2 0-35.6.3-36.2.3-1 4.7-1.3 17.5-1.3h17v36.5zm37.4-14.5c0 19.8-.2 21.9-2.3 27.2a38.2 38.2 0 0 1-27.3 22.7l-4.8.8V151l17.3.2 17.2.3-.1 21.5zM103.6 264.1a41 41 0 0 0-26.3 21.6c-3.2 6.9-4.3 14.3-2.1 14.3 1 0 1.7-1.5 2.1-4.5a36.3 36.3 0 0 1 25.6-27.9c8.7-2.5 8.1-3.7 8.1 15.4 0 14.4.2 17 1.5 17s1.5-2.6 1.5-17v-17h35v17c0 10.7.4 17 1 17s1-6.3 1-17v-17h35v17c0 14.4.2 17 1.5 17s1.5-2.6 1.5-17c0-19.1-.6-17.9 8.1-15.4a36.3 36.3 0 0 1 25.6 27.9c.4 3 1.1 4.5 2.1 4.5 2.3 0 1-8-2.7-15.4a38 38 0 0 0-18.9-17.9l-6.7-3.2-44.5-.2c-24.9-.1-46.2.3-48.4.8z"/>'
        '</g>'       
        '</svg>'
    ));
        return baseSvg;
    }

    function planes(uint256 tokenId, uint256 randomNumber) internal view returns (string memory) {
        string memory animationHeight;
        string memory animationWidth;
            
            if (tokenId % 2 == 0) {
                animationHeight = '<animate attributeName="height" values="50;1;1;50" dur="10s" repeatCount="indefinite"/>';
                animationWidth = '<animate attributeName="width" values="5;1;1;5" dur="10s" repeatCount="indefinite"/>';
            } else {
                animationHeight = animationWidth = '';
            }
        return string(abi.encodePacked(
            '<pattern id="planes" x="4" y="4" width="1" height="1" patternUnits="userSpaceOnUse">',
            animationHeight,
            animationWidth,
            '<path d="M 1 0 Q 1 20 200 100" stroke="', 
            getColor(30000, randomNumber), 
            '" fill="', 
            getColor(2000, randomNumber), 
            '"/>'
            '</pattern>'
        ));
        }

    function getFillPattern(uint256 randomNumber) internal pure returns (string memory) {
        if (randomNumber % 3 == 0) {
            return "url(#spotLight)";
        } else if (randomNumber % 4 == 0) {
            return "url(#glOriOus)";
        } else {
            return "url(#planes)";
        }
    }

    function gFilters(uint256 tokenId) internal pure returns (string memory) {
            string memory filterString = '<g filter="';
            if (tokenId % 10 == 0) {
                filterString = string(abi.encodePacked(filterString,  'url(#oilPainting)url(#vanGoghOilPainting)url(#borders)url(#glow)url(#feOffset)'));
            } else if (tokenId % 4 == 0) {               
                filterString = string(abi.encodePacked(filterString,  'url(#displacementFilter)url(#holographic)url(#glow)url(#glow)url(#feOffset)url(#chaosRain)url(#glow)'));
            } else if (tokenId % 3 == 0) {
                filterString = string(abi.encodePacked(filterString,  'url(#holographic)url(#borders)url(#feOffset)url(#shadows1)url(#shadows)url(#animatedSwirls)url(#pixelate)url(#glow)'));         
            } 
            else {
                filterString = string(abi.encodePacked(filterString,  'url(#shadows1)url(#shadows)url(#animatedSwirls)url(#pixelate)url(#glow)url(#feOffset)'));
            }
            return (filterString) ;
        }
    
    function Claim(uint256 amount) external payable {
        
        require(saleActive);
        require(amount <= maxPerTransaction);
        require(totalAirdroppedTokens + amount <= maxSupply);
        
        uint256[] memory balance = OcOpepen(OcO_addr).tokensOfOwner(msg.sender);
        
        bool allClaimed = true;

        for (uint256 i = 0; i < balance.length; i++) {
            if (!claimedTokens[balance[i]] && balance[i] <= 250) {
                allClaimed = false;
                break;
            }
        }
        if (allClaimed) {
            price = price * amount;
        } 
        else{
            for (uint256 i = 0; i < balance.length; i++) {
                claimedTokens[balance[i]] = true;
            }
            price = price * (amount - 1);
        }
        require(msg.value >= price);
        address[] memory recipients = new address[](1);
        recipients[0] = msg.sender;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        
        OcOpepen(OcO_addr).airdropTokens(recipients, amounts);
        totalAirdroppedTokens += amount;
    }

    function startSale() external onlyOwner {
        require(saleActive == false);
        saleActive = true;
    }

    function stopSale() external onlyOwner {
        require(saleActive == true);
        saleActive = false;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function uint2str(uint _i) internal pure returns (string memory str) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint length;
            while (j != 0) {
                length++;
                j /= 10;
            }
            bytes memory bstr = new bytes(length);
            uint k = length;
            while (_i != 0) {
                bstr[--k] = bytes1(uint8(48 + _i % 10));
                _i /= 10;
            }
            return string(bstr);
        }

    }