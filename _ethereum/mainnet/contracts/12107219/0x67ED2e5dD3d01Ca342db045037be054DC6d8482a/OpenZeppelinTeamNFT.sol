// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./AccessControl.sol";

contract OpenZeppelinTeamNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721("OpenZeppelin Team NFT", "OZT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://openzeppelin.github.io/openzeppelin-team-nft/api/token/";
    }

    function safeMint(address to, uint256 tokenId) public {
        require(hasRole(MINTER_ROLE, msg.sender));
        _safeMint(to, tokenId);
    }
}