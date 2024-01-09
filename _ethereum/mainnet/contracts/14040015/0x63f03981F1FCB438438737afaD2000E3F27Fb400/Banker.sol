// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";

contract Banker is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal totalWeight;
    EnumerableSet.AddressSet internal wallets;
    mapping(address => uint256) internal team;

    modifier OwnerOrMember() {
        require(
            owner() == _msgSender() || wallets.contains(_msgSender()),
            'Ownable: Caller is not the owner or member'
        );
        _;
    }

    function getWeight() external view returns (uint256) {
        return totalWeight;
    }

    function getMemberWeight(address _wallet) external view returns (uint256) {
        return team[_wallet];
    }

    function addMember(address _wallet, uint256 _weight) external onlyOwner {
        require(!wallets.contains(_wallet), 'TEAM: Member already added');
        require(
            _weight > 0,
            'TEAM: Member can not have 0 weight, kick them off the team ye?'
        );

        totalWeight += _weight;

        wallets.add(_wallet);
        team[_wallet] = _weight;
    }

    function updateMember(address _wallet, uint256 _newWeight)
        external
        onlyOwner
    {
        require(
            wallets.contains(_wallet),
            'TEAM: Member not added, please use add member'
        );
        require(
            _newWeight > 0,
            'TEAM: Member can not have 0 weight, kick them off the team ye?'
        );

        uint256 currentWeight = team[_wallet];
        if (currentWeight <= _newWeight) {
            totalWeight += (_newWeight - currentWeight);
        } else {
            totalWeight -= (currentWeight - _newWeight);
        }

        team[_wallet] = _newWeight;
    }

    function removeMember(address _wallet) external onlyOwner {
        require(
            wallets.contains(_wallet),
            'TEAM: Member not added or already removed, you high?'
        );

        totalWeight -= team[_wallet];
        delete team[_wallet];
        wallets.remove(_wallet);
    }

    function release() external OwnerOrMember {
        uint256 contractBalance = address(this).balance;
        uint256 payPerWeight = contractBalance / totalWeight;

        for (uint256 i = 0; i < wallets.length(); i++) {
            address wallet = wallets.at(i);
            uint256 amountToPay = payPerWeight * team[wallet];
            safeTransferETH(wallet, amountToPay);
        }
    }

    /** Utility Function */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    //to recieve eth
    receive() external payable {}
}
