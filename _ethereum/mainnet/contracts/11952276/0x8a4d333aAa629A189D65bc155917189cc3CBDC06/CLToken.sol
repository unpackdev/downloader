// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC20.sol";

contract CLToken is ERC20 {
    using SafeMath for uint256;
    uint256 initialSupply = SafeMath.mul(5*10**5, 10**18);
    constructor() ERC20("CryptoLive", "CLT") {
        _mint(msg.sender, initialSupply);
    }
}