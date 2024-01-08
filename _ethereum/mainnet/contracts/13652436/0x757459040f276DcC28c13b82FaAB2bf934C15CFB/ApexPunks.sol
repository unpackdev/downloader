// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Mintable.sol";
import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";

import "./Base.sol";

/*
 * Dev by @_MrCode_
 *
 * ░█████╗░██████╗░███████╗██╗░░██╗  ██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
 * ██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝  ██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
 * ███████║██████╔╝█████╗░░░╚███╔╝░  ██████╔╝██║░░░██║██╔██╗██║█████═╝░╚█████╗░
 * ██╔══██║██╔═══╝░██╔══╝░░░██╔██╗░  ██╔═══╝░██║░░░██║██║╚████║██╔═██╗░░╚═══██╗
 * ██║░░██║██║░░░░░███████╗██╔╝╚██╗  ██║░░░░░╚██████╔╝██║░╚███║██║░╚██╗██████╔╝
 * ╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░
 *
 */
contract ApexPunks is Base {
    constructor(address _imx)
        ERC721("Apex Punks", "APX")
        Mintable(msg.sender, _imx)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(SET_URI_ROLE, msg.sender);
    }

    mapping(uint256 => string) public rank;
    mapping(uint256 => string) public punkType;
    mapping(uint256 => string) public fullType;
    mapping(uint256 => string) public attributeCount;
    mapping(uint256 => string) public hair;
    mapping(uint256 => string) public eyes;
    mapping(uint256 => string) public facialHair;
    mapping(uint256 => string) public neckAccessory;
    mapping(uint256 => string) public mouthProp;
    mapping(uint256 => string) public mouth;
    mapping(uint256 => string) public blemishes;
    mapping(uint256 => string) public ears;
    mapping(uint256 => string) public nose;
    mapping(uint256 => string) public species;

    function _mintFor(
        address to,
        uint256 id,
        bytes memory blueprint
    ) internal override {
        string[] memory attribute = String.split(string(blueprint), ",");
        require(attribute.length == 14, "invalid blueprint");

        rank[id] = attribute[0];
        punkType[id] = attribute[1];
        fullType[id] = attribute[2];
        attributeCount[id] = attribute[3];
        hair[id] = attribute[4];
        eyes[id] = attribute[5];
        facialHair[id] = attribute[6];
        neckAccessory[id] = attribute[7];
        mouthProp[id] = attribute[8];
        mouth[id] = attribute[9];
        blemishes[id] = attribute[10];
        ears[id] = attribute[11];
        nose[id] = attribute[12];
        species[id] = attribute[13];

        _safeMint(to, id);

        emit TokenCreated(id, to);
    }
}
