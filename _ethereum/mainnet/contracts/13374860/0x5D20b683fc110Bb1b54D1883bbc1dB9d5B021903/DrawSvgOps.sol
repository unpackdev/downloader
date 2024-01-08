// SPDX-License-Identifier: Mixed...
pragma solidity ^0.8.0;
import "./Strings.sol";

/// Copyright (c) Sterling Crispin
/// All rights reserved.
/// @title DrawSvgOps
/// @notice Provides some drawing functions used in MESSAGE
/// @author Sterling Crispin <sterlingcrispin@gmail.com>
library DrawSvgOps {

    string internal constant elli1 = '<ellipse cx="';
    string internal constant elli2 = '" cy="';
    string internal constant elli3 = '" rx="';
    string internal constant elli4 = '" ry="';
    string internal constant elli5 = '" stroke="mediumpurple" stroke-dasharray="';
    string internal constant upgradeShapeEnd = '"  fill-opacity="0"/>';
    string internal constant strBlank = ' ';

    function rand(uint num) internal view returns (uint256) {
        return  uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, num))) % num;
    }
    function Ellipse(uint256 size) external view returns (string memory){
        string memory xLoc = Strings.toString(rand(size-1));
        string memory yLoc = Strings.toString(rand(size-2));
        string memory output = string(abi.encodePacked(
            elli1,xLoc,
            elli2,yLoc,
            elli3,Strings.toString(rand(size-3)),
            elli4,Strings.toString(rand(size-3))));
        output = string(abi.encodePacked(
            output,
            elli5,Strings.toString(rand(7)+1),upgradeShapeEnd,
            elli1,xLoc,
            elli2,yLoc
        ));
        output = string(abi.encodePacked(
            output,elli3,
            Strings.toString(rand(size-4)),
            elli4,Strings.toString(rand(size-5)),
            elli5,Strings.toString(rand(6)+1),upgradeShapeEnd
            ));
        output = string(abi.encodePacked(
            output,
            elli1,xLoc,
            elli2,yLoc,
            elli3,Strings.toString(rand(size-5)),
            elli4));
        output = string(abi.encodePacked(
            output,Strings.toString(rand(size-6)),
            elli5,Strings.toString(rand(4)+1),upgradeShapeEnd
        ));
        return output;
    }

    function Wiggle(uint256 size) external view returns (string memory){
        string memory output = string(abi.encodePacked(
            '<path d="M ',
            Strings.toString(rand(size-1)), strBlank,
            Strings.toString(rand(size-2)), strBlank,
            'Q ', Strings.toString(rand(size-3)), strBlank));
        output = string(abi.encodePacked(output,
            Strings.toString(rand(size-4)), ', ',
            Strings.toString(rand(size-5)), strBlank,
            Strings.toString(rand(size-6)), strBlank,
            'T ',  Strings.toString(rand(size-7)), strBlank,
            Strings.toString(rand(size-8)), '"'
            ));
        output = string(abi.encodePacked(output,
            ' stroke="red" stroke-dasharray="',Strings.toString(rand(7)+1), upgradeShapeEnd
        ));
        return output;
    }
}