// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract NUTS is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("NutsDAO", "NUTS") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function recoverERC20(address tokenAddress) public onlyOwner {
        uint256 tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenAmount > 0);
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
