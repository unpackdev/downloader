pragma solidity ^0.8.0;

import "./IERC20Decimals.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract TimeLock is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Decimals;

    address public wallet;
    uint256 public percent;
    uint256 public poolsCount;
    uint256 public minimalDepositAmount;
    poolName[] poolNamesArray;
    IERC20Decimals token;

    mapping(string => mapping(address => LockBoxStruct[])) public boxPool;
    mapping(string => poolData) public poolLockTime;
    mapping(address => bool) public managers;
    mapping(address => bool) public allowedBuyTokens;

    struct LockBoxStruct {
        address beneficiary;
        uint256 total;
        uint256 balance;
        uint256 payed;
        uint256 depositTime;
        uint256 periodsPassed;
    }

    struct poolData {
        string name;
        uint256 lockPeriod;
        uint256 periodLength;
        uint256 periodsNumber;
        uint256 percent;
        bool exists;
        uint256 startTime;
        uint256 cap;
        uint256 ratio;
        uint8 status;
        uint256 deposited;
        uint256 withdrawn;
    }

    struct bulkDeposit {
        address beneficiary;
        uint256 amount;
    }

    struct poolName {
        string name;
    }

    event LogLockBoxDeposit(
        address sender,
        uint256 amount,
        address stable,
        uint256 releaseTime,
        string pool,
        uint256 ratio
    );
    event LogLockBoxWithdrawal(address receiver, uint256 amount);
    event PoolAdded(string name);
    event UpdateManager(address manager, bool status);

    modifier onlyManager() {
        require(managers[msg.sender], "Only manager can call this function");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    fallback() external payable {}

    function initialize(address _wallet) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        wallet = _wallet;
        percent = 1000000;
        managers[msg.sender] = true;
    }

    function setToken(address _token) external onlyOwner {
        require(address(_token) != address(0), "Zero address not allowed");
        token = IERC20Decimals(_token);
    }

    function setWallet(address _wallet) external onlyOwner {
        require(address(_wallet) != address(0), "Zero address not allowed");
        wallet = _wallet;
    }

    function setBuyToken(address _token, bool _status) external onlyOwner {
        require(_token != address(0), "PrivateStaking: invalid token address");

        allowedBuyTokens[_token] = _status;
    }

    function setManager(address _manager, bool _status) external onlyOwner {
        require(
            _manager != address(0),
            "PrivateStaking: invalid manager address"
        );

        managers[_manager] = _status;

        emit UpdateManager(_manager, _status);
    }

    function setMinimalDepositAmount(uint256 _amount) external onlyOwner {
        minimalDepositAmount = _amount;
    }

    function setPoolStatus(
        string calldata _poolName,
        uint8 _status
    ) external onlyManager {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        require(_status == 0 || _status == 1 || _status == 2, "Wrong status");
        poolLockTime[_poolName].status = _status;
    }

    function withdrawEmergency(
        address _token,
        uint256 _amount
    ) external onlyOwner returns (bool success) {
        require(
            IERC20Decimals(_token).balanceOf(address(this)) >= _amount,
            "Not enough tokens"
        );
        IERC20Decimals(_token).safeTransfer(_msgSender(), _amount);
        return true;
    }

    function addPool(
        string calldata name,
        uint256 lockPeriod,
        uint256 periodLength,
        uint256 periodsNumber,
        uint256 percentPerNumber,
        uint256 startTime,
        uint256 cap,
        uint256 ratio
    ) external onlyOwner returns (bool success) {
        _addPool(
            name,
            lockPeriod,
            periodLength,
            periodsNumber,
            percentPerNumber,
            startTime,
            cap,
            ratio
        );
        return true;
    }

    function updatePool(
        string calldata name,
        uint256 lockPeriod,
        uint256 periodLength,
        uint256 periodsNumber,
        uint256 percentPerNumber,
        uint256 startTime,
        uint256 cap,
        uint256 ratio
    ) external onlyOwner {
        require(poolLockTime[name].exists, "Pool: not exists");
        require(
            periodsNumber.mul(percentPerNumber) <= percent,
            "Pool: percents exceeded limit"
        );
        poolLockTime[name].lockPeriod = lockPeriod;
        poolLockTime[name].periodLength = periodLength;
        poolLockTime[name].periodsNumber = periodsNumber;
        poolLockTime[name].percent = percentPerNumber;
        poolLockTime[name].startTime = startTime;
        poolLockTime[name].cap = cap;
        poolLockTime[name].ratio = ratio;
    }

    function bulkUploadDeposits(
        bytes calldata data,
        string calldata _poolName
    ) external onlyManager {
        bulkDeposit[] memory depositArray = abi.decode(data, (bulkDeposit[]));
        for (uint8 i = 0; i < depositArray.length; i++) {
            depositAdmin(
                depositArray[i].beneficiary,
                depositArray[i].amount,
                _poolName
            );
        }
    }

    function withdraw(
        uint256 lockBoxNumber,
        address beneficiary,
        string calldata _poolName
    ) external returns (bool) {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        LockBoxStruct storage l = boxPool[_poolName][_msgSender()][
            lockBoxNumber
        ];
        require(l.balance > 0, "Benefeciary does not exists");
        uint256 _unlockTime = l.depositTime.add(
            poolLockTime[_poolName].lockPeriod
        );
        require(_unlockTime < block.timestamp, "Funds locked");

        (uint256 amount, uint256 periods) = _calculateUnlockedTokens(
            beneficiary,
            lockBoxNumber,
            _poolName
        );

        l.balance = l.balance.sub(amount);
        l.payed = l.payed.add(amount);
        l.periodsPassed = periods;
        require(
            token.balanceOf(address(this)) >= amount && amount > 0,
            "Wrong amount or balance"
        );
        token.safeTransfer(_msgSender(), amount);
        poolLockTime[_poolName].withdrawn = poolLockTime[_poolName]
            .withdrawn
            .add(amount);
        emit LogLockBoxWithdrawal(_msgSender(), amount);
        return true;
    }

    function getBeneficiaryStructs(
        string calldata _poolName,
        address beneficiary
    ) external view returns (LockBoxStruct[] memory) {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        return boxPool[_poolName][beneficiary];
    }

    function getPools() external view returns (poolName[] memory) {
        return poolNamesArray;
    }

    function getTokensAvailable(
        string calldata _poolName,
        address beneficiary,
        uint256 id
    ) external view returns (uint256, uint256, uint256) {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        (uint256 amount, uint256 periods) = _calculateUnlockedTokens(
            beneficiary,
            id,
            _poolName
        );
        poolData memory pool = poolLockTime[_poolName];
        uint256 timeToUnlock = pool.startTime.add(pool.lockPeriod) >
            block.timestamp
            ? pool.startTime.add(pool.lockPeriod).sub(block.timestamp)
            : 0;
        return (amount, timeToUnlock, periods);
    }

    function deposit(
        address buyToken,
        uint256 amount,
        string memory _poolName
    ) public returns (bool success) {
        require(allowedBuyTokens[buyToken], "Payment method does not allowed");
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        require(poolLockTime[_poolName].status == 1, "Pool: not active");
        require(
            poolLockTime[_poolName].deposited.add(amount) <=
                poolLockTime[_poolName].cap,
            "Pool: cap exceded"
        );
        IERC20Decimals stable = IERC20Decimals(buyToken);
        uint256 stableAmount = (amount * 1e6) /
            (poolLockTime[_poolName].ratio * 10 ** (18 - stable.decimals()));
        require(stableAmount >= minimalDepositAmount, "Minimal amount required");    

        LockBoxStruct memory l;
        l.beneficiary = _msgSender();
        l.balance = amount;
        l.total = amount;
        l.payed = 0;
        l.depositTime = poolLockTime[_poolName].startTime;
        l.periodsPassed = 0;
        boxPool[_poolName][_msgSender()].push(l);
        poolLockTime[_poolName].deposited = poolLockTime[_poolName]
            .deposited
            .add(amount);
        stable.safeTransferFrom(_msgSender(), wallet, stableAmount);
        emit LogLockBoxDeposit(
            _msgSender(),
            amount,
            buyToken,
            poolLockTime[_poolName].lockPeriod,
            _poolName,
            poolLockTime[_poolName].ratio
        );
        return true;
    }

    function depositAdmin(
        address beneficiary,
        uint256 amount,
        string memory _poolName
    ) public onlyManager returns (bool success) {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        require(
            poolLockTime[_poolName].deposited.add(amount) <=
                poolLockTime[_poolName].cap,
            "Pool: cap exceded"
        );

        LockBoxStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount;
        l.total = amount;
        l.payed = 0;
        l.depositTime = poolLockTime[_poolName].startTime;
        l.periodsPassed = 0;
        boxPool[_poolName][beneficiary].push(l);
        poolLockTime[_poolName].deposited = poolLockTime[_poolName]
            .deposited
            .add(amount);
        emit LogLockBoxDeposit(
            beneficiary,
            amount,
            address(0),
            poolLockTime[_poolName].lockPeriod,
            _poolName,
            poolLockTime[_poolName].ratio
        );
        return true;
    }

    function getMapCount(
        address beneficiary,
        string memory _poolName
    ) external view returns (uint256) {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        return boxPool[_poolName][beneficiary].length;
    }

    function _setAmount(uint256 amount) internal pure returns (uint256) {
        uint256 oneToken = 1e18;
        return oneToken.mul(amount);
    }

    function _addPool(
        string memory name,
        uint256 lockPeriod,
        uint256 periodLength,
        uint256 periodsNumber,
        uint256 percentPerNumber,
        uint256 startTime,
        uint256 cap,
        uint256 ratio
    ) internal returns (bool success) {
        require(!poolLockTime[name].exists, "Pool: already exists");
        require(
            periodsNumber.mul(percentPerNumber) <= percent,
            "Pool: percents exceeded limit"
        );

        poolName memory pD;
        poolLockTime[name].name = name;
        poolLockTime[name].lockPeriod = lockPeriod;
        poolLockTime[name].periodLength = periodLength;
        poolLockTime[name].periodsNumber = periodsNumber;
        poolLockTime[name].percent = percentPerNumber;
        poolLockTime[name].cap = cap;
        poolLockTime[name].ratio = ratio;
        poolLockTime[name].exists = true;
        poolLockTime[name].startTime = startTime;
        poolLockTime[name].status = 0;
        poolLockTime[name].deposited = 0;
        poolLockTime[name].withdrawn = 0;
        poolsCount = poolsCount.add(1);

        pD.name = name;
        poolNamesArray.push(pD);
        emit PoolAdded(name);
        return true;
    }

    function _calculateUnlockedTokens(
        address _beneficiary,
        uint256 _boxNumber,
        string memory _poolName
    ) private view returns (uint256, uint256) {
        LockBoxStruct memory box = boxPool[_poolName][_beneficiary][_boxNumber];
        poolData memory pool = poolLockTime[_poolName];
        uint256 _cliff = pool.lockPeriod;
        uint256 _periodLength = pool.periodLength;
        uint256 _periodAmount = (box.total * pool.percent) / percent;
        uint256 _periodsNumber = pool.periodsNumber;

        if (box.depositTime.add(_cliff) > block.timestamp) {
            return (0, 0);
        }

        uint256 periods = block.timestamp.sub(box.depositTime.add(_cliff)).div(
            _periodLength
        );
        periods = periods > _periodsNumber ? _periodsNumber : periods;
        uint256 periodsToSend = periods.sub(box.periodsPassed);

        if (
            box.periodsPassed == _periodsNumber && box.total.sub(box.payed) > 0
        ) {
            return (box.total.sub(box.payed), periods);
        }

        return (periodsToSend.mul(_periodAmount), periods);
    }
}
