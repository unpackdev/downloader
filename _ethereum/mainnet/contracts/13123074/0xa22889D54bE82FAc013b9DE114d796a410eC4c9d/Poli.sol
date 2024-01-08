// SPDX-License-Identifier: CAL
pragma solidity ^0.8.6;

import "./ERC20.sol";

contract Poli is ERC20 {
    constructor(address distributor_) ERC20("NaeemZ", "MNA") { _mint(distributor_, 10 ** (9 + 18)); }
}