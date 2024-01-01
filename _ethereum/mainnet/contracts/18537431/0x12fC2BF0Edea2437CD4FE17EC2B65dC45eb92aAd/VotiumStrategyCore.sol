// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./IVotiumMerkleStash.sol";
import "./ISnapshotDelegationRegistry.sol";
import "./ILockedCvx.sol";
import "./IClaimZap.sol";
import "./ICrvEthPool.sol";
import "./IAfEth.sol";
import "./ERC20Upgradeable.sol";
import "./AggregatorV3Interface.sol";

/// @title Votium Strategy Token internal functions
/// @author Asymmetry Finance
contract VotiumStrategyCore is
    Initializable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    using SafeERC20 for IERC20;

    address public constant SNAPSHOT_DELEGATE_REGISTRY =
        0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446;
    address constant CVX_ADDRESS = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address constant VLCVX_ADDRESS = 0x72a19342e8F1838460eBFCCEf09F6585e32db86E;

    struct SwapData {
        address sellToken;
        address spender;
        address swapTarget;
        bytes swapCallData;
    }

    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 updatedAt;
        bool success;
    }

    uint256 public cvxUnlockObligations;
    address public rewarder;
    address public manager;

    AggregatorV3Interface public chainlinkCvxEthFeed;
    uint256 latestWithdrawId;

    uint256 trackedCvxBalance;
    uint256 minEpoch;

    bool public cvxTrackingInitialized;

    // used to add storage variables in the future
    uint256[18] private __gap;

    event DepositReward(
        uint256 indexed newPrice,
        uint256 indexed ethAmount,
        uint256 indexed cvxAmount
    );

    event FailedToSell(address indexed tokenAddress);
    event MinEpochSet(uint256 indexed newMinEpoch);
    event RewarderSet(address indexed newRewarder);

    error SwapFailed(uint256 index);
    error ChainlinkFailed();
    error NotRewarder();
    error InvalidLockedAmount();
    error InvalidAmount();
    error NotOwner();
    error WithdrawNotReady();
    error AlreadyWithdrawn();
    error NotManager();
    error MinOut();
    error StaleAction();
    error AlreadyInitialized();

    /**
        @notice - Sets the address for the chainlink feed
        @param _cvxEthFeedAddress - Address of the chainlink feed
    */
    function setChainlinkCvxEthFeed(
        address _cvxEthFeedAddress
    ) external onlyOwner {
        chainlinkCvxEthFeed = AggregatorV3Interface(_cvxEthFeedAddress);
    }

    modifier onlyRewarder() {
        if (msg.sender != rewarder) revert NotRewarder();
        _;
    }

    modifier onlyManager() {
        if (address(manager) != address(0) && msg.sender != manager)
            revert NotManager();
        _;
    }

    // As recommended by https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
        @notice - Function to initialize values for the contracts
        @dev - This replaces the constructor for upgradeable contracts
        @param _owner - Address of the owner of the contract (asym multisig)
        @param _rewarder - Address of the rewarder contract (reward oracle)
        @param _manager - Address of the manager contract (afEth)
    */
    function initialize(
        address _owner,
        address _rewarder,
        address _manager
    ) external initializer {
        bytes32 VotiumVoteDelegationId = 0x6376782e65746800000000000000000000000000000000000000000000000000;
        address DelegationRegistry = 0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446;
        address votiumVoteProxyAddress = 0xde1E6A7ED0ad3F61D531a8a78E83CcDdbd6E0c49;
        ISnapshotDelegationRegistry(DelegationRegistry).setDelegate(
            VotiumVoteDelegationId,
            votiumVoteProxyAddress
        );
        rewarder = _rewarder;
        manager = _manager;
        minEpoch = 2;
        __ERC20_init("Votium AfEth Strategy", "vAfEth");
        _transferOwnership(_owner);
        chainlinkCvxEthFeed = AggregatorV3Interface(
            0xC9CbF687f43176B302F03f5e58470b77D07c61c6
        );
    }

    function initializeCvxBalanceTracking() external onlyOwner {
        if (cvxTrackingInitialized) revert AlreadyWithdrawn();
        cvxTrackingInitialized = true;
        trackedCvxBalance = IERC20(CVX_ADDRESS).balanceOf(address(this));
    }

    /**
     * @notice - Function to set the address of the rewarder account that periodically claims rewards
     * @param _rewarder - Address of the rewarder account
     */
    function setRewarder(address _rewarder) external onlyOwner {
        rewarder = _rewarder;
        emit RewarderSet(_rewarder);
    }

    /**
     * @notice - Function to set the address of the rewarder account that periodically claims rewards
     * @param _minEpoch - Address of the rewarder account
     */
    function setMinEpoch(uint256 _minEpoch) external onlyOwner {
        minEpoch = _minEpoch;
        emit MinEpochSet(_minEpoch);
    }

    /**
     * @notice - The amount of cvx in the entire system
     * @return - Amount of cvx in the entire system
     */
    function cvxInSystem() public view returns (uint256) {
        uint256 total = ILockedCvx(VLCVX_ADDRESS).lockedBalanceOf(
            address(this)
        );
        return total + trackedCvxBalance;
    }

    /**
     * @notice - Gets price of vAfEth in cvx
     * @return - Price of vAfEth in cvx
     */
    function cvxPerVotium() public view returns (uint256) {
        uint256 supply = totalSupply();
        uint256 totalCvx = cvxInSystem() - cvxUnlockObligations;
        if (supply == 0 || totalCvx == 0) return 1e18;
        return (totalCvx * 1e18) / supply;
    }

    /**
        @notice - Eth per cvx (chainlink)
        @param _validate - Whether or not to validate the chainlink response
        @return - Price of cvx in eth
     */
    function ethPerCvx(bool _validate) public view returns (uint256) {
        ChainlinkResponse memory cl;
        try chainlinkCvxEthFeed.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 updatedAt,
            uint80 /* answeredInRound */
        ) {
            cl.success = true;
            cl.roundId = roundId;
            cl.answer = answer;
            cl.updatedAt = updatedAt;
        } catch {
            cl.success = false;
        }
        // verify chainlink response
        if (
            (!_validate ||
                (cl.success == true &&
                    cl.roundId != 0 &&
                    cl.answer > 0 &&
                    cl.updatedAt != 0 &&
                    cl.updatedAt <= block.timestamp &&
                    block.timestamp - cl.updatedAt <= 25 hours))
        ) {
            return uint256(cl.answer);
        } else {
            revert ChainlinkFailed();
        }
    }

    /**
     * @notice Allow rewarder oracle account to claim rewards
     * @param _claimProofs - Array of claim proofs
     */
    function claimRewards(
        IVotiumMerkleStash.ClaimParam[] calldata _claimProofs
    ) external onlyRewarder {
        claimVotiumRewards(_claimProofs);
        claimVlCvxRewards();
    }

    /**
     * @notice - Sells amount of eth from votium contract
     * @dev - Puts it into safEthStrategy or votiumStrategy, whichever is underweight.
     * @param _amount - Amount of eth to sell for cvx
     * @param _cvxMinout - Minimum amount of cvx to receive
     * */
    function depositRewards(
        uint256 _amount,
        uint256 _cvxMinout
    ) public payable onlyManager {
        uint256 cvxAmount = buyCvx(_amount);
        if (cvxAmount < _cvxMinout) revert MinOut();
        IERC20(CVX_ADDRESS).approve(VLCVX_ADDRESS, cvxAmount);
        ILockedCvx(VLCVX_ADDRESS).lock(address(this), cvxAmount, 0);
        trackedCvxBalance -= cvxAmount;
        emit DepositReward(cvxPerVotium(), _amount, cvxAmount);
    }

    /**
     * @notice - Allows owner to withdraw any stuck erc20 tokens
     * @dev - Lets us handle any that were not successfully sold via cvx
     * @param _token - Address of the token to withdraw
     */
    function withdrawStuckTokens(address _token) external onlyOwner {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        if (_token == CVX_ADDRESS) {
            if (tokenBalance <= trackedCvxBalance) revert InvalidAmount();
            tokenBalance -= trackedCvxBalance;
        }

        IERC20(_token).safeTransfer(msg.sender, tokenBalance);
    }

    /**
     * @notice - Internal utility function to buy cvx using eth
     * @param _ethAmountIn - Amount of eth to spend
     * @return cvxAmountOut - Amount of cvx bought
     */
    function buyCvx(
        uint256 _ethAmountIn
    ) internal returns (uint256 cvxAmountOut) {
        address CVX_ETH_CRV_POOL_ADDRESS = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
        // eth -> cvx
        cvxAmountOut = ICrvEthPool(CVX_ETH_CRV_POOL_ADDRESS)
            .exchange_underlying{value: _ethAmountIn}(
            0,
            1,
            _ethAmountIn,
            0 // this is handled at the afEth level
        );
        trackedCvxBalance += cvxAmountOut;
    }

    /**
     * @notice - Internal utility function to sell cvx for eth
     * @param _cvxAmountIn - Amount of cvx to sell
     * @return ethAmountOut - Amount of eth received
     */
    function sellCvx(
        uint256 _cvxAmountIn
    ) internal returns (uint256 ethAmountOut) {
        address CVX_ETH_CRV_POOL_ADDRESS = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
        // cvx -> eth
        IERC20(CVX_ADDRESS).approve(CVX_ETH_CRV_POOL_ADDRESS, _cvxAmountIn);

        ethAmountOut = ICrvEthPool(CVX_ETH_CRV_POOL_ADDRESS)
            .exchange_underlying(
                1,
                0,
                _cvxAmountIn,
                0 // this is handled at the afEth level
            );
        trackedCvxBalance -= _cvxAmountIn;
    }

    /**
     * @notice - Function for rewarder to sell all claimed token rewards and buy & lock more cvx
     * @dev - Causes price to go up
     * @param _swapsData - Array of SwapData for 0x swaps
     * @param _safEthMinout - Minimum amount of safEth to mint from rewards
     * @param _cvxMinout - Minimum amount of cvx to mint from rewards
     */
    function applyRewards(
        SwapData[] calldata _swapsData,
        uint256 _safEthMinout,
        uint256 _cvxMinout,
        uint256 _deadline
    ) external onlyRewarder {
        if (block.timestamp > _deadline) revert StaleAction();
        uint256 ethBalanceBefore = address(this).balance;
        for (uint256 i = 0; i < _swapsData.length; i++) {
            // Some tokens do not allow approval if allowance already exists
            uint256 allowance = IERC20(_swapsData[i].sellToken).allowance(
                address(this),
                address(_swapsData[i].spender)
            );
            if (allowance != type(uint256).max) {
                if (allowance > 0) {
                    IERC20(_swapsData[i].sellToken).safeApprove(
                        address(_swapsData[i].spender),
                        0
                    );
                }
                IERC20(_swapsData[i].sellToken).safeApprove(
                    address(_swapsData[i].spender),
                    type(uint256).max
                );
            }
            (bool success, ) = _swapsData[i].swapTarget.call(
                _swapsData[i].swapCallData
            );
            if (!success) {
                emit FailedToSell(_swapsData[i].sellToken);
            }
        }

        // Ensure tracked balances are still valid
        require(
            IERC20(CVX_ADDRESS).balanceOf(address(this)) >= trackedCvxBalance
        );
        uint256 ethBalanceAfter = address(this).balance;
        uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;

        if (address(manager) != address(0))
            IAfEth(manager).depositRewards{value: ethReceived}(
                _safEthMinout,
                _cvxMinout
            );
        else depositRewards(ethReceived, _cvxMinout);
    }

    /**
     * @notice - Internal utility function to claim votium reward tokens
     * @param _claimProofs - Array of claim proofs
     */
    function claimVotiumRewards(
        IVotiumMerkleStash.ClaimParam[] calldata _claimProofs
    ) private {
        IVotiumMerkleStash(0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A)
            .claimMulti(address(this), _claimProofs);
    }

    /**
     * @notice - Internal utility function to claim vlCvx reward tokens
     */
    function claimVlCvxRewards() private {
        address[] memory emptyArray;
        IClaimZap(0x3f29cB4111CbdA8081642DA1f75B3c12DECf2516).claimRewards(
            emptyArray,
            emptyArray,
            emptyArray,
            emptyArray,
            0,
            0,
            0,
            0,
            8
        );
    }

    receive() external payable {}
}
