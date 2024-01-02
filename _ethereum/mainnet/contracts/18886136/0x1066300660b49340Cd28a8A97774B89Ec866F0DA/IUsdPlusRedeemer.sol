// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "./IERC20.sol";
import "./AggregatorV3Interface.sol";

import "./UsdPlus.sol";
import "./StakedUsdPlus.sol";

interface IUsdPlusRedeemer {
    struct Request {
        address owner;
        address receiver;
        IERC20 paymentToken;
        uint256 paymentTokenAmount;
        uint256 usdplusAmount;
    }

    event PaymentTokenOracleSet(IERC20 indexed paymentToken, AggregatorV3Interface oracle);
    event RequestCreated(
        uint256 indexed ticket,
        address indexed receiver,
        IERC20 paymentToken,
        uint256 paymentTokenAmount,
        uint256 usdplusAmount
    );
    event RequestCancelled(uint256 indexed ticket, address indexed to);
    event RequestFulfilled(
        uint256 indexed ticket,
        address indexed receiver,
        IERC20 paymentToken,
        uint256 paymentTokenAmount,
        uint256 usdplusAmount
    );

    error PaymentTokenNotAccepted();
    error InvalidTicket();

    /// @notice USD+
    function usdplus() external view returns (UsdPlus);

    /// @notice stUSD+
    function stakedUsdplus() external view returns (StakedUsdPlus);

    /// @notice Oracle for payment token
    /// @param paymentToken payment token
    /// @dev address(0) if payment token not accepted
    function paymentTokenOracle(IERC20 paymentToken) external view returns (AggregatorV3Interface oracle);

    /// @notice get request info
    /// @param ticket request ticket number
    function requests(uint256 ticket) external view returns (Request memory);

    /// @notice get next request ticket number
    function nextTicket() external view returns (uint256);

    /// @notice get oracle price for payment token
    /// @param paymentToken payment token
    function getOraclePrice(IERC20 paymentToken) external view returns (uint256 price, uint8 decimals);

    /// @notice calculate payment token amount received for burning USD+
    /// @param paymentToken payment token
    /// @param paymentTokenAmount amount of payment token
    function previewWithdraw(IERC20 paymentToken, uint256 paymentTokenAmount)
        external
        view
        returns (uint256 usdplusAmount);

    /// @notice create a request to burn USD+ for payment
    /// @param paymentToken payment token
    /// @param paymentTokenAmount amount of payment token
    /// @param receiver recipient
    /// @param owner USD+ owner
    /// @return ticket request ticket number
    /// @dev exchange rate fixed at time of request creation
    function requestWithdraw(IERC20 paymentToken, uint256 paymentTokenAmount, address receiver, address owner)
        external
        returns (uint256 ticket);

    /// @notice calculate payment token amount received for burning USD+
    /// @param paymentToken payment token
    /// @param usdplusAmount amount of USD+ to burn
    function previewRedeem(IERC20 paymentToken, uint256 usdplusAmount)
        external
        view
        returns (uint256 paymentTokenAmount);

    /// @notice create a request to burn USD+ for payment
    /// @param paymentToken payment token
    /// @param usdplusAmount amount of USD+ to burn
    /// @param receiver recipient
    /// @param owner USD+ owner
    /// @return ticket request ticket number
    /// @dev exchange rate fixed at time of request creation
    function requestRedeem(IERC20 paymentToken, uint256 usdplusAmount, address receiver, address owner)
        external
        returns (uint256 ticket);

    /// @notice calculate payment token amount received for unstaking stUSD+ and burning USD+
    /// @param paymentToken payment token
    /// @param stakedUsdplusAmount amount of stUSD+
    function previewUnstakeAndRedeem(IERC20 paymentToken, uint256 stakedUsdplusAmount)
        external
        view
        returns (uint256 paymentTokenAmount);

    /// @notice unstake stUSD+ and create a request to burn USD+ for payment
    /// @param paymentToken payment token
    /// @param stakedUsdplusAmount amount of stUSD+ to unstake
    /// @param receiver recipient
    /// @param owner stUSD+ owner
    /// @return ticket request ticket number
    /// @dev exchange rate fixed at time of request creation
    function unstakeAndRequestRedeem(IERC20 paymentToken, uint256 stakedUsdplusAmount, address receiver, address owner)
        external
        returns (uint256 ticket);

    /// @notice fulfill a request to burn USD+ for payment
    /// @param ticket request ticket number
    function fulfill(uint256 ticket) external;

    /// @notice cancel a request to burn USD+ for payment
    /// @param ticket request ticket number
    function cancel(uint256 ticket) external;
}
