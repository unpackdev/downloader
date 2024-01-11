//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Plasma is ERC20, Ownable, Pausable {
    mapping(address => bool) public minters;

    constructor(
        string memory name,
        string memory symbol,
        address admin
    ) ERC20(name, symbol) Ownable() {
        Ownable.transferOwnership(admin);
    }

    function mint(address account, uint256 amount) external onlyMinter(msg.sender) whenNotPaused returns (uint256) {
        _mint(account, amount);
        return amount;
    }

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }

    modifier onlyMinter(address minter) {
        require(minters[minter], 'Only minter can mint');
        _;
    }

    function addMultipleMinters(address[] calldata newMinters) external onlyOwner {
        for (uint256 index = 0; index < newMinters.length; index++) {
            address _minter = newMinters[index];
            minters[_minter] = true;
        }
    }

    function removeMultipleMinters(address[] calldata mintersToRemove) external onlyOwner {
        for (uint256 index = 0; index < mintersToRemove.length; index++) {
            address _minter = mintersToRemove[index];
            minters[_minter] = false;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
