// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ITokenPool.sol";
import "./ReentrancyGuard.sol";

contract CakeFlexiblePool is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 lastUserActionAmount; // keeps track of bbc deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
    }

    IERC20 public immutable token; // Staking token
    IERC20 public immutable bbc; // Earning token
    ITokenPool public immutable parentPool; //BBC pool

    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;
    address public admin;
    address public treasury;
    bool public staking = true;

    uint256 public constant MIN_DEPOSIT_AMOUNT = 0.00001 ether;
    uint256 public constant MIN_WITHDRAW_AMOUNT = 0.00001 ether;
    uint256 public constant FEE_RATE_SCALE = 10000;

    //When call bbcpool.withdrawByAmount function,there will be a loss of precision, so need to withdraw more.
    uint256 public withdrawAmountBooster = 10001; // 1.0001

    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 shares,
        uint256 lastDepositedTime
    );
    event WithdrawShares(
        address indexed sender,
        uint256 amount,
        uint256 shares
    );
    event ChargePerformanceFee(
        address indexed sender,
        uint256 amount,
        uint256 shares
    );
    event Pause();
    event Unpause();
    event NewAdmin(address admin);
    event NewTreasury(address treasury);
    event NewWithdrawAmountBooster(uint256 withdrawAmountBooster);

    /**
     * @notice Constructor
     * @param _parentPool: BBCPool contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(ITokenPool _parentPool, address _admin, address _treasury) {
        require(address(_parentPool) != address(0), "invalid _parentPool");
        require(_admin != address(0), "invalid _admin");
        require(_treasury != address(0), "invalid _treasury");
        token = IERC20(_parentPool.token());
        bbc = IERC20(_parentPool.bbc());
        parentPool = _parentPool;
        admin = _admin;
        treasury = _treasury;

        // Infinite approve
        token.safeIncreaseAllowance(address(_parentPool), type(uint256).max);
    }

    /**
     * @notice Checks if the msg.sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    /**
     * @notice Deposits funds into the BBC Flexible Pool.
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in BBC)
     */
    function deposit(uint256 _amount) public virtual whenNotPaused nonReentrant {
        require(staking, "Not allowed to stake");
        require(_amount > MIN_DEPOSIT_AMOUNT, "Deposit amount must be greater than MIN_DEPOSIT_AMOUNT");
        UserInfo storage user = userInfo[msg.sender];
        
        uint256 pool = balanceOf();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        
        uint256 currentShares;
        if (totalShares != 0) {
            currentShares = (_amount * totalShares) / pool;
        } else {
            currentShares = _amount;
        }

        user.shares += currentShares;
        user.lastDepositedTime = block.timestamp;

        totalShares += currentShares;

        _earn();

        user.lastUserActionAmount = (user.shares * balanceOf()) / totalShares;

        user.lastUserActionTime = block.timestamp;

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    /**
     * @notice Withdraws funds from the BBC Flexible Pool
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public virtual nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        //The current pool balance should not include currentPerformanceFee.
        uint256 currentAmount = (_shares * balanceOf()) / totalShares;
        user.shares -= _shares;
        totalShares -= _shares;
        uint256 withdrawAmount = currentAmount;
        if (staking) {
            // withdrawByAmount have a MIN_WITHDRAW_AMOUNT limit ,so need to withdraw more than MIN_WITHDRAW_AMOUNT.
            withdrawAmount = withdrawAmount < MIN_WITHDRAW_AMOUNT ? MIN_WITHDRAW_AMOUNT : withdrawAmount;
            //There will be a loss of precision when call withdrawByAmount, so need to withdraw more.
            withdrawAmount = (withdrawAmount * withdrawAmountBooster) / FEE_RATE_SCALE;
            parentPool.withdrawByAmount(withdrawAmount);
        }

        currentAmount = available() >= currentAmount
            ? currentAmount
            : available();
        token.safeTransfer(msg.sender, currentAmount);

        if (user.shares > 0) {
            user.lastUserActionAmount =
                (user.shares * balanceOf()) /
                totalShares;
        } else {
            user.lastUserActionAmount = 0;
        }

        user.lastUserActionTime = block.timestamp;

        emit WithdrawShares(msg.sender, currentAmount, _shares);
    }

    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() public {
        withdraw(userInfo[msg.sender].shares);
    }

    /**
     * @notice Sets admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
        emit NewAdmin(admin);
    }

    /**
     * @notice Sets treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
        emit NewTreasury(treasury);
    }

    /**
     * @notice Withdraws from BBC Pool without caring about rewards.
     * @dev EMERGENCY ONLY. Only callable by the contract admin.
     */
    function emergencyWithdraw() public onlyAdmin {
        require(staking, "No staking bbc");
        staking = false;
        parentPool.withdrawAll();
    }

    /**
     * @notice Withdraw unexpected tokens sent to the BBC Flexible Pool
     */
    function inCaseTokensGetStuck(address _token) public onlyAdmin {
        require(
            _token != address(token),
            "Token cannot be same as deposit token"
        );

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() public onlyAdmin whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() public onlyAdmin whenPaused {
        _unpause();
        emit Unpause();
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() public view returns (uint256) {
        return totalShares == 0 ? 1e18 : (balanceOf() * 1e18) / totalShares;
    }

    /**
     * @notice Custom logic for how much the pool to be borrowed
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getProfit(address _user) public virtual view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.shares == 0) return 0;
        return
            (getPricePerFullShare() * user.shares) /
            1e18 -
            user.lastUserActionAmount;
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in BBCPool
     */
    function balanceOf() public virtual view returns (uint256) {
        (uint256 shares, , , , , , , , ) = parentPool.userInfo(address(this));
        uint256 pricePerFullShare = parentPool.getPricePerFullShare();
        return
            token.balanceOf(address(this)) +
            (shares * pricePerFullShare) /
            1e18;
    }

    /**
     * @notice Deposits tokens into BBCPool to earn staking rewards
     */
    function _earn() internal {
        uint256 bal = available();
        if (bal > 0) {
            parentPool.deposit(bal, 0);
        }
    }
}