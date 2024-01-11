//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./ERC20.sol";

///@title BigBrainKids ERC20 Contract

contract Neuron is ERC20, ERC20Burnable, AccessControlEnumerable {
    uint256 public constant MAX_SUPPLY = 20000000 * 1e18;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Neuron", "NEURON") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 remainingSupply = MAX_SUPPLY - totalSupply();
        require(remainingSupply > 0, "Neuron MAX_SUPPLY exceeded!");
        _mint(to, remainingSupply > amount ? amount : remainingSupply);
    }
}
