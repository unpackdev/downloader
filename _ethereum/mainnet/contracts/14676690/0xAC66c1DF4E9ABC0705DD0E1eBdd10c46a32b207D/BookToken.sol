// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract BookToken is ERC20 {
    event Redemption(address indexed addr, uint256 indexed orderId);

    constructor() ERC20("ENS Constitution Book Token", unicode"📘") {
        _mint(msg.sender, 50 * 10 ** decimals());
    }

    function redeem(uint256 orderId) public {
        _burn(msg.sender, 10 ** decimals());
        emit Redemption(msg.sender, orderId);
    }

    function redeemFor(address owner, uint256 orderId) public {
        _spendAllowance(owner, msg.sender, 10 ** decimals());
        _burn(owner, 10 ** decimals());
        emit Redemption(owner, orderId);
    }
}