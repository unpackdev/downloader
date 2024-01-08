// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./AccessControl.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

import "./vcUSDPool.sol";

contract WalletTokensalePrivate is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public totalAmount;
    uint256 public totalSold;

    uint256 public minAmountToBuy;
    uint256 public maxAmountToBuy;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");
    // address of main token
    address public govTokenAddress;
    address public USDTAddress;
    uint256 public factor = 10**12;
    uint256 public USDTReceived;
    uint256 public USDTClaimed;

    // for example: 100000 = 0.01 USD
    uint256 public rate;
    uint256 public ratesPrecision = 10**7;

    address public vcUSDPoolAddress;

    uint256 currentLockNumber = 0;
    // true = swap unlocked, false = swap locked
    bool public swapUnlocked = true;

    //true = claim unlocked, false = locked
    bool public claimUnlocked = false;
    // struct of lock tokens
    struct Lock {
        uint256 unlockDate;
        uint256 percent;
    }
    // array of locks tokens
    Lock[] public locks;

    struct UserInfo {
        uint256 amount;
        uint256 claimed;
    }

    mapping(address => UserInfo) public users;
    event TokenExchangedFromUsdt(
        address indexed spender,
        uint256 usdtAmount,
        uint256 daovcAmount,
        string userId,
        uint256 time
    );
    event TokensClaimed(
        address indexed claimer,
        uint256 amountClaimed,
        uint256 time
    );
    event TokenExchangedFromFiat(
        address indexed spender,
        uint256 amount,
        uint256 daovcAmount,
        uint256 time
    );
    event RoundStateChanged(bool state, uint256 time);

    modifier roundUnlocked() {
        require(swapUnlocked, "Round is locked!");
        _;
    }

    modifier claimUnlockedModifier() {
        require(claimUnlocked, "Round is locked!");
        _;
    }

    /**
     * @dev Constructor of Wallet.
     *
     */
    constructor(
        address _govTokenAddress,
        address _USDTAddress,
        uint256 _rate,
        uint256 _totalAmount,
        uint256 _minAmountToBuy,
        uint256 _maxAmountToBuy,
        address _vcUSDPoolAddress,
        uint256 _usdtReceived,
        uint256 _usdtClaimed
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        govTokenAddress = _govTokenAddress;
        USDTAddress = _USDTAddress;
        rate = _rate;
        totalAmount = _totalAmount;
        minAmountToBuy = _minAmountToBuy;
        maxAmountToBuy = _maxAmountToBuy;
        vcUSDPoolAddress = _vcUSDPoolAddress;
        USDTClaimed = _usdtClaimed;
        USDTReceived = _usdtReceived;
    }

    function setRoundState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        swapUnlocked = _state;
        emit RoundStateChanged(_state, block.timestamp);
    }

    /**
     * @dev add the token to Lock pull
     *
     * Parameters:
     *
     * - `_unlockDate` - date of token unlock
     * - `_amount` - token amount
     */
    function addLock(uint256[] memory _unlockDate, uint256[] memory _percent)
        external
    {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _unlockDate.length == 10,
            "unlockDate array must have 10 values!"
        );
        require(_percent.length == 10, "percent array must have 10 values!");

        for (uint256 i = 0; i < _unlockDate.length; i++) {
            locks.push(
                Lock({percent: _percent[i], unlockDate: _unlockDate[i]})
            );
        }
    }

    /** @notice swap usdt to daoVC gov token
     *
     * Parameters:
     *
     *  @param _amountInUsdt - amount in usdt
     */
    function swap(uint256 _amountInUsdt, string memory _userId)
        external
        roundUnlocked
    {
        UserInfo storage user = users[msg.sender];

        uint256 amountInGov = _amountInUsdt.mul(factor).mul(ratesPrecision).div(
            rate
        );
        require(
            _amountInUsdt >= minAmountToBuy &&
                user.amount.add(amountInGov) <= maxAmountToBuy,
            "Amount must must be within the permitted range!"
        );

        require(
            totalSold.add(amountInGov) <= totalAmount,
            "All tokens was sold!"
        );

        ERC20(USDTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amountInUsdt
        );

        USDTReceived = USDTReceived.add(_amountInUsdt);
        user.amount = user.amount.add(amountInGov);
        totalSold = totalSold.add(amountInGov);

        emit TokenExchangedFromUsdt(
            msg.sender,
            _amountInUsdt,
            amountInGov,
            _userId,
            block.timestamp
        );
    }

    /** @notice swap fiat to daoVC gov token
     *
     * Parameters:
     *
     *  @param _user - user's address
     *  @param _amountInUsdt - amount in usd
     */
    function swapBackend(address _user, uint256 _amountInUsdt)
        external
        roundUnlocked
    {
        require(
            hasRole(SERVICE_ROLE, msg.sender),
            "Caller does not have the service role."
        );
        UserInfo storage user = users[_user];

        uint256 amountInGov = _amountInUsdt.mul(factor).mul(ratesPrecision).div(
            rate
        );
        require(
            _amountInUsdt >= minAmountToBuy &&
                user.amount.add(amountInGov) <= maxAmountToBuy,
            "Amount must must be within the permitted range!"
        );

        require(
            totalSold.add(amountInGov) <= totalAmount,
            "All tokens was sold!"
        );

        USDTReceived = USDTReceived.add(_amountInUsdt);
        user.amount = user.amount.add(amountInGov);
        totalSold = totalSold.add(amountInGov);
        emit TokenExchangedFromFiat(
            _user,
            _amountInUsdt,
            amountInGov,
            block.timestamp
        );
    }

    /** @notice user claim's his availeble tokens
     *
     */
    function claim() external nonReentrant claimUnlockedModifier {
        UserInfo storage user = users[msg.sender];
        require(user.amount > 0, "Nothing to claim");
        uint256 newLock = currentLockNumber;
        if (newLock <= locks.length - 2) {
            while (block.timestamp >= locks[newLock + 1].unlockDate) {
                newLock = newLock + 1;
                if (newLock == 9) {
                    break;
                }
            }
            currentLockNumber = newLock;
        }

        uint256 availableAmount = calcAvailableAmount(msg.sender);

        require(availableAmount > 0, "There are not available tokens to claim");
        user.claimed = user.claimed.add(availableAmount);
        ERC20(govTokenAddress).safeTransfer(msg.sender, availableAmount);
        emit TokensClaimed(msg.sender, availableAmount, block.timestamp);
    }

    function sendUsdtToPool(uint256 _amount) external {
        require(
            hasRole(SERVICE_ROLE, msg.sender),
            "Caller does not have the service role."
        );

        ERC20(USDTAddress).safeTransfer(vcUSDPoolAddress, _amount);
        USDTClaimed = USDTClaimed.add(_amount);

        vcUSDPool(vcUSDPoolAddress).sellVcUsdBackend(_amount);
    }

    /** @notice caluclate availeble amount of tokens for user
     *
     * Parameters:
     *
     *  @param _user - address of user
     */
    function calcAvailableAmount(address _user)
        private
        view
        returns (uint256 availableToken)
    {
        UserInfo storage user = users[_user];

        availableToken = (
            user.amount.mul(locks[currentLockNumber].percent).div(100)
        );

        if (availableToken >= user.claimed) {
            availableToken = availableToken.sub(user.claimed);
        } else {
            availableToken = 0;
        }

        return availableToken;
    }

    function getUserInfo(address _user)
        external
        view
        returns (
            uint256 amount_,
            uint256 available_,
            uint256 claimed_,
            uint256 currentLockTime_
        )
    {
        UserInfo storage user = users[_user];

        uint256 newLock = currentLockNumber;
        if (newLock <= locks.length - 2) {
            while (block.timestamp >= locks[newLock + 1].unlockDate) {
                newLock = newLock + 1;
                if (newLock == 9) {
                    break;
                }
            }
        }
        amount_ = user.amount;
        claimed_ = user.claimed;
        available_ = (user.amount.mul(locks[newLock].percent).div(100));

        if (available_ >= user.claimed) {
            available_ = available_.sub(user.claimed);
        } else {
            available_ = 0;
        }

        if (newLock == locks.length - 1) {
            currentLockTime_ = locks[newLock].unlockDate;
        } else {
            currentLockTime_ = locks[newLock + 1].unlockDate;
        }

        return (amount_, available_, claimed_, currentLockTime_);
    }

    function getRoundState() external view returns (bool) {
        return swapUnlocked;
    }

    function removeToken(
        address _recepient,
        uint256 _amount,
        address tokenAddress
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _amount <= ERC20(tokenAddress).balanceOf(address(this)),
            "Amount must be <= balanceOf(this contract)."
        );
        ERC20(tokenAddress).safeTransfer(_recepient, _amount);
    }

    function updateLock(
        uint256 _index,
        uint256 _percent,
        uint256 _unlockDate
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        locks[_index].percent = _percent;
        locks[_index].unlockDate = _unlockDate;
    }

    function updateUserInfo(
        address _user,
        uint256 _amount,
        uint256 _claimed
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        UserInfo storage user = users[_user];
        user.amount = _amount;
        user.claimed = _claimed;
    }

    function updateTokenAddress(address _govTokenAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        govTokenAddress = _govTokenAddress;
    }

    /** @dev claim usdt from this contract
     *
     * Parameters:
     *
     *  - `usdtReceiver` - address, who gets USDT tokens
     */
    function claimUSDT(address _usdtReceiver) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(USDTReceived > 0, "Not enough USDT to claim");
        ERC20(USDTAddress).safeTransfer(
            _usdtReceiver,
            USDTReceived.sub(USDTClaimed)
        );
        USDTClaimed = USDTClaimed.add(USDTReceived.sub(USDTClaimed));
    }

    function getInfoAboutUsdt()
        external
        view
        returns (uint256 USDTReceived_, uint256 USDTClaimed_)
    {
        USDTReceived_ = USDTReceived;
        USDTClaimed_ = USDTClaimed;
        return (USDTReceived_, USDTClaimed_);
    }

    /** @dev returns current rate for contract
     *
     */
    function getRate() external view returns (uint256) {
        return rate;
    }

    /** @dev update rates
     *
     * Parameters:
     *
     *  - `_rate` - rate, for example: 400000 = 0.04$
     */
    function updateRate(uint256 _rate) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        rate = _rate;
    }

    function updateVcUsdPoolAddress(address _vcUSDPoolAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        vcUSDPoolAddress = _vcUSDPoolAddress;
    }

    // amount in usdt
    function updateMinimum(uint256 _minAmountToBuy) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        minAmountToBuy = _minAmountToBuy;
    }

    //amount in gov token
    function updateMaximum(uint256 _maxAmountToBuy) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        maxAmountToBuy = _maxAmountToBuy;
    }

    function updateCurrentLockNumber(uint256 _newCurrentLock) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        currentLockNumber = _newCurrentLock;
    }

    function migrateUsers(
        address[] memory _users,
        uint256[] memory _amounts,
        uint256[] memory _claimed
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _users.length == _amounts.length,
            "Array users and amounts must be the same length!"
        );
        require(
            _users.length == _claimed.length,
            "Array users and claimed must be the same length!"
        );

        for (uint256 i = 0; i < _users.length; i++) {
            UserInfo storage user = users[_users[i]];
            user.amount = _amounts[i];
            user.claimed = _claimed[i];
        }
    }

    function setClaimState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        claimUnlocked = _state;
    }

    function updateTotalAmount(uint256 _totalAmount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        totalAmount = _totalAmount;
    }

    function updateTotalSold(uint256 _totalSold) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        totalSold = _totalSold;
    }

    function updateFactor(uint256 _factor) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        factor = _factor;
    }

    function updateUSDTReceived(uint256 _usdtReceived) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        USDTReceived = _usdtReceived;
    }

    function updateUSDTClaimed(uint256 _usdtClaimed) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        USDTClaimed = _usdtClaimed;
    }
}
