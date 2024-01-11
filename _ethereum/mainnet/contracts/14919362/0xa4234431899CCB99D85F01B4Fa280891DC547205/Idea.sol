// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: yungwknd
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./ERC165.sol";

// 💡 by @yungwknd
contract Idea is AdminControl, ICreatorExtensionTokenURI {
    address private _creator;
    string private _baseURI;

    address[] signUps;
    mapping(address => bool) hasSignedUp;
    bool hasEnded = false;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function signUp() public {
      require(block.number <= 15042069, "Too late to signup.");
      require(!hasSignedUp[msg.sender], "Can only sign up once.");
      signUps.push(msg.sender);
      hasSignedUp[msg.sender] = true;
    }

    function endIdea() public adminRequired {
      require(block.number > 15042069, "Can only win after idea ends.");
      require(!hasEnded, "Can only select winner once.");
      hasEnded = true;
      uint randomWinner = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % signUps.length) + 1;
      IERC721CreatorCore(_creator).mintExtension(signUps[randomWinner]);
    }

    function setBaseURI(string memory baseURI) public adminRequired {
      _baseURI = baseURI;
    }

    function tokenURI(address creator, uint256) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return _baseURI;
    }
}
