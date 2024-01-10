// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./IRevenueSplit.sol";

contract RevenueSplitFactory is Initializable, OwnableUpgradeable {
    event RevenueSplitCreated(address indexed revenueSplitAddress);

    address private _implementation;

    function initialize(address implementation) public initializer {
        __Ownable_init();
        _implementation = implementation;
    }

    function setImplementation(address implementation) public onlyOwner {
        _implementation = implementation;
    }

    function createRevenueSplit(
        string memory name,
        address[] calldata payees,
        uint256[] calldata shares
    ) external {
        address deployed = _create(name, payees, shares);

        emit RevenueSplitCreated(deployed);
    }

    function _create(
        string memory name,
        address[] calldata payees,
        uint256[] calldata shares
    ) private returns (address) {
        address deployed = ClonesUpgradeable.clone(_implementation);
        IRevenueSplit revenueSplit = IRevenueSplit(deployed);
        revenueSplit.initialize(name, payees, shares);

        return deployed;
    }
}
