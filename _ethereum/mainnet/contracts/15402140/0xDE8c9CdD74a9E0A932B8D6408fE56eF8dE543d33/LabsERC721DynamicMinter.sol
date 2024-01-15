// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: PuppetSamurai
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./LabsERC721DynamicMinterBase.sol";
import "./ILabsERC721DynamicMinter.sol";

/*
*/
 
contract LabsERC721DynamicMinter is ILabsERC721DynamicMinter, LabsERC721DynamicMinterBase, Pausable, ReentrancyGuard, AdminControl {

    constructor(address creator, string memory prefix, uint256 mintPrice, uint256 mintMax) {
        _initialize(creator, prefix, mintPrice, mintMax);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, LabsERC721DynamicMinterBase) returns (bool) {
        return interfaceId == type(ILabsERC721DynamicMinter).interfaceId || AdminControl.supportsInterface(interfaceId) || LabsERC721DynamicMinterBase.supportsInterface(interfaceId);
    }

    function premint(address[] memory to) external override adminRequired {
        _premint(to);
    }

    function mint(uint256 quantity) external override payable whenNotPaused nonReentrant {
        _mint(quantity);
    }

    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    function setMintPrice(uint256 mintPrice) external override adminRequired {
        _setMintPrice(mintPrice);
    }

    function setMaxMints(uint256 mintMax) external override adminRequired {
        _setMaxMints(mintMax);
    }
    
    function maxMints() external view virtual returns (uint256) {
    	return _getMaxMints();
    }

    function withdraw(address to, uint amount) external override adminRequired {
        _withdraw(to, amount);
    }

    function pause() external override adminRequired {
        _pause();
    }

    function unpause() external override adminRequired {
        _unpause();
    }        
}
