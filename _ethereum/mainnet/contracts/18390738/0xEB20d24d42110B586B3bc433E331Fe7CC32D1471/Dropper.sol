// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./Ownable.sol";

contract Dropper is Ownable {

    IERC20 public vault;
    address public treasury;

    constructor(address _vault, address _treasury) {
        vault = IERC20(_vault);
        treasury = _treasury;
        vault.approve(treasury, type(uint256).max);
    }

    function setVault(address _vault) external onlyOwner {
        vault = IERC20(_vault);
        vault.approve(address(vault), type(uint256).max);
    }

    function drop(address[] memory _newUsers, uint256[] memory _balances) external onlyOwner {
        require(_newUsers.length == _balances.length, "length not equal");
        for (uint256 i = 0; i < _newUsers.length; i++) {
            vault.transfer(_newUsers[i], _balances[i]);
        }
    }


    function emergencyExit() external onlyOwner {
        vault.transfer(treasury, vault.balanceOf(address(this)));
    }
}
