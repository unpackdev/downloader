// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";

contract Hodlberg is ERC721PresetMinterPauserAutoIdUpgradeable {

    mapping(uint256 => address) private _originalOwner;
    string private _contractURI;

    function init() public initializer {
        __ERC721PresetMinterPauserAutoId_init(
            "Hodlberg",
            "HDLBRG",
            "https://tokenapi.hodlberg.com/"
        );
        _contractURI = "https://hodlberg.com/metadata";
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function changeContractURI(string memory newContractURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721: must have admin role to change");
        _contractURI = newContractURI;
    }

    function changeBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721: must have admin role to change");
        _setBaseURI(baseURI);
    }

    function mintToken(bytes32 ticket) public {
		require(ticket != 0x0, "Ticket cannot be blank");
        uint32 tokenId;
        tokenId = uint32(uint256(keccak256(abi.encodePacked(_msgSender(), ticket))));

        _safeMint(_msgSender(), tokenId);
        _originalOwner[tokenId] = _msgSender();
    }

    function getOriginalOwner(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: token doesn't exist");
        return _originalOwner[tokenId];
    }

    function isOriginalOwner(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ERC721: token doesn't exist");
        return _originalOwner[tokenId] == ownerOf(tokenId);
    }

}