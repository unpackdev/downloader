// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ===================== FraxEtherRedemptionQueue =====================
// ====================================================================
// Users wishing to exchange frxETH for ETH 1-to-1 will need to deposit their frxETH and wait to redeem it.
// When they do the deposit, they get an NFT with a maturity time as well as an amount.

// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian

import "./IERC20.sol";
import "./ERC721.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeCast.sol";
import "./Timelock2Step.sol";
import "./OperatorRole.sol";
import "./IFrxEth.sol";

/// @notice Used by the constructor
/// @param timelockAddress Address of the timelock, which the main owner of the this contract
/// @param operatorAddress Address of the operator, which does other tasks
/// @param frxEthAddress Address of frxEth Erc20
/// @param initialQueueLengthSecondss Initial length of the queue, in seconds
struct FraxEtherRedemptionQueueParams {
    address timelockAddress;
    address operatorAddress;
    address frxEthAddress;
    uint32 initialQueueLengthSeconds;
}

contract FraxEtherRedemptionQueue is ERC721, Timelock2Step, OperatorRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for *;

    // ==============================================================================
    // Storage
    // ==============================================================================

    // Tokens
    // ================
    /// @notice The frxETH token
    IFrxEth public immutable FRX_ETH;

    // Queue-Related
    // ================
    /// @notice State of Frax's frxETH redemption queue
    RedemptionQueueState public redemptionQueueState;

    /// @notice State of Frax's frxETH redemption queue
    /// @param etherLiabilities How much ETH is currently under request to be redeemed
    /// @param nextNftId Autoincrement for the NFT id
    /// @param queueLengthSecs Current wait time (in seconds) a new redeemer would have. Should be close to Beacon.
    /// @param redemptionFee Redemption fee given as a percentage with 1e6 precision
    /// @param earlyExitFee Early NFT back to frxETH exit fee given as a percentage with 1e6 precision
    struct RedemptionQueueState {
        uint64 nextNftId;
        uint64 queueLengthSecs;
        uint64 redemptionFee;
        uint64 earlyExitFee;
    }

    /// @notice Accounting of Frax's frxETH redemption queue
    RedemptionQueueAccounting public redemptionQueueAccounting;

    /// @param etherLiabilities How much ETH would need to be paid out if every NFT holder could claim immediately
    /// @param unclaimedFees Earned fees that the protocol has not collected yet
    struct RedemptionQueueAccounting {
        uint128 etherLiabilities;
        uint128 unclaimedFees;
    }

    /// @notice Information about a user's redemption ticket NFT
    mapping(uint256 nftId => RedemptionQueueItem) public nftInformation;

    /// @notice The ```RedemptionQueueItem``` struct provides metadata information about each Nft
    /// @param hasBeenRedeemed boolean for whether the NFT has been redeemed
    /// @param amount How much ETH is claimable
    /// @param maturity Unix timestamp when they can claim their ETH
    /// @param earlyExitFee EarlyExitFee at time of NFT mint
    struct RedemptionQueueItem {
        bool hasBeenRedeemed;
        uint64 maturity;
        uint120 amount;
        uint64 earlyExitFee;
    }

    /// @notice Maximum queue length the operator can set given in seconds
    uint256 public maxOperatorQueueLengthSeconds = 100 days;

    /// @notice The precision of the redemption fee
    uint64 public constant FEE_PRECISION = 1e6;

    /// @notice The fee recipient for various fees
    address public feeRecipient;

    // ==============================================================================
    // Constructor
    // ==============================================================================

    /// @notice Constructor
    /// @param _params The contructor FraxEtherRedemptionQueueParams params
    constructor(
        FraxEtherRedemptionQueueParams memory _params
    )
        payable
        ERC721("FrxETHRedemptionTicket", "FrxETH Redemption Queue Ticket")
        OperatorRole(_params.operatorAddress)
        Timelock2Step(_params.timelockAddress)
    {
        redemptionQueueState.queueLengthSecs = _params.initialQueueLengthSeconds;
        FRX_ETH = IFrxEth(_params.frxEthAddress);
    }

    /// @notice Allows contract to receive Eth
    receive() external payable {
        // Do nothing except take in the Eth
    }

    // =============================================================================================
    // Configurations / Privileged functions
    // =============================================================================================

    /// @notice When the accrued redemption fees are collected
    /// @param recipient The address to receive the fees
    /// @param collectAmount Amount of fees collected
    event CollectRedemptionFees(address recipient, uint128 collectAmount);

    /// @notice Collect redemption fees
    /// @param _collectAmount Amount of frxEth to collect
    function collectRedemptionFees(uint128 _collectAmount) external {
        // Make sure the sender is either the timelock or the operator
        _requireIsTimelockOrOperator();

        uint128 _unclaimedFees = redemptionQueueAccounting.unclaimedFees;

        // Make sure you are not taking too much
        if (_collectAmount > _unclaimedFees) revert ExceedsCollectedFees(_collectAmount, _unclaimedFees);

        // Decrement the unclaimed fee amount
        redemptionQueueAccounting.unclaimedFees -= _collectAmount;

        // Interactions: Transfer frxEth fees to the recipient
        IERC20(address(FRX_ETH)).safeTransfer({ to: feeRecipient, value: _collectAmount });

        emit CollectRedemptionFees({ recipient: feeRecipient, collectAmount: _collectAmount });
    }

    /// @notice When the timelock or operator recovers ERC20 tokens mistakenly sent here
    /// @param recipient Address of the recipient
    /// @param token Address of the erc20 token
    /// @param amount Amount of the erc20 token recovered
    event RecoverErc20(address recipient, address token, uint256 amount);

    /// @notice Recovers ERC20 tokens mistakenly sent to this contract
    /// @param _tokenAddress Address of the token
    /// @param _tokenAmount Amount of the token
    function recoverErc20(address _tokenAddress, uint256 _tokenAmount) external {
        _requireSenderIsTimelock();
        IERC20(_tokenAddress).safeTransfer({ to: msg.sender, value: _tokenAmount });
        emit RecoverErc20({ recipient: msg.sender, token: _tokenAddress, amount: _tokenAmount });
    }

    /// @notice The EtherRecovered event is emitted when recoverEther is called
    /// @param recipient Address of the recipient
    /// @param amount Amount of the ether recovered
    event RecoverEther(address recipient, uint256 amount);

    /// @notice Recover ETH from exits where people early exited their NFT for frxETH, or when someone mistakenly directly sends ETH here
    /// @param _amount Amount of ETH to recover
    function recoverEther(uint256 _amount) external {
        _requireSenderIsTimelock();

        (bool _success, ) = address(msg.sender).call{ value: _amount }("");
        if (!_success) revert InvalidEthTransfer();

        emit RecoverEther({ recipient: msg.sender, amount: _amount });
    }

    /// @notice When the early exit fee is set
    /// @param oldEarlyExitFee Old early exit fee
    /// @param newEarlyExitFee New early exit fee
    event SetEarlyExitFee(uint64 oldEarlyExitFee, uint64 newEarlyExitFee);

    /// @notice Sets the fee for exiting the NFT early and getting back frxETH (not ETH)
    /// @param _newFee New early exit fee given in percentage terms, using 1e6 precision
    function setEarlyExitFee(uint64 _newFee) external {
        _requireSenderIsTimelock();
        if (_newFee > FEE_PRECISION) revert ExceedsMaxEarlyExitFee(_newFee, FEE_PRECISION);

        emit SetEarlyExitFee({ oldEarlyExitFee: redemptionQueueState.earlyExitFee, newEarlyExitFee: _newFee });

        redemptionQueueState.earlyExitFee = _newFee;
    }

    /// @notice When the redemption fee is set
    /// @param oldRedemptionFee Old redemption fee
    /// @param newRedemptionFee New redemption fee
    event SetRedemptionFee(uint64 oldRedemptionFee, uint64 newRedemptionFee);

    /// @notice Sets the fee for redeeming
    /// @param _newFee New redemption fee given in percentage terms, using 1e6 precision
    function setRedemptionFee(uint64 _newFee) external {
        _requireSenderIsTimelock();
        if (_newFee > FEE_PRECISION) revert ExceedsMaxRedemptionFee(_newFee, FEE_PRECISION);

        emit SetRedemptionFee({ oldRedemptionFee: redemptionQueueState.redemptionFee, newRedemptionFee: _newFee });

        redemptionQueueState.redemptionFee = _newFee;
    }

    /// @notice When the current wait time (in seconds) of the queue is set
    /// @param oldQueueLength Old queue length in seconds
    /// @param newQueueLength New queue length in seconds
    event SetQueueLengthSeconds(uint64 oldQueueLength, uint64 newQueueLength);

    /// @notice Sets the current wait time (in seconds) a new redeemer would have
    /// @param _newLength New queue time, in seconds
    function setQueueLengthSeconds(uint64 _newLength) external {
        _requireIsTimelockOrOperator();
        if (msg.sender != timelockAddress && _newLength > maxOperatorQueueLengthSeconds)
            revert ExceedsMaxQueueLengthSecs(_newLength, maxOperatorQueueLengthSeconds);

        emit SetQueueLengthSeconds({
            oldQueueLength: redemptionQueueState.queueLengthSecs,
            newQueueLength: _newLength
        });

        redemptionQueueState.queueLengthSecs = _newLength;
    }

    /// @notice When the max queue length the operator can set is changed
    /// @param oldMaxQueueLengthSecs Old max queue length in seconds
    /// @param newMaxQueueLengthSecs New max queue length in seconds
    event SetMaxOperatorQueueLengthSeconds(uint256 oldMaxQueueLengthSecs, uint256 newMaxQueueLengthSecs);

    /// @notice Sets the maximum queue length the operator can set
    /// @param _newMaxQueueLengthSeconds New maximum queue length
    function setMaxOperatorQueueLengthSeconds(uint256 _newMaxQueueLengthSeconds) external {
        _requireSenderIsTimelock();

        emit SetMaxOperatorQueueLengthSeconds({
            oldMaxQueueLengthSecs: maxOperatorQueueLengthSeconds,
            newMaxQueueLengthSecs: _newMaxQueueLengthSeconds
        });

        maxOperatorQueueLengthSeconds = _newMaxQueueLengthSeconds;
    }

    /// @notice Sets the operator (bot) that updates the queue length
    /// @param _newOperator New bot address
    function setOperator(address _newOperator) external {
        _requireSenderIsTimelock();
        _setOperator(_newOperator);
    }

    /// @notice When the fee recipient is set
    /// @param oldFeeRecipient Old fee recipient address
    /// @param newFeeRecipient New fee recipient address
    event SetFeeRecipient(address oldFeeRecipient, address newFeeRecipient);

    /// @notice Where redemption and early exit fees go
    /// @param _newFeeRecipient New fee recipient address
    function setFeeRecipient(address _newFeeRecipient) external {
        _requireSenderIsTimelock();

        emit SetFeeRecipient({ oldFeeRecipient: feeRecipient, newFeeRecipient: _newFeeRecipient });

        feeRecipient = _newFeeRecipient;
    }

    // =============================================================================================
    // Queue Functions
    // =============================================================================================

    /// @notice When someone enters the redemption queue
    /// @param nftId The ID of the NFT
    /// @param sender The address of the msg.sender, who is redeeming frxEth
    /// @param recipient The recipient of the NFT
    /// @param amountFrxEthRedeemed The amount of frxEth redeemed
    /// @param maturityTimestamp The date of maturity, upon which redemption is allowed
    /// @param redemptionFeeAmount The redemption fee
    /// @param earlyExitFee The early exit fee at the time of minting
    event EnterRedemptionQueue(
        uint256 indexed nftId,
        address indexed sender,
        address indexed recipient,
        uint256 amountFrxEthRedeemed,
        uint120 redemptionFeeAmount,
        uint64 maturityTimestamp,
        uint256 earlyExitFee
    );

    /// @notice Enter the queue for redeeming frxEth 1-to-1 for Eth, without the need to approve first (EIP-712 / EIP-2612)
    /// @notice Will generate a FrxEthRedemptionTicket NFT that can be redeemed for the actual Eth later.
    /// @param _amountToRedeem Amount to redeem
    /// @param _recipient Recipient of the NFT. Must be ERC721 compatible if a contract
    /// @param _deadline Deadline for this signature
    function enterRedemptionQueueWithPermit(
        uint120 _amountToRedeem,
        address _recipient,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Call the permit
        FRX_ETH.permit({
            owner: msg.sender,
            spender: address(this),
            value: _amountToRedeem,
            deadline: _deadline,
            v: _v,
            r: _r,
            s: _s
        });

        // Do the redemption
        enterRedemptionQueue({ _recipient: _recipient, _amountToRedeem: _amountToRedeem });
    }

    /// @notice Enter the queue for redeeming frxETH 1-to-1. Must approve first.
    /// @notice Will generate a FrxETHRedemptionTicket NFT that can be redeemed for the actual ETH later.
    /// @param _recipient Recipient of the NFT. Must be ERC721 compatible if a contract
    /// @param _amountToRedeem Amount to redeem
    /// @dev Must call approve/permit on frxEth contract prior to this call
    function enterRedemptionQueue(address _recipient, uint120 _amountToRedeem) public nonReentrant {
        // Get queue information
        RedemptionQueueState memory _redemptionQueueState = redemptionQueueState;
        RedemptionQueueAccounting memory _redemptionQueueAccounting = redemptionQueueAccounting;

        // Calculations: redemption fee
        uint120 _redemptionFeeAmount = ((uint256(_amountToRedeem) * _redemptionQueueState.redemptionFee) /
            FEE_PRECISION).toUint120();

        // Calculations: amount of ETH owed to the user
        uint120 _amountEtherOwedToUser = _amountToRedeem - _redemptionFeeAmount;

        // Calculations: increment ether liabilities by the amount of ether owed to the user
        _redemptionQueueAccounting.etherLiabilities += uint128(_amountEtherOwedToUser);

        // Calculations: increment unclaimed fees by the redemption fee taken
        _redemptionQueueAccounting.unclaimedFees += _redemptionFeeAmount;

        // Calculations: maturity timestamp
        uint64 _maturityTimestamp = uint64(block.timestamp) + _redemptionQueueState.queueLengthSecs;

        // Effects: Initialize the redemption ticket NFT information
        nftInformation[_redemptionQueueState.nextNftId] = RedemptionQueueItem({
            amount: _amountEtherOwedToUser,
            maturity: _maturityTimestamp,
            hasBeenRedeemed: false,
            earlyExitFee: _redemptionQueueState.earlyExitFee
        });

        // Effects: Mint the redemption ticket NFT. Make sure the recipient supports ERC721.
        _safeMint({ to: _recipient, tokenId: _redemptionQueueState.nextNftId });

        // Emit here, before the state change
        emit EnterRedemptionQueue({
            nftId: _redemptionQueueState.nextNftId,
            sender: msg.sender,
            recipient: _recipient,
            amountFrxEthRedeemed: _amountToRedeem,
            redemptionFeeAmount: _redemptionFeeAmount,
            maturityTimestamp: _maturityTimestamp,
            earlyExitFee: _redemptionQueueState.earlyExitFee
        });

        // Calculations: Increment the autoincrement
        ++_redemptionQueueState.nextNftId;

        // Effects: Write all of the state changes to storage
        redemptionQueueState = _redemptionQueueState;

        // Effects: Write all of the accounting changes to storage
        redemptionQueueAccounting = _redemptionQueueAccounting;

        // Interactions: Transfer frxEth from sender
        IERC20(address(FRX_ETH)).safeTransferFrom({ from: msg.sender, to: address(this), value: _amountToRedeem });
    }

    /// @notice When someone early redeems their NFT for frxETH, with the penalty
    /// @param nftId The ID of the NFT
    /// @param sender The sender of the NFT
    /// @param recipient The recipient of the redeemed ETH
    /// @param frxEthOut The amount of frxETH actually sent back to the user
    /// @param earlyExitFeeAmount Any penalty fee paid for exiting early
    event EarlyBurnRedemptionTicketNft(
        uint256 indexed nftId,
        address indexed sender,
        address indexed recipient,
        uint120 frxEthOut,
        uint120 earlyExitFeeAmount
    );

    /// @notice Redeems a FrxETHRedemptionTicket NFT early for frxETH, not ETH. Is penalized in doing so. Used if person does not want to wait for exit anymore.
    /// @param _nftId The ID of the NFT
    /// @param _recipient The recipient of the redeemed ETH
    /// @return _frxEthOut The amount of frxETH actually sent back to the user
    function earlyBurnRedemptionTicketNft(
        address payable _recipient,
        uint256 _nftId
    ) external nonReentrant returns (uint120 _frxEthOut) {
        // Checks: ensure proper nft ownership
        if (!_isApprovedOrOwner({ spender: msg.sender, tokenId: _nftId })) revert Erc721CallerNotOwnerOrApproved();

        // Get data from state for use in calculations
        RedemptionQueueAccounting memory _redemptionQueueAccounting = redemptionQueueAccounting;
        RedemptionQueueItem memory _redemptionQueueItem = nftInformation[_nftId];
        uint120 _amountToRedeem = _redemptionQueueItem.amount;

        // Calculations: remove owed ether from the liabilities
        _redemptionQueueAccounting.etherLiabilities -= _amountToRedeem;

        // Calculations: determine the early exit fee
        uint120 _earlyExitFeeAmount = ((uint256(_amountToRedeem) * _redemptionQueueItem.earlyExitFee) / FEE_PRECISION)
            .toUint120();

        // Calculations: increment unclaimedFees
        _redemptionQueueAccounting.unclaimedFees += uint128(_earlyExitFeeAmount);

        // Calculations: Amount of frxETH back to the recipient, minus the fees
        _frxEthOut = _amountToRedeem - _earlyExitFeeAmount;

        // Effects: burn the nft
        _burn(_nftId);

        // Effects: Write back accounting to state
        redemptionQueueAccounting = _redemptionQueueAccounting;

        // Effects: Mark nft as redeemed
        nftInformation[_nftId].hasBeenRedeemed = true;

        emit EarlyBurnRedemptionTicketNft({
            sender: msg.sender,
            recipient: _recipient,
            nftId: _nftId,
            frxEthOut: _frxEthOut,
            earlyExitFeeAmount: _earlyExitFeeAmount
        });

        // Interactions: transfer frxEth
        IERC20(address(FRX_ETH)).safeTransfer({ to: _recipient, value: _frxEthOut });
    }

    /// @notice When someone redeems their NFT for ETH
    /// @param nftId the if of the nft redeemed
    /// @param sender the msg.sender
    /// @param recipient the recipient of the ether
    /// @param amountOut the amount of ether sent to the recipient
    event BurnRedemptionTicketNft(uint256 indexed nftId, address indexed sender, address indexed recipient,  uint120 amountOut);

    /// @notice Redeems a FrxETHRedemptionTicket NFT for ETH. Must have reached the maturity date first.
    /// @param _nftId The ID of the NFT
    /// @param _recipient The recipient of the redeemed ETH
    function burnRedemptionTicketNft(uint256 _nftId, address payable _recipient) external nonReentrant {
        // Checks: ensure proper nft ownership
        if (!_isApprovedOrOwner({ spender: msg.sender, tokenId: _nftId })) revert Erc721CallerNotOwnerOrApproved();

        // Get queue information
        RedemptionQueueItem memory _redemptionQueueItem = nftInformation[_nftId];

        // Checks: Make sure maturity was reached
        if (block.timestamp < _redemptionQueueItem.maturity) {
            revert NotMatureYet({ currentTime: block.timestamp, maturity: _redemptionQueueItem.maturity });
        }

        // Effects: Subtract the amount from total liabilities
        redemptionQueueAccounting.etherLiabilities -= _redemptionQueueItem.amount;

        // Effects: burn the Nft
        _burn(_nftId);

        // Effects: Mark nft as redeemed
        nftInformation[_nftId].hasBeenRedeemed = true;

        // Effects: Burn frxEth to match the amount of ether sent to user 1:1
        FRX_ETH.burn(_redemptionQueueItem.amount);

        // Interactions: Transfer ETH to recipient, minus the fee
        (bool _success, ) = _recipient.call{ value: _redemptionQueueItem.amount }("");
        if (!_success) revert InvalidEthTransfer();

        emit BurnRedemptionTicketNft({
            nftId: _nftId,
            sender: msg.sender,
            recipient: _recipient,
            amountOut: _redemptionQueueItem.amount
        });
    }

    // ====================================
    // Internal Functions
    // ====================================

    /// @notice Checks if msg.sender is current timelock address or the operator
    function _requireIsTimelockOrOperator() internal view {
        if (!((msg.sender == timelockAddress) || (msg.sender == operatorAddress))) revert NotTimelockOrOperator();
    }

    // ====================================
    // Errors
    // ====================================

    /// @notice ERC721: caller is not token owner or approved
    error Erc721CallerNotOwnerOrApproved();

    /// @notice When timelock/operator tries collecting more fees than they are due
    /// @param collectAmount How much fee the ounsender is trying to collect
    /// @param accruedAmount How much fees are actually collectable
    error ExceedsCollectedFees(uint128 collectAmount, uint128 accruedAmount);

    /// @notice When someone tries setting the early exit fee above the max (100%)
    /// @param providedFee The provided early exit fee
    /// @param maxFee The maximum early exit fee
    error ExceedsMaxEarlyExitFee(uint64 providedFee, uint64 maxFee);

    /// @notice When someone tries setting the queue length above the max
    /// @param providedLength The provided queue length
    /// @param maxLength The maximum queue length
    error ExceedsMaxQueueLengthSecs(uint64 providedLength, uint256 maxLength);

    /// @notice When someone tries setting the redemption fee above the max (100%)
    /// @param providedFee The provided redemption fee
    /// @param maxFee The maximum redemption fee
    error ExceedsMaxRedemptionFee(uint64 providedFee, uint64 maxFee);

    /// @notice Invalid ETH transfer during recoverEther
    error InvalidEthTransfer();

    /// @notice NFT is not mature enough to redeem yet
    /// @param currentTime Current time.
    /// @param maturity Time of maturity
    error NotMatureYet(uint256 currentTime, uint64 maturity);

    /// @notice Thrown if the sender is not the timelock or the operator
    error NotTimelockOrOperator();
}
