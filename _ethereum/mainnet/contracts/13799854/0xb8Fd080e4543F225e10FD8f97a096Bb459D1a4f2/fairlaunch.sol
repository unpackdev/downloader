// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1)
        external
        view
        returns (address pair);
}

interface IWETH {
    function balanceOf(address _user) external view returns (uint256 balance);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

contract FairLaunch is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    mapping(uint256 => address) public launchOwner;
    mapping(uint256 => address) public token;
    mapping(uint256 => address) public router;
    mapping(uint256 => uint256) public tokenAmount;
    mapping(uint256 => uint256) public bnbAmount;
    mapping(uint256 => uint256) public launchTime;
    mapping(uint256 => uint256) public unlockTime;
    mapping(uint256 => uint256) public liquidityAmount;
    mapping(uint256 => bool) public isLaunched;
    mapping(uint256 => bool) public isUnlocked;
    mapping(uint256 => bool) public isCanceled;
    mapping(uint256 => bool) public withdrawToken;
    mapping(uint256 => bool) public withdrawNativeCurrency;
    mapping(address => bool) public isRouter;

    uint256 public currentLaunchId;
    uint256 public availableTime = 60 * 10; // 10 minutes

    address payable public feeWallet;
    uint256 public staticFee;
    uint256 public performanceFee = 175; // 1.75% token listed

    constructor(uint256 _staticFee) {
        staticFee = _staticFee;
        feeWallet = payable(msg.sender);
    }

    function updateFeeWallet(address _feewallet) external onlyOwner {
        feeWallet = payable(_feewallet);
    }

    function updateStaticFee(uint256 _staticFee) external onlyOwner {
        staticFee = _staticFee;
    }

    function updateRouter(address _router, bool _value) external onlyOwner {
        isRouter[_router] = _value;
    }

    function updateAvailableTime(uint256 _time) external onlyOwner {
        availableTime = _time;
    }

    function createFairLaunch(
        address _token,
        uint256 _tokenAmount,
        uint256 _bnbAmount,
        uint256 _launchTime,
        address _router,
        uint256 _unlockTime
    ) external payable nonReentrant {
        require(msg.value >= staticFee.add(_bnbAmount), "not-enough-fee");
        require(isRouter[_router], "not-router-address");
        launchOwner[currentLaunchId] = msg.sender;
        token[currentLaunchId] = _token;
        tokenAmount[currentLaunchId] = _tokenAmount.mul(10000 - performanceFee).div(10000);
        bnbAmount[currentLaunchId] = _bnbAmount;
        launchTime[currentLaunchId] = _launchTime;
        unlockTime[currentLaunchId] = _unlockTime;
        router[currentLaunchId] = _router;
        currentLaunchId = currentLaunchId.add(1);
        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );
        IERC20(_token).safeTransfer(feeWallet, _tokenAmount.mul(performanceFee).div(10000));
        feeWallet.transfer(staticFee);
    }

    function _liquidityAdd(uint256 _launchId) internal {
        IERC20 tokenContract = IERC20(token[_launchId]);
        uint256 routerTokenAmount = tokenAmount[_launchId];
        uint256 routerBNBAmount = bnbAmount[_launchId];
        address routerAddr = router[_launchId];
        tokenContract.approve(routerAddr, routerTokenAmount);
        IUniswapV2Router01 routerContract = IUniswapV2Router01(routerAddr);
        uint256 deadline = block.timestamp.add(20 * 60);
        IWETH(routerContract.WETH()).deposit{value: routerBNBAmount}();
        IWETH(routerContract.WETH()).approve(routerAddr, routerBNBAmount);
        (, , uint256 liquidity) = routerContract.addLiquidity(
            routerContract.WETH(),
            address(tokenContract),
            routerBNBAmount,
            routerTokenAmount,
            0,
            0,
            address(this),
            deadline
        );
        liquidityAmount[_launchId] = liquidity;
    }

    function launch(uint256 _launchId) external payable nonReentrant {
        require(
            launchTime[_launchId].add(availableTime) >= block.timestamp,
            "launch-expired"
        );
        require(launchOwner[_launchId] == msg.sender, "not-owner");
        require(!isLaunched[_launchId], "already-launched");
        _liquidityAdd(_launchId);
        isLaunched[_launchId] = true;
    }

    function unlock(uint256 _launchId) external nonReentrant {
        require(launchOwner[_launchId] == msg.sender, "not-owner");
        require(isLaunched[_launchId], "not-launched");
        require(!isUnlocked[_launchId], "already-unlocked");
        require(block.timestamp >= unlockTime[_launchId], "liquidity-locked");
        address routerAddr = router[_launchId];
        address _token = token[_launchId];
        IUniswapV2Router01 routerContract = IUniswapV2Router01(routerAddr);
        address wrappedToken = routerContract.WETH();
        IUniswapV2Factory factory = IUniswapV2Factory(routerContract.factory());
        IERC20 pair = IERC20(factory.getPair(_token, wrappedToken));
        pair.safeTransfer(msg.sender, liquidityAmount[_launchId]);
        isUnlocked[_launchId] = true;
    }

    function cancel(uint256 _launchId) external nonReentrant {
        require(launchOwner[_launchId] == msg.sender, "not-owner");
        require(!isLaunched[_launchId], "already-launched");
        require(!isCanceled[_launchId], "already-canceled");
        isCanceled[_launchId] = true;
    }

    function tokenWithdraw(uint256 _launchId) external nonReentrant {
        require(launchOwner[_launchId] == msg.sender, "not-owner");
        require(isCanceled[_launchId], "not-canceled");
        require(!withdrawToken[_launchId], "withdraw-already");
        uint256 tokenToTransfer = tokenAmount[_launchId];
        IERC20(token[_launchId]).safeTransfer(msg.sender, tokenToTransfer);
        withdrawToken[_launchId] = true;
    }

    function nativeCurrencyWithdraw(uint256 _launchId) external nonReentrant {
        require(launchOwner[_launchId] == msg.sender, "not-owner");
        require(isCanceled[_launchId], "not-canceled");
        require(!withdrawNativeCurrency[_launchId], "withdraw-already");
        uint256 nativeCurrencyToTransfer = bnbAmount[_launchId];
        address payable msgSender = payable(msg.sender);
        msgSender.transfer(nativeCurrencyToTransfer);
        withdrawNativeCurrency[_launchId] = true;
    }
}
