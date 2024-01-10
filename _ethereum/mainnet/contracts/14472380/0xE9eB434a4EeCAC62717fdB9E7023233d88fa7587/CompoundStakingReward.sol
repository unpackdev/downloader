// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

import "./TokenDistributor.sol";
import "./IStakeFor.sol";
import "./IBurnableERC20.sol";


/**
 * @title CompoundStakingReward
 * @notice It handles the staking and auto-compounding of State Token
 */
contract CompoundStakingReward is ReentrancyGuard, AccessControl, IStakeFor {
    using SafeERC20 for IERC20;
    using SafeERC20 for IBurnableERC20;
    using SafeMath for uint256;

    // for `depositFor` call
    bytes32 public constant DEPOSIT_ROLE = keccak256('DEPOSIT_ROLE');

    struct UserInfo {
        uint256 shares; // shares of token staked
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    IBurnableERC20 public immutable stateToken;

    TokenDistributor public immutable tokenDistributor;

    // Total existing shares
    uint256 public totalShares;

    uint256 public immutable startBlock;

    mapping(address => UserInfo) public userInfo;
    
    uint256[] public penaltyPeriods; // penalty in blocks, start from startBlock, using 6500 blocks per day
    uint256[] public penaltyRates;   // penalty rates

    event Deposit(address indexed user, uint256 amount, uint256 harvestedAmount);
    event Withdraw(address indexed user, uint256 amount, uint256 penaltyAmount);

    /**
     * @notice Constructor
     * @param _stateToken address of the token staked
     * @param _tokenDistributor address of the token distributor contract
     */
    constructor(
        address _stateToken,
        address _tokenDistributor,
        uint256 _startBlock,
        uint256[] memory _penaltyPeriods,
        uint256[] memory _penaltyRates
    ) {
        require(
            _penaltyPeriods.length == _penaltyRates.length,
            'Compound Staking: _penaltyPeriods Length must match _penaltyRates Length'
        );
        stateToken = IBurnableERC20(_stateToken);
        tokenDistributor = TokenDistributor(_tokenDistributor);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        require(_startBlock > block.number,"error _startBlock!");
        startBlock = _startBlock;
        penaltyPeriods = _penaltyPeriods;
        penaltyRates = _penaltyRates;
    }

    /**
     * @notice deposit on behalf of `user`, must be called on fresh deposit only
     * @param user deposit user
     * @param amount amount to deposit
     */
    function depositFor(address user, uint256 amount)
        external
        override
        nonReentrant
        onlyRole(DEPOSIT_ROLE)
        returns (bool)
    {
        require(amount >= PRECISION_FACTOR, 'Deposit: Amount must be >= 1 State');

        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Retrieve total amount staked by this contract
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // transfer stakingToken from **sender**
        stateToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentShares;

        // Calculate the number of shares to issue for the user
        if (totalShares != 0) {
            currentShares = (amount * totalShares) / totalAmountStaked;
            // This is a sanity check to prevent deposit for 0 shares
            require(currentShares != 0, 'Deposit: Fail');
        } else {
            currentShares = amount;
        }

        // Adjust internal shares
        userInfo[user].shares += currentShares;
        totalShares += currentShares;

        // Verify state token allowance and adjust if necessary
        _checkAndAdjustStateTokenAllowanceIfRequired(amount, address(tokenDistributor));

        // Deposit user amount in the token distributor contract
        tokenDistributor.deposit(amount);

        emit Deposit(user, amount, 0);

        return true;
    }

    /**
     * @notice Deposit staked tokens
     * @param amount amount to deposit (in State Token)
     * @dev There is a limit of 1 State per deposit to prevent potential manipulation of current shares
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount >= PRECISION_FACTOR, 'Deposit: Amount must be >= 1 State');

        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Retrieve total amount staked by this contract
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Transfer state tokens to this address
        stateToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentShares;

        // Calculate the number of shares to issue for the user
        if (totalShares != 0) {
            currentShares = (amount * totalShares) / totalAmountStaked;
            // This is a sanity check to prevent deposit for 0 shares
            require(currentShares != 0, 'Deposit: Fail');
        } else {
            currentShares = amount;
        }

        // Adjust internal shares
        userInfo[msg.sender].shares += currentShares;
        totalShares += currentShares;

        // Verify state token allowance and adjust if necessary
        _checkAndAdjustStateTokenAllowanceIfRequired(amount, address(tokenDistributor));

        // Deposit user amount in the token distributor contract
        tokenDistributor.deposit(amount);

        emit Deposit(msg.sender, amount, 0);
    }

    /**
     * @notice Withdraw staked tokens
     * @param shares shares to withdraw
     */
    function withdraw(uint256 shares) external nonReentrant {
        require(
            (shares > 0) && (shares <= userInfo[msg.sender].shares),
            'Withdraw: Shares equal to 0 or larger than user shares'
        );

        _withdraw(shares);
    }

    /**
     * @notice Withdraw all staked tokens
     */
    function withdrawAll() external nonReentrant {
        _withdraw(userInfo[msg.sender].shares);
    }

    /**
     * @notice Calculate value of State Token for a user given a number of shares owned
     * @param user address of the user
     */
    function calculateSharesValueInState(address user) external view returns (uint256) {
        // Retrieve amount staked
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Adjust for pending rewards
        totalAmountStaked += tokenDistributor.calculatePendingRewards(address(this));

        // Return user pro-rata of total shares
        return
            userInfo[user].shares == 0
                ? 0
                : (totalAmountStaked * userInfo[user].shares) / totalShares;
    }

    /**
     * @notice Calculate price of one share (in State token)
     * Share price is expressed times 1e18
     */
    function calculateSharePriceInState() external view returns (uint256) {
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Adjust for pending rewards
        totalAmountStaked += tokenDistributor.calculatePendingRewards(address(this));

        return
            totalShares == 0
                ? PRECISION_FACTOR
                : (totalAmountStaked * PRECISION_FACTOR) / (totalShares);
    }

    /**
     * @notice Check current allowance and adjust if necessary
     * @param _amount amount to transfer
     * @param _to token to transfer
     */
    function _checkAndAdjustStateTokenAllowanceIfRequired(uint256 _amount, address _to) internal {
        if (stateToken.allowance(address(this), _to) < _amount) {
            stateToken.approve(_to, type(uint256).max);
        }
    }
    
    /**
     * @notice Calculate the user penalty for early withdrawal
     * @param _amount amount to withdrawal
     */
    function getPenalty(uint256 _amount, uint256 _blockNumber) view public returns (uint256) {
        if (_blockNumber <= startBlock) {
            return 0;
        }

        uint256 currentStartBlock = startBlock;
        for (uint i = 0; i < penaltyPeriods.length; i++) {
            uint256 endBlock = currentStartBlock + penaltyPeriods[i];
            if (_blockNumber < endBlock) {
                return _amount.mul(penaltyRates[i]).div(1000); // decimal: 3
            }
        }
        return 0;
    }

    /**
     * @notice Withdraw staked tokens
     * @param shares shares to withdraw
     */
    function _withdraw(uint256 shares) internal {
        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Retrieve total amount staked and calculated current amount (in State Token)
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));
        uint256 currentAmount = (totalAmountStaked * shares) / totalShares;

        userInfo[msg.sender].shares -= shares;
        totalShares -= shares;

        // Withdraw amount equivalent in shares
        tokenDistributor.withdraw(currentAmount);

        // check penalty 
        uint256 penaltyAmount = getPenalty(currentAmount, block.number);

        stateToken.burn(penaltyAmount);

        uint256 transferAmount = currentAmount.sub(penaltyAmount);
        require(transferAmount > 0, 'no available withdrawal after fee');

        // Transfer state tokens to sender
        stateToken.safeTransfer(msg.sender, transferAmount);

        emit Withdraw(msg.sender, currentAmount, penaltyAmount);
    }
}