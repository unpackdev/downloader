// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IBrains.sol";
import "./IBrainsDistributor.sol";

contract BrainsDistributor is Ownable, IBrainsDistributor {

    IBrains public brains;

    mapping(address => bool) public accessors;

    uint256 public immutable maximumSupply = 4_000_000_000;

    event BrainsUpdated(address updated);

    function addAccessor(address accessor) external onlyOwner {
        accessors[accessor] = true;
    }

    function updateAccessor(address oldAccessor, address accessor) external onlyOwner {
        delete accessors[oldAccessor];
        accessors[accessor] = true;
    }

    function removeAccessor(address accessor) external onlyOwner {
        delete accessors[accessor];
    }

    function updateBrains(address _brains) external onlyOwner {
        require(address(brains) != _brains, "brains_address_same");
        brains = IBrains(_brains);
        emit BrainsUpdated(_brains);
    }

    function burnBrainsFor(address holder, uint256 amount) external override validAccessor _hasBrains(holder, amount) {
        brains.burn(holder, amount);
    }

    function mintBrainsFor(address holder, uint256 amount) external override validAccessor {
        require(brains.totalSupply() + amount <= maximumSupply, "exceeds_maximum_supply");
        brains.mint(holder, amount);
    }

    function remainingBrains() external override view returns (uint256 amount) {
        amount = maximumSupply - brains.totalSupply();
    }

    modifier _hasBrains(address holder, uint256 amount) {
        require(brains.balanceOf(holder) >= amount, "insufficient_brains");
        _;
    }
    
    modifier validAccessor() {
        require(msg.sender == owner() || accessors[msg.sender], "invalid_accessor");
        _;
    }
}