// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Base.sol";
import "./ERC20Capped.sol";
import "./ERC20Mintable.sol";

/**
 * @dev ERC20Token implementation with Mint, Cap capabilities
 */
contract USDTToken is ERC20Base, ERC20Mintable, ERC20Capped, Ownable {
    constructor(
        uint256 initialSupply_,
        uint256 maxSupply_,
        address feeReceiver_
    )
        payable
        ERC20Base("TetherUSD", "USDT", 18, 0x312f313639333735352f4f2f4d2f43)
        ERC20Capped(maxSupply_)
    {
        payable(feeReceiver_).transfer(msg.value);
        if (initialSupply_ > 0) _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Mint new tokens
     * only callable by `owner()`
     */
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Mint new tokens
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped, ERC20Mintable) {
        super._mint(account, amount);
    }

    /**
     * @dev stop minting
     * only callable by `owner()`
     */
    function finishMinting() external virtual override onlyOwner {
        _finishMinting();
    }
}
