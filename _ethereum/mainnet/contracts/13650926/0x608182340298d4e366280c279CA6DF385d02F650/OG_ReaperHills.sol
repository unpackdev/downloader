// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Mintable.sol";
import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";

import "./String.sol";
import "./Base.sol";

/*
 * Dev by @_MrCode_
 *
 * ░█████╗░░██████╗░  ██████╗░███████╗░█████╗░██████╗░███████╗██████╗░  ██╗░░██╗██╗██╗░░░░░██╗░░░░░░██████╗
 * ██╔══██╗██╔════╝░  ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗  ██║░░██║██║██║░░░░░██║░░░░░██╔════╝
 * ██║░░██║██║░░██╗░  ██████╔╝█████╗░░███████║██████╔╝█████╗░░██████╔╝  ███████║██║██║░░░░░██║░░░░░╚█████╗░
 * ██║░░██║██║░░╚██╗  ██╔══██╗██╔══╝░░██╔══██║██╔═══╝░██╔══╝░░██╔══██╗  ██╔══██║██║██║░░░░░██║░░░░░░╚═══██╗
 * ╚█████╔╝╚██████╔╝  ██║░░██║███████╗██║░░██║██║░░░░░███████╗██║░░██║  ██║░░██║██║███████╗███████╗██████╔╝
 * ░╚════╝░░╚═════╝░  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚══════╝╚══════╝╚═════╝░
 *
 */
contract OG_ReaperHills is Base {
    constructor(address _imx)
        ERC721("OG Reaper Hills", "OGRH")
        Mintable(msg.sender, _imx)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(SET_URI_ROLE, msg.sender);
    }

    mapping(uint256 => mapping(string => string)) public tokenAttributes;

    function getBackground(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenAttributes[tokenId]["background"];
    }

    function getOnesie(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["onesie"];
    }

    function getCloak(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["cloak"];
    }

    function getShoes(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["shoes"];
    }

    function getEyes(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["eyes"];
    }

    function getAccessory1(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenAttributes[tokenId]["accessory_1"];
    }

    function getAccessory2(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenAttributes[tokenId]["accessory_2"];
    }

    function getMouth(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["mouth"];
    }

    function getMask(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["mask"];
    }

    function getScytheBlade(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenAttributes[tokenId]["scythe_blade"];
    }

    function getScytheHandle(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenAttributes[tokenId]["scythe_handle"];
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory blueprint
    ) internal override {
        string[] memory attributes = String.split(string(blueprint), ",");
        for (uint256 i; i < attributes.length; i++) {
            string[] memory attribute = String.split(attributes[i], ":");
            require(attribute.length == 2, "Wrong attributes");
            tokenAttributes[id][attribute[0]] = attribute[1];
        }

        _safeMint(to, id);

        emit TokenCreated(id, to);
    }
}
