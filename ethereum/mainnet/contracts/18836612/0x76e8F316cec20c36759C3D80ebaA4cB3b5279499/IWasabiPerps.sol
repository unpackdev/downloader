// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IWasabiVault.sol";

interface IWasabiPerps {

    error LiquidationThresholdNotReached();
    error InvalidSignature();
    error PositionAlreadyTaken();
    error SwapFunctionNeeded();
    error OrderExpired();
    error InvalidCurrency();
    error InvalidTargetCurrency();
    error InsufficientAmountProvided();
    error PrincipalTooHigh();
    error InsufficientAvailablePrincipal();
    error InsufficientCollateralReceived();
    error SenderNotTrader();
    error InvalidPosition();
    error IncorrectSwapParameter();
    error EthTransferFailed(uint256 amount, address _target);
    error InvalidVault();
    error VaultAlreadyExists();
    error WithdrawerNotVault();
    error WithdrawalNotAllowed();
    error InterestAmountNeeded();

    event PositionOpened(
        uint256 positionId,
        address trader,
        address currency,
        address collateralCurrency,
        uint256 downPayment,
        uint256 principal,
        uint256 collateralAmount,
        uint256 feesToBePaid
    );

    event PositionClosed(
        uint256 id,
        address trader,
        uint256 payout,
        uint256 principalRepaid,
        uint256 interestPaid,
        uint256 feeAmount
    );

    event PositionLiquidated(
        uint256 id,
        address trader,
        uint256 payout,
        uint256 principalRepaid,
        uint256 interestPaid,
        uint256 feeAmount
    );

    /// @dev Emitted when a new vault is created
    event NewVault(address indexed pool, address indexed asset, address vault);

    /// @dev Defines a function call
    struct FunctionCallData {
        address to;
        uint256 value;
        bytes data;
    }

    /// @dev Defines a position
    /// @param id The unique identifier for the position.
    /// @param trader The address of the trader who opened the position.
    /// @param currency The address of the currency to be paid for the position.
    /// @param collateralCurrency The address of the currency to be received for the position.
    /// @param lastFundingTimestamp The timestamp of the last funding payment.
    /// @param downPayment The initial down payment amount required to open the position (is in `currency` for long, `collateralCurrency` for short positions)
    /// @param principal The total principal amount to be borrowed for the position (is in `currency`)
    /// @param collateralAmount The total collateral amount to be received for the position (is in `collateralCurrency`)
    /// @param feesToBePaid The total fees to be paid for the position (is in `currency`)
    struct Position {
        uint256 id;
        address trader;
        address currency;
        address collateralCurrency;
        uint256 lastFundingTimestamp;
        uint256 downPayment;
        uint256 principal;
        uint256 collateralAmount;
        uint256 feesToBePaid;
    }

    /// @dev Defines a request to open a position.
    /// @param id The unique identifier for the position.
    /// @param currency The address of the currency to be paid for the position.
    /// @param targetCurrency The address of the currency to be received for the position.
    /// @param downPayment The initial down payment amount required to open the position (is in `currency` for long, `collateralCurrency` for short positions)
    /// @param principal The total principal amount to be borrowed for the position.
    /// @param minTargetAmount The minimum amount of target currency to be received for the position to be valid.
    /// @param expiration The timestamp when this position request expires.
    /// @param fee The fee to be paid for the position
    /// @param functionCallDataList A list of FunctionCallData structures representing functions to call to open the position.
    struct OpenPositionRequest {
        uint256 id;
        address currency;
        address targetCurrency;
        uint256 downPayment;
        uint256 principal;
        uint256 minTargetAmount;
        uint256 expiration;
        uint256 fee;
        FunctionCallData[] functionCallDataList;
    }

    /// @dev Defines a request to close a position.
    /// @param _expiration The timestamp when this position request expires.
    /// @param _interest The interest to be paid for the position.
    /// @param _position The position to be closed.
    /// @param _functionCallDataList A list of FunctionCallData structures representing functions to call to close the position.
    struct ClosePositionRequest {
        uint256 expiration;
        uint256 interest;
        Position position;
        FunctionCallData[] functionCallDataList;
    }

    /// @dev Defines a signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev Opens a position
    /// @param _request the request to open a position
    /// @param _signature the signature of the request
    function openPosition(
        OpenPositionRequest calldata _request,
        Signature calldata _signature
    ) external payable;

    /// @dev Closes a position
    /// @param _unwrapWETH whether to unwrap WETH or not
    /// @param _request the request to close a position
    /// @param _signature the signature of the request
    function closePosition(
        bool _unwrapWETH,
        ClosePositionRequest calldata _request,
        Signature calldata _signature
    ) external payable;

    /// @dev Liquidates a position
    /// @param _unwrapWETH whether to unwrap WETH or not
    /// @param _interest the interest to be paid
    /// @param _position the position to liquidate
    /// @param _swapFunctions the swap functions to use to liquidate the position
    function liquidatePosition(
        bool _unwrapWETH,
        uint256 _interest,
        Position calldata _position,
        FunctionCallData[] calldata _swapFunctions
    ) external payable;

    /// @dev Liquidates a list of positions
    /// @param _unwrapWETH whether to unwrap WETH or not
    /// @param _interests the interests to be paid
    /// @param _positions the positions to liquidate
    /// @param _swapFunctions the swap functions to use to liquidate the positions
    function liquidatePositions(
        bool _unwrapWETH,
        uint256[] calldata _interests,
        Position[] calldata _positions,
        FunctionCallData[][] calldata _swapFunctions
    ) external payable;

    /// @dev Withdraws the given amount for the ERC20 token (or ETH) to the receiver
    /// @param _token the token to withdraw (zero address for ETH)
    /// @param _amount the amount to withdraw
    /// @param _receiver the receiver of the token
    function withdraw(address _token, uint256 _amount, address _receiver) external;

    /// @dev Returns the vault used for the given asset
    function getVault(address _asset) external view returns (IWasabiVault);

    /// @dev Adds a new vault
    function addVault(IWasabiVault _vault) external;
}