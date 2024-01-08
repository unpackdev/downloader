// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";

contract Capital is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    constructor (uint256 initialSupply) ERC20("Capital", "CPL") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 5;
    }

    function recoverToken(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }
}
