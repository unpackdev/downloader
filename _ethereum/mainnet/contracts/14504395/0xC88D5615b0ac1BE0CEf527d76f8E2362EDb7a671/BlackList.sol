// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

contract BlackList is OwnableUpgradeable {
    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    mapping(address => bool) public isBlackListed;

    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds(address _blackListedUser) public virtual onlyOwner {}
}
