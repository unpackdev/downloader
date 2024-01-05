// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;

import "./OVLTokenTypes.sol";
import "./SafeMath.sol";

import "./IDeltaToken.sol";

contract TeamShareTimelock {
    using SafeMath for uint256;
    
    IDeltaToken immutable public DELTA_TOKEN;

    uint256 constant private TOTAL_EXPECTED_AMOUNT = 225_000 ether;

    /// @dev first month is paid out at the start
    uint256 constant private INITIAL_CLAIM = 18_750 ether;
    uint256 constant private VESTING_AMOUNT = TOTAL_EXPECTED_AMOUNT - INITIAL_CLAIM;

    /// @dev 11 months since we advance the first month so it starts
    /// vesting after 30 days for 11 months.
    uint256 constant public TOTAL_VESTING_TIME = 330 days;
    address immutable public TO;

    uint256 public vestingStartTimestamp;
    uint256 public vestingEndTimestamp;
    uint256 public totalClaimed;

    constructor(address _deltaToken, address _to) {
        DELTA_TOKEN = IDeltaToken(_deltaToken);
        TO = _to;
    }

    function initialize() public {
        require(vestingStartTimestamp == 0, 'ALREADY_INITIALIZED');

        DELTA_TOKEN.transferFrom(msg.sender, address(this), TOTAL_EXPECTED_AMOUNT);
        require(DELTA_TOKEN.balanceOf(address(this)) == TOTAL_EXPECTED_AMOUNT, 'INSUFFICIENT_AMOUNT');

        // Verify whitelistings
        UserInformation memory accountInfo = DELTA_TOKEN.userInformation(address(this));
        require(accountInfo.noVestingWhitelisted == true, 'NOT_NOVESTING_WHITELISTED');
        require(accountInfo.fullSenderWhitelisted == true, 'NOT_FULLSENDER_WHITELISTED');

        // Start vesting after 1 month since we advanced the complete first month
        vestingStartTimestamp = block.timestamp + 30 days;

        // Vesting ends in 11 months after that
        vestingEndTimestamp = vestingStartTimestamp + TOTAL_VESTING_TIME;

        // send out the first month right away
        DELTA_TOKEN.transfer(TO, INITIAL_CLAIM);
    }

    function claim() public {
        require(msg.sender == TO, 'INVALID_SENDER');

        // It should never be possible to transfer more
        // than VESTING_AMOUNT (206250 DELTA tokens) from this contract.
        require(totalClaimed < VESTING_AMOUNT, 'ALL_CLAIMED');

        uint256 claimed = claimable();
        DELTA_TOKEN.transfer(TO, claimed);

        totalClaimed = totalClaimed.add(claimed);
    }

    function claimable() public view returns (uint256) {
        // Nothing claimable prior to the first month since we send an advance the first
        // one and don't report any claimable when it's all claimed already.
        // This, to ensure the contract is not used to fullSend arbitrary delta tokens.
        if(block.timestamp < vestingStartTimestamp || totalClaimed >= VESTING_AMOUNT) {
            return 0;
        }
        
        // Vesting has ended, send-out all the balance
        if (block.timestamp >= vestingEndTimestamp) {
            return DELTA_TOKEN.balanceOf(address(this));
        }

        uint256 secondsSinceVestingStarted = block.timestamp - vestingStartTimestamp;
        return VESTING_AMOUNT.mul(secondsSinceVestingStarted).div(TOTAL_VESTING_TIME).sub(totalClaimed);
    }

    receive() external payable {
        revert();
    }
}
