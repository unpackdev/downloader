pragma solidity 0.6.12;

import "./Ownable.sol";
import "./Initializable.sol";
import "./SafeMathInt.sol";
import "./BaseToken.sol";

interface ICascadeV2 {
    function migrate(address user) external;
}

contract Cascade is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    function migrate()
        public
    {
        require(deposits_multiplierLevel[msg.sender] > 0, "no deposit");
        require(address(cascadeV2) != address(0x0), "no cascade v2");

        updateDepositSeconds();

        uint256 numLPTokens = deposits_lpTokensDeposited[msg.sender];
        uint256 numRewardTokens = BASE.balanceOf(address(this)).mul(sumOfUserDepositSeconds(msg.sender)).div(totalDepositSeconds());

        cascadeV2.migrate(msg.sender);

        (uint256 level1, uint256 level2, uint256 level3) = userDepositSeconds(msg.sender);
        totalDepositSecondsLevel1 = totalDepositSecondsLevel1.sub(level1);
        totalDepositSecondsLevel2 = totalDepositSecondsLevel2.sub(level2);
        totalDepositSecondsLevel3 = totalDepositSecondsLevel3.sub(level3);

        if (deposits_multiplierLevel[msg.sender] == 1) {
            totalDepositedLevel1 = totalDepositedLevel1.sub(deposits_lpTokensDeposited[msg.sender]);
        } else if (deposits_multiplierLevel[msg.sender] == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.sub(deposits_lpTokensDeposited[msg.sender]);
        } else if (deposits_multiplierLevel[msg.sender] == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.sub(deposits_lpTokensDeposited[msg.sender]);
        }

        bool ok = lpToken.transfer(address(cascadeV2), deposits_lpTokensDeposited[msg.sender]);
        require(ok, "transfer deposit");
        ok = BASE.transfer(address(cascadeV2), numRewardTokens);
        require(ok, "transfer rewards");

        delete deposits_lpTokensDeposited[msg.sender];
        delete deposits_depositTimestamp[msg.sender];
        delete deposits_multiplierLevel[msg.sender];
        delete deposits_mostRecentBASEWithdrawal[msg.sender];

        emit Migrate(msg.sender, numLPTokens, numRewardTokens);
    }

    mapping(address => uint256) public deposits_lpTokensDeposited;
    mapping(address => uint256) public deposits_depositTimestamp;
    mapping(address => uint8)   public deposits_multiplierLevel;
    mapping(address => uint256) public deposits_mostRecentBASEWithdrawal;

    uint256 public totalDepositedLevel1;
    uint256 public totalDepositedLevel2;
    uint256 public totalDepositedLevel3;
    uint256 public totalDepositSecondsLevel1;
    uint256 public totalDepositSecondsLevel2;
    uint256 public totalDepositSecondsLevel3;
    uint256 public lastAccountingUpdateTimestamp;

    IERC20 public lpToken;
    BaseToken public BASE;
    uint256 public minTimeBetweenWithdrawals;

    uint256 public rewardsStartTimestamp;
    uint256 public rewardsDuration;

    mapping(address => uint256) public deposits_lastMultiplierUpgradeTimestamp;
    uint256 multiplierUpgradeTimeout;

    ICascadeV2 public cascadeV2;

    event Deposit(address indexed user, uint256 previousLPTokens, uint256 additionalTokens, uint256 timestamp);
    event Withdraw(address indexed user, uint256 lpTokens, uint256 baseTokens, uint256 timestamp);
    event UpgradeMultiplierLevel(address indexed user, uint8 oldLevel, uint256 newLevel, uint256 timestamp);
    event Migrate(address indexed user, uint256 lpTokens, uint256 rewardTokens);

    function initialize()
        public
        initializer
    {
        __Ownable_init();
    }

    /**
     * Admin
     */

    function setLPToken(address _lpToken)
        public
        onlyOwner
    {
        lpToken = IERC20(_lpToken);
    }

    function setBASEToken(address _baseToken)
        public
        onlyOwner
    {
        BASE = BaseToken(_baseToken);
    }

    function setCascadeV2(address _cascadeV2)
        public
        onlyOwner
    {
        cascadeV2 = ICascadeV2(_cascadeV2);
    }

    function setMinTimeBetweenWithdrawals(uint256 _minTimeBetweenWithdrawals)
        public
        onlyOwner
    {
        minTimeBetweenWithdrawals = _minTimeBetweenWithdrawals;
    }

    function setRewardsParams(uint256 _rewardsStartTimestamp, uint256 _rewardsDuration)
        public
        onlyOwner
    {
        rewardsStartTimestamp = _rewardsStartTimestamp;
        rewardsDuration = _rewardsDuration;
    }

    function setMultiplierUpgradeTimeout(uint256 _multiplierUpgradeTimeout)
        public
        onlyOwner
    {
        multiplierUpgradeTimeout = _multiplierUpgradeTimeout;
    }

    function adminWithdrawBASE(address recipient, uint256 amount)
        public
        onlyOwner
    {
        require(recipient != address(0x0), "bad recipient");
        require(amount > 0, "bad amount");

        bool ok = BASE.transfer(recipient, amount);
        require(ok, "transfer");
    }

    function rescueMistakenlySentTokens(address token, address recipient, uint256 amount)
        public
        onlyOwner
    {
        require(recipient != address(0x0), "bad recipient");
        require(amount > 0, "bad amount");

        bool ok = IERC20(token).transfer(recipient, amount);
        require(ok, "transfer");
    }

    /**
     * Public methods
     */

    function deposit(uint256 amount)
        public
    {
        require(deposits_lastMultiplierUpgradeTimestamp[msg.sender] == 0, "multiplied too recently");

        updateDepositSeconds();

        uint256 allowance = lpToken.allowance(msg.sender, address(this));
        require(amount <= allowance, "allowance");

        totalDepositedLevel1 = totalDepositedLevel1.add(amount);

        deposits_lpTokensDeposited[msg.sender] = deposits_lpTokensDeposited[msg.sender].add(amount);
        deposits_multiplierLevel[msg.sender] = 1;
        if (deposits_depositTimestamp[msg.sender] == 0) {
            deposits_depositTimestamp[msg.sender] = now;
        }

        bool ok = lpToken.transferFrom(msg.sender, address(this), amount);
        require(ok, "transferFrom");

        emit Deposit(msg.sender, deposits_lpTokensDeposited[msg.sender].sub(amount), amount, now);
    }

    function upgradeMultiplierLevel()
        public
    {
        require(deposits_multiplierLevel[msg.sender] > 0, "no deposit");
        require(deposits_multiplierLevel[msg.sender] < 3, "fully upgraded");

        deposits_lastMultiplierUpgradeTimestamp[msg.sender] = block.timestamp;

        updateDepositSeconds();

        uint8 oldLevel = deposits_multiplierLevel[msg.sender];
        uint256 age = now.sub(deposits_depositTimestamp[msg.sender]);
        uint256 lpTokensDeposited = deposits_lpTokensDeposited[msg.sender];

        if (deposits_multiplierLevel[msg.sender] == 1 && age >= 60 days) {
            uint256 secondsSinceLevel2 = age.sub(30 days);
            uint256 secondsSinceLevel3 = age.sub(60 days);
            totalDepositedLevel1 = totalDepositedLevel1.sub(lpTokensDeposited);
            totalDepositedLevel3 = totalDepositedLevel3.add(lpTokensDeposited);
            totalDepositSecondsLevel2 = totalDepositSecondsLevel2.add( lpTokensDeposited.mul(secondsSinceLevel2) );
            totalDepositSecondsLevel3 = totalDepositSecondsLevel3.add( lpTokensDeposited.mul(secondsSinceLevel2.add(secondsSinceLevel3)) );
            deposits_multiplierLevel[msg.sender] = 3;

        } else if (deposits_multiplierLevel[msg.sender] == 1 && age >= 30 days) {
            uint256 secondsSinceLevel2 = age.sub(30 days);
            totalDepositedLevel1 = totalDepositedLevel1.sub(lpTokensDeposited);
            totalDepositedLevel2 = totalDepositedLevel2.add(lpTokensDeposited);
            totalDepositSecondsLevel1 = totalDepositSecondsLevel1.sub( lpTokensDeposited.mul(secondsSinceLevel2) );
            totalDepositSecondsLevel2 = totalDepositSecondsLevel2.add( lpTokensDeposited.mul(secondsSinceLevel2) );
            deposits_multiplierLevel[msg.sender] = 2;

        } else if (deposits_multiplierLevel[msg.sender] == 2 && age >= 60 days) {
            uint256 secondsSinceLevel3 = age.sub(60 days);
            totalDepositedLevel2 = totalDepositedLevel2.sub(lpTokensDeposited);
            totalDepositedLevel3 = totalDepositedLevel3.add(lpTokensDeposited);
            totalDepositSecondsLevel3 = totalDepositSecondsLevel3.add( lpTokensDeposited.mul(secondsSinceLevel3) );
            deposits_multiplierLevel[msg.sender] = 3;

        } else {
            revert("ineligible");
        }

        emit UpgradeMultiplierLevel(msg.sender, oldLevel, deposits_multiplierLevel[msg.sender], now);
    }

    function withdrawLPTokens()
        public
    {
        require(deposits_lastMultiplierUpgradeTimestamp[msg.sender] == 0, "multiplied too recently");

        updateDepositSeconds();

        uint256 owed = owedTo(msg.sender);
        require(BASE.balanceOf(address(this)) >= owed, "available tokens");
        require(deposits_multiplierLevel[msg.sender] > 0, "doesn't exist");
        require(deposits_lpTokensDeposited[msg.sender] > 0, "no stake");
        require(allowedToWithdraw(msg.sender), "too soon");

        deposits_mostRecentBASEWithdrawal[msg.sender] = now;

        (uint256 level1, uint256 level2, uint256 level3) = userDepositSeconds(msg.sender);
        totalDepositSecondsLevel1 = totalDepositSecondsLevel1.sub(level1);
        totalDepositSecondsLevel2 = totalDepositSecondsLevel2.sub(level2);
        totalDepositSecondsLevel3 = totalDepositSecondsLevel3.sub(level3);

        if (deposits_multiplierLevel[msg.sender] == 1) {
            totalDepositedLevel1 = totalDepositedLevel1.sub(deposits_lpTokensDeposited[msg.sender]);
        } else if (deposits_multiplierLevel[msg.sender] == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.sub(deposits_lpTokensDeposited[msg.sender]);
        } else if (deposits_multiplierLevel[msg.sender] == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.sub(deposits_lpTokensDeposited[msg.sender]);
        }

        uint256 deposited = deposits_lpTokensDeposited[msg.sender];

        delete deposits_lpTokensDeposited[msg.sender];
        delete deposits_depositTimestamp[msg.sender];
        delete deposits_multiplierLevel[msg.sender];
        delete deposits_mostRecentBASEWithdrawal[msg.sender];

        bool ok = lpToken.transfer(msg.sender, deposited);
        require(ok, "transfer");
        ok = BASE.transfer(msg.sender, owed);
        require(ok, "transfer");

        emit Withdraw(msg.sender, deposited, owed, now);
    }

    /**
     * Accounting utilities
     */

    function updateDepositSeconds()
        public
    {
        (totalDepositSecondsLevel1, totalDepositSecondsLevel2, totalDepositSecondsLevel3) = getUpdatedDepositSeconds();
        lastAccountingUpdateTimestamp = now;
    }

    function getUpdatedDepositSeconds()
        public
        view
        returns (uint256 level1, uint256 level2, uint256 level3)
    {
        uint256 delta = now.sub(lastAccountingUpdateTimestamp);
        return (
            totalDepositSecondsLevel1.add(totalDepositedLevel1.mul(delta)),
            totalDepositSecondsLevel2.add(totalDepositedLevel2.mul(delta)),
            totalDepositSecondsLevel3.add(totalDepositedLevel3.mul(delta))
        );
    }

    /**
     * Getters
     */

    function depositInfo(address user)
        public
        view
        returns (
            uint256 _lpTokensDeposited,
            uint256 _depositTimestamp,
            uint8   _multiplierLevel,
            uint256 _mostRecentBASEWithdrawal,
            uint256 _userDepositSeconds,
            uint256 _totalDepositSeconds
        )
    {
        uint256 delta = now.sub(lastAccountingUpdateTimestamp);
        _totalDepositSeconds = totalDepositSecondsLevel1.add(totalDepositedLevel1.mul(delta))
                                  .add(totalDepositSecondsLevel2.add(totalDepositedLevel2.mul(delta)).mul(2))
                                  .add(totalDepositSecondsLevel3.add(totalDepositedLevel3.mul(delta)).mul(3));

        return (
            deposits_lpTokensDeposited[user],
            deposits_depositTimestamp[user],
            deposits_multiplierLevel[user],
            deposits_mostRecentBASEWithdrawal[user],
            sumOfUserDepositSeconds(user),
            _totalDepositSeconds
        );
    }

    function allowedToWithdraw(address user)
        public
        view
        returns (bool)
    {
        return deposits_mostRecentBASEWithdrawal[user] == 0
                ? now > deposits_depositTimestamp[user].add(minTimeBetweenWithdrawals)
                : now > deposits_mostRecentBASEWithdrawal[user].add(minTimeBetweenWithdrawals);
    }

    function userDepositSeconds(address user)
        public
        view
        returns (uint256 level1, uint256 level2, uint256 level3)
    {
        uint256 timeSinceDeposit = now.sub(deposits_depositTimestamp[user]);
        uint256 multiplier = deposits_multiplierLevel[user];
        uint256 lpTokens = deposits_lpTokensDeposited[user];
        uint256 secondsLevel1;
        uint256 secondsLevel2;
        uint256 secondsLevel3;
        if (multiplier == 1) {
            secondsLevel1 = timeSinceDeposit;
        } else if (multiplier == 2) {
            secondsLevel1 = 30 days;
            secondsLevel2 = timeSinceDeposit.sub(30 days);
        } else if (multiplier == 3) {
            secondsLevel1 = 30 days;
            secondsLevel2 = 30 days;
            secondsLevel3 = timeSinceDeposit.sub(60 days);
        }

        return (
            lpTokens.mul(secondsLevel1),
            lpTokens.mul(secondsLevel2),
            lpTokens.mul(secondsLevel3)
        );
    }

    function sumOfUserDepositSeconds(address user)
        public
        view
        returns (uint256)
    {
        (uint256 level1, uint256 level2, uint256 level3) = userDepositSeconds(user);
        return level1.add(level2.mul(2)).add(level3.mul(3));
    }

    function totalDepositSeconds()
        public
        view
        returns (uint256)
    {
        (uint256 level1, uint256 level2, uint256 level3) = getUpdatedDepositSeconds();
        return level1.add(level2.mul(2)).add(level3.mul(3));
    }

    function rewardsPool()
        public
        view
        returns (uint256)
    {
        uint256 baseBalance = BASE.balanceOf(address(this));
        uint256 unlocked;
        if (rewardsStartTimestamp > 0) {
            uint256 secondsIntoVesting = now.sub(rewardsStartTimestamp);
            if (secondsIntoVesting > rewardsDuration) {
                unlocked = baseBalance;
            } else {
                unlocked = baseBalance.mul( now.sub(rewardsStartTimestamp) ).div(rewardsDuration);
            }
        } else {
            unlocked = baseBalance;
        }
        return unlocked;
    }

    function owedTo(address user)
        public
        view
        returns (uint256 amount)
    {
        if (totalDepositSeconds() == 0) {
            return 0;
        }
        return rewardsPool().mul(sumOfUserDepositSeconds(user)).div(totalDepositSeconds());
    }
}
