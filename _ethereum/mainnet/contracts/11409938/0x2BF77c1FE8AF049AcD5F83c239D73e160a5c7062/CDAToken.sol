// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
import "./ERC20.sol";
contract CDAToken is ERC20 {
    constructor(uint256 initialSupply) public ERC20("CubeDao Token", "CDA") {
        _mint(msg.sender, initialSupply);
    }
}