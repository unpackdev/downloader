// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IBooster.sol";
import "./IRewardStaking.sol";
import "./IFeeDistributor.sol";

/**
 * @title   BoosterHelper
 * @author  AuraFinance
 * @notice  Invokes booster.earmarkRewards for multiple pools and booster.earmarkFees.
 * @dev     Allows anyone to call `earmarkRewards` & `earmarkFees` via the booster.
 */
contract BoosterHelper {
    using SafeERC20 for IERC20;

    IBooster public immutable booster;
    address public immutable crv;

    address public immutable voterProxy = 0x37aeB332D6E57112f1BFE36923a7ee670Ee9278b;

    mapping(address => uint256) public lastTokenTimes;
    IFeeDistributor public feeDistro;

    /**
     * @param _booster      Booster.sol, e.g. 0x631e58246A88c3957763e1469cb52f93BC1dDCF2
     * @param _crv          oLIT  e.g. 0x627fee87d0D9D2c55098A06ac805Db8F98B158Aa
     */
    constructor(address _booster, address _crv) {
        booster = IBooster(_booster);
        crv = _crv;
        
        feeDistro = IFeeDistributor(0x951f99350d816c0E160A2C71DEfE828BdfC17f12);
    }

    function earmarkRewards(uint256[] memory _pids) external returns (uint256) {
        uint256 len = _pids.length;
        require(len > 0, "!pids");

        for (uint256 i = 0; i < len; i++) {
            require(booster.earmarkRewards(_pids[i]), "!earmark reward");
        }
        // Return all incentives to the sender
        uint256 crvBal = IERC20(crv).balanceOf(address(this));
        IERC20(crv).safeTransfer(msg.sender, crvBal);
        return crvBal;
    }

    /**
     * @notice Invoke processIdleRewards for each pool id.
     * @param _pids Array of pool ids
     */
    function processIdleRewards(uint256[] memory _pids) external {
        uint256 len = _pids.length;
        require(len > 0, "!pids");

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = booster.poolInfo(_pids[i]);
            IRewardStaking baseRewardPool = IRewardStaking(poolInfo.crvRewards);
            baseRewardPool.processIdleRewards();
        }
    }

    /**
     * @dev Claims fees from fee claimer, and pings the booster to distribute.
     * @param _tokens Token address to claim fees for.
     * @param _checkpoints Number of checkpoints required previous to claim fees.
     */
    function claimFees(IERC20[] memory _tokens, uint256 _checkpoints) external {
        uint256 len = _tokens.length;
        require(len > 0, "!_tokens");

        // Checkpoint user n times before claiming fees
        for (uint256 i = 0; i < _checkpoints; i++) {
            feeDistro.checkpointUser(voterProxy);
        }

        for (uint256 i = 0; i < len; i++) {
            // Validate if the token should be claimed
            IERC20 token = _tokens[i];
            uint256 tokenTime = feeDistro.getTokenTimeCursor(token);
            require(tokenTime > lastTokenTimes[address(token)], "not time yet");

            IBooster.FeeDistro memory feeDist = booster.feeTokens(address(token));
            uint256 balanceBefore = token.balanceOf(feeDist.rewards);

            booster.earmarkFees(address(token));

            uint256 balanceAfter = token.balanceOf(feeDist.rewards);
            require((balanceAfter - balanceBefore) > 0, "nothing claimed");

            lastTokenTimes[address(token)] = tokenTime;
        }
    }
}
