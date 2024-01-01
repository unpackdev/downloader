// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;
pragma abicoder v2;

import "./ERC20Burnable.sol";
import "./DastraERC20.sol";

contract DastraERC20Burnable is DastraERC20, ERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 _decimals,
        uint256 cap,
        address trustedForwarder,
        address owner
    ) DastraERC20(name, symbol, initialSupply, _decimals, cap, trustedForwarder, owner) payable {
        
    }

    function decimals() public view virtual override(DastraERC20, ERC20) returns (uint8) {
        return super.decimals();
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        return super._mint(account, amount);
    }

    function _msgSender() internal view virtual override(Context, DastraERC20) returns (address sender) {
        return DastraERC20._msgSender();
    }

    function _msgData() internal view virtual override(Context, DastraERC20) returns (bytes calldata) {
        return DastraERC20._msgData();
    }
}