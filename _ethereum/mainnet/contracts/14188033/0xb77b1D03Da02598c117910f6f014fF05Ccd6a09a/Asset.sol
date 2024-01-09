// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Mintable.sol";
import "./Strings.sol";

contract Asset is ERC721, Mintable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    // TokenUI for OpenSea
    // per https://docs.opensea.io/docs/metadata-standards

    /**
    * @dev Returns an URI for a given token ID
    */
    function tokenURI(uint256 _tokenId) public pure override returns (string memory) {
        return appendStrings(
            baseURI(),
            Strings.toString(_tokenId)
        );
    }

    // for OpenSea?
    // per https://docs.opensea.io/docs/1-structuring-your-smart-contract
    function baseTokenURI() public pure returns (string memory) {
        return baseURI();
    }

    // this one is just internal? 
    function baseURI() public pure returns (string memory) {
        return 'https://metadata.vyworlds.com/getSkinMeta/';
    } 

    function appendStrings(string memory string1, string memory string2) private pure returns(string memory) {
        return string(abi.encodePacked(string1, string2));
    }

}
