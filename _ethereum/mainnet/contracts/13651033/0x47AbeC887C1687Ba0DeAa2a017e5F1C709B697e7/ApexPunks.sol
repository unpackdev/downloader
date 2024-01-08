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

    mapping(uint256 => mapping(string => string)) public tokenAttributes;

    function getHat(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["hat"];
    }

    function getEyes(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["eyes"];
    }

    function getFur(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["fur"];
    }

    function getMouth(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["mouth"];
    }

    function getBackground(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenAttributes[tokenId]["background"];
    }

    function getClothes(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["clothes"];
    }

    function getEarring(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["earring"];
    }

    function getSpecies(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["species"];
    }

    function getLegendary(uint256 tokenId) public view returns (string memory) {
        return tokenAttributes[tokenId]["legendary"];
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
