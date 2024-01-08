// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract Baloney is ERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxSupply;

    constructor(uint256 _maxSupply, uint256 vaultSharePercent, address vaultAddress) ERC20("Baloney", "BALONEY") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        maxSupply = _maxSupply;

        uint256 vaultShareAmount = _maxSupply.div(100).mul(vaultSharePercent);
        _mint(vaultAddress, vaultShareAmount);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply().add(amount) <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }
}
