// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IRiskManagerV1.sol";
import "./Auctioneer.sol";
import "./Auction.sol";
import "./CoveragePoolConstants.sol";
import "./GovernanceUtils.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/// @title tBTC v1 Deposit contract interface
/// @notice This is an interface with just a few function signatures of a main
///      Deposit contract from tBTC. tBTC deposit contract functions declared in
///      this interface are used by RiskManagerV1 contract to interact with tBTC
///      v1 deposits. For more information about tBTC Deposit please see:
///      https://github.com/keep-network/tbtc/blob/solidity/v1.1.0/solidity/contracts/deposit/Deposit.sol
interface IDeposit {
    function withdrawFunds() external;

    function purchaseSignerBondsAtAuction() external;

    function currentState() external view returns (uint256);

    function lotSizeTbtc() external view returns (uint256);

    function withdrawableAmount() external view returns (uint256);

    function auctionValue() external view returns (uint256);
}

/// @title tBTC v1 deposit token (TDT) interface
/// @notice This is an interface with just a few function signatures of a main
///      contract from tBTC. For more information about tBTC Deposit please see:
///      https://github.com/keep-network/tbtc/blob/solidity/v1.1.0/solidity/contracts/system/TBTCDepositToken.sol
interface ITBTCDepositToken {
    function exists(uint256 _tokenId) external view returns (bool);
}

/// @title Signer bonds swap strategy
/// @notice This interface is meant to abstract the underlying signer bonds
///         swap strategy and make it interchangeable for the governance.
///         Risk manager uses the strategy to swap ETH from tBTC deposit
///         purchased signer bonds back into collateral token accepted by
///         coverage pool.
interface ISignerBondsSwapStrategy {
    /// @notice Notifies the strategy about signer bonds purchase.
    /// @param amount Amount of purchased signer bonds.
    function onSignerBondsPurchased(uint256 amount) external;
}

/// @title Risk Manager for tBTC v1
/// @notice Risk Manager is a smart contract with the exclusive right to claim
///         coverage from the coverage pool. Demanding coverage is akin to
///         filing a claim in traditional insurance and processing your own
///         claim. The risk manager holds an incredibly privileged position,
///         because the ability to claim coverage of an arbitrarily large
///         position could bankrupt the coverage pool.
///         tBTC v1 risk manager demands coverage by opening an auction for TBTC
///         and liquidating portion of the coverage pool when tBTC v1 deposit is
///         in liquidation and signer bonds on offer reached the specific
///         threshold. In practice, it means no one is willing to purchase
///         signer bonds for that deposit on tBTC side.
contract RiskManagerV1 is IRiskManagerV1, Auctioneer, Ownable {
    using SafeERC20 for IERC20;
    using RiskManagerV1Rewards for RiskManagerV1Rewards.Storage;

    /// @notice Governance delay that needs to pass before any risk manager
    ///         parameter change initiated by the governance takes effect.
    uint256 public constant GOVERNANCE_DELAY = 12 hours;

    // See https://github.com/keep-network/tbtc/blob/v1.1.0/solidity/contracts/deposit/DepositStates.sol
    uint256 public constant DEPOSIT_FRAUD_LIQUIDATION_IN_PROGRESS_STATE = 9;
    uint256 public constant DEPOSIT_LIQUIDATION_IN_PROGRESS_STATE = 10;
    uint256 public constant DEPOSIT_LIQUIDATED_STATE = 11;

    /// @notice Coverage pool auction will not be opened if the deposit's bond
    ///         auction offers a bond percentage lower than this threshold.
    ///         Risk manager should open a coverage pool auction for only those
    //          tBTC deposits that nobody else is willing to purchase bonds
    ///         from. The value can be updated by the governance in two steps.
    ///         First step is to begin the update process with the new value
    ///         and the second step is to finalize it after
    ///         `GOVERNANCE_DELAY` has passed.
    uint256 public bondAuctionThreshold; // percentage
    uint256 public newBondAuctionThreshold;
    uint256 public bondAuctionThresholdChangeInitiated;

    /// @notice The length with which every new auction is opened. Auction length
    ///         is the amount of time it takes for the auction to get to 100%
    ///         of all collateral on offer, in seconds. This parameter value
    ///         should be updated and kept up to date based on the coverage pool
    ///         TVL and tBTC v1 minimum lot size allowed so that a new auction
    ///         does not liquidate too much too early. Auction length is the
    ///         same, no matter tBTC deposit lot size.
    ///         The value can be updated by the governance in two steps.
    ///         First step is to begin the update process with the new value
    ///         and the second step is to finalize it after
    ///         `GOVERNANCE_DELAY` has passed.
    uint256 public auctionLength;
    uint256 public newAuctionLength;
    uint256 public auctionLengthChangeInitiated;

    /// @notice The strategy used to swap ETH from tBTC deposit purchased signer
    ///         bonds into an asset accepted by coverage pool as collateral.
    ///         The value can be updated by the governance in two steps.
    ///         First step is to begin the update process with the new value
    ///         and the second step is to finalize it after
    ///         `GOVERNANCE_DELAY` has passed.
    ISignerBondsSwapStrategy public signerBondsSwapStrategy;
    ISignerBondsSwapStrategy public newSignerBondsSwapStrategy;
    uint256 public signerBondsSwapStrategyInitiated;

    IERC20 public immutable tbtcToken;
    ITBTCDepositToken public immutable tbtcDepositToken;

    /// @notice TBTC surplus collected from early closed auctions.
    ///         When tBTC deposit gets liquidated outside of coverage pools and
    ///         an auction was opened earlier by the risk manager for that
    ///         deposit, it might happen that the auction was partially filled
    ///         and some TBTC from that auction has accumulated. In such a case,
    ///         TBTC surplus left on the risk manager can be used to purchase
    ///         signer bonds from another liquidating tBTC deposit in the future
    ///         assuming enough surplus will accumulate up to that point.
    uint256 public tbtcSurplus;

    /// @notice Keeps track of notifier rewards for those calling
    ///         `notifyLiquidation` and `notifyLiquidated`.
    RiskManagerV1Rewards.Storage public rewards;

    // deposit in liquidation => opened coverage pool auction
    mapping(address => address) public depositToAuction;
    // opened coverage pool auction => deposit in liquidation
    mapping(address => address) public auctionToDeposit;

    event NotifiedLiquidated(address indexed deposit, address notifier);
    event NotifiedLiquidation(address indexed deposit, address notifier);

    event BondAuctionThresholdUpdateStarted(
        uint256 bondAuctionThreshold,
        uint256 timestamp
    );
    event BondAuctionThresholdUpdated(uint256 bondAuctionThreshold);

    event AuctionLengthUpdateStarted(uint256 auctionLength, uint256 timestamp);
    event AuctionLengthUpdated(uint256 auctionLength);

    event SignerBondsSwapStrategyUpdateStarted(
        address indexed signerBondsSwapStrategy,
        uint256 timestamp
    );
    event SignerBondsSwapStrategyUpdated(
        address indexed signerBondsSwapStrategy
    );

    event LiquidationNotifierRewardUpdateStarted(
        uint256 liquidationNotifierReward,
        uint256 timestamp
    );
    event LiquidationNotifierRewardUpdated(uint256 liquidationNotifierReward);

    event LiquidatedNotifierRewardUpdateStarted(
        uint256 liquidatedNotifierReward,
        uint256 timestamp
    );
    event LiquidatedNotifierRewardUpdated(uint256 liquidatedNotifierReward);

    /// @notice Reverts if called before the governance delay elapses.
    /// @param changeInitiatedTimestamp Timestamp indicating the beginning
    ///        of the change.
    modifier onlyAfterGovernanceDelay(uint256 changeInitiatedTimestamp) {
        require(changeInitiatedTimestamp > 0, "Change not initiated");
        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp - changeInitiatedTimestamp >= GOVERNANCE_DELAY,
            "Governance delay has not elapsed"
        );
        _;
    }

    /// @notice Reverts if called by any account other than the current signer
    ///         bonds swap strategy.
    modifier onlySignerBondsSwapStrategy() {
        require(
            msg.sender == address(signerBondsSwapStrategy),
            "Caller is not the signer bonds swap strategy"
        );
        _;
    }

    constructor(
        IERC20 _tbtcToken,
        ITBTCDepositToken _tbtcDepositToken,
        CoveragePool _coveragePool,
        ISignerBondsSwapStrategy _signerBondsSwapStrategy,
        address _masterAuction,
        uint256 _auctionLength,
        uint256 _bondAuctionThreshold
    ) Auctioneer(_coveragePool, _masterAuction) {
        tbtcToken = _tbtcToken;
        tbtcDepositToken = _tbtcDepositToken;
        signerBondsSwapStrategy = _signerBondsSwapStrategy;
        auctionLength = _auctionLength;
        bondAuctionThreshold = _bondAuctionThreshold;
    }

    /// @notice Receives ETH from tBTC for purchasing and withdrawing deposit
    ///         signer bonds.
    //slither-disable-next-line locked-ether
    receive() external payable {}

    /// @notice Notifies the risk manager about tBTC deposit in liquidation
    ///         state for which signer bonds on offer passed the threshold
    ///         expected by the risk manager. In practice, it means no one else
    ///         is willing to purchase signer bonds from that deposit so the
    ///         risk manager should open an auction to collect TBTC and purchase
    ///         those bonds liquidating part of the coverage pool. If there is
    ///         enough TBTC surplus from earlier auctions accumulated by the
    ///         risk manager, bonds are purchased right away without opening an
    ///         auction. Notifier calling this function receives a share in the
    ///         coverage pool as a reward - underwriter tokens are transferred
    ///         to the notifier's address.
    /// @param  depositAddress liquidating tBTC deposit address
    function notifyLiquidation(address depositAddress) external override {
        require(
            tbtcDepositToken.exists(uint256(uint160(depositAddress))),
            "Address is not a deposit contract"
        );

        IDeposit deposit = IDeposit(depositAddress);
        require(
            isDepositLiquidationInProgress(deposit),
            "Deposit is not in liquidation state"
        );

        require(
            depositToAuction[depositAddress] == address(0),
            "Already notified on the deposit in liquidation"
        );

        require(
            deposit.auctionValue() >=
                (address(deposit).balance * bondAuctionThreshold) / 100,
            "Deposit bond auction percentage is below the threshold level"
        );

        uint256 lotSizeTbtc = deposit.lotSizeTbtc();

        emit NotifiedLiquidation(depositAddress, msg.sender);

        // Reward the notifier by giving them some share of the pool.
        if (rewards.liquidationNotifierReward > 0) {
            // slither-disable-next-line reentrancy-benign
            coveragePool.grantAssetPoolShares(
                msg.sender,
                rewards.liquidationNotifierReward
            );
        }

        // If the surplus can cover the deposit liquidation cost, liquidate
        // that deposit directly without the auction process.
        if (tbtcSurplus >= lotSizeTbtc) {
            tbtcSurplus -= lotSizeTbtc;
            liquidateDeposit(deposit);
            return;
        }

        // slither-disable-next-line reentrancy-no-eth
        address auctionAddress = createAuction(
            tbtcToken,
            lotSizeTbtc,
            auctionLength
        );
        depositToAuction[depositAddress] = auctionAddress;
        auctionToDeposit[auctionAddress] = depositAddress;
    }

    /// @notice Notifies the risk manager about tBTC deposit liquidated outside
    ///         the coverage pool for which the risk manager opened an auction
    ///         earlier (as a result of `notifyLiquidation` call). Function
    ///         closes the auction early and collects TBTC surplus from the
    ///         auction in case the auction was partially taken before the
    ///         deposit got liquidated. Notifier calling this function receives
    ///         a share in the coverage pool as a reward - underwriter tokens
    ///         are transferred to the notifier's address.
    /// @param  depositAddress liquidated tBTC Deposit address
    function notifyLiquidated(address depositAddress) external override {
        require(
            depositToAuction[depositAddress] != address(0),
            "No auction for given deposit"
        );

        IDeposit deposit = IDeposit(depositAddress);
        require(
            deposit.currentState() == DEPOSIT_LIQUIDATED_STATE,
            "Deposit is not in liquidated state"
        );
        emit NotifiedLiquidated(depositAddress, msg.sender);

        Auction auction = Auction(depositToAuction[depositAddress]);

        delete depositToAuction[depositAddress];
        delete auctionToDeposit[address(auction)];
        uint256 amountTransferred = earlyCloseAuction(auction);

        // Add auction's transferred amount to the surplus pool.
        // slither-disable-next-line reentrancy-benign
        tbtcSurplus += amountTransferred;

        // Reward the notifier by giving them some share of the pool.
        if (rewards.liquidatedNotifierReward > 0) {
            coveragePool.grantAssetPoolShares(
                msg.sender,
                rewards.liquidatedNotifierReward
            );
        }
    }

    /// @notice Begins the bond auction threshold update process. The value of
    ///         the threshold must not be greater than 100. The threshold should
    ///         be high enough so that the possibility of purchasing signer
    ///         bonds outside of coverage pools after opening an auction is
    ///         minimal.
    /// @dev Can be called only by the contract owner.
    /// @param _newBondAuctionThreshold New bond auction threshold in percent
    function beginBondAuctionThresholdUpdate(uint256 _newBondAuctionThreshold)
        external
        onlyOwner
    {
        require(
            _newBondAuctionThreshold <= 100,
            "Bond auction threshold must be lower or equal to 100"
        );
        newBondAuctionThreshold = _newBondAuctionThreshold;
        /* solhint-disable-next-line not-rely-on-time */
        bondAuctionThresholdChangeInitiated = block.timestamp;
        /* solhint-disable not-rely-on-time */
        emit BondAuctionThresholdUpdateStarted(
            _newBondAuctionThreshold,
            block.timestamp
        );
    }

    /// @notice Finalizes the bond auction threshold update process.
    /// @dev Can be called only by the contract owner, after the the
    ///      governance delay elapses.
    function finalizeBondAuctionThresholdUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(bondAuctionThresholdChangeInitiated)
    {
        bondAuctionThreshold = newBondAuctionThreshold;
        emit BondAuctionThresholdUpdated(bondAuctionThreshold);
        bondAuctionThresholdChangeInitiated = 0;
        newBondAuctionThreshold = 0;
    }

    /// @notice Begins the auction length update process. The auction length
    ///         should be adjusted very carefully. Total value locked of the
    ///         coverage pool and minimum possible auction amount need to be
    ///         taken into account. The goal is to find a "sweet spot" for
    ///         auction length, not making it too short (which leads to big
    ///         sums of coverage pool become available in a short time) and not
    ///         making it too long (which leads to bidders waiting for too long
    ///         until it will makes sense for them to bid on an auction).
    /// @dev Can be called only by the contract owner.
    /// @param _newAuctionLength New auction length in seconds
    function beginAuctionLengthUpdate(uint256 _newAuctionLength)
        external
        onlyOwner
    {
        newAuctionLength = _newAuctionLength;
        /* solhint-disable-next-line not-rely-on-time */
        auctionLengthChangeInitiated = block.timestamp;
        /* solhint-disable-next-line not-rely-on-time */
        emit AuctionLengthUpdateStarted(_newAuctionLength, block.timestamp);
    }

    /// @notice Finalizes the auction length update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeAuctionLengthUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(auctionLengthChangeInitiated)
    {
        auctionLength = newAuctionLength;
        emit AuctionLengthUpdated(newAuctionLength);
        newAuctionLength = 0;
        auctionLengthChangeInitiated = 0;
    }

    /// @notice Begins the liquidation notifier reward update process.
    ///         Total value locked of the coverage pool and the cost of calling
    ///         `notifyLiquidation` needs to be taken into account so that the
    ///         call incentive is attractive enough and at the same time it does
    ///         not offer to much value held the coverage pool.
    /// @dev Can be called only by the contract owner.
    /// @param _newLiquidationNotifierReward New liquidation notifier reward
    function beginLiquidationNotifierRewardUpdate(
        uint256 _newLiquidationNotifierReward
    ) external onlyOwner {
        /* solhint-disable-next-line not-rely-on-time */
        emit LiquidationNotifierRewardUpdateStarted(
            _newLiquidationNotifierReward,
            block.timestamp
        );

        rewards.beginLiquidationNotifierRewardUpdate(
            _newLiquidationNotifierReward
        );
    }

    /// @notice Finalizes the liquidation notifier reward update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeLiquidationNotifierRewardUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            rewards.liquidationNotifierRewardChangeInitiated
        )
    {
        emit LiquidationNotifierRewardUpdated(
            rewards.newLiquidationNotifierReward
        );

        rewards.finalizeLiquidationNotifierRewardUpdate();
    }

    /// @notice Begins the liquidated notifier reward update process.
    ///         Total value locked of the coverage pool and the cost of calling
    ///         `notifyLiquidated` needs to be taken into account so that the
    ///         call incentive is attractive enough and at the same time it does
    ///         not offer to much value held the coverage pool.
    /// @param _newLiquidatedNotifierReward New liquidated notifier reward
    function beginLiquidatedNotifierRewardUpdate(
        uint256 _newLiquidatedNotifierReward
    ) external onlyOwner {
        /* solhint-disable-next-line not-rely-on-time */
        emit LiquidatedNotifierRewardUpdateStarted(
            _newLiquidatedNotifierReward,
            block.timestamp
        );

        rewards.beginLiquidatedNotifierRewardUpdate(
            _newLiquidatedNotifierReward
        );
    }

    /// @notice Finalizes the liquidated notifier reward update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses
    function finalizeLiquidatedNotifierRewardUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            rewards.liquidatedNotifierRewardChangeInitiated
        )
    {
        emit LiquidatedNotifierRewardUpdated(
            rewards.newLiquidatedNotifierReward
        );

        rewards.finalizeLiquidatedNotifierRewardUpdate();
    }

    /// @notice Begins the signer bonds swap strategy update process.
    /// @dev Must be followed by a finalizeSignerBondsSwapStrategyUpdate after
    ///      the governance delay elapses.
    /// @param _newSignerBondsSwapStrategy The new signer bonds swap strategy
    function beginSignerBondsSwapStrategyUpdate(
        ISignerBondsSwapStrategy _newSignerBondsSwapStrategy
    ) external onlyOwner {
        require(
            address(_newSignerBondsSwapStrategy) != address(0),
            "Invalid signer bonds swap strategy address"
        );
        newSignerBondsSwapStrategy = _newSignerBondsSwapStrategy;
        /* solhint-disable-next-line not-rely-on-time */
        signerBondsSwapStrategyInitiated = block.timestamp;
        emit SignerBondsSwapStrategyUpdateStarted(
            address(_newSignerBondsSwapStrategy),
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp
        );
    }

    /// @notice Finalizes the signer bonds swap strategy update.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeSignerBondsSwapStrategyUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(signerBondsSwapStrategyInitiated)
    {
        signerBondsSwapStrategy = newSignerBondsSwapStrategy;
        emit SignerBondsSwapStrategyUpdated(
            address(newSignerBondsSwapStrategy)
        );
        delete newSignerBondsSwapStrategy;
        signerBondsSwapStrategyInitiated = 0;
    }

    /// @notice Withdraws the given amount of accumulated signer bonds.
    /// @dev Can be called only by the signer bonds swap strategy itself.
    ///      This method should typically be used as part of the swap logic.
    ///      Third-party calls may block funds on the strategy contract in case
    ///      that strategy is not able to perform the swap.
    /// @param amount Amount of signer bonds being withdrawn
    function withdrawSignerBonds(uint256 amount)
        external
        override
        onlySignerBondsSwapStrategy
    {
        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls
        (bool success, ) = address(signerBondsSwapStrategy).call{value: amount}(
            ""
        );
        require(success, "Failed to send Ether");
        /* solhint-enable avoid-low-level-calls */
    }

    /// @notice Get the time remaining until the bond auction threshold
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingBondAuctionThresholdUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                bondAuctionThresholdChangeInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @notice Get the time remaining until the auction length parameter
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingAuctionLengthUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                auctionLengthChangeInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @notice Get the time remaining until the liquidation notifier reward
    ///         parameter can be updated.
    /// @return Remaining time in seconds.
    function getRemainingLiquidationNotifierRewardUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                rewards.liquidationNotifierRewardChangeInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @notice Get the time remaining until the liquidated notifier reward
    ///         amount parameter can be updated.
    /// @return Remaining time in seconds.
    function getRemainingLiquidatedNotifierRewardUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                rewards.liquidatedNotifierRewardChangeInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @notice Get the time remaining until the signer bonds swap strategy
    ///         can be changed.
    /// @return Remaining time in seconds.
    function getRemainingSignerBondsSwapStrategyChangeTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                signerBondsSwapStrategyInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @return True if there are open auctions managed by the risk manager.
    ///         Returns false otherwise.
    function hasOpenAuctions() external view override returns (bool) {
        return openAuctionsCount > 0;
    }

    /// @return Current value of the liquidation notifier reward.
    function liquidationNotifierReward() external view returns (uint256) {
        return rewards.liquidationNotifierReward;
    }

    /// @return Current value of the liquidated notifier reward.
    function liquidatedNotifierReward() external view returns (uint256) {
        return rewards.liquidatedNotifierReward;
    }

    /// @notice Cleans up auction and deposit data and executes deposit liquidation.
    /// @dev This function is invoked when Auctioneer determines that an auction
    ///      is eligible to be closed. It cannot be called on-demand outside
    ///      the Auctioneer contract. By the time this function is called, all
    ///      the TBTC tokens for the coverage pool auction should be transferred
    ///      to this contract in order to buy signer bonds.
    /// @param auction Coverage pool auction
    function onAuctionFullyFilled(Auction auction) internal override {
        IDeposit deposit = IDeposit(auctionToDeposit[address(auction)]);
        // Make sure the deposit was not liquidated outside of Coverage Pool
        require(
            isDepositLiquidationInProgress(deposit),
            "Deposit liquidation is not in progress"
        );

        delete depositToAuction[address(deposit)];
        delete auctionToDeposit[address(auction)];

        liquidateDeposit(deposit);
    }

    /// @notice Purchases ETH from signer bonds and swaps obtained funds
    ///         using the underlying signer bonds swap strategy.
    /// @dev By the time this function is called, TBTC token balance for this
    ///      contract should be enough to buy signer bonds.
    /// @param deposit TBTC deposit which should be liquidated.
    function liquidateDeposit(IDeposit deposit) internal {
        uint256 approvedAmount = deposit.lotSizeTbtc();
        tbtcToken.safeApprove(address(deposit), approvedAmount);

        // Purchase signers bonds ETH with TBTC acquired from the auction or
        // taken from the surplus pool.
        deposit.purchaseSignerBondsAtAuction();

        uint256 withdrawableAmount = deposit.withdrawableAmount();
        deposit.withdrawFunds();

        signerBondsSwapStrategy.onSignerBondsPurchased(withdrawableAmount);
    }

    /// @notice Reverts if the deposit for which the auction was created is no
    ///         longer in the liquidation state. This could happen if signer
    ///         bonds were purchased from tBTC deposit directly, outside of
    ///         coverage pool auction.
    /// @dev This function is invoked when the auctioneer is informed about the
    ///      results of an auction and the auction was partially filled.
    /// @param auction Address of an auction whose deposit needs to be checked.
    function onAuctionPartiallyFilled(Auction auction) internal view override {
        IDeposit deposit = IDeposit(auctionToDeposit[address(auction)]);
        // Make sure the deposit was not liquidated outside of Coverage Pool
        require(
            isDepositLiquidationInProgress(deposit),
            "Deposit liquidation is not in progress"
        );
    }

    function isDepositLiquidationInProgress(IDeposit deposit)
        internal
        view
        returns (bool)
    {
        uint256 state = deposit.currentState();

        return (state == DEPOSIT_LIQUIDATION_IN_PROGRESS_STATE ||
            state == DEPOSIT_FRAUD_LIQUIDATION_IN_PROGRESS_STATE);
    }
}

/// @title RiskManagerV1Rewards
/// @notice Contains logic responsible for calculating notifier rewards for
///         both deposit liquidation start and deposit liquidated events.
///         All parameters can be updated using a two-phase process.
/// @dev The client contract should take care of authorizations or governance
///      delays according to their needs.
/* solhint-disable-next-line ordering */
library RiskManagerV1Rewards {
    struct Storage {
        // Amount of COV tokens which should be given as reward for the
        // notifier reporting about the start of deposit liquidation process.
        uint256 liquidationNotifierReward;
        uint256 newLiquidationNotifierReward;
        uint256 liquidationNotifierRewardChangeInitiated;
        // Amount of COV tokens which should be given as reward for the
        // notifier reporting about a deposit being liquidated outside of the
        // coverage pool.
        uint256 liquidatedNotifierReward;
        uint256 newLiquidatedNotifierReward;
        uint256 liquidatedNotifierRewardChangeInitiated;
    }

    /// @notice Begins the liquidation notifier reward update process.
    /// @param _newLiquidationNotifierReward New liquidation notifier reward.
    function beginLiquidationNotifierRewardUpdate(
        Storage storage self,
        uint256 _newLiquidationNotifierReward
    ) internal {
        /* solhint-disable not-rely-on-time */
        self.newLiquidationNotifierReward = _newLiquidationNotifierReward;
        self.liquidationNotifierRewardChangeInitiated = block.timestamp;
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the liquidation notifier reward update process.
    function finalizeLiquidationNotifierRewardUpdate(Storage storage self)
        internal
    {
        self.liquidationNotifierReward = self.newLiquidationNotifierReward;
        self.newLiquidationNotifierReward = 0;
        self.liquidationNotifierRewardChangeInitiated = 0;
    }

    /// @notice Begins the liquidated notifier reward update process.
    /// @param _newLiquidatedNotifierReward New liquidated notifier reward
    function beginLiquidatedNotifierRewardUpdate(
        Storage storage self,
        uint256 _newLiquidatedNotifierReward
    ) internal {
        /* solhint-disable not-rely-on-time */
        self.newLiquidatedNotifierReward = _newLiquidatedNotifierReward;
        self.liquidatedNotifierRewardChangeInitiated = block.timestamp;
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the liquidated notifier reward update process.
    function finalizeLiquidatedNotifierRewardUpdate(Storage storage self)
        internal
    {
        self.liquidatedNotifierReward = self.newLiquidatedNotifierReward;
        self.newLiquidatedNotifierReward = 0;
        self.liquidatedNotifierRewardChangeInitiated = 0;
    }
}
