// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC20.sol";

import "./IBrainsDistributor.sol";

contract Brains is Ownable, ERC20 {

    IBrainsDistributor public distributor;

    event BrainsBurned(uint256 amount);
    event BrainsMinted(uint256 amount);

    constructor(address _distributor) ERC20("BRAINS", "BRAINS") {
        distributor = IBrainsDistributor(_distributor);
    }

    function updateDistributor(address _distributor) external onlyOwner {
        distributor = IBrainsDistributor(_distributor);
    }

    function mint(address holder, uint256 amount) external _onlyDistributor() {
        _mint(holder, amount);
        emit BrainsMinted(amount);
    }

    function burn(address holder, uint256 amount) external _onlyDistributor() {
        _burn(holder, amount);
        emit BrainsBurned(amount);
    }

    modifier _onlyDistributor() {
        require(msg.sender == owner() || msg.sender == address(distributor), "caller_not_distributor");
        _;
    }
}