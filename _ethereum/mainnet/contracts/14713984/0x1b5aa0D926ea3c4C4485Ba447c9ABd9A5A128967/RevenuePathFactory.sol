// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Clones.sol";

import "./RevenuePath.sol";

contract RevenuePathFactory is Ownable, Pausable {
    address immutable pathImplementation;

    event RevenuePathCreated(address indexed _from, address indexed _walletAddress, string _walletName);

    constructor()  {
        pathImplementation = address(new RevenuePath());
    }


    function createRevenuePath(address[] memory payees, uint256[] memory shares, string memory name) whenNotPaused external returns (address) {

        address payable clone = payable(Clones.clone(pathImplementation));
        RevenuePath(clone).initialize(payees, shares, name);

        // Loop over every payee and emit wallet created event. 
        // Note: This does create a linear cost increase as the length of payees rise.
        for(uint256 i = 0; i < payees.length; i++) {
            emit RevenuePathCreated(payees[i], clone, name);
        }

        return clone;
    }

    function pause() onlyOwner external {
        _pause();
    }

    function unpause() onlyOwner external {
        _unpause();
    }
}