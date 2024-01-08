// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./AccessControl.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ECDSA.sol";
import "./vcUSDPool.sol";

contract WalletTokensalePublic is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    uint256 public constant AMOUNT_USD = 500000000;

    uint256 public totalAmount;
    uint256 public totalSold;

    uint256 public maxAmountToBuy;

    /// @dev address of main token
    address public govTokenAddress;
    address public USDTAddress;
    uint256 public factor = 10**12;
    uint256 public USDTReceived;
    uint256 public USDTClaimed;

    /// @dev for example: 100000 = 0.01 USD
    uint256 public rate;
    uint256 public ratesPrecision = 10**7;

    address public vcUSDPoolAddress;

    uint256 currentLockNumber = 0;
    /// @dev true = swap unlocked, false = swap locked
    bool public swapUnlocked = true;

    /// @dev true = claim unlocked, false = locked
    bool public claimUnlocked = false;
    /// @dev struct of lock tokens
    struct Lock {
        uint256 unlockDate;
        uint256 percent;
    }
    /// @dev array of locks tokens
    Lock[] public locks;

    struct UserInfo {
        uint256 amount;
        uint256 claimed;
    }

    mapping(address => UserInfo) public users;

    mapping(bytes32 => bool) hashes;
    uint256 public swapsCount;

    event TokenExchanged(
        address indexed spender,
        uint256 usdAmount,
        uint256 daovcAmount,
        uint256 time,
        string userId
    );
    event TokenExchangedFiat(
        address indexed spender,
        uint256 amount,
        uint256 daovcAmount,
        uint256 time
    );
    event TokensClaimed(
        address indexed claimer,
        uint256 amountClaimed,
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
     * @dev Constructor of Wallet
     * @param _govTokenAddress address of main token
     * @param _USDTAddress address of USDT token
     * @param _rate rate value
     * @param _totalAmount total amount of tokens
     * @param _maxAmountToBuy max amount ot buy in usdt
     * @param _vcUSDPoolAddress vc usd pool address
     * @param _usdtReceived initial value of received usdt
     * @param _usdtClaimed initial value of claimed usdt
     */
    constructor(
        address _govTokenAddress,
        address _USDTAddress,
        uint256 _rate,
        uint256 _totalAmount,
        uint256 _maxAmountToBuy,
        address _vcUSDPoolAddress,
        uint256 _usdtReceived,
        uint256 _usdtClaimed
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        govTokenAddress = _govTokenAddress;
        USDTAddress = _USDTAddress;
        rate = _rate;
        totalAmount = _totalAmount;
        maxAmountToBuy = _maxAmountToBuy;
        vcUSDPoolAddress = _vcUSDPoolAddress;
        USDTClaimed = _usdtClaimed;
        USDTReceived = _usdtReceived;
    }

    /**
     * @dev set round state
     * @param _state state of round
     */
    function setRoundState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        swapUnlocked = _state;
        emit RoundStateChanged(_state, block.timestamp);
    }

    /**
     * @dev add the token to Lock pull
     * @param _unlockDate date of token unlock
     * @param _percent percent of unlocked token
     */
    function addLock(uint256[] memory _unlockDate, uint256[] memory _percent)
        external
    {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _unlockDate.length == _percent.length,
            "unlockDate array and percent arrays must have same values"
        );

        for (uint256 i = 0; i < _unlockDate.length; i++) {
            locks.push(
                Lock({percent: _percent[i], unlockDate: _unlockDate[i]})
            );
        }
    }

    /**
     * @dev swap usdt to daoVC gov token
     * @param hashedMessage hash of transaction data
     * @param _sequence transaction number
     * @param _v v of hash signature
     * @param _r r of hash signature
     * @param _s s of hash signature
     */
    function swap(
        bytes32 hashedMessage,
        string memory _userId,
        uint256 _sequence,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external roundUnlocked {
        address service = ECDSA.recover(hashedMessage, _v, _r, _s);
        require(hasRole(SERVICE_ROLE, service), "Signed not by a service");

        bytes32 message = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_userId, _sequence))
        );

        require(hashedMessage == message, "Incorrect hashed message");
        require(
            !hashes[message],
            "Sequence amount already claimed or dublicated"
        );
        hashes[message] = true;
        swapsCount++;

        UserInfo storage user = users[msg.sender];

        uint256 amountInGov = AMOUNT_USD.mul(factor).mul(ratesPrecision).div(
            rate
        );
        require(
            user.amount.add(amountInGov) <= maxAmountToBuy,
            "You cannot swap more tokens"
        );

        require(
            totalSold.add(amountInGov) <= totalAmount,
            "All tokens was sold"
        );

        ERC20(USDTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            AMOUNT_USD
        );

        USDTReceived = USDTReceived.add(AMOUNT_USD);
        user.amount = user.amount.add(amountInGov);
        totalSold = totalSold.add(amountInGov);

        emit TokenExchanged(
            msg.sender,
            AMOUNT_USD,
            amountInGov,
            block.timestamp,
            _userId
        );
    }

    /**
     * @dev swap fiat to daoVC gov token
     * @param _user  user's address
     */
    function swapBackend(address _user) external roundUnlocked {
        require(
            hasRole(SERVICE_ROLE, msg.sender),
            "Caller does not have the service role"
        );
        UserInfo storage user = users[_user];

        uint256 amountInGov = AMOUNT_USD.mul(factor).mul(ratesPrecision).div(
            rate
        );
        require(
            user.amount.add(amountInGov) <= maxAmountToBuy,
            "You cannot swap more tokens"
        );

        require(
            totalSold.add(amountInGov) <= totalAmount,
            "All tokens was sold"
        );

        swapsCount++;
        USDTReceived = USDTReceived.add(AMOUNT_USD);
        user.amount = user.amount.add(amountInGov);
        totalSold = totalSold.add(amountInGov);
        emit TokenExchangedFiat(_user, AMOUNT_USD, amountInGov, block.timestamp);
    }

    /**
     * @dev user claim's his availeble tokens
     */
    function claim() external nonReentrant claimUnlockedModifier {
        UserInfo storage user = users[msg.sender];
        require(user.amount > 0, "Nothing to claim");
        uint256 newLock = currentLockNumber;
        if (newLock <= locks.length - 2) {
            while (block.timestamp >= locks[newLock + 1].unlockDate) {
                newLock = newLock + 1;
                if (newLock == locks.length - 1) {
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

    /**
     * @dev send USDT to vc usd pool
     */
    function sendUsdtToPool(uint256 _amount) external {
        require(
            hasRole(SERVICE_ROLE, msg.sender),
            "Caller does not have the service role"
        );

        ERC20(USDTAddress).safeTransfer(vcUSDPoolAddress, _amount);
        USDTClaimed = USDTClaimed.add(_amount);

        vcUSDPool(vcUSDPoolAddress).sellVcUsdBackend(_amount);
    }

    /**
     * @dev Caluclate available amount of tokens for user
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

    /**
     * @dev get user info
     * @param _user address of user
     */
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
                if (newLock == locks.length - 1) {
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

    /**
     * @dev get state of round
     */
    function getRoundState() external view returns (bool) {
        return swapUnlocked;
    }

    /**
     * @dev remove tokens from pool
     * @param _recepient address of recipient
     * @param _amount amount of tokens
     * @param tokenAddress address of token
     */
    function removeToken(
        address _recepient,
        uint256 _amount,
        address tokenAddress
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");

        ERC20(tokenAddress).safeTransfer(_recepient, _amount);
    }

    /**
     * @dev update lock data
     * @param _index index of lock data
     * @param _percent percent value
     * @param _unlockDate date of unlock
     */
    function updateLock(
        uint256 _index,
        uint256 _percent,
        uint256 _unlockDate
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        locks[_index].percent = _percent;
        locks[_index].unlockDate = _unlockDate;
    }

    /**
     * @dev update user info
     * @param _user address of user
     * @param _amount amount of tokens
     * @param _claimed amount of claimed tokens
     */
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

    /**
     * @dev set address of token
     * @param _govTokenAddress address of gov token
     */
    function updateTokenAddress(address _govTokenAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        govTokenAddress = _govTokenAddress;
    }

    /** @dev claim usdt from this contract
     *  @param _usdtReceiver address, who gets USDT tokens
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

    /**
     * @dev
     */
    function getInfoAboutUsdt()
        external
        view
        returns (uint256 USDTReceived_, uint256 USDTClaimed_)
    {
        USDTReceived_ = USDTReceived;
        USDTClaimed_ = USDTClaimed;
        return (USDTReceived_, USDTClaimed_);
    }

    /**
     * @dev returns current rate for contract
     */
    function getRate() external view returns (uint256) {
        return rate;
    }

    /**
     * @dev update rates
     * @param _rate rate, for example: 400000 = 0.04$
     */
    function updateRate(uint256 _rate) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        rate = _rate;
    }

    /**
     * @dev update vc usd pool address
     * @param _vcUSDPoolAddress address of vc usd pool
     */
    function updateVcUsdPoolAddress(address _vcUSDPoolAddress) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        vcUSDPoolAddress = _vcUSDPoolAddress;
    }

    /**
     * @dev update maximum amount to buy
     * @param _maxAmountToBuy maximum amount value
     */
    function updateMaximum(uint256 _maxAmountToBuy) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        maxAmountToBuy = _maxAmountToBuy;
    }

    /**
     * @dev update current lock number
     * @param _newCurrentLock new lock number
     */
    function updateCurrentLockNumber(uint256 _newCurrentLock) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        currentLockNumber = _newCurrentLock;
    }

    /**
     * @dev add users with info
     * @param _users users addresses array
     * @param _amounts amounts array
     * @param _claimed claimed amount array
     */
    function migrateUsers(
        address[] memory _users,
        uint256[] memory _amounts,
        uint256[] memory _claimed
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(
            _users.length == _amounts.length,
            "Array users and amounts must be the same length"
        );
        require(
            _users.length == _claimed.length,
            "Array users and claimed must be the same length"
        );

        for (uint256 i = 0; i < _users.length; i++) {
            UserInfo storage user = users[_users[i]];
            user.amount = _amounts[i];
            user.claimed = _claimed[i];
        }
    }

    /**
     * @dev set state of claim
     * @param _state state of claim
     */
    function setClaimState(bool _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        claimUnlocked = _state;
    }

    /**
     * @dev set total amount of reward tokens
     * @param _totalAmount total amount value
     */
    function updateTotalAmount(uint256 _totalAmount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        totalAmount = _totalAmount;
    }

    /**
     * @dev set total sold
     * @param _totalSold total sold amount
     */
    function updateTotalSold(uint256 _totalSold) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        totalSold = _totalSold;
    }

    /**
     * @dev set factor
     * @param _factor factor value
     */
    function updateFactor(uint256 _factor) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        factor = _factor;
    }

    /**
     * @dev set value of received USDT
     * @param _usdtReceived received USDT amount
     */
    function updateUSDTReceived(uint256 _usdtReceived) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        USDTReceived = _usdtReceived;
    }

    /**
     * @dev set value of claimed USDT
     * @param _usdtClaimed claimed USDT amount
     */
    function updateUSDTClaimed(uint256 _usdtClaimed) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        USDTClaimed = _usdtClaimed;
    }
}
