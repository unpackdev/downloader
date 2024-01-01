// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./StakeTONStorage.sol";
import "./console.sol";

interface IStake {
     function isAdmin(address _owner) external returns (bool);
}

/// @title The connector that integrates tokamak
contract TokamakStakeUpgrade7 is
    StakeTONStorage
{

    function changeAddresses(address _depositManager, address _seigManager, address _tokamakLayer2) external {
        require(IStake(address(this)).isAdmin(msg.sender), "caller is not admin");

        require(
            depositManager != depositManager || seigManager != _seigManager || tokamakLayer2 != _tokamakLayer2,
            "same address"
        );

        depositManager = _depositManager;
        seigManager = _seigManager;
        tokamakLayer2 = _tokamakLayer2;
    }

}
