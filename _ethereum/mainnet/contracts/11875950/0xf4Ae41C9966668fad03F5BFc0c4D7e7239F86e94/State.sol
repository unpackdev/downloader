// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import "./SafeMath.sol";
import "./UQ112x112.sol";
import "./IBurnableERC20.sol";
import "./IUniswapOracle.sol";
import "./Ownable.sol";

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract State is Ownable {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    // Token which will be used to charge penalty or reward incentives.
    IBurnableERC20 public incentiveToken;

    // Pair that will be using this contract.
    address public pairAddress;

    // Token which is the main token of a protocol.
    address public protocolTokenAddress;

    // A fraction of penalty is being used to fund the ecosystem.
    address ecosystemFund;

    // Used to track the latest twap price.
    IUniswapOracle public uniswapOracle;

    // Default price of when reward is to be given.
    uint256 public rewardPrice = uint256(110).mul(1e16); // ~1.2$
    // Default price of when penalty is to be charged.
    uint256 public penaltyPrice = uint256(110).mul(1e16); // ~0.95$

    // Should we use oracle to get diff. price feeds or not.
    bool public useOracle = false;

    bool public isTokenAProtocolToken = true;

    // Max. reward per hour to be given out.
    uint256 public rewardPerEpoch = 0;

    // Multipiler for rewards and penalty.
    uint256 public rewardMultiplier = 5 * 100000; // 5x
    uint256 public penaltyMultiplier = 10 * 100000; // 10x

    // Percentage of penalty to be burnt from the token's supply.
    uint256 public penaltyToBurn = uint256(45); // In %.
    // Percentage of penalty to be kept inside this contract to act as fund for rewards.
    uint256 public penaltyToKeep = uint256(45); // In %.
    // Percentage of penalty to be redirected to diff. funds(currently ecosystem fund).
    uint256 public penaltyToRedirect = uint256(10); // In %.

    // The reward which can be given out during this epoch.
    uint256 public availableRewardThisEpoch = 0;
    uint256 public rewardsThisEpoch = 0;

    // The reward which has been collected through the penalities accross all epochs.
    uint256 public rewardCollectedFromPenalties = 0;

    uint256 public arthToMahaRate;

    /**
     * Modifier.
     */
    modifier onlyPair {
        require(msg.sender == pairAddress, 'Controller: Forbidden');
        _;
    }
}
