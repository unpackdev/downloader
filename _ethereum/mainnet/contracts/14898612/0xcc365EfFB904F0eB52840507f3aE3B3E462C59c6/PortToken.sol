// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20.sol";

contract PortToken is ERC20 {
    constructor() ERC20("Teleport", "PORT") {}
}
