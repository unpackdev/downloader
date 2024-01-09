// SPDX-License-Identifier: ISC

pragma solidity ^0.8.9;

import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeCast.sol";
import "./IUniswapV2Pair.sol";

error ShutdownError();
error NotAllowedToken();
error ZeroAmountError();
error NoLocksError();
error NotMultisigOrGovernor();
error ZeroValueError();

// Onx Locking contract for https://app.onx.finance/
// ONX and other allowed tokens locked in this contract will be entitled to voting rights for the Onx Finance platform
// Based on EPS Staking contract for http://ellipsis.finance/
// Based on CVX Locking contract for https://convexfinance.com/
contract OnxLocker is Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;

    /* ========== STATE VARIABLES ========== */

    struct StakingTokens {
        address token;
        address slpAddress;
    }
    struct Balances {
        uint256 locked;
        uint256 boosted;
        uint32 nextUnlockIndex;
        uint32 nextRequstedUnbondIndex;
    }
    struct LockedBalance {
        uint256 amount;
        uint256 boosted;
        uint32 unlockTime;
    }
    struct Epoch {
        uint256 supply; // epoch boosted supply
        uint32 date; // epoch start date
    }

    //token constants
    address public governor;
    uint256 _totalTokens;

    mapping(uint256 => address) private tokens;
    mapping(address => StakingTokens) public stakingTokens;

    // Duration of lock period 28 days
    uint256 public LOCK_DURATION;

    //supplies and epochs
    mapping(address => uint256) public lockedSupply;
    mapping(address => uint256) public boostedSupply;
    Epoch[] public epochs;

    //mappings for balance data
    mapping(address => mapping(address => Balances)) public balances;
    mapping(address => mapping(address => LockedBalance[])) public userLocks;

    //shutdown
    bool public isShutdown;

    address public multisigWallet;

    //erc20-like interface
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /* ========== MODIFIERS ========== */

    modifier onlyMultisigOrGovernor() {
        if (msg.sender != multisigWallet && msg.sender != governor) {
            revert NotMultisigOrGovernor();
        }
        _;
    }

    function initialize(address _governor, address _multisigWallet)
        public
        initializer
    {
        __ReentrancyGuard_init();

        governor = _governor;
        multisigWallet = _multisigWallet;

        _name = "OnX.Finance Governance";
        _symbol = "onONX";
        _decimals = 18;

        LOCK_DURATION = 31 days;

        if (epochs.length == 0) {
            uint256 currentEpoch = getCurrentEpoch();
            epochs.push(Epoch({supply: 0, date: currentEpoch.toUint32()}));
        }

        _totalTokens = 0;
        isShutdown = false;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /* ========== ADMIN CONFIGURATION ========== */
    function setLockDuration(uint256 _duration) public onlyMultisigOrGovernor {
        if (_duration == 0) {
            revert ZeroValueError();
        }

        LOCK_DURATION = _duration;
    }

    function setMultisig(address _wallet) public onlyMultisigOrGovernor {
        multisigWallet = _wallet;
    }

    function setGovernor(address _governor) public onlyMultisigOrGovernor {
        governor = _governor;
    }

    //shutdown the contract. unstake all tokens. release all locks
    function shutdown() external onlyMultisigOrGovernor {
        isShutdown = true;
    }

    function setStakingToken(address token, address slpAddress)
        external
        onlyMultisigOrGovernor
    {
        if (token == address(0)) {
            revert NotAllowedToken();
        }

        // new token
        if (stakingTokens[token].token == address(0)) {
            tokens[_totalTokens] = token;
            _totalTokens++;
        }

        stakingTokens[token] = StakingTokens({
            token: token,
            slpAddress: slpAddress
        });
    }

    // total token balance of an account, including unlocked but not withdrawn tokens
    function lockedBalanceOf(address _user, address _token)
        external
        view
        returns (uint256 amount)
    {
        return balances[_user][_token].locked;
    }

    function balanceOf(address _user) external view returns (uint256 amount) {
        for (uint256 i = 0; i < _totalTokens; i++) {
            address token = tokens[i];

            amount = amount + balances[_user][token].boosted;
        }
        return amount;
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp / LOCK_DURATION) * LOCK_DURATION;
    }

    //supply of all properly locked BOOSTED balances at most recent eligible epoch
    function totalSupply() external view returns (uint256 amount) {
        for (uint256 i = 0; i < _totalTokens; i++) {
            address token = tokens[i];
            amount = amount + boostedSupply[token];
        }

        return amount;
    }

    // Information on a user's locked balances
    function lockedBalances(address _user, address _token)
        external
        view
        returns (
            uint256 total,
            uint256 requestable,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        )
    {
        LockedBalance[] memory locks = userLocks[_user][_token];
        Balances memory userBalance = balances[_user][_token];

        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
        uint256 idx;
        for (uint256 i = nextUnlockIndex; i < locks.length; i++) {
            if (locks[i].unlockTime == 0) {
                requestable = requestable + locks[i].amount;
            } else if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }
                lockData[idx] = locks[i];
                idx++;
                locked = locked + locks[i].amount;
            } else {
                unlockable = unlockable + locks[i].amount;
            }
        }
        return (userBalance.locked, requestable, unlockable, locked, lockData);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transferStakingToken(
        address _token,
        address _address,
        uint256 amount
    ) internal {
        StakingTokens memory item = stakingTokens[_token];

        IERC20Upgradeable(item.token).safeTransfer(_address, amount);
    }

    // Locked tokens cannot be withdrawn for LOCK_DURATION and are eligible to receive stakingReward rewards
    function lock(address _token, uint256 _amount) external nonReentrant {
        StakingTokens memory item = stakingTokens[_token];

        IERC20Upgradeable(item.token).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        _lock(_token, msg.sender, _amount);
    }

    function getBoostedAmount(address _token, uint256 _amount)
        public
        view
        returns (uint256)
    {
        StakingTokens memory staked = stakingTokens[_token];

        if (staked.slpAddress != address(0)) {
            IUniswapV2Pair slpUniV2 = IUniswapV2Pair(staked.slpAddress);

            uint256 ts = slpUniV2.totalSupply();

            (, uint256 reserve2, ) = slpUniV2.getReserves();

            return ((2 * reserve2) * _amount) / ts;
        } else {
            return _amount;
        }
    }

    //lock tokens
    function _lock(
        address _token,
        address _account,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            revert ZeroAmountError();
        }
        if (stakingTokens[_token].token == address(0)) {
            revert NotAllowedToken();
        }
        if (isShutdown) {
            revert ShutdownError();
        }

        Balances storage bal = balances[_account][_token];

        //calc lock and boosted amount
        uint256 lockAmount = _amount;
        uint256 boostedAmount = getBoostedAmount(_token, _amount);

        //add user balances
        bal.locked = bal.locked + lockAmount;
        bal.boosted = bal.boosted + boostedAmount;

        //add to total supplies
        lockedSupply[_token] = lockedSupply[_token] + lockAmount;
        boostedSupply[_token] = boostedSupply[_token] + boostedAmount;

        //add user lock records or add to current
        userLocks[_account][_token].push(
            LockedBalance({
                amount: lockAmount,
                boosted: boostedAmount,
                unlockTime: 0
            })
        );

        emit Staked(_account, _token, _amount, lockAmount, boostedAmount);
    }

    // Withdraw all currently locked tokens where the unlock time has passed
    function _processExpiredLocks(address _token, address _staker) internal {
        LockedBalance[] storage locks = userLocks[_staker][_token];
        Balances storage userBalance = balances[_staker][_token];

        if (locks.length == 0) {
            revert NoLocksError();
        }

        uint256 locked;
        uint256 boostedAmount;
        uint256 length = locks.length;

        if (
            isShutdown ||
            (locks[length - 1].unlockTime != 0 &&
                locks[length - 1].unlockTime <= block.timestamp)
        ) {
            //if time is beyond last lock, can just bundle everything together
            locked = userBalance.locked;
            boostedAmount = userBalance.boosted;

            //dont delete, just set next index
            userBalance.nextUnlockIndex = length.toUint32();
        } else {
            //use a processed index(nextUnlockIndex) to not loop as much
            //deleting does not change array length
            uint32 nextUnlockIndex = userBalance.nextUnlockIndex;
            for (uint256 i = nextUnlockIndex; i < length; i++) {
                if (locks[i].unlockTime == 0) {
                    break;
                } else {
                    //unlock time must be less or equal to time
                    if (locks[i].unlockTime > block.timestamp) break;

                    //add to cumulative amounts
                    locked = locked + locks[i].amount;
                    boostedAmount = boostedAmount + locks[i].boosted;
                    //set next unlock index
                    nextUnlockIndex++;
                }
            }

            //update next unlock index
            userBalance.nextUnlockIndex = nextUnlockIndex;
        }

        if (locked > 0) {
            //update user balances and total supplies
            userBalance.locked = userBalance.locked - locked;
            userBalance.boosted = userBalance.boosted - boostedAmount;

            lockedSupply[_token] = lockedSupply[_token] - locked;
            boostedSupply[_token] = boostedSupply[_token] - boostedAmount;

            emit Withdrawn(_staker, _token, locked);

            // return to user
            transferStakingToken(_token, _staker, locked);
        }
    }

    function requestUnbond(address _token) external nonReentrant {
        address _account = msg.sender;

        _processExpiredLocks(_token, _account);

        LockedBalance[] storage locks = userLocks[_account][_token];
        Balances storage userBalance = balances[_account][_token];

        if (locks.length == 0) {
            revert NoLocksError();
        }

        uint256 length = locks.length;
        uint256 unlockTime = block.timestamp + LOCK_DURATION;

        if (isShutdown || (locks[length - 1].unlockTime != 0)) {
            //dont delete, just set next index
            userBalance.nextRequstedUnbondIndex = length.toUint32();
        } else {
            //use a processed index(nextUnlockIndex) to not loop as much
            //deleting does not change array length
            uint32 nextRequstedUnbondIndex = userBalance
                .nextRequstedUnbondIndex;

            for (uint256 i = nextRequstedUnbondIndex; i < length; i++) {
                locks[i].unlockTime = unlockTime.toUint32();
                nextRequstedUnbondIndex++;
            }

            //update next unlock index
            userBalance.nextRequstedUnbondIndex = nextRequstedUnbondIndex;
        }
    }

    // Withdraw/relock all currently locked tokens where the unlock time has passed
    function unlock(address token) external nonReentrant {
        _processExpiredLocks(token, msg.sender);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address token) public onlyMultisigOrGovernor {
        StakingTokens memory item = stakingTokens[token];

        uint256 balance = IERC20Upgradeable(item.token).balanceOf(
            address(this)
        );

        IERC20Upgradeable(item.token).safeTransfer(multisigWallet, balance);

        emit EmergencyWithdraw(msg.sender, multisigWallet, balance);
    }

    /* ========== EVENTS ========== */
    event Staked(
        address indexed _user,
        address _token,
        uint256 _paidAmount,
        uint256 _lockedAmount,
        uint256 _boostedAmount
    );

    event Withdrawn(address indexed _user, address _token, uint256 _amount);

    event EmergencyWithdraw(
        address indexed user,
        address _token,
        uint256 amount
    );
}
