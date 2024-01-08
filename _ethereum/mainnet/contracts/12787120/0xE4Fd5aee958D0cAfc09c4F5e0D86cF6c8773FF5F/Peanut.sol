//SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
import "./LiquidityAmounts.sol";
import "./IWETH9.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./PriceMath.sol";
import "./console.sol";

contract Peanut is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    uint256 private _currentPositionId;

    uint8 public constant TICK_SPACING = 60;
    uint16 public constant FEE = 3000;

    address public constant uniswapV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant uniswapV3PositionsNFT = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address public constant token0 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    address public constant token1 = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT

    mapping(int24 => mapping(int24 => uint256)) contractPositions;
    address public immutable uniswapV3Pool;

    struct Balances {
        uint256 balanceToken0;
        uint256 balanceToken1;
    }

    constructor() ERC20('Peanut LP', 'PLP') {
        uniswapV3Pool = IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, FEE);
    }

    function balance0() external view returns (uint256) {
        return address(this).balance;
    }

    function balance1() external view returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }

    receive() external payable {
        require(msg.sender == token0, 'Not WETH9');
    }

    function getCurrentPrice() public view returns (uint256 price) {
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(uniswapV3Pool).slot0();
        price = PriceMath.getPriceAtSqrtRatio(token0, token1, sqrtPriceX96);
    }

    function getTickForPrice(uint256 price) public pure returns (int24 tick) {
        uint160 sqrtPriceX96 = PriceMath.getSqrtRatioAtPrice(token0, token1, price);
        tick = _getTickAtSqrtRatioWithFee(sqrtPriceX96);
    }

    function getTicksForPriceRange(uint256 priceRange) public view returns (int24 tickLower, int24 tickUpper) {
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(uniswapV3Pool).slot0();
        (uint160 sqrtPriceAX96, uint160 sqrtPriceBX96) = _getSqrtPricesForPriceRange(priceRange, sqrtPriceX96);
        tickLower = _getTickAtSqrtRatioWithFee(sqrtPriceAX96);
        tickUpper = _getTickAtSqrtRatioWithFee(sqrtPriceBX96);
    }

    function getCurrentPositionID() public view returns (uint256 positionId){
        return _currentPositionId;
    }

    function getUserShare(address account) public view returns (uint256 share) {
        require(totalSupply() > 0, 'No share');
        share = balanceOf(account).mul(100).div(totalSupply());
    }

    function createPositionForGivenRange(uint256 priceRange, uint256 amount0Desired, uint256 amount1Desired) public payable onlyOwner {
        require(_currentPositionId == 0, 'Position has already exist');
        require(amount0Desired == msg.value, 'Not enough ETH');
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(uniswapV3Pool).slot0();
        (uint160 sqrtPriceAX96, uint160 sqrtPriceBX96) = _getSqrtPricesForPriceRange(priceRange, sqrtPriceX96);
        ERC20(token1).safeTransferFrom(msg.sender, address(this), amount1Desired);
        (uint128 liquidity) = _createPositionForGivenSqrtPrices(sqrtPriceX96, sqrtPriceAX96, sqrtPriceBX96);
        _mint(msg.sender, liquidity);
    }

    function changePositionForGivenRange(uint256 priceRange) public onlyOwner {
        require(_currentPositionId > 0, 'Current position did not created');
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(uniswapV3Pool).slot0();
        (uint160 sqrtPriceAX96, uint160 sqrtPriceBX96) = _getSqrtPricesForPriceRange(priceRange, sqrtPriceX96);
        _changePositionForGivenSqrtPrices(sqrtPriceX96, sqrtPriceAX96, sqrtPriceBX96);
    }

    function changePositionForGivenPrices(uint256 priceLower, uint256 priceUpper) public onlyOwner {
        require(_currentPositionId > 0, 'Current position did not created');
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(uniswapV3Pool).slot0();
        uint160 sqrtPriceLowerX96 = PriceMath.getSqrtRatioAtPrice(token0, token1, priceLower);
        uint160 sqrtPriceUpperX96 = PriceMath.getSqrtRatioAtPrice(token0, token1, priceUpper);
        _changePositionForGivenSqrtPrices(sqrtPriceX96, sqrtPriceLowerX96, sqrtPriceUpperX96);
    }

    function addLiquidity(uint256 amount1) public payable {
        require(_currentPositionId > 0, 'Current position did not created');
        (,,,,,,,uint128 prevLiquidity,,,,) = INonfungiblePositionManager(uniswapV3PositionsNFT).positions(_currentPositionId);

        uint256 amount0 = msg.value;

        Balances memory startBalances = _getBalances(address(this), amount0);
        ERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        _addLiquidity(prevLiquidity, startBalances, amount0, amount1);
    }

    function _calculatePartsOfTokensInPosition() private view returns (uint256 partOfToken0, uint256 partOfToken1) {
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(uniswapV3Pool).slot0();
        (,,,,,int24 tickLower,int24 tickUpper, uint128 prevLiquidity, ,,,) = INonfungiblePositionManager(uniswapV3PositionsNFT).positions(_currentPositionId);
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtPriceLowerX96, sqrtPriceUpperX96, prevLiquidity);
        uint256 price = PriceMath.getPriceAtSqrtRatio(token0, token1, sqrtPriceX96);
        uint256 token1InToken0 = FullMath.mulDiv(amount1, 10 ** 18, price);
        partOfToken1 = token1InToken0.mul(100).div(token1InToken0.add(amount0));
        partOfToken0 = 100 - partOfToken1;
    }

    function addLiquidityETH() public payable {
        require(_currentPositionId > 0, 'Current position did not created');
        (,,,,,,, uint128 prevLiquidity, ,,,) = INonfungiblePositionManager(uniswapV3PositionsNFT).positions(_currentPositionId);
        (,uint256 part) = _calculatePartsOfTokensInPosition();
        uint256 amount0ToSwap = msg.value.mul(part).div(100);
        uint256 amount0 = msg.value - amount0ToSwap;

        Balances memory startBalances = _getBalances(address(this), amount0);

        (uint256 amount1) = _swapExactETHToTokens(amount0ToSwap);
        _addLiquidity(prevLiquidity, startBalances, amount0, amount1);
    }

    function addLiquidityUSDT(uint256 amount) public payable {
        require(_currentPositionId > 0, 'Current position did not created');
        (,,,,,,, uint128 prevLiquidity, ,,,) = INonfungiblePositionManager(uniswapV3PositionsNFT).positions(_currentPositionId);
        Balances memory startBalances = _getBalances(address(this));
        (uint256 part,) = _calculatePartsOfTokensInPosition();
        uint256 amount1ToSwap = amount.mul(part).div(100);
        uint256 amount1 = amount - amount1ToSwap;
        ERC20(token1).safeTransferFrom(msg.sender, address(this), amount);
        (uint256 amount0) = _swapExactTokensToETH(amount1ToSwap);

        _addLiquidity(prevLiquidity, startBalances, amount0, amount1);
    }

    function _addLiquidity(uint128 prevLiquidity, Balances memory startBalances, uint256 amount0, uint256 amount1) private {
        _resetAllowance(uniswapV3PositionsNFT);
        ERC20(token1).safeIncreaseAllowance(uniswapV3PositionsNFT, amount1);

        (uint128 liquidity,,) = INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).increaseLiquidity{value : amount0}(
            INonfungiblePositionManager.IncreaseLiquidityParams({
        tokenId : _currentPositionId,
        amount0Desired : amount0,
        amount1Desired : amount1,
        amount0Min : 0,
        amount1Min : 0,
        deadline : 10000000000
        })
        );

        uint256 amount = _calculateAmountForLiquidity(prevLiquidity, liquidity);
        _mint(msg.sender, amount);

        _refund(startBalances);
    }

    function collectFee() public onlyOwner {
        require(_currentPositionId > 0, 'Current position did not created');
        (,,,,,int24 tickLower,int24 tickUpper,uint128 liquidity,,,,) = INonfungiblePositionManager(uniswapV3PositionsNFT).positions(_currentPositionId);
        (uint160 sqrtPriceCurrentX96,,,,,,) = IUniswapV3Pool(uniswapV3Pool).slot0();
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        (uint256 amount0Needed, uint256 amount1Needed) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceCurrentX96, sqrtPriceLowerX96, sqrtPriceUpperX96, liquidity);

        (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(uniswapV3PositionsNFT).collect(
            INonfungiblePositionManager.CollectParams({
        tokenId : _currentPositionId,
        recipient : address(this),
        amount0Max : type(uint128).max,
        amount1Max : type(uint128).max
        })
        );

        require(amount0 > 0 || amount1 > 0, 'Not enough fee earned to claim');
        IWETH9(token0).withdraw(amount0);

        uint256 price = PriceMath.getPriceAtSqrtRatio(token0, token1, sqrtPriceCurrentX96);
        uint256 amount0InToken1 = amount0.mul(price).div(1e18);
        require(amount0InToken1.add(amount1) > 0, 'Not enough fee earned to claim');
        uint256 amount0InToken1Needed = amount0Needed.mul(price).div(1e18);
        uint256 share = amount0InToken1.mul(10 ** 6).div(amount0InToken1.add(amount1));
        uint256 shareNeeded = amount0InToken1Needed.mul(10 ** 6).div(amount0InToken1Needed.add(amount1Needed));

        if (share > shareNeeded) {
            uint256 diff = (share - shareNeeded).mul(amount0).div(10 ** 6);
            _swapExactETHToTokens(diff);
        } else if (share < shareNeeded) {
            uint256 diff = ((10 ** 6 - share) - (10 ** 6 - shareNeeded)).mul(amount1).div(10 ** 6);
            _swapExactTokensToETH(diff);
        }

        (uint256 amount0After, uint256 amount1After) = (address(this).balance, ERC20(token1).balanceOf(address(this)));

        _resetAllowance(uniswapV3PositionsNFT);
        ERC20(token1).safeIncreaseAllowance(uniswapV3PositionsNFT, amount1After);

        INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).increaseLiquidity{value : amount0After}(
            INonfungiblePositionManager.IncreaseLiquidityParams({
        tokenId : _currentPositionId,
        amount0Desired : amount0After,
        amount1Desired : amount1After,
        amount0Min : 0,
        amount1Min : 0,
        deadline : 10000000000
        })
        );
    }

    function claim(uint256 amount) public {
        (uint256 amount0Decreased, uint256 amount1Decreased) = _claim(amount);
        TransferHelper.safeTransferETH(msg.sender, amount0Decreased);
        ERC20(token1).safeTransfer(msg.sender, amount1Decreased);
    }

    function claimETH(uint256 amount) public {
        (uint256 amount0Decreased, uint256 amount1Decreased) = _claim(amount);
        uint256 amount0ForToken1;
        if (amount1Decreased > 0) {
            (amount0ForToken1) = _swapExactTokensToETH(amount1Decreased);
        }
        TransferHelper.safeTransferETH(msg.sender, amount0Decreased.add(amount0ForToken1));
    }

    function claimUSDT(uint256 amount) public {
        (uint256 amount0Decreased, uint256 amount1Decreased) = _claim(amount);
        uint256 amount1ForToken0;
        if (amount0Decreased > 0) {
            (amount1ForToken0) = _swapExactETHToTokens(amount0Decreased);
        }
        ERC20(token1).safeTransfer(msg.sender, amount1Decreased.add(amount1ForToken0));
    }

    function _claim(uint256 amount) private returns (uint256 amount0Decreased, uint256 amount1Decreased)  {
        require(_currentPositionId > 0, 'Current position did not created');
        require(amount <= balanceOf(msg.sender), "Not enough tokens");
        (,,,,,,,uint128 liquidity,,,uint128 tokensOwed0,uint128 tokensOwed1) = INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).positions(_currentPositionId);
        uint256 partOfShares = FullMath.mulDiv(amount, decimals(), totalSupply());
        uint256 amount0OfFee = 0;
        uint256 amount1OfFee = 0;
        if (tokensOwed0 > 0) {
            amount0OfFee = FullMath.mulDiv(tokensOwed0, partOfShares, decimals());
        }
        if (tokensOwed1 > 0) {
            amount1OfFee = FullMath.mulDiv(tokensOwed1, partOfShares, decimals());
        }
        uint128 shareForLiquidity = toUint128(FullMath.mulDiv(uint256(liquidity), partOfShares, decimals()));
        _burn(msg.sender, amount);
        (amount0Decreased, amount1Decreased) = INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId : _currentPositionId,
        liquidity : shareForLiquidity,
        amount0Min : 0,
        amount1Min : 0,
        deadline : 10000000000
        })
        );
        INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).collect(INonfungiblePositionManager.CollectParams({
        tokenId : _currentPositionId,
        recipient : address(this),
        amount0Max : toUint128(amount0Decreased.add(amount0OfFee)),
        amount1Max : toUint128(amount1Decreased.add(amount1OfFee))
        }));
        IWETH9(token0).withdraw(amount0Decreased);
    }

    function _getSqrtPricesForPriceRange(uint256 priceRange, uint160 sqrtPriceX96) private pure returns (uint160 sqrtPriceAX96, uint160 sqrtPriceBX96) {
        uint256 firstHalf = priceRange.div(2);
        uint256 secondHalf = priceRange.sub(firstHalf);
        uint256 price = PriceMath.getPriceAtSqrtRatio(token0, token1, sqrtPriceX96);
        sqrtPriceAX96 = PriceMath.getSqrtRatioAtPrice(token0, token1, price - firstHalf);
        sqrtPriceBX96 = PriceMath.getSqrtRatioAtPrice(token0, token1, price + secondHalf);
    }

    function _getTickAtSqrtRatioWithFee(uint160 sqrtPriceX96) internal pure returns (int24) {
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        int24 tickCorrection = tick % int24(TICK_SPACING);

        return tick - tickCorrection;
    }

    function _swapTokens(uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceLowerX96,
        uint160 sqrtPriceUpperX96) internal returns (uint256 amount0, uint256 amount1) {
        (uint256 amount0Before, uint256 amount1Before) = (address(this).balance, ERC20(token1).balanceOf(address(this)));
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(sqrtPriceCurrentX96, sqrtPriceLowerX96, sqrtPriceUpperX96, amount0Before, amount1Before);
        (uint256 amount0Needed, uint256 amount1Needed) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceCurrentX96, sqrtPriceLowerX96, sqrtPriceUpperX96, liquidity);
        uint256 price = PriceMath.getPriceAtSqrtRatio(token0, token1, sqrtPriceCurrentX96);
        uint256 amount0InToken1 = amount0Needed.mul(price).div(1e18);
        if (amount1Before == 0) {
            _swapExactETHToTokens(amount0Before.mul(45).div(100));
        } else if (amount0Before == 0) {
            _swapExactTokensToETH(amount1Before.mul(60).div(100));
        } else if (amount0Needed.mul(100).div(amount0Before) < 90) {
            uint256 diff = amount0Before.sub(amount0Needed);
            uint256 share = amount1Needed.mul(10 ** 6).div(amount0InToken1.add(amount1Needed));
            uint256 amount0NeedToSwap = diff.mul(share.div(2)).div(10 ** 6);
            _swapExactETHToTokens(amount0NeedToSwap);
        } else if (amount1Needed.mul(100).div(amount1Before) < 90) {
            uint256 diff = amount1Before.sub(amount1Needed);
            uint256 share = amount0InToken1.mul(10 ** 6).div(amount0InToken1.add(amount1Needed));
            uint256 amount0NeedToSwap = diff.mul(share.mul(2)).div(10 ** 6);
            _swapExactTokensToETH(amount0NeedToSwap);
        }

        (amount0, amount1) = (address(this).balance, ERC20(token1).balanceOf(address(this)));
    }

    function _createPositionForGivenSqrtPrices(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceLowerX96,
        uint160 sqrtPriceUpperX96
    ) private returns (uint128){
        (uint256 amount0, uint256 amount1) = _swapTokens(sqrtPriceCurrentX96, sqrtPriceLowerX96, sqrtPriceUpperX96);

        int24 tickLower = _getTickAtSqrtRatioWithFee(sqrtPriceLowerX96);
        int24 tickUpper = _getTickAtSqrtRatioWithFee(sqrtPriceUpperX96);
        require(tickUpper > tickLower, 'Invalid ticks');

        uint256 allowed = ERC20(token1).allowance(address(this), uniswapV3PositionsNFT);
        if (allowed != 0) {
            ERC20(token1).safeDecreaseAllowance(uniswapV3PositionsNFT, allowed);
        }
        ERC20(token1).safeIncreaseAllowance(uniswapV3PositionsNFT, amount1);

        (uint256 tokenId, uint128 liquidity,,) = INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).mint{value : amount0}(
            INonfungiblePositionManager.MintParams({
        token0 : token0,
        token1 : token1,
        fee : FEE,
        tickLower : tickLower,
        tickUpper : tickUpper,
        amount0Desired : amount0,
        amount1Desired : amount1,
        amount0Min : 0,
        amount1Min : 0,
        recipient : address(this),
        deadline : 10000000000
        })
        );
        _currentPositionId = tokenId;
        contractPositions[tickLower][tickUpper] = tokenId;
        return liquidity;
    }

    function _removeLiquidity(uint128 liquidity) private returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId : _currentPositionId,
        liquidity : liquidity,
        amount0Min : 0,
        amount1Min : 0,
        deadline : 10000000000
        })
        );
        (amount0, amount1) = INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).collect(INonfungiblePositionManager.CollectParams({
        tokenId : _currentPositionId,
        recipient : address(this),
        amount0Max : type(uint128).max,
        amount1Max : type(uint128).max
        }));
        IWETH9(token0).withdraw(amount0);
    }

    function _swapExactETHToTokens(uint256 amountIn) private returns (uint256 amountOut){
        (amountOut) = ISwapRouter(uniswapV3Router).exactInputSingle{value : amountIn}(
            ISwapRouter.ExactInputSingleParams({
        tokenIn : token0,
        tokenOut : token1,
        fee : FEE,
        recipient : address(this),
        deadline : 10000000000,
        amountIn : amountIn,
        amountOutMinimum : 0,
        sqrtPriceLimitX96 : 0
        })
        );
    }

    function _swapExactTokensToETH(uint256 amountIn) private returns (uint256 amountOut){
        _resetAllowance(uniswapV3Router);
        ERC20(token1).safeIncreaseAllowance(uniswapV3Router, amountIn);
        (amountOut) = ISwapRouter(uniswapV3Router).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
        tokenIn : token1,
        tokenOut : token0,
        fee : FEE,
        recipient : address(this),
        deadline : 10000000000,
        amountIn : amountIn,
        amountOutMinimum : 0,
        sqrtPriceLimitX96 : 0
        })
        );

        IWETH9(token0).withdraw(IWETH9(token0).balanceOf(address(this)));
    }

    function _changePositionForGivenSqrtPrices(uint160 sqrtPriceCurrentX96, uint160 sqrtPriceLowerX96, uint160 sqrtPriceUpperX96) private {
        (,,,,,,,uint128 previousLiquidity,,,,) = INonfungiblePositionManager(uniswapV3PositionsNFT).positions(_currentPositionId);
        _removeLiquidity(previousLiquidity);
        _createPositionForGivenSqrtPrices(sqrtPriceCurrentX96, sqrtPriceLowerX96, sqrtPriceUpperX96);
    }

    function unstake() external onlyOwner {
        INonfungiblePositionManager(
            uniswapV3PositionsNFT
        ).safeTransferFrom(address(this), owner(), _currentPositionId);
    }

    function withdraw() external onlyOwner {
        Balances memory currentBalances = _getBalances(address(this));
        if (currentBalances.balanceToken0 > 0) {
            TransferHelper.safeTransferETH(owner(), currentBalances.balanceToken0);
        }

        if (currentBalances.balanceToken1 > 0) {
            TransferHelper.safeTransfer(token1, owner(), currentBalances.balanceToken1);
        }
    }

    function _refund(Balances memory startBalances) private {
        _refundETH(startBalances.balanceToken0);
        _refundToken(startBalances.balanceToken1);
    }

    function _refundETH(uint256 startBalance) private {
        Balances memory currentBalances = _getBalances(address(this));
        if (currentBalances.balanceToken0 > startBalance) {
            TransferHelper.safeTransferETH(msg.sender, currentBalances.balanceToken0 - startBalance);
        }
    }

    function _refundToken(uint256 startBalance) private {
        Balances memory currentBalances = _getBalances(address(this));
        if (currentBalances.balanceToken1 > startBalance) {
            TransferHelper.safeTransfer(token1, msg.sender, currentBalances.balanceToken1 - startBalance);
        }
    }

    function _getBalances(address addr) private view returns (Balances memory balances) {
        return Balances({
        balanceToken0 : addr.balance,
        balanceToken1 : ERC20(token1).balanceOf(addr)
        });
    }

    function _getBalances(address addr, uint256 transferredAmount) private view returns (Balances memory balances) {
        return Balances({
        balanceToken0 : addr.balance.sub(transferredAmount),
        balanceToken1 : ERC20(token1).balanceOf(addr)
        });
    }

    function _resetAllowance(address spender) private {
        uint256 allowed = ERC20(token1).allowance(address(this), spender);
        if (allowed != 0) {
            ERC20(token1).safeDecreaseAllowance(spender, allowed);
        }
    }

    function _calculateAmountForLiquidity(uint128 prevLiquidity, uint128 newLiquidity) private view returns (uint256 amount) {
        if (prevLiquidity == 0) {
            amount = newLiquidity;
        } else {
            amount = totalSupply().mul(uint256(newLiquidity)).div(uint256(prevLiquidity));
        }
    }

    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }
}
