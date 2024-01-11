// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";

/// @custom:security-contact security@shapeshift.io
contract VFOX is ERC20, Ownable, ERC20Permit {
    constructor() ERC20("vFOX", "vFOX") ERC20Permit("vFOX") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}