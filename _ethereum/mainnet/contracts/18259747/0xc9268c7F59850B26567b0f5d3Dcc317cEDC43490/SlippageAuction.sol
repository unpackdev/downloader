// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

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
// Slippage auction to sell tokens over time.  Both tokens must be 18 decimals.
// It has 3 parameters:
// - amount of sell token to auction
// - slippage per token bought
// - price decrease per day.
// For this we can calculate the time the auction will operate at the market price.
// Example:
// - We auction 10M
// - We pick a slippage such that a 100k buy will result in 0.1% slippage
// => 10M = 100x100k, so total price impact during the auction will be 20% (price impact is twice the slippage)
// - We lower the price 1% per day
// => the auction will be at the market price for at least 20 days.

// Frax Finance: https://github.com/FraxFinance

import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Timelock2Step.sol";
import "./IUniswapV2Callee.sol";

/// @title SlippageAuction
/// @notice Slippage auction to sell tokens over time.
/// @dev Both tokens must be 18 decimals.
contract SlippageAuction is ReentrancyGuard, Timelock2Step {
    using SafeERC20 for IERC20;

    // ==============================================================================
    // Storage
    // ==============================================================================

    /// @notice The name of this auction
    string public name;

    /// @notice Slippage precision
    uint256 public constant PRECISION = 1e18;

    /// @notice Stored information about auctions
    Auction[] public auctions;

    /// @notice The token used for buying the sellToken
    address public immutable BUY_TOKEN;

    /// @notice The token being auctioned off
    address public immutable SELL_TOKEN;

    /// @notice token0 to adhere to UniswapV2 interface
    address public immutable token0;

    /// @notice token1 to adhere to UniswapV2 interface
    address public immutable token1;

    // ==============================================================================
    // Structs
    // ==============================================================================

    /// @notice Auction information
    /// @param amountLeft Amount of sellToken remaining to buy
    /// @param buyTokenProceeds Amount of buyToken that came in from sales
    /// @param lastPrice Price of the last sale, in buyToken amount per sellToken (amount of buyToken to purchase 1e18 sellToken)
    /// @param minPrice Minimum price of 1e18 sellToken, in buyToken
    /// @param priceDecay Price decay, (wei per second), using PRECISION
    /// @param priceSlippage Slippage fraction. E.g (0.01 * PRECISION) = 1%
    /// @param lastBuyTime Time of the last sale
    /// @param expiry UNIX timestamp when the auction ends
    /// @param exited If the auction has ended
    struct Auction {
        uint128 amountLeft;
        uint128 buyTokenProceeds;
        uint128 lastPrice;
        uint128 minPrice;
        uint64 priceDecay;
        uint64 priceSlippage;
        uint32 lastBuyTime;
        uint32 expiry;
        bool ended;
    }

    // ==============================================================================
    // Constructor
    // ==============================================================================

    /// @param _timelockAddress Address of the timelock/owner contract
    /// @param _buyToken The token used to buy the sellToken being auctioned off
    /// @param _sellToken The token being auctioned off
    constructor(address _timelockAddress, address _buyToken, address _sellToken) Timelock2Step(_timelockAddress) {
        name = string(abi.encodePacked("SlippageAuction: ", IERC20Metadata(_sellToken).symbol()));
        BUY_TOKEN = _buyToken;
        SELL_TOKEN = _sellToken;

        token0 = _buyToken;
        token1 = _sellToken;
    }

    // ==============================================================================
    // Views
    // ==============================================================================

    /// @notice The ```version``` function returns the semantic version of this contract
    /// @return _major The major version
    /// @return _minor The minor version
    /// @return _patch The patch version
    function version() external pure returns (uint256 _major, uint256 _minor, uint256 _patch) {
        return (1, 0, 0);
    }

    /// @notice The ```getPreSlippagePrice``` function calculates the pre-slippage price from the time decay alone
    /// @param _auction The auction struct
    /// @return _price The price
    function getPreSlippagePrice(Auction memory _auction) public view returns (uint256 _price) {
        // Calculate the sale price (in buyToken per sellToken), factoring in the time decay
        uint256 _decay = (_auction.priceDecay * (block.timestamp - _auction.lastBuyTime));

        // Prevent revert on underflow when decay is too large
        if (_decay > _auction.lastPrice) {
            return _auction.minPrice;
        }

        // Calculate the price
        _price = _auction.lastPrice - _decay;

        // Never go below the minimum price
        if (_price < _auction.minPrice) {
            _price = _auction.minPrice;
        }
    }

    /// @notice The ```getAmountOut``` function calculates the amount of sellTokens out for a given buyToken amount
    /// @param _amountIn Amount of buyToken in
    /// @param _revertOnOverAmountLeft Whether to revert if _amountOut > amountLeft
    /// @return _amountOut Amount of sellTokens out
    /// @return _slippagePerSellToken The slippage component of the price change (in buyToken per sellToken)
    /// @return _postSlippagePrice The post-slippage price from the time decay + slippage
    function getAmountOut(
        uint256 _amountIn,
        bool _revertOnOverAmountLeft
    ) public view returns (uint256 _amountOut, uint256 _slippagePerSellToken, uint256 _postSlippagePrice) {
        uint256 _auctionNumber = auctions.length - 1;
        // Get the auction info
        Auction memory _auction = auctions[_auctionNumber];
        if (_auction.ended) revert AuctionAlreadyExited();
        if (block.timestamp >= _auction.expiry) revert AuctionExpired();

        // Calculate the sale price (in buyToken per sellToken), factoring in the time decay
        uint256 _preSlippagePrice = getPreSlippagePrice({ _auction: _auction });

        // Calculate the slippage component of the price (in buyToken per sellToken)
        _slippagePerSellToken = (_auction.priceSlippage * _amountIn) / PRECISION;

        // Calculate the output amount of sellToken, Set return value
        _amountOut = (_amountIn * PRECISION) / (_preSlippagePrice + _slippagePerSellToken);

        // Make sure you are not going over the amountLeft, set return value
        if (_amountOut > _auction.amountLeft) {
            if (_revertOnOverAmountLeft) revert InsufficientSellTokensAvailable();
            else _amountOut = _auction.amountLeft;
        }

        // Set return value
        _postSlippagePrice = _preSlippagePrice + (2 * _slippagePerSellToken); // Price impact is twice the slippage
    }

    /// @notice The ```getAmountInMax``` function calculates how many buyTokens you would need to buy out the remaining sellTokens in the auction
    /// @return _amountIn Amount of buyToken needed
    /// @return _slippagePerSellToken The slippage component of the price change (in buyToken per sellToken)
    /// @return _postSlippagePrice The post-slippage price from the time decay + slippage
    function getAmountInMax()
        external
        view
        returns (uint256 _amountIn, uint256 _slippagePerSellToken, uint256 _postSlippagePrice)
    {
        uint256 _auctionNumber = auctions.length - 1;

        // Get the auction info
        Auction memory _auction = auctions[_auctionNumber];

        // Call the internal function with amountLeft
        return _getAmountIn({ _auction: _auction, _desiredOut: _auction.amountLeft });
    }

    /// @notice The ```getAmountIn``` function calculates how many buyTokens you would need in order to obtain a given number of sellTokens
    /// @param _desiredOut The desired number of sellTokens
    /// @return _amountIn Amount of buyToken needed
    /// @return _slippagePerSellToken The slippage component of the price change (in buyToken per sellToken)
    /// @return _postSlippagePrice The post-slippage price from the time decay + slippage
    function getAmountIn(
        uint256 _desiredOut
    ) public view returns (uint256 _amountIn, uint256 _slippagePerSellToken, uint256 _postSlippagePrice) {
        uint256 _auctionNumber = auctions.length - 1;

        // Get the auction info
        Auction memory _auction = auctions[_auctionNumber];

        // Call the internal function with _desiredOut, set return values
        (_amountIn, _slippagePerSellToken, _postSlippagePrice) = _getAmountIn({
            _auction: _auction,
            _desiredOut: _desiredOut
        });
    }

    /// @notice The ```_getAmountIn``` function calculate how many buyTokens you would need to obtain a given number of sellTokens
    /// @param _auction The auction struct
    /// @return _amountIn Amount of buyToken needed
    /// @return _slippagePerSellToken The slippage component of the price change (in buyToken per sellToken)
    /// @return _postSlippagePrice The post-slippage price from the time decay + slippage
    function _getAmountIn(
        Auction memory _auction,
        uint256 _desiredOut
    ) internal view returns (uint256 _amountIn, uint256 _slippagePerSellToken, uint256 _postSlippagePrice) {
        // Do checks
        if (_auction.ended) revert AuctionAlreadyExited();
        if (block.timestamp >= _auction.expiry) revert AuctionExpired();
        if (_desiredOut > _auction.amountLeft) revert InsufficientSellTokensAvailable();

        // Calculate the sale price (in buyToken per sellToken), factoring in the time decay
        uint256 _preSlippagePrice = uint256(getPreSlippagePrice({ _auction: _auction }));

        // Math in a more readable format:
        // uint256 _numerator = (_desiredOut * _preSlippagePrice) / PRECISION;
        // uint256 _denominator = (PRECISION -
        //     ((_desiredOut * uint256(_auction.priceSlippage)) / PRECISION));
        // _amountIn = (_numerator * PRECISION) / _denominator;

        // Set return params _amountIn
        _amountIn =
            (_desiredOut * _preSlippagePrice) /
            (PRECISION - (_desiredOut * uint256(_auction.priceSlippage)) / PRECISION);

        // Set return params, calculate the slippage component of the price (in buyToken per sellToken)
        _slippagePerSellToken = (_auction.priceSlippage * _amountIn) / PRECISION;
        _postSlippagePrice = _auction.lastPrice + (2 * _slippagePerSellToken); // Price impact is twice the slippage
    }

    /// @notice The ```getAmountIn``` function calculates how many buyTokens you would need in order to obtain a given number of sellTokens
    /// @dev Maintains compatability with some router implementations
    /// @param amountOut The amount out of sell tokens
    /// @param tokenOut The sell token address
    /// @return _amountIn The amount of buyToken needed
    function getAmountIn(uint256 amountOut, address tokenOut) external view returns (uint256 _amountIn) {
        if (tokenOut != SELL_TOKEN) revert InvalidTokenOut();
        (_amountIn, , ) = getAmountIn({ _desiredOut: amountOut });
    }

    /// @notice The ```getAmountOut``` function calculates the amount of sellTokens out for a given buyToken amount
    /// @dev Used to maintain compatibility
    /// @param _amountIn Amount of buyToken in
    /// @param tokenIn The token being swapped in
    /// @return _amountOut Amount of sellTokens out
    function getAmountOut(uint256 _amountIn, address tokenIn) external view returns (uint256 _amountOut) {
        if (tokenIn == BUY_TOKEN) revert InvalidTokenIn();
        (_amountOut, , ) = getAmountOut({ _amountIn: _amountIn, _revertOnOverAmountLeft: false });
    }

    /// @notice Gets a struct instead of a tuple for auctions()
    /// @param _auctionNumber Auction ID
    /// @return _auctionStruct The struct of the auction
    function getAuctionStruct(uint256 _auctionNumber) external view returns (Auction memory) {
        return auctions[_auctionNumber];
    }

    /// @notice The ```auctionsLength``` function returns the length of the auctions array
    /// @return _length The length of the auctions array
    function auctionsLength() external view returns (uint256 _length) {
        _length = auctions.length;
    }

    /// @notice The ```getLatestAuction``` function returns the latest auction
    /// @dev Returns an empty struct if there are no auctions
    /// @return _latestAuction The latest auction struct
    function getLatestAuction() external view returns (Auction memory _latestAuction) {
        uint256 _length = auctions.length;
        if (_length == 0) return _latestAuction;
        _latestAuction = auctions[auctions.length - 1];
    }

    // ==============================================================================
    // Owner-only Functions
    // ==============================================================================

    /// @notice Parameters for creating an auction
    /// @dev Sender must have an allowance on sellToken
    /// @param sellAmount Amount of sellToken being sold
    /// @param startPrice Starting price of 1e18 sellToken, in buyToken
    /// @param minPrice Minimum price of 1e18 sellToken, in buyToken
    /// @param priceDecay Price decay, (wei per second), using PRECISION
    /// @param priceSlippage Slippage fraction. E.g (0.01 * PRECISION) = 1%
    /// @param expiry UNIX timestamp when the auction ends
    struct StartAuctionParams {
        uint128 sellAmount;
        uint128 startPrice;
        uint128 minPrice;
        uint64 priceDecay;
        uint64 priceSlippage;
        uint32 expiry;
    }

    /// @notice The ```startAuction``` function starts a new auction
    /// @param _params StartAuctionParams
    /// @dev Requires an erc20 allowance on the sellToken prior to calling
    function startAuction(StartAuctionParams memory _params) external nonReentrant returns (uint256 _auctionNumber) {
        _requireSenderIsTimelock();

        // Pre-compute the auction number
        _auctionNumber = auctions.length;

        // Ensure that the previous auction, if any, has ended
        if (_auctionNumber > 0) {
            Auction memory _lastAuction = auctions[_auctionNumber - 1];
            if (_lastAuction.ended == false) revert LastAuctionStillActive();
        }

        // Create the auction
        auctions.push(
            Auction({
                priceDecay: _params.priceDecay,
                priceSlippage: _params.priceSlippage,
                amountLeft: _params.sellAmount,
                buyTokenProceeds: 0,
                lastPrice: _params.startPrice,
                lastBuyTime: uint32(block.timestamp),
                minPrice: _params.minPrice,
                expiry: _params.expiry,
                ended: false
            })
        );

        emit AuctionStarted({
            auctionNumber: _auctionNumber,
            sellAmount: _params.sellAmount,
            startPrice: _params.startPrice,
            minPrice: _params.minPrice,
            priceDecay: _params.priceDecay,
            priceSlippage: _params.priceSlippage,
            expiry: _params.expiry
        });

        // Take the sellTokens from the sender
        IERC20(SELL_TOKEN).safeTransferFrom({ from: msg.sender, to: address(this), value: _params.sellAmount });
    }

    /// @notice The ```stopAuction``` function ends the auction
    /// @dev Only callable by the auction owner
    /// @return _buyProceeds Amount of buyToken obtained from the auction
    /// @return _unsoldRemaining Amount of unsold sellTokens left over
    function stopAuction() public nonReentrant returns (uint256 _buyProceeds, uint256 _unsoldRemaining) {
        _requireSenderIsTimelock();

        // Get the auction info and perform checks
        uint256 _auctionNumber = auctions.length - 1;
        Auction memory _auction = auctions[_auctionNumber];
        if (_auction.ended) revert AuctionAlreadyExited();

        // Set Return params
        _buyProceeds = IERC20(BUY_TOKEN).balanceOf({ account: address(this) });
        _unsoldRemaining = IERC20(SELL_TOKEN).balanceOf({ account: address(this) });

        _auction.ended = true;
        _auction.buyTokenProceeds = uint128(_buyProceeds);
        _auction.amountLeft = uint128(_unsoldRemaining);

        // Effects: Update state with final balances;
        auctions[_auctionNumber] = _auction;

        // Return buyToken proceeds from the auction to the sender
        IERC20(BUY_TOKEN).safeTransfer({ to: msg.sender, value: _buyProceeds });

        // Return any unsold sellToken to the sender
        IERC20(SELL_TOKEN).safeTransfer({ to: msg.sender, value: _unsoldRemaining });

        emit AuctionExited({ auctionNumber: _auctionNumber });
    }

    // ==============================================================================
    // Public Functions
    // ==============================================================================

    /// @notice The ```swap``` function swaps buyTokens for sellTokens
    /// @dev This low-level function should be called from a contract which performs important safety checks
    /// @dev Token0 is always the BUY_TOKEN, token1 is always the SELL_TOKEN
    /// @param _buyTokenOut The amount of buyTokens to receive
    /// @param _sellTokenOut The amount of sellTokens to receive
    /// @param _to The recipient of the output tokens
    /// @param _callbackData Callback data
    function swap(
        uint256 _buyTokenOut,
        uint256 _sellTokenOut,
        address _to,
        bytes memory _callbackData
    ) public nonReentrant {
        if (_buyTokenOut != 0) revert ExcessiveBuyTokenOut({ minOut: 0, actualOut: _buyTokenOut });
        if (_sellTokenOut == 0) revert InsufficientOutputAmount({ minOut: 1, actualOut: 0 });

        // Get the auction info (similar to get reserves in univ2)
        uint256 _auctionNumber = auctions.length - 1;
        Auction memory _auction = auctions[_auctionNumber];

        // Transfer tokens
        IERC20(SELL_TOKEN).safeTransfer({ to: _to, value: _sellTokenOut });

        // Callback if necessary for flash swap
        if (_callbackData.length > 0) {
            IUniswapV2Callee(_to).uniswapV2Call({
                sender: msg.sender,
                amount0: _buyTokenOut,
                amount1: _sellTokenOut,
                data: _callbackData
            });
        }

        // Calculate the amount of buyTokens in
        uint256 _buyTokenBalance = IERC20(BUY_TOKEN).balanceOf({ account: address(this) });
        uint256 _buyTokenIn = _buyTokenBalance - _auction.buyTokenProceeds;

        // Adheres to uniswap v2 interface, called here to prevent stack-too-deep error
        emit Swap({
            sender: msg.sender,
            amount0In: _buyTokenIn,
            amount1In: 0,
            amount0Out: _buyTokenOut,
            amount1Out: _sellTokenOut,
            to: _to
        });

        // Call the internal function with _desiredOut
        (uint256 _minAmountIn, uint256 _slippagePerSellToken, uint256 _postSlippagePrice) = _getAmountIn({
            _auction: _auction,
            _desiredOut: _sellTokenOut
        });

        // Check invariant
        if (_buyTokenIn < _minAmountIn) revert InsufficientInputAmount({ minIn: _minAmountIn, actualIn: _buyTokenIn });

        // Mutate _auction, which has the previous state
        _auction.amountLeft -= uint128(_sellTokenOut);
        _auction.buyTokenProceeds = uint128(_buyTokenBalance);
        _auction.lastPrice = uint128(_postSlippagePrice);
        _auction.lastBuyTime = uint32(block.timestamp);

        // Write back to state, similar to _update in univ2
        auctions[_auctionNumber] = _auction;

        // Emit Buy event
        emit Buy({
            auctionNumber: _auctionNumber,
            buyToken: BUY_TOKEN,
            sellToken: SELL_TOKEN,
            amountIn: uint128(_buyTokenIn),
            amountOut: uint128(_sellTokenOut),
            lastPrice: _auction.lastPrice,
            slippagePerSellToken: uint128(_slippagePerSellToken)
        });
    }

    /// @notice The ```swapExactTokensForTokens``` function swaps an exact amount of input tokens for as many output tokens as possible
    /// @dev Must have an allowance on the BUY_TOKEN prior to invocation
    /// @param _amountIn The amount of buy tokens to send.
    /// @param _amountOutMin The minimum amount of sell tokens that must be received for the transaction not to revert
    /// @param _ignored Ignored parameter, necessary to adhere to uniV2 interface
    /// @param _to Recipient of the output tokens
    /// @param _deadline Unix timestamp after which the transaction will revert
    /// @return _amounts The input token amount and output token amount
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _ignored,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory _amounts) {
        if (block.timestamp > _deadline) revert Expired();
        (uint256 _amountOut, , ) = getAmountOut({ _amountIn: _amountIn, _revertOnOverAmountLeft: true });
        if (_amountOut < _amountOutMin) {
            revert InsufficientOutputAmount({ minOut: _amountOutMin, actualOut: _amountOut });
        }
        IERC20(BUY_TOKEN).safeTransferFrom({ from: msg.sender, to: address(this), value: _amountIn });
        this.swap({ _buyTokenOut: 0, _sellTokenOut: _amountOut, _to: _to, _callbackData: new bytes(0) });
        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;
        _amounts[1] = _amountOut;
    }

    /// @notice The ```swapTokensForExactTokens``` function receives an exact amount of output tokens for as few input tokens as possible
    /// @dev Must have an allowance on the BUY_TOKEN prior to invocation
    /// @param _amountOut The amount of sell tokens to receive
    /// @param _amountInMax The maximum amount of buy tokens that can be required before the transaction reverts
    /// @param _ignored Ignored parameter, necessary to adhere to uniV2 interface
    /// @param _to Recipient of the output tokens
    /// @param _deadline Unix timestamp after which the transaction will revert
    /// @return _amounts The input token amount and output token amount
    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _ignored,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory _amounts) {
        // Ensure deadline has not passed
        if (block.timestamp > _deadline) revert Expired();

        // Calculate the amount of buyTokens in & check invariant
        (uint256 _amountIn, , ) = getAmountIn({ _desiredOut: _amountOut });
        if (_amountIn > _amountInMax) revert ExcessiveInputAmount({ minIn: _amountInMax, actualIn: _amountIn });

        // Interactions: Transfer buyTokens to the contract
        IERC20(BUY_TOKEN).safeTransferFrom({ from: msg.sender, to: address(this), value: _amountIn });
        

        swap({ _buyTokenOut: 0, _sellTokenOut: _amountOut, _to: _to, _callbackData: new bytes(0) });
        
        // Set return variable
        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;
        _amounts[1] = _amountOut;
    }

    // ==============================================================================
    // Errors
    // ==============================================================================

    /// @notice The ```AuctionAlreadyExited``` error is emitted when a user attempts to exit an auction that has already ended
    error AuctionAlreadyExited();

    /// @notice The ```AuctionExpired``` error is emitted when a user attempts to interact with an auction that has expired
    error AuctionExpired();

    /// @notice The ```LastAuctionStillActive``` error is emitted when a user attempts to start a new auction before the previous one has ended
    error LastAuctionStillActive();

    /// @notice The ```InsufficientOutputAmount``` error is emitted when a user attempts to swap a given amount of buy tokens that would result in an insufficient amount of sell tokens
    /// @param minOut Minimum out that the user expects
    /// @param actualOut Actual amount out that would occur
    error InsufficientOutputAmount(uint256 minOut, uint256 actualOut);

    /// @notice The ```InsufficientInputAmount``` error is emitted when a user attempts to swap an insufficient amount of buy tokens
    /// @param minIn Minimum in that the contract requires
    /// @param actualIn Actual amount in that has been deposited
    error InsufficientInputAmount(uint256 minIn, uint256 actualIn);

    /// @notice The ```ExcessiveInputAmount``` error is emitted when a user attempts to swap an excessive amount of buy tokens for aa given amount of sell tokens
    /// @param minIn Minimum in that the user expects
    /// @param actualIn Actual amount in that would occur
    error ExcessiveInputAmount(uint256 minIn, uint256 actualIn);

    /// @notice The ```InsufficientSellTokensAvailable``` error is emitted when a user attempts to buy more sell tokens than are left in the auction
    error InsufficientSellTokensAvailable();

    /// @notice The ```CannotPurchaseBuyToken``` error is emitted when a user attempts to buy the buyToken using the swap() function
    error ExcessiveBuyTokenOut(uint256 minOut, uint256 actualOut);

    /// @notice The ```Expired``` error is emitted when a user attempts to make a swap after the transaction deadline has passed
    error Expired();

    /// @notice The ```InvalidTokenIn``` error is emitted when a user attempts to use an invalid buy token
    error InvalidTokenIn();

    /// @notice The ```InvalidTokenOut``` error is emitted when a user attempts to use an invalid sell token
    error InvalidTokenOut();

    // ==============================================================================
    // Events
    // ==============================================================================

    /// @dev The ```AuctionExited``` event is emitted when an auction is ended
    /// @param auctionNumber The ID of the auction
    event AuctionExited(uint256 auctionNumber);

    /// @dev The ```Buy``` event is emitted when a swap occurs and has more information than the ```Swap``` event
    /// @param auctionNumber The ID of the auction, and index in the auctions array
    /// @param buyToken The token used to buy the sellToken being auctioned off
    /// @param sellToken The token being auctioned off
    /// @param amountIn Amount of buyToken in
    /// @param amountOut Amount of sellToken out
    /// @param lastPrice The execution price of the buy
    /// @param slippagePerSellToken How many buyTokens (per sellToken) were added as slippage
    event Buy(
        uint256 auctionNumber,
        address buyToken,
        address sellToken,
        uint128 amountIn,
        uint128 amountOut,
        uint128 lastPrice,
        uint128 slippagePerSellToken
    );

    /// @notice The ```Swap``` event is emitted when a swap occurs
    /// @param sender The address of the sender
    /// @param amount0In The amount of BUY_TOKEN in
    /// @param amount1In The amount of SELL_TOKEN in
    /// @param amount0Out The amount of BUY_TOKEN out
    /// @param amount1Out The amount of SELL_TOKEN out
    /// @param to The address of the recipient
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /// @dev The ```AuctionStarted``` event is emitted when an auction is started
    /// @param auctionNumber The ID of the auction
    /// @param sellAmount Amount of sellToken being sold
    /// @param startPrice Starting price of the sellToken, in buyToken
    /// @param minPrice Minimum price of the sellToken, in buyToken
    /// @param priceDecay Price decay, per day, using PRECISION
    /// @param priceSlippage Slippage fraction. E.g (0.01 * PRECISION) = 1%
    /// @param expiry Expiration time of the auction
    event AuctionStarted(
        uint256 auctionNumber,
        uint128 sellAmount,
        uint128 startPrice,
        uint128 minPrice,
        uint128 priceDecay,
        uint128 priceSlippage,
        uint32 expiry
    );
}
