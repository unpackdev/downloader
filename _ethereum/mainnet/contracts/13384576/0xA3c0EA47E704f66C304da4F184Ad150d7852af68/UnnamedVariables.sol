// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract UnnamedVariables is ERC721URIStorage, AccessControl {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor() ERC721("UnnamedVariables", "UNVAR") {
        // Grant the contract deployer the default admin role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createNFT(string memory tokenURI) public onlyRole(MINTER_ROLE) returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }

    function burnNFT(uint256 tokenid) public returns (uint256) {
        require(msg.sender == ownerOf(tokenid), "Caller is not token owner");
        _burn(tokenid);
        return tokenid;
    }

    //For Data NFTs external APIs may be used, update tokenURI is required in case API dies, data source can be updated.
    function updateNFTMetadata(uint256 tokenid, string memory newTokenURI) public returns (uint256) {
        require(msg.sender == ownerOf(tokenid), "Caller is not token owner");
        _setTokenURI(tokenid, newTokenURI);
        return tokenid;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}