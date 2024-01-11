//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./RiftRootContracts.sol";

abstract contract RiftRootGP is Initializable, RiftRootContracts {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function __RiftRootGP_init() internal initializer {
        RiftRootContracts.__RiftRootContracts_init();
    }

    function updateStakeSettings(uint256 _amountNeededToOpenPortal) external onlyAdminOrOwner {
        amountNeededToOpenPortal = _amountNeededToOpenPortal;
    }

    function stakeGP(uint256 _amount) external {
        require(_amount > 0, "Must stake some GP.");
        amountCurrentlyStaked += _amount;
        addressToGPStaked[msg.sender] += _amount;

        if(!addressesStaked.contains(msg.sender)) {
            addressesStaked.add(msg.sender);
        }

        bool _wasTransferred = gp.transferFrom(msg.sender, address(this), _amount);
        require(_wasTransferred, "GP not transferred");
    }

    function unstakeGP(uint256 _amount) external {
        uint256 _amountStaked = addressToGPStaked[msg.sender];
        require(_amountStaked >= _amount, "Too much GP to unstake");

        amountCurrentlyStaked -= _amount;
        addressToGPStaked[msg.sender] -= _amount;

        if(addressToGPStaked[msg.sender] == 0) {
            addressesStaked.remove(msg.sender);
        }

        bool _wasTransferred = gp.transfer(msg.sender, _amount);
        require(_wasTransferred, "GP not transferred");
    }

}