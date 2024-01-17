// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IWETH.sol";
import "./IPancakeRouter02.sol";
import "./IPancakePair.sol";
import "./IPancakeFactory.sol";

// PCSFeeHandler_V4
contract PCSFeeHandler is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct RemoveLiquidityInfo {
        IPancakePair pair;
        uint amount;
        uint amountAMin;
        uint amountBMin;
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
            swap(swapList[i].amountIn, swapList[i].amountOutMin, swapList[i].path, ignoreError);
        }
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

    function swap(
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
            // We trust `PancakeSwapRouter` and we approve `MAX` for simplicity and gas-saving.
            if (allowance > 0) {
                // Sometimes, we noticed this error: "approve from non-zero to non-zero allowance"
                // So we clear the allowance first
                IERC20Upgradeable(token).safeApprove(address(pancakeSwapRouter), 0);
            }
            IERC20Upgradeable(token).safeApprove(address(pancakeSwapRouter), UNLIMITED_APPROVAL_AMOUNT);
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
