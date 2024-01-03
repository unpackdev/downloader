// File: contracts/Interfaces.sol

// SPDX-License-Identifier: --🦉--
pragma solidity =0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity =0.6.12;

library SafeMathLT {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "modulo by zero");
        return a % b;
    }
}


pragma solidity =0.6.12;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        // (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}


pragma solidity =0.6.12;




library SafeERC20 {
    using SafeMathLT for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
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
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


pragma solidity =0.6.12;
// pragma solidity =0.7.0;
pragma experimental ABIEncoderV2;




contract CUPFINANCE {
    using SafeMathLT for uint256;
    using SafeERC20 for IERC20;

    IERC20 public mintedToken = IERC20(
        0xb3d9489cf47B8F773B9c3616D629b647B47F283A
    );

    struct Difficulty {
        uint256 EndedAt;
        bool Exists;
    }

    struct Deposit {
        uint256 Difficulty;
        uint256 Amount;
        uint256 DepositedAt;
        bool Closed;
        uint256 ClosedAt;
    }

    struct User {
        bool Exists;
        uint256 Balances;
        Deposit[] Deposits;
        address Referrer;
        address[] Invited1st;
        address[] Invited2nd;
    }

    struct Reward {
        uint256 ClosedRewardTotal;
        uint256 ClosedRewardUsed;
        bool Stoped;
        uint256 CurrentRewardUsed;
        uint256 MintRewardTotal;
        uint256 LastRewardAt;
    }

    uint256 public CONTRACT_STARTED_AT;
    uint256 public CONTRACT_DEPOSIT_PERCENT = 20;
    uint256 public CONTRACT_WITHDRAWN_PERCENT = 0;
    uint256 public TOKEN_MINT_TOTAL = 15000000 * 1e18;
    uint256 public TOKEN_MINT_USED = 0;
    uint256 private TOTAL_BALANCE_SUPPLY = 0;
    uint256 public CONTRACT_DIFFICULTY = 5 * 1e8;

    mapping(uint256 => Difficulty) public DIFFICULTIES;
    mapping(address => User) public USERS;
    mapping(address => Reward) public REWARDS;
    mapping(address => uint256) public BONUS;

    address payable public CONTRACT_DEVELOPER;
    address payable public CONTRACT_FOUNDATION;
    address public CONTRACT_DEFAULT_REFERRER;
    bool public CONTRACT_INITED = false;

    uint256[] public REFERRAL_PERCENTS = [10, 5];
    uint256[] public ALLDIFFICULTIES = [CONTRACT_DIFFICULTY];

    event onStake(address indexed account, address referrer, uint256 amount);
    event onReward(address indexed account, uint256 reward);
    event onBouns(address indexed account, uint256 bouns);
    event onWithdraw(address indexed account, uint256 amount);
    event onLayer(uint256 indexed layerID, uint256 startedAt);

    modifier afterDeveloper() {
        require(msg.sender == CONTRACT_DEVELOPER);
        _;
    }

    modifier afterStarted() {
        require(block.timestamp > CONTRACT_STARTED_AT, "not start");
        _;
    }

    constructor() public {
        CONTRACT_DEVELOPER = msg.sender;
        CONTRACT_STARTED_AT = block.timestamp;
    }

    receive() external payable {
        _(msg.sender, msg.value, CONTRACT_DEFAULT_REFERRER);
    }

    function _(
        address account,
        uint256 amount,
        address referrer
    ) internal {
        if (referrer == account) {
            referrer = CONTRACT_DEFAULT_REFERRER;
        }

        if (USERS[account].Exists == false) {
            USERS[account].Referrer = referrer;

            USERS[referrer].Invited1st.push(account);
            USERS[USERS[referrer].Referrer].Invited2nd.push(account);
        }

        USERS[account].Deposits.push(
            Deposit(CONTRACT_DIFFICULTY, amount, block.timestamp, false, 0)
        );
        USERS[account].Balances = USERS[account].Balances.add(amount);
        TOTAL_BALANCE_SUPPLY = TOTAL_BALANCE_SUPPLY.add(amount);
        USERS[account].Exists = true;

        if (REWARDS[msg.sender].Stoped) {
            getReward();
        }

        emit onStake(account, referrer, amount);
    }

    function stake(address referrer) external payable afterStarted {
        require(referrer != address(0), "referrer = address(0)");
        require(msg.value > 0, "msg.value = 0");

        uint256 burnAmount = msg.value.mul(CONTRACT_DEPOSIT_PERCENT).div(100);
        CONTRACT_FOUNDATION.transfer(burnAmount);

        _(msg.sender, msg.value, referrer);
    }

    function computeDifficulties(Deposit memory d)
        internal
        view
        returns (uint256)
    {
        uint256 earnedAmount;
        uint256 nextEndedAt = d.DepositedAt;

        if (ALLDIFFICULTIES.length > 1) {
            uint256 difficultyIndex = 0;
            for (uint256 i = 0; i < ALLDIFFICULTIES.length; i++) {
                if (ALLDIFFICULTIES[i] == d.Difficulty) {
                    difficultyIndex = i;
                    break;
                }
            }

            for (uint256 i = difficultyIndex; i < ALLDIFFICULTIES.length; i++) {
                if (DIFFICULTIES[ALLDIFFICULTIES[i]].Exists) {
                    earnedAmount = earnedAmount.add(
                        d.Amount.mul(
                            DIFFICULTIES[ALLDIFFICULTIES[i]]
                                .EndedAt
                                .sub(nextEndedAt)
                                .div(1 seconds)
                                .mul(ALLDIFFICULTIES[i])
                                .div(1e8)
                        )
                    );

                    nextEndedAt = DIFFICULTIES[ALLDIFFICULTIES[i]].EndedAt;
                }
            }
        }

        earnedAmount = earnedAmount.add(
            d
                .Amount
                .mul(block.timestamp.sub(nextEndedAt).div(1 seconds))
                .mul(CONTRACT_DIFFICULTY)
                .div(1e8)
        );

        return earnedAmount;
    }

    function _earned(address account) internal view returns (uint256) {
        require(account != address(0), "account = address(0)");
        require(
            TOKEN_MINT_USED < TOKEN_MINT_TOTAL,
            "TOKEN_MINT_USED >= TOKEN_MINT_TOTAL"
        );

        User memory u = USERS[account];

        uint256 earnedAmount;

        for (uint256 i = 0; i < u.Deposits.length; i++) {
            Deposit memory d = u.Deposits[i];

            if (d.Closed) {
                continue;
            }

            earnedAmount = earnedAmount.add(computeDifficulties(d));
        }

        earnedAmount = earnedAmount.div(1 days);
        earnedAmount = earnedAmount.add(
            REWARDS[account].ClosedRewardTotal.sub(
                REWARDS[account].ClosedRewardUsed
            )
        );

        earnedAmount = earnedAmount.sub(REWARDS[account].CurrentRewardUsed);

        if (TOKEN_MINT_USED.add(earnedAmount) > TOKEN_MINT_TOTAL) {
            earnedAmount = earnedAmount.sub(
                TOKEN_MINT_USED.add(earnedAmount).sub(TOKEN_MINT_TOTAL)
            );
        }

        return earnedAmount;
    }

    function getMyEarnd(address account)
        public
        view
        afterStarted
        returns (uint256)
    {
        return _earned(account);
    }

    function getMyInvitedLength(address account)
        external
        view
        returns (uint256, uint256)
    {
        User memory user = USERS[account];

        return (user.Invited1st.length, user.Invited2nd.length);
    }

    function getMyInvitedBonus(address account)
        public
        view
        afterStarted
        returns (uint256)
    {
        require(account != address(0), "account = address(0)");

        uint256 bonusBonus1st;
        uint256 bonusBonus2nd;

        User memory user = USERS[account];

        for (uint256 i = 0; i < user.Invited1st.length; i++) {
            uint256 earnedAmount;
            uint256 rewardAmount = REWARDS[user.Invited1st[i]].MintRewardTotal;

            earnedAmount = _earned(user.Invited1st[i]).add(rewardAmount);
            bonusBonus1st = bonusBonus1st.add(
                earnedAmount.mul(REFERRAL_PERCENTS[0]).div(100)
            );
        }

        for (uint256 i = 0; i < user.Invited2nd.length; i++) {
            uint256 earnedAmount;
            uint256 rewardAmount = REWARDS[user.Invited2nd[i]].MintRewardTotal;

            earnedAmount = _earned(user.Invited2nd[i]).add(rewardAmount);
            bonusBonus2nd = bonusBonus2nd.add(
                earnedAmount.mul(REFERRAL_PERCENTS[1]).div(100)
            );
        }

        return bonusBonus1st.add(bonusBonus2nd).sub(BONUS[account]);
    }

    function getBonus() public afterStarted {
        uint256 bonusAmount;

        bonusAmount = getMyInvitedBonus(msg.sender);

        if (bonusAmount > 0) {
            BONUS[msg.sender] = BONUS[msg.sender].add(bonusAmount);
            TOKEN_MINT_USED = TOKEN_MINT_USED.add(bonusAmount);

            mintedToken.safeTransfer(msg.sender, bonusAmount);
            emit onBouns(msg.sender, bonusAmount);
        }
    }

    function getReward() public afterStarted {
        uint256 earnedAmount;
        uint256 totalAmount;

        earnedAmount = _earned(msg.sender);

        if (REWARDS[msg.sender].Stoped) {
            REWARDS[msg.sender].Stoped = false;
            REWARDS[msg.sender].CurrentRewardUsed = 0;
        } else {
            REWARDS[msg.sender].CurrentRewardUsed = REWARDS[msg.sender]
                .CurrentRewardUsed
                .add(earnedAmount);
        }

        totalAmount = earnedAmount;

        if (totalAmount > 0) {
            REWARDS[msg.sender].ClosedRewardUsed = REWARDS[msg.sender]
                .ClosedRewardTotal;
            TOKEN_MINT_USED = TOKEN_MINT_USED.add(totalAmount);

            REWARDS[msg.sender].MintRewardTotal = REWARDS[msg.sender]
                .MintRewardTotal
                .add(totalAmount);

            mintedToken.safeTransfer(msg.sender, totalAmount);
            emit onReward(msg.sender, totalAmount);
        }
    }

    function withdraw() public afterStarted {
        User storage u = USERS[msg.sender];

        TOTAL_BALANCE_SUPPLY = TOTAL_BALANCE_SUPPLY.sub(u.Balances);

        REWARDS[msg.sender].ClosedRewardTotal = REWARDS[msg.sender]
            .ClosedRewardTotal
            .add(_earned(msg.sender));

        REWARDS[msg.sender].CurrentRewardUsed = 0;
        REWARDS[msg.sender].Stoped = true;

        for (uint256 i = 0; i < u.Deposits.length; i++) {
            u.Deposits[i].Closed = true;
            u.Deposits[i].ClosedAt = block.timestamp;
        }

        uint256 amount = u.Balances.sub(
            u.Balances.mul(CONTRACT_DEPOSIT_PERCENT).div(100)
        );

        uint256 burnAmount = u.Balances.mul(CONTRACT_WITHDRAWN_PERCENT).div(
            100
        );

        msg.sender.transfer(amount.sub(burnAmount));
        CONTRACT_FOUNDATION.transfer(burnAmount);

        emit onWithdraw(msg.sender, amount);

        u.Balances = 0;
    }

    function exit() external afterStarted {
        withdraw();
        getBonus();
        getReward();
    }

    function getDeposit(address account)
        external
        view
        afterStarted
        returns (Deposit[] memory)
    {
        require(account != address(0), "account = address(0)");

        User memory u = USERS[account];

        return u.Deposits;
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_BALANCE_SUPPLY;
    }

    function balanceOf(address account)
        public
        view
        afterStarted
        returns (uint256)
    {
        require(account != address(0), "account = address(0)");

        return USERS[account].Balances;
    }

    function setDifficulty(uint256 v)
        external
        afterDeveloper
        returns (uint256)
    {
        require(DIFFICULTIES[v].Exists == false, "difficulty = true");

        ALLDIFFICULTIES.push(v);
        DIFFICULTIES[CONTRACT_DIFFICULTY] = Difficulty(block.timestamp, true);
        CONTRACT_DIFFICULTY = v;

        return ALLDIFFICULTIES.length;
    }

    function setDepositPercent(uint256 percent) external afterDeveloper {
        CONTRACT_DEPOSIT_PERCENT = percent;
    }

    function setWithdrawnPercent(uint256 percent) external afterDeveloper {
        CONTRACT_WITHDRAWN_PERCENT = percent;
    }

    function setDefaultReferrer(address account) external afterDeveloper {
        require(account != address(0), "account = address(0)");

        CONTRACT_DEFAULT_REFERRER = account;
    }

    function setDeveloper(address payable account) external afterDeveloper {
        require(account != address(0), "account = address(0)");

        CONTRACT_DEVELOPER = account;
    }

    function setFoundation(address payable account) external afterDeveloper {
        require(account != address(0), "account = address(0)");

        CONTRACT_FOUNDATION = account;
    }

    function init() external afterDeveloper {
        require(CONTRACT_INITED == false, "CONTRACT_INITED = true");

        mintedToken.mint(address(this), TOKEN_MINT_TOTAL);

        CONTRACT_INITED = true;
    }
}