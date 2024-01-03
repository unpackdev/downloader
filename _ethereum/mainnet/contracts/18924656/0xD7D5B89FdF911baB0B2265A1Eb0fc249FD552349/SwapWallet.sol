// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./SafeCast.sol";
import "./SwapWalletFactory.sol";
import "./IWETH.sol";
import "./ICErc20.sol";
import "./IUniRouter.sol";
import "./ICurveCrypto.sol";
import "./IOneInchRouter.sol";
import "./IComptroller.sol";
import "./ICLiquidator.sol";
import "./IOpenOcean.sol";
import "./ISwapRouter.sol";


contract SwapWallet is Initializable, ReentrancyGuardUpgradeable {

    address private constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant _ZERO_ADDRESS = address(0);

    address private constant _CLIQUIDATOR = 0x0870793286aaDA55D39CE7f82fb2766e8004cF43;
    address private constant _COMPTROLLER = 0xfD36E2c2a6789Db23113685031d7F16329158384;

    uint128 constant MAX_FACTORY_COINS = 8;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    address private _owner;
    address private _pendingOwner;

    SwapWalletFactory private factory;

    IWETH private WETH;
    IComptroller private comptroller;
    ICLiquidator private cliquidator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);
    event WithdrawHappened(address indexed assetAddress, uint256 amount, address indexed toAddress);

    event LiquidateAccount(address indexed borrower, uint256 liquidity, uint256 shortfall);
    event LiquidateBorrowAmounts(address indexed repayToken, uint256 repayMax);

    event OnchainSettlement(address indexed fromToken, uint256 fromAmount, address indexed toToken, uint256 toAmount);

    function initialize(address owner_, SwapWalletFactory factory_) public initializer{ 
        __SwapWallet_init(owner_, factory_);
    }

    function __SwapWallet_init(address owner_, SwapWalletFactory factory_) internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
        __SwapWallet_init_unchained(owner_, factory_);
    }

    function __SwapWallet_init_unchained(address owner_, SwapWalletFactory factory_) internal onlyInitializing {
        require(owner_ != address(0), "SwapWallet: owner is the zero address");

        _owner = owner_;
        factory = factory_;
        WETH = IWETH(factory_.WETH());
        comptroller = IComptroller(_COMPTROLLER);
        cliquidator = ICLiquidator(_CLIQUIDATOR);
    }

    receive() external payable {
            // React to receiving ether
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function getFactory() external view returns (address) {
        return address(factory);
    }

    function getWETH() external view returns (address) {
        return address(WETH);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "SwapWallet: caller is not the owner");
        _;
    }

     modifier onlyOnchainLP() {
        require(factory.onchainlp() == msg.sender, "SwapWallet: caller is not the onchain-LP");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SwapWallet: new owner is the zero address");
        require(newOwner != _owner, "SwapWallet: new owner is the same as the current owner");

        emit OwnershipTransferred(_owner, newOwner);
        _pendingOwner = newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == _pendingOwner, "SwapWallet: invalid new owner");
        emit OwnershipAccepted(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    function withdraw(address assetAddress_, uint256 amount_, address toAddress_) external nonReentrant {
        require(amount_ > 0, "SwapWallet: ZERO_AMOUNT");
        require(msg.sender == _owner || msg.sender == factory.owner(), "SwapWallet: only owner or factory owner can withdraw");
        bool isWhitelistAddress = factory.whitelistAddressToIndex(toAddress_) > 0 || toAddress_ == address(factory);
        require(isWhitelistAddress, "SwapWallet: withdraw to non whitelist address");
        if (assetAddress_ == address(0)) {
            address self = address(this);
            uint256 assetBalance = self.balance;
            require(assetBalance >= amount_, "SwapWallet: not enough balance");
            _safeTransferETH(toAddress_, amount_);
            emit WithdrawHappened(assetAddress_, amount_, toAddress_);
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(assetAddress_);
            uint256 assetBalance = token.balanceOf(address(this));
            require(assetBalance >= amount_, "SwapWallet: not enough balance");
            token.safeTransfer(toAddress_, amount_);
            emit WithdrawHappened(assetAddress_, amount_, toAddress_);
        }
    }

    function verifyExchange(address router, address from, address to) internal view {
        (address token0, address token1) = from < to ? (from, to) : (to, from);
        require(factory.whitelistPairToIndex(router, token0, token1) > 0, "SwapWallet: cannot swap non-whitelisted pair");
    }

    function verifySwapPath(address router, address[] calldata path) internal view{
        require(path.length > 1, "SwapWallet: path should contain at least two tokens");
        uint len = path.length - 1;
        for (uint i; i < len;  ++i) {
            address tokenA = path[i];
            address tokenB = path[i + 1];
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
            require(factory.whitelistPairToIndex(router, token0, token1) > 0, "SwapWallet: cannot swap non-whitelisted pair");
        }
    }

    function swapExactTokensForTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external nonReentrant onlyOwner {
        verifySwapPath(router, path);
        IERC20Upgradeable fromToken = IERC20Upgradeable(path[0]);
        fromToken.safeApprove(address(router), 0);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        IUniRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    function swapTokensForExactTokens(
        address router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint deadline
    ) external nonReentrant onlyOwner {
        verifySwapPath(router, path);
        IERC20Upgradeable fromToken = IERC20Upgradeable(path[0]);
        fromToken.safeApprove(address(router), 0);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);
        IUniRouter(router).swapTokensForExactTokens(amountOut, amountInMax , path, address(this), deadline);
    }

    function swapTokensForExactETH(
        address router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint deadline
    ) external nonReentrant onlyOwner {
        verifySwapPath(router, path);
        IERC20Upgradeable fromToken = IERC20Upgradeable(path[0]);
        fromToken.safeApprove(address(router), 0);
        fromToken.safeIncreaseAllowance(address(router), amountInMax);
        IUniRouter(router).swapTokensForExactETH(amountOut, amountInMax, path, address(this), deadline);
    }

    function swapExactTokensForETH(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external nonReentrant onlyOwner {
        verifySwapPath(router, path);
        IERC20Upgradeable fromToken = IERC20Upgradeable(path[0]);
        fromToken.safeApprove(address(router), 0);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        IUniRouter(router).swapExactTokensForETH(amountIn, amountOutMin, path, address(this), deadline);
    }

    function swapExactETHForTokens(
        address router,
        uint amountOutMin, 
        address[] calldata path, 
        uint deadline) external payable nonReentrant onlyOwner {
        verifySwapPath(router, path);
        IUniRouter(router).swapExactETHForTokens{value: msg.value}(amountOutMin, path, address(this), deadline);
    }

    function swapETHForExactTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external payable nonReentrant onlyOwner{
        verifySwapPath(router, path);
        IUniRouter(router).swapETHForExactTokens{value: msg.value}(amountOutMin, path, address(this), deadline);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external nonReentrant onlyOwner {
        verifySwapPath(router, path);
        IERC20Upgradeable fromToken = IERC20Upgradeable(path[0]);
        fromToken.safeApprove(address(router), 0);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        IUniRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external payable nonReentrant onlyOwner {
        verifySwapPath(router, path);
        IUniRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(amountOutMin, path, address(this), deadline);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external nonReentrant onlyOwner {
        verifySwapPath(router, path);
        IERC20Upgradeable fromToken = IERC20Upgradeable(path[0]);
        fromToken.safeApprove(address(router), 0);
        fromToken.safeIncreaseAllowance(address(router), amountIn);
        IUniRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    function swapCurveExchange(
        address pool,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 from,
        uint256 to
    ) external nonReentrant onlyOwner {
        address addr_from = ICurveCrypto(pool).coins(from);
        address addr_to = ICurveCrypto(pool).coins(to);
        verifyExchange(pool, addr_from, addr_to);
        IERC20Upgradeable fromToken = IERC20Upgradeable(addr_from);
        fromToken.safeApprove(address(pool), 0);
        fromToken.safeIncreaseAllowance(address(pool), amountIn);
        int128 from_int = SafeCast.toInt128(SafeCast.toInt256(from));
        int128 to_int = SafeCast.toInt128(SafeCast.toInt256(to));
        ICurveCrypto(pool).exchange(from_int, to_int, amountIn, amountOutMin);
    }

    function swapCurveV2Exchange(
        address pool,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 from,
        uint256 to
    ) external nonReentrant onlyOwner {
        address[MAX_FACTORY_COINS] memory addrs = ICurveFactory(factory.curveFactory()).get_underlying_coins(pool);
        address addr_from = addrs[from];
        address addr_to = addrs[to];
        require(addr_from != address(0) && addr_to != address(0), "SwapWallet: FROM or TO zero address");
        verifyExchange(pool, addr_from, addr_to);
        IERC20Upgradeable(addr_from).safeApprove(address(pool), 0);
        IERC20Upgradeable(addr_from).safeIncreaseAllowance(address(pool), amountIn);
        int128 from_int = SafeCast.toInt128(SafeCast.toInt256(from));
        int128 to_int = SafeCast.toInt128(SafeCast.toInt256(to));
        ICurveCryptoV2(pool).exchange_underlying(from_int, to_int, amountIn, amountOutMin);
    }

    function swapOneInchExchange(
        address router,
        address executor,
        IOneInchRouter.OneInchSwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable nonReentrant onlyOwner {
        address src = desc.srcToken;
        address dst = desc.dstToken;
        require(desc.dstReceiver == address(this), "1Inch return address wrong");
        verifyExchange(router, src, dst);
        uint256 srcBefore = _tokenBalance(src);
        uint256 dstBefore = _tokenBalance(dst);
        uint256 retAmt;
        uint256 sptAmt;
        if (_isETH(src)) {
            (retAmt, sptAmt) = IOneInchRouter(router).swap{value: msg.value}(executor, desc, permit, data);
        } else {
            IERC20Upgradeable fromToken = IERC20Upgradeable(src);
            fromToken.safeApprove(address(router), 0);
            fromToken.safeIncreaseAllowance(address(router), desc.amount);
            (retAmt, sptAmt) = IOneInchRouter(router).swap(executor, desc, permit, data);
        }
        uint256 srcAfter = _tokenBalance(src);
        uint256 dstAfter = _tokenBalance(dst);
        require(srcBefore - srcAfter == sptAmt, "1Inch wrong spent amount");
        require(dstAfter - dstBefore == retAmt, "1Inch wrong return amount");
        require(dstAfter - dstBefore >= desc.minReturnAmount, "1Inch wrong return amount");
    }

    function swapOpenOceanExchange(
        address router, 
        IOpenOceanCaller caller, 
        IOpenOcean.OpenOceanSwapDescription memory desc, 
        IOpenOceanCaller.CallDescription[] calldata calls
    ) external payable nonReentrant onlyOwner {
        address src = desc.srcToken;
        address dst = desc.dstToken;
        require(desc.dstReceiver == address(this), "OpenOcean return address wrong");
        verifyExchange(router, src, dst);
        uint256 srcBefore = _tokenBalance(src);
        uint256 dstBefore = _tokenBalance(dst);
        uint256 retAmt;
        if (_isETH(src)) {
            retAmt = IOpenOcean(router).swap{value: msg.value}(caller, desc, calls);
        } else {
            IERC20Upgradeable fromToken = IERC20Upgradeable(src);
            fromToken.safeApprove(address(router), 0);
            fromToken.safeIncreaseAllowance(address(router), desc.amount);
            retAmt = IOpenOcean(router).swap(caller, desc, calls);
        }
        uint256 srcAfter = _tokenBalance(src);  
        uint256 dstAfter = _tokenBalance(dst);
        require(srcBefore - srcAfter == desc.amount, "OpenOcean wrong spent amount");
        require(dstAfter - dstBefore == retAmt, "OpenOcean wrong return amount");
        require(dstAfter - dstBefore >= desc.minReturnAmount, "OpenOcean wrong return amount");
    }


    function swapExactInput(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint24[] calldata fees,
        uint deadline
    ) external payable nonReentrant onlyOwner returns (uint256) {
        require(path.length > 1, "path should contain at least two tokens");
        require(path.length <= 4, "path should contain at most four tokens");
        require(path.length == fees.length + 1, "v3: length, path == fees - 1");
        verifySwapPath(router, path);
        uint256 amountOut;
        if (path.length == 2) {
            ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: path[0],
                tokenOut: path[1],
                fee: fees[0],
                deadline: deadline,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });
            IERC20Upgradeable from = IERC20Upgradeable(path[0]);
            from.safeApprove(address(router), 0);
            from.safeIncreaseAllowance(address(router), params.amountIn);
            amountOut = ISwapRouter(router).exactInputSingle(params);
        } else if (path.length == 3) {
            ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(path[0], fees[0], path[1], fees[1], path[2]),
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin
            });
            IERC20Upgradeable from = IERC20Upgradeable(path[0]);
            from.safeApprove(address(router), 0);
            from.safeIncreaseAllowance(address(router), params.amountIn);
            amountOut = ISwapRouter(router).exactInput(params);
        } else if (path.length == 4) {
            ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(path[0], fees[0], path[1], fees[1], path[2], fees[2], path[3]),
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin
            });
            IERC20Upgradeable from = IERC20Upgradeable(path[0]);
            from.safeApprove(address(router), 0);
            from.safeIncreaseAllowance(address(router), params.amountIn);
            amountOut = ISwapRouter(router).exactInput(params);
        }
        require(deadline >= block.timestamp, "trade expired");
        require(amountOut >= amountOutMin, "amountOut < amountOutMin");
        return amountOut;
    }


    function swapExactOutput(
        address router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint24[] calldata fees,
        uint deadline
    ) external payable nonReentrant onlyOwner returns (uint256) {
        require(path.length > 1, "path should contain at least two tokens");
        require(path.length <= 4, "path should contain at most four tokens");
        require(path.length == fees.length + 1, "v3: length, path == fees - 1");
        verifySwapPath(router, path);
        uint256 amountIn;
        if (path.length == 2) {
            ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: path[0],
                tokenOut: path[1],
                fee: fees[0],
                recipient: address(this),
                deadline: deadline,
                amountOut: amountOut,
                amountInMaximum: amountInMax,
                sqrtPriceLimitX96: 0
            });
            IERC20Upgradeable from = IERC20Upgradeable(path[0]);
            from.safeApprove(address(router), 0);
            from.safeIncreaseAllowance(address(router), params.amountInMaximum);
            amountOut = ISwapRouter(router).exactOutputSingle(params);
        } else if (path.length == 3) {
            ISwapRouter.ExactOutputParams memory params =
            ISwapRouter.ExactOutputParams({
                path: abi.encodePacked(path[0], fees[0], path[1], fees[1], path[2]),
                recipient: address(this),
                deadline: deadline,
                amountOut: amountOut,
                amountInMaximum: amountInMax
            });
            IERC20Upgradeable from = IERC20Upgradeable(path[0]);
            from.safeApprove(address(router), 0);
            from.safeIncreaseAllowance(address(router), params.amountInMaximum);
            amountOut = ISwapRouter(router).exactOutput(params);
        } else if (path.length == 4) {
            ISwapRouter.ExactOutputParams memory params =
            ISwapRouter.ExactOutputParams({
                path: abi.encodePacked(path[0], fees[0], path[1], fees[1], path[2], fees[2], path[3]),
                recipient: address(this),
                deadline: deadline,
                amountOut: amountOut,
                amountInMaximum: amountInMax
            });
            IERC20Upgradeable from = IERC20Upgradeable(path[0]);
            from.safeApprove(address(router), 0);
            from.safeIncreaseAllowance(address(router), params.amountInMaximum);
            amountOut = ISwapRouter(router).exactOutput(params);
        }
        require(deadline >= block.timestamp, "trade expired");
        require(amountIn <= amountInMax, "amountIn > amountInMax");
        return amountIn;
    }


    function liquidateBorrower(
        address borrower,
        address repayCToken,
        uint256 repayAmount,
        address seizeCToken
    ) external payable nonReentrant onlyOwner {
        ( , uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(borrower);
        emit LiquidateAccount(borrower, liquidity, shortfall);
        require(liquidity == 0, "liquidity is not zero");
        require(shortfall > 0, "shortfall should above zero");
        verifyExchange(borrower, repayCToken, seizeCToken);
        address repayToken = CErc20Storage(repayCToken).underlying();
        require(repayToken != address(0), "repay token not listed");

        // uint(10**18) adjustments ensure that all place values are dedicated
        // to repay and seize precision rather than unnecessary closeFact and liqIncent decimals
        uint repayMax = CErc20(repayCToken).borrowBalanceCurrent(borrower) * comptroller.closeFactorMantissa() / uint(10**18);

        if (repayAmount > 0 && repayMax > repayAmount) {
            repayMax = repayAmount;
        } 
        if (repayMax > _tokenBalance(repayToken)) {
            repayMax = _tokenBalance(repayToken);
        }
        
        require(repayMax > 0, "no balance to repay");
        IERC20Upgradeable(repayToken).safeApprove(address(cliquidator), 0);
        IERC20Upgradeable(repayToken).safeApprove(address(cliquidator), repayMax);
        cliquidator.liquidateBorrow(repayCToken, borrower, repayMax, seizeCToken);

        emit LiquidateBorrowAmounts(repayToken, repayMax);
    }

    function redeemVToken(
        address seizeCToken
    ) external payable nonReentrant onlyOwner {
        require(CErc20(seizeCToken).redeem(_tokenBalance(seizeCToken)) == 0, "redeem failed.");
    }

    function onchainSettlement(
        address fromToken,
        uint256 fromAmount,
        address toToken,
        uint256 toAmount
    ) external payable nonReentrant onlyOnchainLP {
        if (_isETH(fromToken)) {
            require(msg.value == fromAmount, "msg value is not equal to amount");
            _convertToWETH(fromAmount);
        } else {
            IERC20Upgradeable(fromToken).safeTransferFrom(msg.sender, address(this), fromAmount);
        }
        if (_isETH(toToken)) {
            require(toAmount <= WETH.balanceOf(address(this)), "exceed vault amount");
            _convertFromWETH(toAmount);
            _safeTransferETH(msg.sender, toAmount);
        } else {
            require(toAmount <= IERC20Upgradeable(toToken).balanceOf(address(this)), "exceed vault amount");
            IERC20Upgradeable(toToken).safeTransfer(msg.sender, toAmount);
        }
        emit OnchainSettlement(fromToken, fromAmount, toToken, toAmount);
    }

    function _convertToWETH(uint amountETH) internal {
        require(amountETH > 0, "SwapWallet: ZERO_AMOUNT");
        address self = address(this);
        uint256 assetBalance = self.balance;
        require(assetBalance >= amountETH, "SwapWallet: NOT_ENOUGH");
        WETH.deposit{value: amountETH}();
    }

    function convertToWETH(uint amountETH) external onlyOwner {
        _convertToWETH(amountETH);
    }

    function _convertFromWETH(uint amountWETH) internal {
        require(amountWETH > 0, "SwapWallet: ZERO_AMOUNT");
        uint256 assetBalance = WETH.balanceOf(address(this));
        require(assetBalance >= amountWETH, "SwapWallet: NOT_ENOUGH");
        WETH.withdraw(amountWETH);
    }

    function convertFromWETH(uint amountWETH) external onlyOwner {
        _convertFromWETH(amountWETH);
    }

    function findPool(address from, address to) external view returns(address) {
        return ICurveFactory(factory.curveFactory()).find_pool_for_coins(from, to);
    }

    function getUnderlyingCoins(address pool) external view returns(address[MAX_FACTORY_COINS] memory) {
        return ICurveFactory(factory.curveFactory()).get_underlying_coins(pool);
    }

    function getUnderlyingDecimals(address pool) external view returns(uint256[MAX_FACTORY_COINS] memory) {
        return ICurveFactory(factory.curveFactory()).get_underlying_decimals(pool);
    }

    function getUnderlyingBalances(address pool) external view returns(uint256[MAX_FACTORY_COINS] memory) {
        return ICurveFactory(factory.curveFactory()).get_underlying_balances(pool);
    }

    function _isETH(address token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }

    function _tokenBalance(address token) internal view returns(uint256) {
        if (_isETH(token)) {
            return address(this).balance;
        } else {
            return IERC20Upgradeable(token).balanceOf(address(this));
        }
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value}("");
        require(success, "SwapWallet: transfer eth failed");
    }

}