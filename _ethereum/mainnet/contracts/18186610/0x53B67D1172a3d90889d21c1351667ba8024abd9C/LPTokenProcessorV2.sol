// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./KeeperCompatible.sol";
import "./AccessControlEnumerable.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./ILPTokenProcessorV2.sol";
import "./INonfungiblePositionManager.sol";
import "./IPriceOracleManager.sol";
import "./ISwapRouterV3.sol";

contract LPTokenProcessorV2 is ILPTokenProcessorV2, KeeperCompatible, AccessControlEnumerable {
    using SafeERC20 for IERC20Metadata;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant LP_ADMIN_ROLE = keccak256("LP_ADMIN_ROLE");

    address public treasury;
    mapping(address => address) public routerByFactory;
    mapping(address => bool) public v2Routers;
    address public feeToken;
    address public immutable FLOKI;

    address public routerForFloki;

    IPriceOracleManager public priceOracle;

    uint256 private _sellDelay;

    mapping(address => uint256) private _lastAdded;

    TokenSwapInfo[] private _tokens;

    uint256 public constant globalBasisPoints = 10000;
    uint256 public constant burnBasisPoints = 2500; // 25%
    uint256 public constant referrerBasisPoints = 2500; // 25%
    uint256 public slippageBasisPoints = 300; // 3%
    mapping(address => uint256) public perTokenSlippage;
    bool public requireOraclePrice;
    uint24 public wethToUsdV3PoolFee = 3000; // 0.3%

    uint256 public feeCollectedLastBlock;
    uint256 public flokiBurnedLastBlock;
    uint256 public referrerShareLastBlock;

    event TokenAdded(address indexed tokenAddress);
    event TokenProcessed(address indexed tokenAddress);
    event TokenRemoved(address indexed tokenAddress);
    event SellDelayUpdated(uint256 indexed oldDelay, uint256 indexed newDelay);
    event PriceOracleUpdated(address indexed oldOracle, address indexed newOracle);
    event SlippageUpdated(uint256 oldSlippage, uint256 newSlippage);
    event SlippagePerTokenUpdated(uint256 oldSlippage, uint256 newSlippage, address token);
    event FeeCollected(uint256 indexed previousBlock, address indexed vault, uint256 feeAmount);
    event FeeTokenUpdated(address indexed oldFeeToken, address indexed newFeeToken);
    event ReferrerSharedPaid(uint256 indexed previousBlock, address indexed vault, address referrer, uint256 feeAmount);
    event FlokiBurned(uint256 indexed previousBlock, address indexed vault, uint256 feeAmount, uint256 flokiAmount);

    constructor(
        address flokiAddress,
        uint256 sellDelay,
        address mainRouter,
        bool isV2Router,
        address feeTokenAddress,
        address treasuryAddress,
        address priceOracleAddress,
        uint24 v3DefaultPoolFee
    ) {
        require(mainRouter != address(0), "LPTokenProcessorV2::constructor::ZERO: Router cannot be zero address.");
        require(feeTokenAddress != address(0), "LPTokenProcessorV2::constructor::ZERO: feeToken cannot be zero address.");
        require(treasuryAddress != address(0), "LPTokenProcessorV2::constructor::ZERO: Treasury cannot be zero address.");
        _sellDelay = sellDelay;
        routerForFloki = mainRouter;
        if (mainRouter != address(0)) {
            routerByFactory[IUniswapV2Router02(mainRouter).factory()] = mainRouter;
            v2Routers[mainRouter] = isV2Router;
        }
        FLOKI = flokiAddress;
        feeToken = feeTokenAddress;
        treasury = treasuryAddress;
        priceOracle = IPriceOracleManager(priceOracleAddress);
        wethToUsdV3PoolFee = v3DefaultPoolFee;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setFeeToken(address newFeeToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFeeToken != address(0), "LPTokenProcessorV2::setFeeToken::ZERO: feeToken cannot be zero address.");
        address oldFeeToken = feeToken;
        feeToken = newFeeToken;
        emit FeeTokenUpdated(oldFeeToken, newFeeToken);
    }

    function setSellDelay(uint256 newDelay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldDelay = _sellDelay;
        _sellDelay = newDelay;

        emit SellDelayUpdated(oldDelay, newDelay);
    }

    function setPriceOracle(address newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldOracle = address(priceOracle);
        priceOracle = IPriceOracleManager(newOracle);
        emit PriceOracleUpdated(oldOracle, newOracle);
    }

    function setSlippageBasisPoints(uint256 newSlippage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldSlippage = slippageBasisPoints;
        slippageBasisPoints = newSlippage;
        emit SlippageUpdated(oldSlippage, newSlippage);
    }

    function setSlippagePerToken(uint256 slippage, address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldSlippage = perTokenSlippage[token];
        perTokenSlippage[token] = slippage;
        emit SlippagePerTokenUpdated(oldSlippage, slippage, token);
    }

    function setRequireOraclePrice(bool requires) external onlyRole(DEFAULT_ADMIN_ROLE) {
        requireOraclePrice = requires;
    }

    function setWethToUsdV3PoolFee(uint24 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wethToUsdV3PoolFee = newFee;
    }

    function addTokenForSwapping(TokenSwapInfo memory params) external override onlyRole(LP_ADMIN_ROLE) {
        // Update timestamp before checking whether token was already in the
        // set of locked LP tokens, because otherwise the timestamp would
        // not be updated on repeated calls (within the selling timeframe).
        uint256 initialBalance = IERC20Metadata(params.tokenAddress).balanceOf(address(this));
        IERC20Metadata(params.tokenAddress).safeTransferFrom(msg.sender, address(this), params.amount);
        uint256 earnedAmount = IERC20Metadata(params.tokenAddress).balanceOf(address(this)) - initialBalance;

        _lastAdded[params.tokenAddress] = block.timestamp;
        _tokens.push(
            TokenSwapInfo({
                tokenAddress: params.tokenAddress,
                routerFactory: params.routerFactory,
                isV2: params.isV2,
                referrer: params.referrer,
                vault: params.vault,
                amount: earnedAmount,
                v3PoolFee: params.v3PoolFee
            })
        );
        emit TokenAdded(params.tokenAddress);
    }

    function clearTokensFromSwapping() external onlyRole(LP_ADMIN_ROLE) {
        delete _tokens;
    }

    function removeTokensFromSwappingByIndexes(uint256[] memory indexes) external onlyRole(LP_ADMIN_ROLE) {
        for (uint256 i = 0; i < indexes.length; i++) {
            uint256 index = indexes[i];
            address tokenAddress = _tokens[index].tokenAddress;
            _tokens[index] = _tokens[_tokens.length - 1];
            _tokens.pop();
            emit TokenRemoved(tokenAddress);
        }
    }

    function removeTokenFromSwapping(address tokenAddress) external onlyRole(LP_ADMIN_ROLE) {
        for (uint256 i = _tokens.length; i > 0; i--) {
            if (_tokens[i - 1].tokenAddress == tokenAddress) {
                _tokens[i - 1] = _tokens[_tokens.length - 1];
                _tokens.pop();
                break;
            }
        }
    }

    function getTokensForSwapping() external view returns (TokenSwapInfo[] memory) {
        return _tokens;
    }

    function addRouter(address routerAddress, bool isV2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(routerAddress != address(0), "LPTokenProcessorV2::addRouter::ZERO: Router cannot be zero address.");
        routerByFactory[IUniswapV2Router02(routerAddress).factory()] = routerAddress;
        v2Routers[routerAddress] = isV2;
    }

    function getRouter(address tokenAddress) external view override returns (address) {
        return routerByFactory[IUniswapV2Pair(tokenAddress).factory()];
    }

    function isV2LiquidityPoolToken(address token) external view override returns (bool) {
        bool success = false;
        bytes memory data;
        address tokenAddress;

        (success, data) = token.staticcall(abi.encodeWithSelector(IUniswapV2Pair.token0.selector));
        if (!success) {
            return false;
        }
        assembly {
            tokenAddress := mload(add(data, 32))
        }
        if (!_isContract(tokenAddress)) {
            return false;
        }

        (success, data) = token.staticcall(abi.encodeWithSelector(IUniswapV2Pair.token1.selector));
        if (!success) {
            return false;
        }
        assembly {
            tokenAddress := mload(add(data, 32))
        }
        if (!_isContract(tokenAddress)) {
            return false;
        }

        return true;
    }

    function _isContract(address externalAddress) private view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(externalAddress)
        }
        return codeSize > 0;
    }

    function isV3LiquidityPoolToken(address tokenAddress, uint256 tokenId) external view override returns (bool) {
        (address token0, address token1, , ) = getV3Position(tokenAddress, tokenId);
        return token0 != address(0) && token1 != address(0);
    }

    function getV3Position(address tokenAddress, uint256 tokenId)
        public
        view
        override
        returns (
            address,
            address,
            uint128,
            uint24
        )
    {
        try INonfungiblePositionManager(tokenAddress).positions(tokenId) returns (
            uint96,
            address,
            address token0,
            address token1,
            uint24 fee,
            int24,
            int24,
            uint128 liquidity,
            uint256,
            uint256,
            uint128,
            uint128
        ) {
            return (token0, token1, liquidity, fee);
        } catch {
            return (address(0), address(0), 0, 0);
        }
    }

    // Check whether any LP tokens are owned to sell.
    function checkUpkeep(
        bytes memory /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 loopLimit = _tokens.length;

        if (loopLimit == 0) {
            return (false, abi.encode(""));
        }

        for (uint256 i = 0; i < loopLimit; i++) {
            TokenSwapInfo memory tokenInfo = _tokens[i];
            if ((_lastAdded[tokenInfo.tokenAddress] + _sellDelay) < block.timestamp) {
                address routerAddress = routerByFactory[tokenInfo.routerFactory];
                if (routerAddress != address(0)) {
                    // We only need one token ready for processing
                    return (true, abi.encode(""));
                }
            }
        }
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        uint256 tokensLength = _tokens.length;
        if (tokensLength == 0) {
            return;
        }
        for (uint256 i = 0; i < tokensLength; i++) {
            bool success = _processTokenSwapping(i);
            if (success) break; // only process one token per transaction
        }
    }

    function processTokenSwapping(address token) external onlyRole(LP_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i].tokenAddress == token) {
                _processTokenSwapping(i);
                break;
            }
        }
    }

    function processTokenSwappingByIndex(uint256 index) external onlyRole(LP_ADMIN_ROLE) {
        _processTokenSwapping(index);
    }

    function _processTokenSwapping(uint256 index) private returns (bool) {
        TokenSwapInfo memory info = _tokens[index];
        address routerAddress = routerByFactory[info.routerFactory];
        if (routerAddress == address(0)) return false;
        if ((_lastAdded[info.tokenAddress] + _sellDelay) >= block.timestamp) return false;

        uint256 initialFeeAmount = IERC20Metadata(feeToken).balanceOf(address(this));
        if (info.isV2) {
            // V2 LP Tokens
            _swapV2TokenByFeeToken(info.tokenAddress, info.amount, routerAddress);
        } else {
            // Regular ERC20 tokens
            bool success = false;
            if (v2Routers[routerAddress]) {
                success = _swapTokensWithV2Router(info.tokenAddress, info.amount, feeToken, address(this), routerAddress);
            } else {
                uint24[] memory poolFees = new uint24[](2);
                poolFees[0] = info.v3PoolFee;
                poolFees[1] = wethToUsdV3PoolFee;
                success = _swapTokensWithV3Router(info.tokenAddress, info.amount, feeToken, poolFees, address(this), routerAddress);
            }
            require(success, "LPTokenProcessorV2::performUpkeep: Failed to swap ERC20 token by feeToken.");
        }
        uint256 newFeeAmount = IERC20Metadata(feeToken).balanceOf(address(this));
        if (info.tokenAddress == feeToken) {
            // If the feeToken is the same as the token to be processed, there is no swap, so the balance of feeToken is not increased.
            // We need to manually increase the "newFeeAmount" otherwise their difference will be zero.
            newFeeAmount += info.amount;
        }
        uint256 feeAmount = newFeeAmount - initialFeeAmount;
        _processFees(info, feeAmount);
        _tokens[index] = _tokens[_tokens.length - 1];
        _tokens.pop();
        emit TokenProcessed(info.tokenAddress);
        return true;
    }

    /**
     * Unpairs the liquidity pool token and swap the unpaired tokens by feeToken.
     */
    function _swapV2TokenByFeeToken(
        address tokenAddress,
        uint256 lpBalance,
        address routerAddress
    ) private returns (uint256) {
        require(routerAddress != address(0), "LPTokenProcessorV2::_swapV2TokenByFeeToken: Unsupported router.");
        IUniswapV2Pair lpToken = IUniswapV2Pair(tokenAddress);
        lpToken.approve(routerAddress, lpBalance);

        address token0 = lpToken.token0();
        address token1 = lpToken.token1();

        // liquidate and swap by feeToken
        IUniswapV2Router02(routerAddress).removeLiquidity(token0, token1, lpBalance, 0, 0, address(this), block.timestamp);
        // we can't use the amounts returned from "removeLiquidity"
        //  because it doesn't take fees/taxes into account
        bool success = _swapTokensWithV2Router(token0, IERC20Metadata(token0).balanceOf(address(this)), feeToken, address(this), routerAddress);
        require(success, "LPTokenProcessorV2::_swapV2TokenByFeeToken: Failed to swap token0 to feeToken.");
        success = _swapTokensWithV2Router(token1, IERC20Metadata(token1).balanceOf(address(this)), feeToken, address(this), routerAddress);
        require(success, "LPTokenProcessorV2::_swapV2TokenByFeeToken: Failed to swap token1 to feeToken.");

        return lpBalance;
    }

    function _burnFloki(uint256 feeAmount, address vault) private returns (uint256) {
        // Burn FLOKI
        if (FLOKI != address(0)) {
            uint256 burnShare = (feeAmount * burnBasisPoints) / globalBasisPoints;
            feeAmount -= burnShare;
            uint256 flokiBurnedInitial = IERC20Metadata(FLOKI).balanceOf(BURN_ADDRESS);
            _swapTokensWithV2Router(feeToken, burnShare, FLOKI, BURN_ADDRESS, routerForFloki);
            uint256 flokiBurned = IERC20Metadata(FLOKI).balanceOf(BURN_ADDRESS) - flokiBurnedInitial;
            emit FlokiBurned(flokiBurnedLastBlock, vault, feeAmount, flokiBurned);
            flokiBurnedLastBlock = block.number;
        }
        return feeAmount;
    }

    function _processFees(TokenSwapInfo memory info, uint256 feeBalance) private {
        // Pay referrers
        uint256 treasuryShare = _burnFloki(feeBalance, info.vault);
        if (info.referrer != address(0)) {
            uint256 referrerShare = (feeBalance * referrerBasisPoints) / globalBasisPoints;
            treasuryShare -= referrerShare;
            IERC20Metadata(feeToken).safeTransfer(info.referrer, referrerShare);
            emit ReferrerSharedPaid(referrerShareLastBlock, info.vault, info.referrer, referrerShare);
            referrerShareLastBlock = block.number;
        }
        IERC20Metadata(feeToken).safeTransfer(treasury, treasuryShare);
        emit FeeCollected(feeCollectedLastBlock, info.vault, treasuryShare);
        feeCollectedLastBlock = block.number;
    }

    function swapTokens(
        address sourceToken,
        uint256 sourceAmount,
        address destinationToken,
        address receiver,
        address routerAddress,
        uint24[] memory poolFees
    ) external override returns (bool) {
        uint256 initialBalance = IERC20Metadata(sourceToken).balanceOf(address(this));
        IERC20Metadata(sourceToken).safeTransferFrom(address(msg.sender), address(this), sourceAmount);
        uint256 receivedAmount = IERC20Metadata(sourceToken).balanceOf(address(this)) - initialBalance;

        if (v2Routers[routerAddress]) {
            return _swapTokensWithV2Router(sourceToken, receivedAmount, destinationToken, receiver, routerAddress);
        } else {
            return _swapTokensWithV3Router(sourceToken, receivedAmount, destinationToken, poolFees, receiver, routerAddress);
        }
    }

    function _swapTokensWithV2Router(
        address sourceToken,
        uint256 sourceAmount,
        address destinationToken,
        address receiver,
        address routerAddress
    ) private returns (bool) {
        IERC20Metadata token = IERC20Metadata(sourceToken);
        // if they happen to be the same, no need to swap, just transfer
        if (sourceToken == destinationToken) {
            if (receiver == address(this)) return true;
            token.safeTransfer(receiver, sourceAmount);
            return true;
        }
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address WETH = router.WETH();

        address[] memory path;
        if (sourceToken == WETH || destinationToken == WETH) {
            path = new address[](2);
            path[0] = sourceToken;
            path[1] = destinationToken;
        } else {
            path = new address[](3);
            path[0] = sourceToken;
            path[1] = WETH;
            path[2] = destinationToken;
        }

        uint256 allowed = token.allowance(address(this), routerAddress);
        if (allowed > 0) {
            token.safeApprove(routerAddress, 0);
        }
        token.safeApprove(routerAddress, sourceAmount);

        uint256 amount = 0;
        if (destinationToken == feeToken) {
            uint256 price = _getPriceInUSDWithSlippage(sourceToken);
            amount = (sourceAmount * price) / 10**token.decimals();
        }
        try router.swapExactTokensForTokensSupportingFeeOnTransferTokens(sourceAmount, amount, path, receiver, block.timestamp) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }
        return true;
    }

    function _swapTokensWithV3Router(
        address sourceToken,
        uint256 sourceAmount,
        address destinationToken,
        uint24[] memory poolFees,
        address receiver,
        address routerAddress
    ) private returns (bool) {
        IERC20Metadata token = IERC20Metadata(sourceToken);
        // if they happen to be the same, no need to swap, just transfer
        if (sourceToken == destinationToken) {
            if (receiver == address(this)) return true;
            token.safeTransfer(receiver, sourceAmount);
            return true;
        }
        ISwapRouterV3 router = ISwapRouterV3(routerAddress);
        address WETH = router.WETH9();

        bytes memory path;
        if (sourceToken == WETH || destinationToken == WETH) {
            path = abi.encodePacked(sourceToken, poolFees[0], destinationToken);
        } else {
            path = abi.encodePacked(sourceToken, poolFees[0], WETH, poolFees[1], destinationToken);
        }

        uint256 allowed = token.allowance(address(this), routerAddress);
        if (allowed > 0) {
            token.safeApprove(routerAddress, 0);
        }
        token.safeApprove(routerAddress, sourceAmount);

        uint256 amount = 0;
        if (destinationToken == feeToken) {
            uint256 price = _getPriceInUSDWithSlippage(sourceToken);
            amount = (sourceAmount * price) / 10**token.decimals();
        }
        ISwapRouterV3.ExactInputParams memory params = ISwapRouterV3.ExactInputParams({
            path: path,
            recipient: receiver,
            amountIn: sourceAmount,
            amountOutMinimum: amount
        });
        try router.exactInput(params) returns (uint256 amountOut) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }
        return true;
    }

    function _getPriceInUSDWithSlippage(address token) private returns (uint256) {
        if (address(priceOracle) == address(0)) {
            return 0;
        }
        priceOracle.fetchPriceInUSD(token);
        // the USD price in the same decimals as the feeToken token
        uint256 price = priceOracle.getPriceInUSD(token, IERC20Metadata(feeToken).decimals());
        require(price > 0 || !requireOraclePrice, "LPTokenProcessorV2::_getPriceWithSlippage: Price is zero.");
        uint256 slippage = perTokenSlippage[token];
        if (slippage == 0) {
            slippage = slippageBasisPoints;
        }
        return price - ((price * slippage) / globalBasisPoints);
    }

    function adminWithdraw(
        address tokenAddress,
        uint256 amount,
        address destination
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(0)) {
            // We specifically ignore this return value.
            (bool success, ) = payable(destination).call{ value: amount }("");
            require(success, "Failed to withdraw ETH");
        } else {
            IERC20Metadata(tokenAddress).safeTransfer(destination, amount);
        }
    }

    receive() external payable {}
}
