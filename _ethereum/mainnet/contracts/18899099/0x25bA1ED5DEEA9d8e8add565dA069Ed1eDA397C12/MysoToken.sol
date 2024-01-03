// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract MysoToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    function initialize() public initializer {
        ERC20Upgradeable.__ERC20_init("MYSO Token", "MYT");
        _transferOwnership(msg.sender);
        _mint(msg.sender, 100000000 * 1e18);
    }
}
