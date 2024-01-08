// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
// pragma abicoder v2;
pragma abicoder v2;

import "./ERC20.sol";
import "./SafeMath.sol";

contract Vesting {
    using SafeMath for uint256;

    address public immutable governance;

    IERC20 public token;

    mapping(address => uint256) public oneYearVesting;
    mapping(address => uint256) public twoYearVesting;

    // total supply allowed for one and two year vesting
    uint256 allowedOneYearVesting;
    uint256 claimedOneYearVesting;

    uint256 allowedTwoYearVesting;
    uint256 claimedTwoYearVesting;

    struct VestingData {
        address user;
        uint256 amount;
    }

    // strategic development supply details
    address public development;
    uint256 public developmentIndex;

    // founders and affilates supply details
    address public founders;
    uint256 public foundersIndex;

    // core team supply details
    address public coreTeam;
    uint256 public coreTeamIndex;

    uint256 constant QUARTER = 7776000;

    struct TimeLock {
        address team;
        uint256 amount; // tokens to release per quarter
        uint256 lastClaimed; // timestamp of last claimed
        uint256 claimedSupply; // total claimed supply till date
        uint256 allowedSupply; // total allowed supply
    }

    mapping(uint256 => TimeLock) public timelocks;

    uint256 public immutable startTime;

    uint256 constant BASE = 1000000000000000000;

    constructor(
        address _governance,
        address _development,
        address _founders,
        address _coreTeam
    ) {
        governance = _governance;

        development = _development;
        coreTeam = _coreTeam;

        // initiate Timlock struct
        TimeLock storage timelock;
        
        // set timelock for strategic development team, development team have id of 0
        timelock = timelocks[0];
        timelock.team = _development;
        timelock.amount = 13750000 * BASE;
        timelock.allowedSupply = 110000000 * BASE;
        developmentIndex = 0;

        // set timelock for founders and affilates, founders and affilates have id of 1
        timelock = timelocks[1];
        timelock.team = _founders;
        timelock.amount = 8250000 * BASE;
        timelock.allowedSupply = 66000000 * BASE;
        foundersIndex = 1;

        // set time lock for core time, core team have id of 2
        timelock = timelocks[2];
        timelock.team = _coreTeam;
        timelock.amount = 3437500 * BASE;
        timelock.allowedSupply = 27500000 * BASE;
        coreTeamIndex = 2;

        // set vesting data, tokens allowed to claim in vesting
        allowedOneYearVesting = 37125000 * BASE;
        allowedTwoYearVesting = 37125000 * BASE;

        // set start time
        startTime = block.timestamp;
    }

    // claim tokens
    function claimVested() public {
        require(
            oneYearVesting[msg.sender] > 0 || twoYearVesting[msg.sender] > 0,
            "not allowed"
        );

        if (oneYearVesting[msg.sender] > 0) {
            uint256 amount = oneYearVesting[msg.sender];
            // check if one year has been passed
            require(!(startTime + 31536000 >= block.timestamp), "prohibited");
            require(
                claimedOneYearVesting.add(amount) <= allowedOneYearVesting,
                "limit exceeded"
            );
            oneYearVesting[msg.sender] = 0;
            claimedOneYearVesting = claimedOneYearVesting.add(amount);
            IERC20(token).transfer(msg.sender, amount);
        }
        if (twoYearVesting[msg.sender] > 0) {
            uint256 amount = twoYearVesting[msg.sender];
            // check if two years has been passed
            require(!(startTime + 31536000 * 2 >= block.timestamp), "prohibited");
            require(
                claimedTwoYearVesting.add(amount) <= allowedTwoYearVesting,
                "limit exceeded"
            );
            twoYearVesting[msg.sender] = 0;
            claimedTwoYearVesting = claimedTwoYearVesting.add(amount);
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    function addToVesting(VestingData[] memory _users, uint256 _years) public {
        require(msg.sender == governance, "not authorised");
        if (_years == 1) {
            for (uint256 i = 0; i < _users.length; i++) {
                oneYearVesting[_users[i].user] = oneYearVesting[_users[i].user]
                    .add(_users[i].amount);
            }
        } else if (_years == 2) {
            for (uint256 i = 0; i < _users.length; i++) {
                twoYearVesting[_users[i].user] = twoYearVesting[_users[i].user]
                    .add(_users[i].amount);
            }
        }
    }

    function claimForTeam(uint256 _id, address _to) public {
        TimeLock storage timelock = timelocks[_id];
        // let people start claiming from 1 Jan 2022
        require(block.timestamp >= 1640995200, "Claiming not started");

        // check if the call is receiving from team
        require(timelock.team == msg.sender, "unauthorised call");

        if (timelock.lastClaimed == 0) {
            timelock.lastClaimed = block.timestamp;
            timelock.claimedSupply = timelock.claimedSupply.add(
                timelock.amount
            );
            token.transfer(_to, timelock.amount);
        } else {
            // check if the team is claiming more than allowed
            require(
                timelock.claimedSupply.add(timelock.amount) <=
                    timelock.allowedSupply,
                "already claimed all"
            );

            // check if the quarter is over or not
            require(
                timelock.lastClaimed.add(QUARTER) <= block.timestamp,
                "quater not over"
            );

            // update last claimed tokens and total claimed supply till date
            timelock.lastClaimed = timelock.lastClaimed.add(QUARTER);
            timelock.claimedSupply = timelock.claimedSupply.add(
                timelock.amount
            );

            // transfer tokens to the user
            token.transfer(_to, timelock.amount);
        }
    }

    function addToken(address _token) public {
        require(msg.sender == governance);
        require(address(token) == address(0), "token already has been set");
        token = IERC20(_token);
    }

}
