pragma solidity 0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./BurnTokens.sol";
import "./FeeCalculator.sol";
import "./FeeOperator.sol";
import "./SafeERC20TransferFrom.sol";
import "./ICircleTokenMessenger.sol";
import "./Admin.sol";

/**
 * @title TokenRouter
 * @notice Calls Circle's TokenMessenger contract to burn tokens on source chain
 */
contract TokenRouter is FeeCalculator, FeeOperator, BurnTokens, Pausable {
    using SafeERC20 for IERC20;

    ICircleTokenMessenger public immutable circleTokenMessenger;
    address public immutable circleTokenMessengerAddress;

    // ============ Events ============
    /**
     * @notice Emitted when a DepositToken message is sent. Similar as DepositForBurn event in TokenMessenger contract
     * https://github.com/circlefin/evm-cctp-contracts/blob/master/src/TokenMessenger.sol
     * @param nonce unique nonce reserved by message
     * @param burnToken address of token burnt on source domain
     * @param amount deposit amount
     * @param depositor address where deposit is transferred from
     * @param mintRecipient address receiving minted tokens on destination domain as bytes32
     * @param destinationDomain destination domain
     * @param totalFee fee amount
     */
    event TransferTokens(
        uint64 nonce, 
        address burnToken, 
        uint256 amount, 
        address depositor, 
        address mintRecipient, 
        uint32 destinationDomain,
        uint256 totalFee
    );

    // Errors
    error InvalidTokenMessengerAddress();
    error InvalidMintRecipientAddress();
    error AmountLessThanFee();

    // ============ Constructor ============
    /**
     * @param circleTokenMessenger_ Cirle's TokenMessenger contract address
     * @param burnToken_ address of burnToken.
     */
    constructor (address circleTokenMessenger_, address burnToken_) BurnTokens(burnToken_) {
        if (circleTokenMessenger_ == address(0)) {
            revert InvalidTokenMessengerAddress();
        }

        circleTokenMessenger = ICircleTokenMessenger(circleTokenMessenger_);
        circleTokenMessengerAddress = circleTokenMessenger_;
    }

    // ============ External Functions  ============
    /**
     * @notice Collects fee from sender and calls Circle's TokenMessenger contract to burn tokens.
     * Emits a `TransferTokens` event.
     * @dev It defines same input parameters as depositForBurn in TokenMessenger contract
     * https://github.com/circlefin/evm-cctp-contracts/blob/master/src/TokenMessenger.sol
     * Modifications:
     * mintRecipient is address instead of bytes32
     * @param amount amount of tokens to burn
     * @param destinationDomain destination domain
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @return nonce unique nonce reserved by message
     */
    function transferTokens(
        uint256 amount, 
        uint32 destinationDomain,
        address mintRecipient,
        address burnToken
    )
        external 
        nonReentrant 
        whenNotPaused 
        returns (uint64 nonce) 
    {
        if (mintRecipient == address(0)) {
            revert InvalidMintRecipientAddress();
        }
        if (!isSupportedBurnToken(burnToken)) {
            revert BurnTokens.UnSupportedBurnToken();
        }

        uint256 fee = calculateFee(amount, destinationDomain);
        if (amount <= fee) {
            revert AmountLessThanFee();
        }

        IERC20 token = IERC20(burnToken);

        uint256 transferredAmount = SafeERC20TransferFrom.safeTransferFrom(token, amount);

        uint256 bridgeAmt = transferredAmount - fee;
        token.safeIncreaseAllowance(circleTokenMessengerAddress, bridgeAmt);

        bytes32 mintRecipientBytes32 = bytes32(uint256(uint160(mintRecipient)));

        nonce = circleTokenMessenger.depositForBurn(bridgeAmt, destinationDomain, mintRecipientBytes32, burnToken);

        emit TransferTokens(nonce, burnToken, amount, msg.sender, mintRecipient, destinationDomain, fee);
    }

    /**
     * @notice pause the contract
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * @notice unpause the contract 
     */
    function unpause() public onlyAdmin {
        _unpause();
    }
}
