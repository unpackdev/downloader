// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./SafeERC20.sol";


contract TMM is ERC20Permit, Ownable {
    using SafeERC20 for IERC20;

    constructor(address owner)
        ERC20("Take My Muffin", "TMM")
        ERC20Permit("Take My Muffin")
    {
        _mint(msg.sender, 275_000e6);
        transferOwnership(owner);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }
}
