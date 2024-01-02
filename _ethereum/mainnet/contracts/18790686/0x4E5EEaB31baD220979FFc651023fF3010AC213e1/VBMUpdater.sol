// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20.sol";

struct Point {
    uint256 bias;
    uint256 slope;
}

struct VotedSlope {
    uint256 slope;
    uint256 power;
    uint256 end;
}

/// @notice Bounty struct requirements.
struct Bounty {
    // Address of the target gauge.
    address gauge;
    // Manager.
    address manager;
    // Address of the ERC20 used for rewards.
    address rewardToken;
    // Number of periods.
    uint8 numberOfPeriods;
    // Timestamp where the bounty become unclaimable.
    uint256 endTimestamp;
    // Max Price per vote.
    uint256 maxRewardPerVote;
    // Total Reward Added.
    uint256 totalRewardAmount;
    // Blacklisted addresses.
    address[] blacklist;
}

interface ISDTGaugeController {
    function checkpoint_gauge(address _gauge) external;
    function points_weight(address, uint256) external view returns (Point memory);
    function vote_user_slopes(address, address) external view returns (VotedSlope memory);
    function last_user_vote(address, address) external view returns (uint256);
}

interface ISDTDIstributor {
    function distributeMulti(address[] calldata gaugeAddr) external;
}

interface IVBM {
    function updateBounty() external;
    function bountyId() external view returns(uint256);
    function platform() external view returns(address);
}

interface IPlatform {
    function getBlacklistedAddressesPerBounty(uint256 bountyID) external view returns(address[] memory);
    function getCurrentPeriod() external view returns(uint256);
    function getBounty(uint256 bountyID) external view returns(Bounty memory);
}

contract VBMUpdater {
    
    /// @notice Week in seconds.
    uint256 private constant _WEEK = 1 weeks;

    function checkpointAndUpdate(address _gaugeController, address _distributor, address _tokenReward, address[] calldata _gauges) external {
        
        uint256 length = _gauges.length;
        for(uint256 i = 0; i < length;) {
            ISDTGaugeController(_gaugeController).checkpoint_gauge(_gauges[i]);

            unchecked {
                ++i;
            }
        }

        ISDTDIstributor(_distributor).distributeMulti(_gauges);

        for(uint256 i = 0; i < length; ++i) {
            address gauge = _gauges[i];
            uint256 tokenRewardBalance = ERC20(_tokenReward).balanceOf(gauge);
            if(tokenRewardBalance == 0) {
                continue;        
            }

            address platform = IVBM(gauge).platform();
            uint256 bountyID = IVBM(gauge).bountyId();
            uint256 period = IPlatform(platform).getCurrentPeriod();
            Bounty memory bounty = IPlatform(platform).getBounty(bountyID);
                
            if(period >= bounty.endTimestamp) {
                // Closable, can't update
                continue;  
            }

            address[] memory blacklistedAddresses = IPlatform(platform).getBlacklistedAddressesPerBounty(bountyID);
            uint256 gaugeBias = _getAdjustedBias(_gaugeController, gauge, blacklistedAddresses, period);
                
            if(gaugeBias > 0) {
                IVBM(gauge).updateBounty();    
            }
        }
    }

    function _getAdjustedBias(address _gaugeController, address _gauge, address[] memory _addressesBlacklisted, uint256 _period)
        public
        view
        returns (uint256 gaugeBias)
    {
        // Cache the user slope.
        VotedSlope memory userSlope;
        // Bias
        uint256 _bias;
        // Last Vote
        uint256 _lastVote;
        // Cache the length of the array.
        uint256 length = _addressesBlacklisted.length;
        // Cache blacklist.
        // Get the gauge slope.
        gaugeBias = ISDTGaugeController(_gaugeController).points_weight(_gauge, _period).bias;

        for (uint256 i = 0; i < length;) {
            // Get the user slope.
            userSlope = ISDTGaugeController(_gaugeController).vote_user_slopes(_addressesBlacklisted[i], _gauge);
            _lastVote = ISDTGaugeController(_gaugeController).last_user_vote(_addressesBlacklisted[i], _gauge);
            if (_period > _lastVote) {
                _bias = _getAddrBias(userSlope.slope, userSlope.end, _period);
                gaugeBias -= _bias;
            }
            // Increment i.
            unchecked {
                ++i;
            }
        }
    }

    function _getAddrBias(uint256 userSlope, uint256 endLockTime, uint256 currentPeriod)
        public
        pure
        returns (uint256)
    {
        if (currentPeriod + _WEEK >= endLockTime) return 0;
        return userSlope * (endLockTime - currentPeriod);
    }
}
