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

interface IMasterChef {
    function userInfo(uint256 poolId, address user)
        external
        view
        returns (uint256 amount, uint256 rewardDept);
}

interface IAutoVault {
    function userInfo(address user)
        external
        view
        returns (
            uint256 shares,
            uint256 lastDepositTime,
            uint256 balanceAtLastAction,
            uint256 lastActionTime
        );
}

interface IWETH {
    function balanceOf(address _user) external view returns (uint256 balance);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Presale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    mapping(uint256 => uint256) public minContributeRate;
    mapping(uint256 => uint256) public maxContributeRate;
    mapping(uint256 => address) presaleTokens;
    mapping(uint256 => uint256) public startTime;
    mapping(uint256 => uint256) public tier1Time;
    mapping(uint256 => uint256) public tier2Time;
    mapping(uint256 => uint256) public endTime;
    mapping(uint256 => uint256) public liquidityLockTime;
    mapping(address => bool) public routers;
    mapping(uint256 => address) public routerId;
    mapping(uint256 => uint256) defaultRouterRate;
    mapping(uint256 => uint256) routerRate;
    mapping(uint256 => uint256) public tier1Rate;
    mapping(uint256 => uint256) public tier2Rate;
    mapping(uint256 => uint256) public liquidityRate;
    mapping(uint256 => uint256) public publicRate;
    mapping(uint256 => uint256) public softCap;
    mapping(uint256 => uint256) public hardCap;
    mapping(uint256 => bool) public isGold;
    mapping(uint256 => mapping(address => uint256)) userContribution;
    mapping(uint256 => mapping(address => bool)) public whitelist1;
    mapping(uint256 => mapping(address => bool)) public whitelist2;
    mapping(address => bool) public basewhitelist;
    mapping(uint256 => bool) public iswhitelist;
    mapping(uint256 => bool) public iswhitelist1;
    mapping(uint256 => bool) public iswhitelist2;
    mapping(uint256 => mapping(address => uint256)) public userContributionBNB;
    mapping(uint256 => uint256) public totalContributionBNB;
    mapping(uint256 => uint256) public totalContributionToken;
    mapping(uint256 => mapping(address => uint256))
        public userContributionToken;
    mapping(uint256 => bool) public withdrawFlag;
    mapping(uint256 => bool) public presaleStatus;
    mapping(uint256 => address) presaleOwner;
    mapping(uint256 => mapping(address => uint256)) liquidityAmount;
    mapping(uint256 => bool) public isDeposited;
    mapping(uint256 => mapping(address => bool)) public isClaimed;
    mapping(address => uint256[]) outsideContribution;
    mapping(uint256 => mapping(address => bool)) balanceContribute;
    uint256 public outsideContributionBalance;
    address payable public feeWallet;
    address payable public raiseFeeWallet;
    address public defaultRouter;
    uint256 public currentFee;
    uint256 public performanceFee = 175; //1.75% of token sold and BNB raised
    uint256 public whitelistFee;
    uint256 public currentPresaleId;
    uint256 public outsideContributionCount = 5;
    uint256 public contributionPeriod = 60 * 60 * 24 * 30; // 1 month
    uint256 public maxPresaleLength = 60 * 60 * 24 * 3; // 3 days
    uint256 public minLiquidityLock = 60 * 60 * 24 * 180; // 6 months
    address public masterChef;
    address public autoVault;
    IERC20 sphynxToken;

    // events
    event SaleCreated(
        uint256 saleId,
        uint256 startTime,
        uint256 endTime,
        address token
    );

    constructor(uint256 _fee, address _sphynx) {
        currentFee = _fee;
        feeWallet = payable(msg.sender);
        raiseFeeWallet = payable(msg.sender);
        sphynxToken = IERC20(_sphynx);
    }

    function updateSphynx(address _sphynx) external onlyOwner {
        sphynxToken = IERC20(_sphynx);
    }

    function updateFeeWallet(address _feewallet) external onlyOwner {
        feeWallet = payable(_feewallet);
    }

    function updateRaiseFeeWallet(address _raiseFeeWallet) external onlyOwner {
        raiseFeeWallet = payable(_raiseFeeWallet);
    }

    function setStaticFee(uint256 _fee) external onlyOwner {
        currentFee = _fee;
    }

    function updatePerformanceFee(uint256 _performanceFee) external onlyOwner {
        performanceFee = _performanceFee;
    }

    function updatewhitelistFee(uint256 _whitelistFee) external onlyOwner {
        whitelistFee = _whitelistFee;
    }

    function updateBasewhitelist(address[] memory _whitelists, bool _value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelists.length; i++) {
            address _whitelist = _whitelists[i];
            basewhitelist[_whitelist] = _value;
        }
    }

    function updateMaxPresaleLength(uint256 _value) external onlyOwner {
        maxPresaleLength = _value;
    }

    function updateMinLiquidityLock(uint256 _value) external onlyOwner {
        minLiquidityLock = _value;
    }

    function updateMasterChef(address _masterChef) external onlyOwner {
        masterChef = _masterChef;
    }

    function updateAutoVault(address _autoVault) external onlyOwner {
        autoVault = _autoVault;
    }

    function updateOutsideContributionCount(uint256 _count) external onlyOwner {
        outsideContributionCount = _count;
    }

    function updateContributionPeriod(uint256 _period) external onlyOwner {
        contributionPeriod = _period;
    }

    function enablewhitelist(uint256 _saleId, bool value) external payable {
        require(presaleOwner[_saleId] == msg.sender, "not-presale-owner");
        require(msg.value >= whitelistFee || value == false, "fee-not-enough");
        iswhitelist[_saleId] = value;
    }

    function updatewhitelist(
        uint256 _saleId,
        address[] memory _whitelists,
        uint256 _class
    ) external {
        require(presaleOwner[_saleId] == msg.sender, "not-presale-owner");
        require(iswhitelist[_saleId], "whitelist-not-enabled");
        if (_class == 1) {
            iswhitelist1[_saleId] = true;
            for (uint256 i = 0; i < _whitelists.length; i++) {
                address _whitelist = _whitelists[i];
                whitelist1[_saleId][_whitelist] = true;
            }
        } else if (_class == 2) {
            iswhitelist2[_saleId] = true;
            for (uint256 i = 0; i < _whitelists.length; i++) {
                address _whitelist = _whitelists[i];
                whitelist2[_saleId][_whitelist] = true;
            }
        } else {
            for (uint256 i = 0; i < _whitelists.length; i++) {
                address _whitelist = _whitelists[i];
                whitelist1[_saleId][_whitelist] = false;
                whitelist2[_saleId][_whitelist] = false;
            }
        }
    }

    function setOutsideContributionBalance(uint256 _balance)
        external
        onlyOwner
    {
        outsideContributionBalance = _balance;
    }

    struct PresaleInfo {
        uint256 saleId;
        address token;
        uint256 minContributeRate;
        uint256 maxContributeRate;
        uint256 startTime;
        uint256 tier1Time;
        uint256 tier2Time;
        uint256 endTime;
        uint256 liquidityLockTime;
        address routerId;
        uint256 tier1Rate;
        uint256 tier2Rate;
        uint256 publicRate;
        uint256 liquidityRate;
        uint256 softCap;
        uint256 hardCap;
        uint256 defaultRouterRate;
        uint256 routerRate;
        bool isGold;
    }

    function createPresale(PresaleInfo calldata pInfo)
        external
        payable
        nonReentrant
    {
        require(pInfo.saleId == currentPresaleId, "presale-already-exist");
        require(routers[pInfo.routerId], "not-router-address");
        require(msg.value >= currentFee, "not-enough-fee");
        require(
            pInfo.startTime <= pInfo.tier1Time &&
                pInfo.tier1Time <= pInfo.tier2Time &&
                pInfo.tier2Time <= pInfo.endTime,
            "time-incorrect"
        );
        require(
            pInfo.endTime.sub(pInfo.startTime) <= maxPresaleLength,
            "presale-length-reach-limit"
        );
        require(
            pInfo.liquidityLockTime.sub(pInfo.endTime) >= minLiquidityLock,
            "liquidity-lock-time-limit"
        );
        require(pInfo.tier1Rate >= pInfo.tier2Rate, "tier1-rate");
        require(pInfo.tier2Rate >= pInfo.publicRate, "tier2-rate");
        presaleTokens[currentPresaleId] = pInfo.token;
        minContributeRate[currentPresaleId] = pInfo.minContributeRate;
        maxContributeRate[currentPresaleId] = pInfo.maxContributeRate;
        startTime[currentPresaleId] = pInfo.startTime;
        tier1Time[currentPresaleId] = pInfo.tier1Time;
        tier2Time[currentPresaleId] = pInfo.tier2Time;
        endTime[currentPresaleId] = pInfo.endTime;
        liquidityLockTime[currentPresaleId] = pInfo.liquidityLockTime;
        routerId[currentPresaleId] = pInfo.routerId;
        tier1Rate[currentPresaleId] = pInfo.tier1Rate;
        tier2Rate[currentPresaleId] = pInfo.tier2Rate;
        publicRate[currentPresaleId] = pInfo.publicRate;
        liquidityRate[currentPresaleId] = pInfo.liquidityRate;
        softCap[currentPresaleId] = pInfo.softCap;
        hardCap[currentPresaleId] = pInfo.hardCap;
        presaleOwner[currentPresaleId] = msg.sender;
        defaultRouterRate[currentPresaleId] = pInfo.defaultRouterRate;
        routerRate[currentPresaleId] = pInfo.routerRate;
        isGold[currentPresaleId] = pInfo.isGold;
        emit SaleCreated(
            currentPresaleId,
            pInfo.startTime,
            pInfo.endTime,
            pInfo.token
        );
        currentPresaleId = currentPresaleId.add(1);
        feeWallet.transfer(currentFee);
    }

    function getDepositAmount(uint256 _saleId)
        public
        view
        returns (uint256 amount)
    {
        uint256 _hardCap = hardCap[_saleId];
        uint256 _tier1Rate = tier1Rate[_saleId];
        uint256 _routerRate = routerRate[_saleId];
        uint256 _defaultRouterRate = defaultRouterRate[_saleId];
        uint256 _liquidityRate = liquidityRate[_saleId];
        amount = _hardCap.mul(_tier1Rate);
        uint256 _routerAmount = _hardCap
            .mul(_routerRate.add(_defaultRouterRate))
            .mul(_liquidityRate)
            .div(100);
        amount = amount.add(_routerAmount);
        amount = amount.mul(10000 + performanceFee).div(10000).div(10**18);
    }

    function tier1Sale(uint256 _saleId) internal {
        require(
            whitelist1[_saleId][msg.sender] == true ||
                (outsideContributionBalance != 0 &&
                    sphynxToken.balanceOf(msg.sender).add(getStakedAmount()) >=
                    outsideContributionBalance &&
                    balanceContribute[_saleId][msg.sender] == false &&
                    isGold[_saleId]),
            "permission-denied"
        );
        if (!whitelist1[_saleId][msg.sender]) {
            balanceContribute[_saleId][msg.sender] = true;
        }
        uint256 rate = tier1Rate[_saleId];
        userContributionToken[_saleId][msg.sender] += rate.mul(msg.value).div(
            10**18
        );
        totalContributionToken[_saleId] += rate.mul(msg.value).div(10**18);
    }

    function tier2Sale(uint256 _saleId) internal {
        bool _balanceContributionAvailable = sphynxToken
            .balanceOf(msg.sender)
            .add(getStakedAmount()) >=
            outsideContributionBalance &&
            !balanceContribute[_saleId][msg.sender] &&
            isGold[_saleId] &&
            outsideContributionBalance != 0;
        bool _outsideContributionAvailable = basewhitelist[msg.sender] &&
            (outsideContribution[msg.sender].length <=
                outsideContributionCount ||
                block.timestamp.sub(
                    outsideContribution[msg.sender][
                        outsideContribution[msg.sender].length -
                            outsideContributionCount
                    ]
                ) >=
                contributionPeriod);
        require(
            whitelist2[_saleId][msg.sender] == true ||
                _balanceContributionAvailable ||
                _outsideContributionAvailable,
            "permission-denied"
        );
        if (!whitelist2[_saleId][msg.sender]) {
            if (_balanceContributionAvailable) {
                balanceContribute[_saleId][msg.sender] = true;
            } else {
                outsideContribution[msg.sender].push(block.timestamp);
            }
        }
        uint256 rate = tier2Rate[_saleId];
        userContributionToken[_saleId][msg.sender] += rate.mul(msg.value).div(
            10**18
        );
        totalContributionToken[_saleId] += rate.mul(msg.value).div(10**18);
    }

    function publicSale(uint256 _saleId) internal {
        uint256 rate = publicRate[_saleId];
        userContributionToken[_saleId][msg.sender] += rate.mul(msg.value).div(
            10**18
        );
        totalContributionToken[_saleId] += rate.mul(msg.value).div(10**18);
    }

    function getStakedAmount() internal view returns (uint256 amount) {
        if (masterChef != address(0)) {
            (amount, ) = IMasterChef(masterChef).userInfo(0, msg.sender);
        }
        if (autoVault != address(0)) {
            (uint256 _vaultAmount, , , ) = IAutoVault(autoVault).userInfo(
                msg.sender
            );
            amount = amount.add(_vaultAmount);
        }
    }

    function contribute(uint256 _saleId) external payable nonReentrant {
        require(presaleTokens[_saleId] != address(0), "presale-not-exist");
        require(isDeposited[_saleId], "token-not-deposited-yet");
        require(
            block.timestamp >= startTime[_saleId] &&
                block.timestamp <= endTime[_saleId],
            "presale-not-active"
        );
        userContributionBNB[_saleId][msg.sender] += msg.value;
        totalContributionBNB[_saleId] += msg.value;
        require(
            userContributionBNB[_saleId][msg.sender] <=
                maxContributeRate[_saleId],
            "over-max-contrubution-amount"
        );
        require(
            userContributionBNB[_saleId][msg.sender] >=
                minContributeRate[_saleId],
            "less-than-min-contrubution-amount"
        );
        require(
            totalContributionBNB[_saleId] <= hardCap[_saleId],
            "over-hardcap-amount"
        );
        if (iswhitelist[_saleId]) {
            if (block.timestamp < tier1Time[_saleId]) {
                tier1Sale(_saleId);
            } else if (
                tier1Time[_saleId] <= block.timestamp &&
                block.timestamp <= tier2Time[_saleId]
            ) {
                tier2Sale(_saleId);
            } else {
                publicSale(_saleId);
            }
        } else {
            publicSale(_saleId);
        }
    }

    function claimToken(uint256 _saleId) external payable nonReentrant {
        require(
            presaleStatus[_saleId] ||
                ((endTime[_saleId] < block.timestamp) &&
                    (totalContributionBNB[_saleId] < softCap[_saleId])),
            "presale-not-end"
        );
        require(
            userContributionBNB[_saleId][msg.sender] > 0,
            "did-not-contribute-this-presale"
        );
        require(!isClaimed[_saleId][msg.sender], "already-claimed");
        address _token = presaleTokens[_saleId];
        bool isSuccess = totalContributionBNB[_saleId] > softCap[_saleId];
        IERC20 token = IERC20(_token);
        if (isSuccess) {
            token.safeTransfer(
                msg.sender,
                userContributionToken[_saleId][msg.sender]
            );
        } else {
            address payable msgSender = payable(msg.sender);
            msgSender.transfer(userContributionBNB[_saleId][msg.sender]);
        }
        isClaimed[_saleId][msg.sender] = true;
    }

    function depositToken(uint256 _saleId) external {
        require(presaleOwner[_saleId] == msg.sender, "not-presale-owner");
        address _token = presaleTokens[_saleId];
        IERC20 token = IERC20(_token);
        uint256 requiredAmount = getDepositAmount(_saleId);
        uint256 originBalance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), requiredAmount);
        uint256 balance = token.balanceOf(address(this));
        require(
            balance.sub(originBalance) == requiredAmount,
            "amount-not-equal"
        );
        isDeposited[_saleId] = true;
    }

    function _liquidityAdd(
        IERC20 token,
        address routerAddr,
        bool isDefault,
        uint256 routerBNB,
        uint256 defaultRouterBNB,
        uint256 _saleId
    ) internal {
        uint256 routerTokenAmount = liquidityRate[_saleId].mul(routerBNB).div(
            10**18
        );
        uint256 defaultRouterTokenAmount = liquidityRate[_saleId]
            .mul(defaultRouterBNB)
            .div(10**18);
        if (routerBNB != 0) {
            token.approve(routerAddr, routerTokenAmount);
            IUniswapV2Router01 router = IUniswapV2Router01(routerAddr);
            uint256 deadline = block.timestamp.add(20 * 60);
            IWETH(router.WETH()).deposit{value: routerBNB}();
            IWETH(router.WETH()).approve(routerAddr, routerBNB);
            (, , uint256 liquidity) = router.addLiquidity(
                router.WETH(),
                address(token),
                routerBNB,
                routerTokenAmount,
                0,
                0,
                address(this),
                deadline
            );
            liquidityAmount[_saleId][routerAddr] = liquidity;
        }
        if (!isDefault && defaultRouterBNB != 0) {
            token.approve(defaultRouter, defaultRouterTokenAmount);
            IUniswapV2Router01 router1 = IUniswapV2Router01(defaultRouter);
            uint256 deadline = block.timestamp.add(20 * 60);
            IWETH(router1.WETH()).deposit{value: defaultRouterBNB}();
            IWETH(router1.WETH()).approve(defaultRouter, defaultRouterBNB);
            (, , uint256 liquidity) = router1.addLiquidity(
                router1.WETH(),
                address(token),
                defaultRouterBNB,
                defaultRouterTokenAmount,
                0,
                0,
                address(this),
                deadline
            );
            liquidityAmount[_saleId][defaultRouter] = liquidity;
        }
        uint256 tokenAmount = getDepositAmount(_saleId)
            .mul(10000 - performanceFee)
            .div(10000)
            .sub(routerTokenAmount)
            .sub(defaultRouterTokenAmount)
            .sub(totalContributionToken[_saleId]);
        token.safeTransfer(msg.sender, tokenAmount);
    }

    function addLiquidity(uint256 realAmount, uint256 _saleId) internal {
        address _token = presaleTokens[_saleId];
        address routerAddr = routerId[_saleId];
        bool isDefaultRouter = defaultRouter == address(0) ||
            defaultRouter == routerAddr;
        uint256 realRate = routerRate[_saleId];
        uint256 routerBNB = realAmount.mul(realRate).div(100);
        uint256 defaultRouterBNB = realAmount
            .mul(defaultRouterRate[_saleId])
            .div(100);
        uint256 remainAmount = realAmount.sub(routerBNB).sub(defaultRouterBNB);
        _liquidityAdd(
            IERC20(_token),
            routerAddr,
            isDefaultRouter,
            routerBNB,
            defaultRouterBNB,
            _saleId
        );
        address payable msgSender = payable(msg.sender);
        msgSender.transfer(remainAmount);
    }

    function withdrawLiquidity(uint256 _saleId) external nonReentrant {
        require(presaleOwner[_saleId] == msg.sender, "not-presale-owner");
        require(
            block.timestamp > liquidityLockTime[_saleId],
            "liquidity-locked"
        );
        require(!withdrawFlag[_saleId], "already-withdraw");
        address routerAddr = routerId[_saleId];
        address _token = presaleTokens[_saleId];
        IUniswapV2Router01 router = IUniswapV2Router01(routerAddr);
        address wrappedToken = router.WETH();
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IERC20 pair = IERC20(factory.getPair(_token, wrappedToken));
        pair.safeTransfer(msg.sender, liquidityAmount[_saleId][routerAddr]);
        if (
            liquidityAmount[_saleId][defaultRouter] != 0 &&
            routerAddr != defaultRouter
        ) {
            IUniswapV2Router01 router1 = IUniswapV2Router01(defaultRouter);
            IUniswapV2Factory factory1 = IUniswapV2Factory(router1.factory());
            IERC20 pair1 = IERC20(factory1.getPair(_token, wrappedToken));
            pair1.safeTransfer(
                msg.sender,
                liquidityAmount[_saleId][defaultRouter]
            );
        }
        withdrawFlag[_saleId] = true;
    }

    function emergencyWithdraw(uint256 _saleId) external payable nonReentrant {
        require(!presaleStatus[_saleId], "presale-already-end");
        address payable msgSender = payable(msg.sender);
        uint256 _bnbAmount = userContributionBNB[_saleId][msg.sender];
        uint256 _tokenAmount = userContributionToken[_saleId][msg.sender];
        msgSender.transfer(_bnbAmount);
        userContributionBNB[_saleId][msg.sender] = 0;
        userContributionToken[_saleId][msg.sender] = 0;
        totalContributionBNB[_saleId] = totalContributionBNB[_saleId].sub(
            _bnbAmount
        );
        totalContributionToken[_saleId] = totalContributionToken[_saleId].sub(
            _tokenAmount
        );
    }

    function finalize(uint256 _saleId) external nonReentrant {
        require(presaleOwner[_saleId] == msg.sender, "not-presale-owner");
        require(
            endTime[_saleId] <= block.timestamp ||
                (hardCap[_saleId].sub(minContributeRate[_saleId]) <=
                    totalContributionBNB[_saleId]),
            "presale-active"
        );
        require(!presaleStatus[_saleId], "already-finilize");
        presaleStatus[_saleId] = true;
        bool isSuccess = totalContributionBNB[_saleId] > softCap[_saleId];
        if (isSuccess) {
            uint256 fee = totalContributionBNB[_saleId].mul(performanceFee).div(
                10000
            );
            raiseFeeWallet.transfer(fee);
            uint256 realAmount = totalContributionBNB[_saleId].sub(fee);
            address _token = presaleTokens[_saleId];
            IERC20 token = IERC20(_token);
            uint256 tokenFee = totalContributionToken[_saleId]
                .mul(performanceFee)
                .div(10000);
            uint256 originalBalance = token.balanceOf(raiseFeeWallet);
            token.safeTransfer(raiseFeeWallet, tokenFee);
            uint256 currentBalance = token.balanceOf(raiseFeeWallet);
            require(
                originalBalance + tokenFee == currentBalance,
                "should-exclude-fee"
            );
            addLiquidity(realAmount, _saleId);
        } else {
            uint256 tokenAmount = getDepositAmount(_saleId);
            address _token = presaleTokens[_saleId];
            IERC20 token = IERC20(_token);
            token.safeTransfer(msg.sender, tokenAmount);
        }
    }

    function addRouter(address _newRouter) external onlyOwner {
        routers[_newRouter] = true;
    }

    function setDefaultRouter(address _defaultRouter) external onlyOwner {
        defaultRouter = _defaultRouter;
    }
}
