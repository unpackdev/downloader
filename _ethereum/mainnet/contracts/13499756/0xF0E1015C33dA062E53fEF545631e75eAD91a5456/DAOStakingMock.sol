// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.1;

import "./IDAOStaking.sol";

contract DAOStakingMock {
    uint256 private _stakeborgTokenStaked;
    mapping(address => uint256) private _votingPowerAtTs;
    bool public lockCreatorBalanceHasBeenCalled;
    bool public withdrawHasBeenCalled;

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp) external view returns (uint256){
        return _votingPowerAtTs[user];
    }

    function votingPower(address user) external view returns (uint256) {
        return _votingPowerAtTs[user];
    }

    function stakeborgTokenStaked() external view returns (uint256) {
        return _stakeborgTokenStaked;
    }

    function stakeborgTokenStakedAtTs(uint256 ts) public view returns (uint256) {
        return _stakeborgTokenStaked;
    }

    function setstakeborgTokenStaked(uint256 val) public {
        _stakeborgTokenStaked = val;
    }

    function setVotingPower(address user, uint256 val) public {
        _votingPowerAtTs[user] = val;
    }

    function withdraw(uint256 amount) external {
        withdrawHasBeenCalled = true;
    }
}
