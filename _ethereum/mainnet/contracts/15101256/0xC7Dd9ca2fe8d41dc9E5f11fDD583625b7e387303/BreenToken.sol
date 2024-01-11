// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract BreenToken is ERC20, Ownable {
    constructor() ERC20("Breen", "BRP") {
        _mint(msg.sender, 1_000_000_000 * 1e9);
    }

    function decimals() public pure override returns(uint8) {
        return 9;
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }

    function removeUnsupportedGoveranceToken(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        token.transfer(msg.sender, amount);
    }

    function removeLockedEther(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}
