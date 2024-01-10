//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./base64.sol";
import "./Strings.sol";
import "./FileTokens.sol";

/**

STEMS GARDEN METADATA v1

*/

contract Meta {


    modifier tokenExists(uint token_id_){
        IFileTokens garden_ = IFileTokens(msg.sender);
        require(garden_.ownerOf(token_id_) != address(0), 'TOKEN_DOES_NOT_EXIST');
        _;
    }

    function getMeta(uint token_id_) public view tokenExists(token_id_) returns(string memory){
        
        IFileTokens garden_ = IFileTokens(msg.sender);
        IFileTokens.Token memory token_ = garden_.getToken(token_id_);

        string memory stitle_ = garden_.getString(string(abi.encodePacked('s',Strings.toString(token_.batch),'_title')));
        bool hasStitle_ = (bytes(stitle_).length > 0);

        string[] memory keys_ = new string[](2);
        string[] memory values_ = new string[](2);

        keys_[0] = 'file';
        values_[0] = token_.file;

        keys_[1] = 'license';
        values_[1] = 'CC0';
        
        bytes memory json_ = abi.encodePacked(
        '{',
        '"name":"Stems Garden | S',Strings.toString(token_.batch), hasStitle_ ? string(abi.encodePacked(': ', stitle_)) : '', ' | #',Strings.toString(token_id_),'",',
        '"description":"A collaborative audio project.",',
        '"image":"',getArtwork(token_id_),'",',
        '"attributes": [',
            _getAttributesJSON(keys_, values_),
        ']',
        '}');

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json_)));
        
    }


    function _getAttributesJSON(string[] memory keys_, string[] memory values_) private pure returns(string memory json_){
        for(uint i = 0; i < keys_.length; i++) {
            json_ = string(abi.encodePacked(json_, '{"trait_type":"',keys_[i],'", "value": "',values_[i],'"}', keys_.length == i+1 ? '' : ','));
        }
    }


    function getArtwork(uint token_id_) public view tokenExists(token_id_) returns(string memory){
        
        bytes memory svg_ = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" preserveAspectRatio="xMinYMin meet"> <style> .txt { font-family: Arial, sans-serif; font-size: 100px; letter-spacing: 0.5em; } .green { fill: #00ff00; } .italic { font-style: italic; } .sm { font-size: 12px; } .uc { text-transform: uppercase; } .white { fill: white; } .bold { font-weight: bold; } </style> <defs> <filter xmlns="http://www.w3.org/2000/svg" id="blur" x="-0.1" y="0"><feGaussianBlur in="SourceGraphic" stdDeviation="10"/></filter> <rect id="bg" width="1000" height="1000" x="0" y="0"/> <linearGradient id="g1"> <stop offset="0" stop-color="#000000"> <animate attributeName="offset" begin="0s" dur="10s" values="0;0.1;0" repeatCount="indefinite" /> </stop> <stop offset="0" stop-color="#5f665f"> <animate attributeName="offset" begin="0s" dur="10s" values="0.9;1;0.9" repeatCount="indefinite" /> </stop> </linearGradient> <linearGradient id="g2"> <stop offset="10%" stop-color="#000000" /> <stop offset="80%" stop-color="#a8009a" /> </linearGradient> </defs> <g clip-path="#bg"> <use href="#bg" fill="white"/> <!-- <use href="#bg" fill="url(#g1)" opacity="0.3"/> --> <use href="#bg" fill="url(#g2)" opacity="0.15"/> <text filter="url(#blur)" class="txt italic green" width="900" transform="translate(50, 400)"> <tspan x="0" y="1em">Dirt</tspan> <tspan x="320" y="2.5em">speaks</tspan> <tspan x="0" y="3.7em">truth</tspan> </text> <text class="txt italic sm white uc" transform="translate(30, 35)" opacity="1"> <tspan x="775" y="0">STEMS GARDEN</tspan> <tspan x="0" y="0">#',Strings.toString(token_id_),'</tspan> </text> </g> </svg>');
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg_)));

    }

}