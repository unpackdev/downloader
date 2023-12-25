// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./Ownable.sol";

contract RGBPOINTS is ERC20, ERC20Permit, ERC20Votes, Ownable {
    error InvalidMinter();

    address public immutable nft = msg.sender;

    constructor(address initialOwner) ERC20("RGB POINTS", "RGB") ERC20Permit("RGB POINTS") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public {
        if (msg.sender != nft) revert InvalidMinter();
        _mint(to, amount * 10 ** decimals());
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
