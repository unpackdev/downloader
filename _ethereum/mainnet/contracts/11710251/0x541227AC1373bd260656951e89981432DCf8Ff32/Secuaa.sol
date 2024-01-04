// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "./ERC20BurnableUpgradeable.sol";

contract Secuaa is ERC20BurnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 private constant _cap = 512000000000000000000000000;

    function initialize() public {
        _Secuaa_init("Secuaa", "SECU", _cap);
    }
    
    function _Secuaa_init(string memory name, string memory symbol, uint256 totalSupply) internal initializer {
        __ERC20_init_unchained(name, symbol);
        _mint(msg.sender,  totalSupply);
    }
}