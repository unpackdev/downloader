// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";

contract BlackList is Ownable {
    mapping (address => bool) public isBlackListed;

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;

        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;

        emit RemovedBlackList(_clearedUser);
    }

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }
}

