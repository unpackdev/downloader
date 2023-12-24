// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IWETH.sol";
import "./IPancakeRouter02.sol";
import "./IPancakePair.sol";
import "./IPancakeFactory.sol";
import "./IStargateRouter.sol";
import "./IAggregationRouterV5.sol";

contract PCSFeeHandlerETH is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct RemoveLiquidityInfo {
        IPancakePair pair;
        uint amount;
        uint amountAMin;
        uint amountBMin;
    }

    struct AggregatorSwapInfo {
        IAggregationExecutor executor;
        IAggregationRouterV5.SwapDescription desc;
        bytes data;
    }

    struct SwapInfo {
        uint amountIn;
        uint amountOutMin;
        address[] path;
    }

    struct LPData {
        address lpAddress;
        address token0;
        uint256 token0Amt;
        address token1;
        uint256 token1Amt;
        uint256 userBalance;
        uint256 totalSupply;
    }

    event SwapFailure(uint amountIn, uint amountOutMin, address[] path);
    event RmoveLiquidityFailure(IPancakePair pair, uint amount, uint amountAMin, uint amountBMin);
    event NewPancakeSwapRouter(address indexed sender, address indexed router);
    event NewOperatorAddress(address indexed sender, address indexed operator);
    event NewBurnAddress(address indexed sender, address indexed burnAddress);
    event NewVaultAddress(address indexed sender, address indexed vaultAddress);
    event NewBurnRate(address indexed sender, uint burnRate);
    event NewStargateSwapSlippage(address indexed sender, uint stargateSwapSlippage);
    event AggregatorSwapFail(address indexed srcToken, address indexed dstToken, uint256 amount);

    // Token address for `payment`, that's our swap `target`.
    // On BSC, our `payment` is $CAKE
    // On ETH, there is no $CAKE, our `target` is $WETH
    address public paymentToken;
    IPancakeRouter02 public pancakeSwapRouter;
    address public operatorAddress; // address of the operator

    address public burnAddress;
    address public vaultAddress;

    uint public burnRate; // rate for burn (e.g. 718750 means 71.875%)
    uint constant public RATE_DENOMINATOR = 1000000;
    uint constant UNLIMITED_APPROVAL_AMOUNT = type(uint256).max;
    mapping(address => bool) public validDestination;
    IWETH WETH;

    // Maximum amount of BNB/ETH to top-up operator
    uint public operatorTopUpLimit;

    // Copied from: @openzeppelin/contracts/security/ReentrancyGuard.sol
    // We are not extending from `ReentrancyGuard` for contract storage safety.
    // As there were existing old version smart contract when we added this.
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    //---------------------------------------------------------------------
    uint256 public stargateSwapSlippage;

    // following are all constant variables
    uint256 public constant DEFAULT_STARGATE_SWAP_SLIPPAGE = 50; //out of 10000. 50 = 0.5%
    uint256 public constant SLIPPAGE_DENOMINATOR = 10_000;
    // https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    uint256 internal constant stargateUsdcPoolId = 1;
    uint256 internal constant stargateBusdPoolId = 5;

    // https://etherscan.io/address/0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97#code
    uint8 internal constant STARGATE_TYPE_SWAP_REMOTE = 1;

    // https://stargateprotocol.gitbook.io/stargate/developers/chain-ids
    uint16 internal constant stargateBnbChainId = 102; // mainnet
    // uint16 internal constant stargateBnbChainId = 10102; // testnet

    // https://stargateprotocol.gitbook.io/stargate/developers/official-erc20-addresses
    IERC20Upgradeable internal constant ETH_USDC_ADDRESS = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // mainnet
    // IERC20Upgradeable internal constant ETH_USDC_ADDRESS = IERC20Upgradeable(0xDf0360Ad8C5ccf25095Aa97ee5F2785c8d848620); // testnet

    // https://bscscan.com/address/0x0ED943Ce24BaEBf257488771759F9BF482C39706
    address internal constant bscPCSFeeHandler = 0x0ED943Ce24BaEBf257488771759F9BF482C39706; // mainnet
    // address internal constant bscPCSFeeHandler = 0xf9578Af957fC6d730844b7DD2Ca1c24eBaD0f98F; // testnet

    // https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
    IStargateRouter constant public stargateRouter = IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98); // mainnet
    // IStargateRouter constant public stargateRouter = IStargateRouter(0x7612aE2a34E5A363E137De748801FB4c86499152); // testnet
    //---------------------------------------------------------------------
    IAggregationRouterV5 public constant swapAggregator = IAggregationRouterV5(0x1111111254EEB25477B68fb85Ed929f73A960582);

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operatorAddress, "Not owner/operator");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _paymentToken,
        address _pancakeSwapRouter,
        address _operatorAddress,
        address _burnAddress,
        address _vaultAddress,
        uint _burnRate,
        address[] memory destinations
    )
        external
        initializer
    {
        __Ownable_init();
        __UUPSUpgradeable_init();
        paymentToken = _paymentToken;
        pancakeSwapRouter = IPancakeRouter02(_pancakeSwapRouter);
        operatorAddress = _operatorAddress;
        burnAddress = _burnAddress;
        vaultAddress = _vaultAddress;
        require(_burnRate <= RATE_DENOMINATOR, "invalid rate");
        burnRate = _burnRate;
        for (uint256 i = 0; i < destinations.length; ++i)
        {
            validDestination[destinations[i]] = true;
        }
        WETH = IWETH(pancakeSwapRouter.WETH());
        operatorTopUpLimit = 100 ether;
    }

    /**
     * @notice Process LP token, `removeLiquidity` and `swap`
     * @dev Callable by owner/operator
     */
    function processFee(
        RemoveLiquidityInfo[] calldata liquidityList,
        SwapInfo[] calldata swapList,
        bool ignoreError
    )
        external
        onlyOwnerOrOperator
    {
        for (uint256 i = 0; i < liquidityList.length; ++i) {
            removeLiquidity(liquidityList[i], ignoreError);
        }
        for (uint256 i = 0; i < swapList.length; ++i) {
            _swap(swapList[i].amountIn, swapList[i].amountOutMin, swapList[i].path, ignoreError);
        }
    }

    /**
     * @notice swap tokens
     * @dev Callable by owner/operator
     */
    function swap(
        AggregatorSwapInfo[] calldata swapList,
        bool ignoreError
    )
        external
        onlyOwnerOrOperator
    {
        // sell tokens
        for (uint256 i = 0; i < swapList.length; ++i) {
            _aggragator_swap(swapList[i], ignoreError);
        }
    }

    function _aggragator_swap(
        AggregatorSwapInfo calldata swapInfo,
        bool ignoreError
    )
        internal
    {
        require(swapInfo.desc.dstReceiver == address(this), "invalid desc");
        require(validDestination[swapInfo.desc.dstToken], "invalid desc");

        uint256 allowance = IERC20Upgradeable(swapInfo.desc.srcToken).allowance(address(this), address(swapAggregator));
        if (allowance < swapInfo.desc.amount) {
            // can we approve UNLIMITED_APPROVAL_AMOUNT?
            IERC20Upgradeable(swapInfo.desc.srcToken).safeIncreaseAllowance(address(swapAggregator), swapInfo.desc.amount - allowance);
        }
        uint256 dstAmountBefore = IERC20Upgradeable(swapInfo.desc.dstToken).balanceOf(address(this));
        bytes memory permit = new bytes(0);
        // swap can be `partially successful`
        try swapAggregator.swap(swapInfo.executor, swapInfo.desc, permit, swapInfo.data)
        {
            uint256 dstAmountAfter = IERC20Upgradeable(swapInfo.desc.dstToken).balanceOf(address(this));
            // this should never happen, as aggregator already validated this.
            require((dstAmountAfter - dstAmountBefore) >= swapInfo.desc.minReturnAmount, "return not enough");
        } catch {
            emit AggregatorSwapFail(swapInfo.desc.srcToken, swapInfo.desc.dstToken, swapInfo.desc.amount);
            require(ignoreError, "swap failed");
        }
        // do we need to clear allowance?
    }

    function removeLiquidity(
        RemoveLiquidityInfo calldata info,
        bool ignoreError
    )
        internal
    {
        uint allowance = info.pair.allowance(address(this), address(pancakeSwapRouter));
        if (allowance < info.amount) {
            // We trust `PancakeSwapRouter` and we approve `MAX` for simplicity and gas-saving.
            // `PancakeERC20` only requires `MAX` approval once.
            IERC20Upgradeable(address(info.pair)).safeApprove(address(pancakeSwapRouter), UNLIMITED_APPROVAL_AMOUNT);
        }
        address token0 = info.pair.token0();
        address token1 = info.pair.token1();
        try pancakeSwapRouter.removeLiquidity(
                token0,
                token1,
                info.amount,
                info.amountAMin,
                info.amountBMin,
                address(this),
                block.timestamp
            )
        {
            // do nothing here
        } catch {
            emit RmoveLiquidityFailure(info.pair, info.amount, info.amountAMin, info.amountBMin);
            require(ignoreError, "remove liquidity failed");
            // if one of the swap fails, we do NOT revert and carry on
        }
    }

    function _swap(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        bool ignoreError
    )
        internal
    {
        require(path.length > 1, "invalid path");
        require(validDestination[path[path.length - 1]], "invalid path");
        address token = path[0];
        uint tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        amountIn = (amountIn > tokenBalance) ? tokenBalance : amountIn;
        // TODO: need to adjust `token0AmountOutMin` ?
        uint allowance = IERC20Upgradeable(token).allowance(address(this), address(pancakeSwapRouter));
        if (allowance < amountIn) {
            IERC20Upgradeable(token).safeIncreaseAllowance(address(pancakeSwapRouter), UNLIMITED_APPROVAL_AMOUNT - allowance);
        }
        try pancakeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp
            )
        {
            // do nothing here
        } catch {
            emit SwapFailure(amountIn, amountOutMin, path);
            require(ignoreError, "swap failed");
            // if one of the swap fails, we do NOT revert and carry on
        }
    }

    /**
     * @notice Send payment tokens to specified wallets(burn and vault)
     * @dev Callable by owner/operator
     */
    function payTreasury(uint amount)
        external
        onlyOwnerOrOperator
    {
        require (amount > 0, "invalid amount");
        uint burnAmount = amount * burnRate / RATE_DENOMINATOR;
        // The rest goes to the vault wallet.
        uint vaultAmount = amount - burnAmount;
        _withdraw(paymentToken, burnAddress, burnAmount);
        _withdraw(paymentToken, vaultAddress, vaultAmount);
    }

    /**
     * @notice Set PancakeSwapRouter
     * @dev Callable by owner
     */
    function setPancakeSwapRouter(address _pancakeSwapRouter) external onlyOwner {
        pancakeSwapRouter = IPancakeRouter02(_pancakeSwapRouter);
        emit NewPancakeSwapRouter(msg.sender, _pancakeSwapRouter);
    }

    /**
     * @notice Set operator address
     * @dev Callable by owner
     */
    function setOperator(address _operatorAddress) external onlyOwner {
        operatorAddress = _operatorAddress;
        emit NewOperatorAddress(msg.sender, _operatorAddress);
    }

    /**
     * @notice Set address for `burn`
     * @dev Callable by owner
     */
    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
        emit NewBurnAddress(msg.sender, _burnAddress);
    }

    /**
     * @notice Set vault address
     * @dev Callable by owner
     */
    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
        emit NewVaultAddress(msg.sender, _vaultAddress);
    }

    /**
     * @notice Set percentage of $CAKE being sent for burn
     * @dev Callable by owner
     */
    function setBurnRate(uint _burnRate) external onlyOwner {
        require(_burnRate <= RATE_DENOMINATOR, "invalid rate");
        burnRate = _burnRate;
        emit NewBurnRate(msg.sender, _burnRate);
    }

    /**
     * @notice Withdraw tokens from this smart contract
     * @dev Callable by owner
     */
    function withdraw(address tokenAddr, address payable to, uint amount)
        external
        nonReentrant
        onlyOwner
    {
        _withdraw(tokenAddr, to, amount);
    }

    function _withdraw(address tokenAddr, address to, uint amount) internal
    {
        require(to != address(0), "invalid recipient");
        if (amount == 0) {
            return;
        }
        if (tokenAddr == address(0)) {
            uint256 bnbBalance = address(this).balance;
            if (amount > bnbBalance) {
                // BNB/ETH not enough, unwrap WBNB/WETH
                // If WBNB/WETH balance is not enough, `withdraw` will `revert`.
                WETH.withdraw(amount - bnbBalance);
            }
            (bool success, ) = payable(to).call{ value: amount }("");
            require(success, "call failed");
        }
        else {
            IERC20Upgradeable(tokenAddr).safeTransfer(to, amount);
        }
    }

    /**
     * @notice bridge(cross-chain-sending) token.
     *         This feature is added to ETH PCS fee to BSC network.
     *         Currently, for simplicity, it only supports ETH-USDC -> BSC-BUSD bridging.
     * @dev Callable by owner/operator
     */
    function sendEthUsdcToBsc(uint256 amount) external payable onlyOwnerOrOperator {
        uint allowance = ETH_USDC_ADDRESS.allowance(address(this), address(stargateRouter));
        if (allowance < amount) {
            ETH_USDC_ADDRESS.safeApprove(address(stargateRouter), UNLIMITED_APPROVAL_AMOUNT);
        }

        uint256 swapFee;
        (swapFee,) = stargateRouter.quoteLayerZeroFee(
            stargateBnbChainId,
            STARGATE_TYPE_SWAP_REMOTE,
            abi.encodePacked(bscPCSFeeHandler),
            bytes(""),
            IStargateRouter.lzTxObj(0, 0, "0x")
        );


        // do NOT require `msg.value >= swapFee` because we might want to use ETH in this smart contract.
        // require(msg.value >= swapFee, "not enough value");
        // https://stargateprotocol.gitbook.io/stargate/developers/how-to-swap
        // swap ETH-USDC -> BSC-BUSD
        //-------------------------------------------------------------------------------
        // For `lzTxObj` paramter:
        // We only need `additional gasLimit` if we need to call external smart contract(token swap is not part of external call).
        // https://github.com/stargate-protocol/stargate/blob/c647a3a647fc693c38b16ef023c54e518b46e206/contracts/Router.sol#L406
        //-------------------------------------------------------------------------------
        stargateRouter.swap { value : swapFee } (
            stargateBnbChainId,
            stargateUsdcPoolId,
            stargateBusdPoolId,
            payable(address(this)),           // refund adddress. extra gas (if any) is returned to this address
            amount,                           // quantity to swap
            getStargateMinOut(amount),        // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(0, 0, "0x"),  // 0 additional gasLimit increase, 0 airdrop, at 0x address
            abi.encodePacked(bscPCSFeeHandler),   // the address to send the tokens to on the destination
            bytes("")                      // bytes param, if you wish to send additional payload you can abi.encode() them here
        );
    }

    function getStargateMinOut(uint256 _amountIn) internal view returns(uint256) {
        if (stargateSwapSlippage > 0) {
            return (_amountIn * (SLIPPAGE_DENOMINATOR - stargateSwapSlippage)) / SLIPPAGE_DENOMINATOR;
        }
        else {
            // this saves one multi-sig operation
            return (_amountIn * (SLIPPAGE_DENOMINATOR - DEFAULT_STARGATE_SWAP_SLIPPAGE)) / SLIPPAGE_DENOMINATOR;
        }
    }

    /**
     * @notice Set `stargate swap slipapge`
     * @dev Callable by owner
     */
    function setStargateSwapSlippage(uint _stargateSwapSlippage) external onlyOwner {
        require(_stargateSwapSlippage < SLIPPAGE_DENOMINATOR, "invalid slippage");
        stargateSwapSlippage = _stargateSwapSlippage;
        emit NewStargateSwapSlippage(msg.sender, _stargateSwapSlippage);
    }

    /**
     * @notice transfer some BNB/ETH to the operator as gas fee
     * @dev Callable by owner
     */
    function topUpOperator(uint256 amount) external onlyOwner {
        require(amount <= operatorTopUpLimit, "too much");
        _withdraw(address(0), operatorAddress, amount);
    }

    /**
     * @notice Set top-up limit
     * @dev Callable by owner
     */
    function setOperatorTopUpLimit(uint256 _operatorTopUpLimit) external onlyOwner {
        operatorTopUpLimit = _operatorTopUpLimit;
    }

    function addDestination(address addr) external onlyOwner {
        validDestination[addr] = true;
    }

    function removeDestination(address addr) external onlyOwner {
        validDestination[addr] = false;
    }

    // Utility for performance improvement, as we can get multiple of `pair addresses`.
    function getPairAddress(
        address factory,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            address[] memory pairs,
            uint256 nextCursor
        )
    {
        IPancakeFactory pcsFactory = IPancakeFactory(factory);
        uint256 maxLength = pcsFactory.allPairsLength();
        uint256 length = size;
        if (cursor >= maxLength) {
            address[] memory emptyList;
            return (emptyList, maxLength);
        }
        if (length > maxLength - cursor) {
            length = maxLength - cursor;
        }

        address[] memory values = new address[](length);
        for (uint256 i = 0; i < length; ++i) {
            address tempAddr = address(pcsFactory.allPairs(cursor+i));
            values[i] = tempAddr;
        }

        return (values, cursor + length);
    }

    function getPairTokens(
        address[] calldata lps,
        address account
    )
        external
        view
        returns (
            LPData[] memory
        )
    {
        LPData[] memory lpListData = new LPData[](lps.length);
        for (uint256 i = 0; i < lps.length; ++i) {
            IPancakePair pair = IPancakePair(lps[i]);
            lpListData[i].lpAddress = lps[i];
            lpListData[i].token0 = pair.token0();
            lpListData[i].token1 = pair.token1();
            (lpListData[i].token0Amt, lpListData[i].token1Amt, ) = pair.getReserves();
            lpListData[i].userBalance = pair.balanceOf(account);
            lpListData[i].totalSupply = pair.totalSupply();
        }
        return lpListData;
    }

    receive() external payable {}
    fallback() external payable {}
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
