// SPDX-License-Identifier: ISC
pragma solidity ^0.8.23;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= SlippageAuction ==========================
// ====================================================================
// Dutch-style Auction. Starts at a high price and gradually decreases until the entire lot
// of tokens is sold, or the time expires.
// Frax Finance: https://github.com/FraxFinance

import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Timelock2Step.sol";
import "./IUniswapV2Callee.sol";

/// @title SlippageAuction
/// @notice Slippage auction to sell tokens over time. Created via factory.
/// @dev Both tokens must be 18 decimals.
/// @dev https://github.com/FraxFinance/frax-bonds
contract SlippageAuction is ReentrancyGuard, Timelock2Step {
    using SafeERC20 for IERC20;

    // ==============================================================================
    // Storage
    // ==============================================================================

    /// @notice The name of this auction
    string public name;

    /// @notice Slippage precision
    uint256 public constant PRECISION = 1e18;

    /// @notice Stored information about details
    Detail[] public details;

    /// @notice The token used for buying the tokenSell
    address public immutable TOKEN_BUY;

    /// @notice The token being auctioned off
    address public immutable TOKEN_SELL;

    /// @notice Alias for TOKEN_BUY
    /// @dev Maintains UniswapV2 interface
    address public immutable token0;

    /// @notice Alias for TOKEN_SELL
    /// @notice Maintains UniswapV2 interface
    address public immutable token1;

    // ==============================================================================
    // Structs
    // ==============================================================================

    /// @notice Detail information behind an auction
    /// @notice Auction information
    /// @param amountListed Amount of sellToken placed for auction
    /// @param amountLeft Amount of sellToken remaining to buy
    /// @param amountExcessBuy Amount of any additional TOKEN_BUY sent to contract during auction
    /// @param amountExcessSell Amount of any additional TOKEN_SELL sent to contract during auction
    /// @param tokenBuyReceived Amount of tokenBuy that came in from sales
    /// @param priceLast Price of the last sale, in tokenBuy amount per tokenSell (amount of tokenBuy to purchase 1e18 tokenSell)
    /// @param priceMin Minimum price of 1e18 tokenSell, in tokenBuy
    /// @param priceDecay Price decay, (wei per second), using PRECISION
    /// @param priceSlippage Slippage fraction. E.g (0.01 * PRECISION) = 1%
    /// @param lastBuyTime Time of the last sale
    /// @param expiry UNIX timestamp when the auction ends
    /// @param active If the auction is active
    struct Detail {
        uint128 amountListed;
        uint128 amountLeft;
        uint128 amountExcessBuy;
        uint128 amountExcessSell;
        uint128 tokenBuyReceived;
        uint128 priceLast;
        uint128 priceMin;
        uint64 priceDecay;
        uint64 priceSlippage;
        uint32 lastBuyTime;
        uint32 expiry;
        bool active;
    }

    // ==============================================================================
    // Constructor
    // ==============================================================================

    /// @param _timelock Address of the timelock/owner
    /// @param _tokenBuy Token used to purchase _tokenSell
    /// @param _tokenSell Token sold in the auction
    constructor(address _timelock, address _tokenBuy, address _tokenSell) Timelock2Step(_timelock) {
        name = string(abi.encodePacked("SlippageAuction: ", IERC20Metadata(_tokenSell).symbol()));
        TOKEN_BUY = _tokenBuy;
        TOKEN_SELL = _tokenSell;

        token0 = _tokenBuy;
        token1 = _tokenSell;
    }

    // ==============================================================================
    // Views
    // ==============================================================================

    /// @notice Returns the semantic version of this contract
    /// @return _major The major version
    /// @return _minor The minor version
    /// @return _patch The patch version
    function version() external pure returns (uint256 _major, uint256 _minor, uint256 _patch) {
        return (1, 0, 0);
    }

    /// @notice Calculates the pre-slippage price (with the user supplied auction _detail) from the time decay alone
    /// @param _detail The auction struct
    /// @return _price The price
    function getPreSlippagePrice(Detail memory _detail) public view returns (uint256 _price) {
        // Calculate Decay
        uint256 _decay = (_detail.priceDecay * (block.timestamp - _detail.lastBuyTime));

        // Calculate the sale price (in tokenBuy per tokenSell), factoring in the time decay
        if (_detail.priceLast < _decay) {
            return _price = _detail.priceMin;
        } else {
            _price = _detail.priceLast - _decay;
        }

        // Never go below the minimum price
        if (_price < _detail.priceMin) _price = _detail.priceMin;
    }

    /// @notice Calculates the pre-slippage price (with the current auction) from the time decay alone
    function getPreSlippagePrice() external view returns (uint256) {
        return getPreSlippagePrice(details[details.length - 1]);
    }

    /// @notice Calculates the amount of tokenSells out for a given tokenBuy amount
    /// @param amountIn Amount of tokenBuy in
    /// @param _revertOnOverAmountLeft Whether to revert if amountOut > amountLeft
    /// @return amountOut Amount of tokenSell out
    /// @return _slippagePerTokenSell The slippage component of the price change (in tokenBuy per tokenSell)
    /// @return _postPriceSlippage The post-slippage price from the time decay + slippage
    function getAmountOut(
        uint256 amountIn,
        bool _revertOnOverAmountLeft
    ) public view returns (uint256 amountOut, uint256 _slippagePerTokenSell, uint256 _postPriceSlippage) {
        // Get the auction number
        uint256 _auctionNumber = details.length - 1;

        // Get the auction info
        Detail memory _detail = details[_auctionNumber];

        // Revert if the auction is inactive or expired
        if (!_detail.active) revert AuctionNotActive();
        if (block.timestamp >= _detail.expiry) revert AuctionExpired();

        // Calculate the sale price (in tokenBuy per tokenSell), factoring in the time decay
        uint256 _preSlippagePrice = getPreSlippagePrice({ _detail: _detail });

        // Calculate the slippage component of the price (in tokenBuy per tokenSell)
        _slippagePerTokenSell = (_detail.priceSlippage * amountIn) / PRECISION;

        // Calculate the output amount of tokenSell
        amountOut = (amountIn * PRECISION) / (_preSlippagePrice + _slippagePerTokenSell);

        // Make sure you are not going over the amountLeft
        if (amountOut > _detail.amountLeft) {
            if (_revertOnOverAmountLeft) revert InsufficientTokenSellsAvailable();
            else amountOut = _detail.amountLeft;
        }

        // Set return value
        _postPriceSlippage = _preSlippagePrice + (2 * _slippagePerTokenSell); // Price impact is twice the slippage
    }

    /// @notice Calculates how much tokenBuy you would need to buy out the remaining tokenSell in the auction
    /// @return amountIn Amount of tokenBuy needed
    /// @return _slippagePerTokenSell The slippage component of the price change (in tokenBuy per tokenSell)
    /// @return _postPriceSlippage The post-slippage price from the time decay + slippage
    function getAmountInMax()
        external
        view
        returns (uint256 amountIn, uint256 _slippagePerTokenSell, uint256 _postPriceSlippage)
    {
        // Get the auction number
        uint256 _auctionNumber = details.length - 1;

        // Get the auction info
        Detail memory detail = details[_auctionNumber];

        // Call the internal function with amountLeft
        return _getAmountIn({ _detail: detail, amountOut: detail.amountLeft });
    }

    /// @notice Calculates how much tokenBuy you would need in order to obtain a given number of tokenSell
    /// @param amountOut The desired amount of tokenSell
    /// @return amountIn Amount of tokenBuy needed
    /// @return _slippagePerTokenSell The slippage component of the price change (in tokenBuy per tokenSell)
    /// @return _postPriceSlippage The post-slippage price from the time decay + slippage
    function getAmountIn(
        uint256 amountOut
    ) public view returns (uint256 amountIn, uint256 _slippagePerTokenSell, uint256 _postPriceSlippage) {
        // Get the auction number
        uint256 _auctionNumber = details.length - 1;

        // Get the auction info
        Detail memory detail = details[_auctionNumber];

        // Call the internal function with amountOut, set return values
        (amountIn, _slippagePerTokenSell, _postPriceSlippage) = _getAmountIn({ _detail: detail, amountOut: amountOut });
    }

    /// @notice Calculate how much tokenBuy you would need to obtain a given number of tokenSell
    /// @param _detail The auction struct
    /// @return amountIn Amount of tokenBuy needed
    /// @return _slippagePerTokenSell The slippage component of the price change (in tokenBuy per tokenSell)
    /// @return _postPriceSlippage The post-slippage price from the time decay + slippage
    function _getAmountIn(
        Detail memory _detail,
        uint256 amountOut
    ) internal view returns (uint256 amountIn, uint256 _slippagePerTokenSell, uint256 _postPriceSlippage) {
        // Do checks
        if (!_detail.active) revert AuctionNotActive();
        if (block.timestamp >= _detail.expiry) revert AuctionExpired();
        if (amountOut > _detail.amountLeft) revert InsufficientTokenSellsAvailable();

        // Calculate the sale price (in tokenBuy per tokenSell), factoring in the time decay
        uint256 _preSlippagePrice = getPreSlippagePrice({ _detail: _detail });

        // Math in a more readable format:
        // uint256 _numerator = (amountOut * _preSlippagePrice) / PRECISION;
        // uint256 _denominator = (PRECISION -
        //     ((amountOut * uint256(_detail.priceSlippage)) / PRECISION));
        // amountIn = (_numerator * PRECISION) / _denominator;

        // Set return params amountIn
        amountIn =
            (amountOut * _preSlippagePrice) /
            (PRECISION - (amountOut * uint256(_detail.priceSlippage)) / PRECISION);

        // Set return params, calculate the slippage component of the price (in tokenBuy per tokenSell)
        _slippagePerTokenSell = (_detail.priceSlippage * amountIn) / PRECISION;
        _postPriceSlippage = _preSlippagePrice + (2 * _slippagePerTokenSell); // Price impact is twice the slippage
    }

    /// @notice Calculates how much tokenBuy you would need in order to obtain a given number of tokenSell
    /// @dev Maintains compatibility with some router implementations
    /// @param amountOut The amount out of sell tokens
    /// @param tokenOut The sell token address
    /// @return amountIn The amount of tokenBuy needed
    function getAmountIn(uint256 amountOut, address tokenOut) public view returns (uint256 amountIn) {
        if (tokenOut != TOKEN_SELL) revert InvalidTokenOut();
        (amountIn, , ) = getAmountIn({ amountOut: amountOut });
    }

    /// @notice Calculates the amount of tokenSell out for a given tokenBuy amount
    /// @dev Used to maintain compatibility
    /// @param amountIn Amount of tokenBuy in
    /// @param tokenIn The token being swapped in
    /// @return amountOut Amount of tokenSells out
    function getAmountOut(uint256 amountIn, address tokenIn) public view returns (uint256 amountOut) {
        if (tokenIn != TOKEN_BUY) revert InvalidTokenIn();
        (amountOut, , ) = getAmountOut({ amountIn: amountIn, _revertOnOverAmountLeft: false });
    }

    /// @dev Uni v2 support without revert
    function skim(address) external pure {
        return;
    }

    /// @dev Uni v2 support without revert
    function sync() external pure {
        return;
    }

    function getAmountOut(uint256, uint256, uint256) external pure returns (uint256) {
        revert NotImplemented();
    }

    function getAmountIn(uint256, uint256, uint256) external pure returns (uint256) {
        revert NotImplemented();
    }

    function getReserves() external pure returns (uint112, uint112, uint32) {
        revert NotImplemented();
    }

    function price0CumulativeLast() external pure returns (uint256) {
        revert NotImplemented();
    }

    function price1CumulativeLast() external pure returns (uint256) {
        revert NotImplemented();
    }

    function kLast() external pure returns (uint256) {
        revert NotImplemented();
    }

    function factory() external pure returns (address) {
        revert NotImplemented();
    }

    function MINIMUM_LIQUIDITY() external pure returns (uint256) {
        revert NotImplemented();
    }

    function initialize(address, address) external pure {
        revert NotImplemented();
    }

    /// @notice Gets a struct instead of a tuple for details()
    /// @param _auctionNumber Detail ID
    /// @return The struct of the auction
    function getDetailStruct(uint256 _auctionNumber) external view returns (Detail memory) {
        return details[_auctionNumber];
    }

    /// @notice Returns the length of the details array
    /// @return _length The length of the details array
    function detailsLength() external view returns (uint256 _length) {
        _length = details.length;
    }

    /// @notice Returns the latest auction
    /// @dev Returns an empty struct if there are no auctions
    /// @return _latestAuction The latest auction struct
    function getLatestAuction() external view returns (Detail memory _latestAuction) {
        uint256 _length = details.length;
        if (_length == 0) return _latestAuction;
        _latestAuction = details[details.length - 1];
    }

    // ==============================================================================
    // Owner-only Functions
    // ==============================================================================

    /// @notice Parameters for starting an auction
    /// @dev Sender must have an allowance on tokenSell
    /// @param amountListed Amount of tokenSell being sold
    /// @param priceStart Starting price of 1e18 tokenSell, in tokenBuy
    /// @param priceMin Minimum price of 1e18 tokenSell, in tokenBuy
    /// @param priceDecay Price decay, (wei per second), using PRECISION
    /// @param priceSlippage Slippage fraction. E.g (0.01 * PRECISION) = 1%
    /// @param expiry UNIX timestamp when the auction ends
    struct StartAuctionParams {
        uint128 amountListed;
        uint128 priceStart;
        uint128 priceMin;
        uint64 priceDecay;
        uint64 priceSlippage;
        uint32 expiry;
    }

    /// @notice Starts a new auction
    /// @dev Requires an ERC20 allowance on the tokenSell prior to calling
    /// @param _params StartAuctionParams
    function startAuction(StartAuctionParams calldata _params) external nonReentrant returns (uint256 _auctionNumber) {
        _requireSenderIsTimelock();

        // Check expiry is not in the past
        if (_params.expiry < block.timestamp) revert Expired();

        // Ensure that enough amountListed are for sale to prevent round-down errors
        // see E2E test for 1e6 requirement.  At 1e8 requirement, there should be enough trades
        // to constitute an auction.
        if (_params.amountListed < 1e8) revert AmountListedTooLow();

        // Ensure that priceStart > priceMin
        if (_params.priceStart < _params.priceMin) revert PriceStartLessThanPriceMin();

        // Ensure slippage does not exceed max of 50%
        if (_params.priceSlippage >= PRECISION / 2) revert PriceSlippageTooHigh();

        // Prevent edge-case revert of amountOut within getAmountOut
        if (_params.priceMin == 0 && _params.priceSlippage == 0) revert PriceMinAndSlippageBothZero();

        // Pre-compute the auction number
        _auctionNumber = details.length;

        // Ensure that the previous auction, if any, has been stopped
        if (_auctionNumber > 0) {
            Detail memory _lastAuction = details[_auctionNumber - 1];
            if (_lastAuction.active) revert LastAuctionStillActive();
        }

        // Create the auction
        details.push(
            Detail({
                amountListed: _params.amountListed,
                amountLeft: _params.amountListed,
                amountExcessBuy: 0,
                amountExcessSell: 0,
                tokenBuyReceived: 0,
                priceLast: _params.priceStart,
                priceMin: _params.priceMin,
                priceDecay: _params.priceDecay,
                priceSlippage: _params.priceSlippage,
                lastBuyTime: uint32(block.timestamp),
                expiry: _params.expiry,
                active: true
            })
        );

        emit AuctionStarted({
            auctionNumber: _auctionNumber,
            amountListed: _params.amountListed,
            priceStart: _params.priceStart,
            priceMin: _params.priceMin,
            priceDecay: _params.priceDecay,
            priceSlippage: _params.priceSlippage,
            expiry: _params.expiry
        });

        // Clear out any tokens held by the auction so that bookkeeping is accurate
        _withdrawAnyAvailableTokens({ _excess: true });

        // Take the tokenSells from the sender
        IERC20(TOKEN_SELL).safeTransferFrom(msg.sender, address(this), _params.amountListed);
    }

    /// @notice Ends the auction
    /// @dev Only callable by the auction owner
    /// @return tokenBuyReceived Amount of tokenBuy obtained from the auction
    /// @return tokenSellRemaining Amount of unsold tokenSell left over
    function stopAuction() public nonReentrant returns (uint256 tokenBuyReceived, uint256 tokenSellRemaining) {
        _requireSenderIsTimelock();

        // Get the auction info and perform checks
        uint256 _auctionNumber = details.length - 1;
        Detail storage detail = details[_auctionNumber];
        if (!detail.active) revert AuctionNotActive();

        // Skim excess token to sender if additional has been received to keep bookkeeping accurate
        _withdrawIfTokenBalance({ _token: TOKEN_BUY, _priorBalance: detail.tokenBuyReceived, _excess: true });
        _withdrawIfTokenBalance({ _token: TOKEN_SELL, _priorBalance: detail.amountLeft, _excess: true });

        // Set Return params
        tokenBuyReceived = IERC20(TOKEN_BUY).balanceOf(address(this));
        tokenSellRemaining = IERC20(TOKEN_SELL).balanceOf(address(this));

        // Effects: Update state with final balances;
        detail.active = false;
        detail.tokenBuyReceived = uint128(tokenBuyReceived);
        detail.amountLeft = uint128(tokenSellRemaining);

        // Return any TOKEN_BUY and TOKEN_SELL from the auction to the timelock
        _withdrawAnyAvailableTokens({ _excess: false });

        emit AuctionStopped({
            auctionNumber: _auctionNumber,
            tokenBuyReceived: tokenBuyReceived,
            tokenSellRemaining: tokenSellRemaining
        });
    }

    // ==============================================================================
    // Public Functions
    // ==============================================================================

    /// @notice Swaps tokenBuys for tokenSells
    /// @dev This low-level function should be called from a contract which performs important safety checks
    /// @dev Token0 is always the TOKEN_BUY, token1 is always the TOKEN_SELL
    /// @dev Maintains uniV2 interface
    /// @param amount0Out The amount of tokenBuys to receive
    /// @param amount1Out The amount of tokenSells to receive
    /// @param to The recipient of the output tokens
    /// @param data Callback data
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes memory data) public nonReentrant {
        if (amount0Out != 0) revert ExcessiveTokenBuyOut({ minOut: 0, actualOut: amount0Out });
        if (amount1Out == 0) revert InsufficientOutputAmount({ minOut: 1, actualOut: 0 });

        // Get the auction info (similar to get reserves in univ2)
        uint256 _auctionNumber = details.length - 1;
        Detail memory detail = details[_auctionNumber];

        // Transfer tokens
        IERC20(TOKEN_SELL).safeTransfer(to, amount1Out);

        // Callback if necessary for flash swap
        if (data.length > 0) {
            IUniswapV2Callee(to).uniswapV2Call({
                sender: msg.sender,
                amount0: amount0Out,
                amount1: amount1Out,
                data: data
            });
        }

        // Calculate the amount of tokenBuys in
        uint256 _tokenBuyBalance = IERC20(TOKEN_BUY).balanceOf(address(this));
        uint256 _tokenBuyIn = _tokenBuyBalance - detail.tokenBuyReceived;

        // Adheres to uniswap v2 interface, called here to prevent stack-too-deep error
        emit Swap({
            sender: msg.sender,
            amount0In: _tokenBuyIn,
            amount1In: 0,
            amount0Out: 0,
            amount1Out: amount1Out,
            to: to
        });

        // Call the internal function with amountOut
        (uint256 _minAmountIn, uint256 _slippagePerTokenSell, uint256 _postPriceSlippage) = _getAmountIn({
            _detail: detail,
            amountOut: amount1Out
        });

        // Check invariants
        if (_tokenBuyIn < _minAmountIn) revert InsufficientInputAmount({ minIn: _minAmountIn, actualIn: _tokenBuyIn });
        if (_minAmountIn == 0) revert InputAmountZero();

        // Mutate _auction, which has the previous state
        detail.amountLeft -= safeUint128(amount1Out);
        detail.tokenBuyReceived = safeUint128(_tokenBuyBalance);
        detail.priceLast = safeUint128(_postPriceSlippage);
        detail.lastBuyTime = uint32(block.timestamp);

        // Write back to state, similar to _update in univ2
        details[_auctionNumber] = detail;

        // Emit Buy event
        emit Buy({
            auctionNumber: _auctionNumber,
            tokenBuy: TOKEN_BUY,
            tokenSell: TOKEN_SELL,
            amountIn: safeUint128(_tokenBuyIn),
            amountOut: safeUint128(amount1Out),
            priceLast: detail.priceLast,
            slippagePerTokenSell: safeUint128(_slippagePerTokenSell)
        });
    }

    /// @notice Swaps an exact amount of input tokens for as many output tokens as possible
    /// @dev Must have an allowance on the TOKEN_BUY prior to invocation
    /// @dev Maintains uniV2 interface
    /// @param amountIn The amount of buy tokens to send.
    /// @param amountOutMin The minimum amount of sell tokens that must be received for the transaction not to revert
    /// @param to Recipient of the output tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return _amounts The input token amount and output token amount
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory _amounts) {
        path; // compile warnings

        // Ensure deadline has not passed
        if (block.timestamp > deadline) revert Expired();

        // Calculate the amount of tokenSells out & check invariant
        (uint256 amountOut, , ) = getAmountOut({ amountIn: amountIn, _revertOnOverAmountLeft: true });
        if (amountOut < amountOutMin) {
            revert InsufficientOutputAmount({ minOut: amountOutMin, actualOut: amountOut });
        }
        // Interactions: Transfer tokenBuys to the contract
        IERC20(TOKEN_BUY).safeTransferFrom(msg.sender, address(this), amountIn);

        // Call the swap function
        swap({ amount0Out: 0, amount1Out: amountOut, to: to, data: new bytes(0) });

        // Set return values
        _amounts = new uint256[](2);
        _amounts[0] = amountIn;
        _amounts[1] = amountOut;
    }

    /// @notice Receives an exact amount of output tokens for as few input tokens as possible
    /// @dev Must have an allowance on the TOKEN_BUY prior to invocation
    /// @dev Maintains uniV2 interface
    /// @param amountOut The amount of sell tokens to receive
    /// @param amountInMax The maximum amount of buy tokens that can be required before the transaction reverts
    /// @param to Recipient of the output tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return _amounts The input token amount and output token amount
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory _amounts) {
        path; // compile warning

        // Ensure deadline has not passed
        if (block.timestamp > deadline) revert Expired();

        // Calculate the amount of tokenBuys in & check invariant
        (uint256 amountIn, , ) = getAmountIn({ amountOut: amountOut });
        if (amountIn > amountInMax) revert ExcessiveInputAmount({ minIn: amountInMax, actualIn: amountIn });

        // Interactions: Transfer tokenBuys to the contract
        IERC20(TOKEN_BUY).safeTransferFrom(msg.sender, address(this), amountIn);

        // Call the swap function
        swap({ amount0Out: 0, amount1Out: amountOut, to: to, data: new bytes(0) });

        // Set return variable
        _amounts = new uint256[](2);
        _amounts[0] = amountIn;
        _amounts[1] = amountOut;
    }

    // ==============================================================================
    // Helpers
    // ==============================================================================

    /// @notice Withdraw available TOKEN_BUY and TOKEN_SELL on startAuction() and stopAuction()
    /// @param _excess Whether to bookkeep any excess tokens received outside of auction
    function _withdrawAnyAvailableTokens(bool _excess) private {
        _withdrawIfTokenBalance({ _token: TOKEN_BUY, _priorBalance: 0, _excess: _excess });
        _withdrawIfTokenBalance({ _token: TOKEN_SELL, _priorBalance: 0, _excess: _excess });
    }

    /// @notice Withdraw available TOKEN_BUY and TOKEN_SELL on startAuction() and stopAuction()
    /// @param _token Address of the token you want to withdraw
    /// @param _priorBalance Prior balance of the _token
    /// @param _excess Whether to bookkeep any excess tokens received outside of auction
    function _withdrawIfTokenBalance(address _token, uint256 _priorBalance, bool _excess) private {
        // Fetch the current balance of _token
        uint256 balance = IERC20(_token).balanceOf(address(this));

        // If the current balance is higher than the prior balance
        if (balance > _priorBalance) {
            uint256 amount = balance - _priorBalance;

            // Bookkeep any excess token received
            if (_excess) {
                Detail storage detail = details[details.length - 1];
                if (_token == TOKEN_BUY) {
                    detail.amountExcessBuy += safeUint128(amount);
                } else {
                    // token == TOKEN_SELL
                    detail.amountExcessSell += safeUint128(amount);
                }
            }

            IERC20(_token).safeTransfer(msg.sender, amount);
        }
    }

    /// @dev Overflow protection
    function safeUint128(uint256 number) internal pure returns (uint128 casted) {
        if (number > type(uint128).max) revert Overflow();
        casted = uint128(number);
    }

    // ==============================================================================
    // Errors
    // ==============================================================================

    /// @notice Emitted when a user attempts to start an auction selling too few tokens
    error AmountListedTooLow();

    /// @notice Emitted when a user attempts to end an auction that has been stopped
    error AuctionNotActive();

    /// @notice Emitted when a user attempts to interact with an auction that has expired
    error AuctionExpired();

    /// @notice Emitted when a user attempts to start a new auction before the previous one has been stopped (via ```stopAuction()```)
    error LastAuctionStillActive();

    /// @notice Emitted when a user attempts to swap a given amount of buy tokens that would result in an insufficient amount of sell tokens
    /// @param minOut Minimum out that the user expects
    /// @param actualOut Actual amount out that would occur
    error InsufficientOutputAmount(uint256 minOut, uint256 actualOut);

    /// @notice Emitted when a user attempts to swap an insufficient amount of buy tokens
    /// @param minIn Minimum in that the contract requires
    /// @param actualIn Actual amount in that has been deposited
    error InsufficientInputAmount(uint256 minIn, uint256 actualIn);

    /// @notice Emitted when a user attempts to swap an excessive amount of buy tokens for aa given amount of sell tokens
    /// @param minIn    Minimum in that the user expects
    /// @param actualIn Actual amount in that would occur
    error ExcessiveInputAmount(uint256 minIn, uint256 actualIn);

    /// @notice Emitted when a user attempts to buy more sell tokens than are left in the auction
    error InsufficientTokenSellsAvailable();

    /// @notice Emitted when attempting to swap where the calculated amountIn is 0
    error InputAmountZero();

    /// @notice Emitted when a user attempts to buy the tokenBuy using the swap() function
    error ExcessiveTokenBuyOut(uint256 minOut, uint256 actualOut);

    /// @notice Emitted when a user attempts to make a swap after the transaction deadline has passed
    error Expired();

    /// @notice Emitted when a user attempts to use an invalid buy token
    error InvalidTokenIn();

    /// @notice Emitted when a user attempts to use an invalid sell token
    error InvalidTokenOut();

    /// @notice Emitted when calling `startAuction()` when `StartAuctionParams.priceMin == 0 && StartAuctionParams.priceSlippage == 0`
    error PriceMinAndSlippageBothZero();

    /// @notice Emitted when attempting to call a uni-v2 pair function that is not supported by this contract
    error NotImplemented();

    /// @notice Emitted when downcasting a uint on type overflow
    error Overflow();

    /// @notice Emitted when a user attempts to start an auction with `_params.priceStart < _params.priceMin`
    error PriceStartLessThanPriceMin();

    /// @notice Emitted when attempting to call `startAuction()` where `priceSlippage >= PRECISION`
    error PriceSlippageTooHigh();

    // ==============================================================================
    // Events
    // ==============================================================================

    /// @dev Emitted when an auction is stopped
    /// @param auctionNumber The ID of the auction
    /// @param tokenBuyReceived Amount of tokenBuy obtained from the auction
    /// @param tokenSellRemaining Amount of unsold tokenSells left over
    event AuctionStopped(uint256 auctionNumber, uint256 tokenBuyReceived, uint256 tokenSellRemaining);

    /// @dev Emitted when a swap occurs and has more information than the ```Swap``` event
    /// @param auctionNumber The ID of the auction, and index in the details array
    /// @param tokenBuy The token used to buy the tokenSell being auctioned off
    /// @param tokenSell The token being auctioned off
    /// @param amountIn Amount of tokenBuy in
    /// @param amountOut Amount of tokenSell out
    /// @param priceLast The execution price of the buy
    /// @param slippagePerTokenSell How many tokenBuys (per tokenSell) were added as slippage
    event Buy(
        uint256 auctionNumber,
        address tokenBuy,
        address tokenSell,
        uint128 amountIn,
        uint128 amountOut,
        uint128 priceLast,
        uint128 slippagePerTokenSell
    );

    /// @notice Emitted when a swap occurs
    /// @param sender The address of the sender
    /// @param amount0In The amount of TOKEN_BUY in
    /// @param amount1In The amount of TOKEN_SELL in
    /// @param amount0Out The amount of TOKEN_BUY out
    /// @param amount1Out The amount of TOKEN_SELL out
    /// @param to The address of the recipient
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /// @dev Emitted when an auction is started
    /// @param auctionNumber The ID of the auction
    /// @param amountListed Amount of tokenSell being sold
    /// @param priceStart Starting price of the tokenSell, in tokenBuy
    /// @param priceMin Minimum price of the tokenSell, in tokenBuy
    /// @param priceDecay Price decay, per day, using PRECISION
    /// @param priceSlippage Slippage fraction. E.g (0.01 * PRECISION) = 1%
    /// @param expiry Expiration time of the auction
    event AuctionStarted(
        uint256 auctionNumber,
        uint128 amountListed,
        uint128 priceStart,
        uint128 priceMin,
        uint128 priceDecay,
        uint128 priceSlippage,
        uint32 expiry
    );
}
