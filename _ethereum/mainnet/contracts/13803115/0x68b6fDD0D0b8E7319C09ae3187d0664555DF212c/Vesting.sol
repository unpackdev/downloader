// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC20Mintable.sol";
import "./IVesting.sol";

contract Vesting is IVesting, EIP712Upgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    bytes32 private constant _CONTAINER_TYPEHASE =
        keccak256(
            "Container(address sender,uint256 amount,bool isFiat,uint256 nonce)"
        );

    uint256 public constant MAX_INITIAL_PERCENTAGE = 1e20;

    bool public isCompleted;
    address public signer;
    uint8 public rewardTokenDecimals;
    uint8 public stakedTokenDecimals;

    mapping(address => uint256) public rewardsPaid;
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public specificAllocation;
    mapping(address => VestingInfo) public specificVesting;

    string private _name;
    uint256 private _totalSupply;
    uint256 private _tokenPrice;
    uint256 private _totalDeposited;
    uint256 private _initialPercentage;
    uint256 private _minAllocation;
    uint256 private _maxAllocation;
    uint256 private _startDate;
    uint256 private _endDate;
    IERC20 private _rewardToken;
    IERC20 private _depositToken;
    VestingType private _vestingType;
    VestingInfo private _vestingInfo;

    mapping(address => mapping(uint256 => bool)) private nonces;

    function initialize(
        string memory name_,
        address rewardToken_,
        address depositToken_,
        address signer_,
        uint256 initialUnlockPercentage_,
        uint256 minAllocation_,
        uint256 maxAllocation_,
        VestingType vestingType_
    ) external override initializer {
        require(
            rewardToken_ != address(0) && depositToken_ != address(0),
            "Incorrect token address"
        );
        require(minAllocation_ <= maxAllocation_, "Incorrect allocation size");
        require(
            initialUnlockPercentage_ <= MAX_INITIAL_PERCENTAGE,
            "Incorrect initial percentage"
        );
        require(signer_ != address(0), "Incorrect signer address");

        _initialPercentage = initialUnlockPercentage_;
        _minAllocation = minAllocation_;
        _maxAllocation = maxAllocation_;
        _name = name_;
        _vestingType = vestingType_;
        _rewardToken = IERC20(rewardToken_);
        _depositToken = IERC20(depositToken_);
        rewardTokenDecimals = IERC20Metadata(rewardToken_).decimals();
        stakedTokenDecimals = IERC20Metadata(depositToken_).decimals();

        signer = signer_;

        __Ownable_init();
        __EIP712_init("Vesting", "v1");
    }

    function getTimePoint()
        external
        view
        virtual
        override
        returns (uint256 startDate, uint256 endDate)
    {
        return (_startDate, _endDate);
    }

    function getAvailAmountToDeposit(address _addr)
        external
        view
        virtual
        override
        returns (uint256 minAvailAllocation, uint256 maxAvailAllocation)
    {
        uint256 totalCurrency = convertToCurrency(_totalSupply);

        if (totalCurrency <= _totalDeposited) {
            return (0, 0);
        }

        uint256 depositedAmount = deposited[_addr];

        uint256 remaining = totalCurrency - _totalDeposited;

        uint256 maxAllocation = specificAllocation[_addr] > 0
            ? specificAllocation[_addr]
            : _maxAllocation;
        maxAvailAllocation = depositedAmount < maxAllocation
            ? Math.min(maxAllocation - depositedAmount, remaining)
            : 0;
        minAvailAllocation = depositedAmount == 0 ? _minAllocation : 0;
    }

    function getInfo()
        external
        view
        virtual
        override
        returns (
            string memory name,
            address stakedToken,
            address rewardToken,
            uint256 minAllocation,
            uint256 maxAllocation,
            uint256 totalSupply,
            uint256 totalDeposited,
            uint256 tokenPrice,
            uint256 initialUnlockPercentage,
            VestingType vestingType
        )
    {
        return (
            _name,
            address(_depositToken),
            address(_rewardToken),
            _minAllocation,
            _maxAllocation,
            _totalSupply,
            _totalDeposited,
            _tokenPrice,
            _initialPercentage,
            _vestingType
        );
    }

    function getVestingInfo()
        external
        view
        virtual
        override
        returns (
            uint256 periodDuration,
            uint256 countPeriodOfVesting,
            Interval[] memory intervals
        )
    {
        VestingInfo memory info = _vestingInfo;
        uint256 size = info.unlockIntervals.length;
        intervals = new Interval[](size);

        for (uint256 i = 0; i < size; i++) {
            intervals[i] = info.unlockIntervals[i];
        }
        periodDuration = info.periodDuration;
        countPeriodOfVesting = info.countPeriodOfVesting;
    }

    function getBalanceInfo(address _addr)
        external
        view
        virtual
        override
        returns (uint256 lockedBalance, uint256 unlockedBalance)
    {
        uint256 tokenBalance = convertToToken(deposited[_addr]);

        if (!_isVestingStarted()) {
            return (tokenBalance, 0);
        }

        uint256 unlock = _calculateUnlock(_addr, 0);
        return (tokenBalance - unlock - rewardsPaid[_addr], unlock);
    }

    function initializeToken(uint256 tokenPrice_, uint256 totalSypply_)
        external
        virtual
        override
        onlyOwner
    {
        require(_tokenPrice == 0, "Is was initialized before");
        require(totalSypply_ > 0 && tokenPrice_ > 0, "Incorrect amount");

        _tokenPrice = tokenPrice_;
        _totalSupply = totalSypply_;

        _rewardToken.safeTransferFrom(
            _msgSender(),
            address(this),
            totalSypply_
        );
    }

    function increaseTotalSupply(uint256 _amount)
        external
        virtual
        override
        onlyOwner
    {
        require(!isCompleted, "Vesting should be not completed");
        _totalSupply += _amount;
        _rewardToken.safeTransferFrom(_msgSender(), address(this), _amount);
        emit IncreaseTotalSupply(_amount);
    }

    function setTimePoint(uint256 startDate_, uint256 endDate_)
        external
        virtual
        override
        onlyOwner
    {
        require(
            startDate_ < endDate_ && block.timestamp < startDate_,
            "Incorrect dates"
        );
        _startDate = startDate_;
        _endDate = endDate_;
        emit SetTimePoint(startDate_, endDate_);
    }

    function setSigner(address addr_) external virtual override onlyOwner {
        require(addr_ != address(0), "Incorrect signer address");
        signer = addr_;
    }

    function setSpecificAllocation(
        address[] calldata addrs_,
        uint256[] calldata amount_
    ) external virtual override onlyOwner {
        require(addrs_.length == amount_.length, "Diff array size");
        uint256 index = 0;
        for (index; index < addrs_.length; index++) {
            specificAllocation[addrs_[index]] = amount_[index];
            if (gasleft() < 20000) {
                break;
            }
        }
        if (index != addrs_.length) {
            index++;
        }
        emit SetSpecificAllocation(addrs_[:index], amount_[:index]);
    }

    function setSpecificVesting(
        address addr_,
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        uint256 cliffDuration_,
        Interval[] calldata intervals_
    ) external virtual override onlyOwner {
        VestingInfo storage info = specificVesting[addr_];
        require(
            !(info.countPeriodOfVesting > 0 || info.unlockIntervals.length > 0),
            "was initialized before"
        );
        _setVesting(
            info,
            periodDuration_,
            countPeriodOfVesting_,
            cliffDuration_,
            intervals_
        );
    }

    function setVesting(
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        uint256 cliffDuration_,
        Interval[] calldata intervals_
    ) external virtual override onlyOwner {
        VestingInfo storage info = _vestingInfo;
        _setVesting(
            info,
            periodDuration_,
            countPeriodOfVesting_,
            cliffDuration_,
            intervals_
        );
    }

    function addDepositeAmount(
        address[] calldata _addrArr,
        uint256[] calldata _amountArr
    ) external virtual override onlyOwner {
        require(_addrArr.length == _amountArr.length, "Incorrect array length");
        require(!_isVestingStarted(), "Sale is closed");

        uint256 remainingAllocation = _totalSupply -
            convertToToken(_totalDeposited);
        uint256 index = 0;
        for (index; index < _addrArr.length; index++) {
            uint256 convertAmount = convertToToken(_amountArr[index]);
            require(
                convertAmount <= remainingAllocation,
                "Not enough allocation"
            );
            remainingAllocation -= convertAmount;
            deposited[_addrArr[index]] += _amountArr[index];
            _totalDeposited += _amountArr[index];
            if (gasleft() < 40000) {
                break;
            }
        }
        if (index != _addrArr.length) {
            index++;
        }

        emit Deposites(_addrArr[:index], _amountArr[:index]);
    }

    function completeVesting() external virtual override onlyOwner {
        require(_isVestingStarted(), "Vesting can't be started");
        require(!isCompleted, "Complete was called before");
        isCompleted = true;

        uint256 soldToken = convertToToken(_totalDeposited);

        if (soldToken < _totalSupply)
            _rewardToken.safeTransfer(_msgSender(), _totalSupply - soldToken);

        uint256 balance = _depositToken.balanceOf(address(this));
        _depositToken.safeTransfer(_msgSender(), balance);
    }

    function deposite(
        uint256 _amount,
        bool _fiat,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual override {
        require(!nonces[_msgSender()][_nonce], "Nonce used before");
        require(
            _isValidSigner(_msgSender(), _amount, _fiat, _nonce, _v, _r, _s),
            "Invalid signer"
        );
        require(_isSale(), "Sale is closed");
        require(_isValidAmount(_amount), "Invalid amount");

        nonces[_msgSender()][_nonce] = true;
        deposited[_msgSender()] += _amount;
        _totalDeposited += _amount;

        uint256 transferAmount = _convertToCorrectDecimals(
            _amount,
            rewardTokenDecimals,
            stakedTokenDecimals
        );
        if (!_fiat) {
            _depositToken.safeTransferFrom(
                _msgSender(),
                address(this),
                transferAmount
            );
        }

        if (VestingType.SWAP == _vestingType) {
            uint256 tokenAmount = convertToToken(_amount);
            rewardsPaid[_msgSender()] += tokenAmount;
            _rewardToken.safeTransfer(_msgSender(), tokenAmount);
            emit Harvest(_msgSender(), tokenAmount);
        }

        emit Deposite(_msgSender(), _amount, _fiat);
    }

    function harvestFor(address _addr) external virtual override {
        _harvest(_addr, 0);
    }

    function harvest() external virtual override {
        _harvest(_msgSender(), 0);
    }

    function harvestInterval(uint256 intervalIndex) external virtual override {
        _harvest(_msgSender(), intervalIndex);
    }

    function DOMAIN_SEPARATOR()
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    function convertToToken(uint256 _amount)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return (_amount * 10**rewardTokenDecimals) / _tokenPrice;
    }

    function convertToCurrency(uint256 _amount)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return (_amount * _tokenPrice) / 10**rewardTokenDecimals;
    }

    function _calculateUnlock(address _addr, uint256 intervalIndex)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 tokenAmount = convertToToken(deposited[_addr]);
        uint256 oldRewards = rewardsPaid[_addr];

        VestingInfo memory info = specificVesting[_addr].periodDuration > 0 ||
            specificVesting[_addr].unlockIntervals.length > 0
            ? specificVesting[_addr]
            : _vestingInfo;

        if (VestingType.LINEAR_VESTING == _vestingType) {
            tokenAmount = _calculateLinearUnlock(info, tokenAmount);
        } else if (VestingType.INTERVAL_VESTING == _vestingType) {
            tokenAmount = _calculateIntervalUnlock(
                info.unlockIntervals,
                tokenAmount,
                intervalIndex
            );
        }
        return tokenAmount > oldRewards ? tokenAmount - oldRewards : 0;
    }

    function _calculateLinearUnlock(
        VestingInfo memory info,
        uint256 tokenAmount
    ) internal view virtual returns (uint256) {
        if (block.timestamp > _endDate + info.cliffDuration) {
            uint256 initialUnlockAmount = (tokenAmount * _initialPercentage) /
                MAX_INITIAL_PERCENTAGE;
            uint256 passePeriod = Math.min(
                (block.timestamp - _endDate - info.cliffDuration) /
                    info.periodDuration,
                info.countPeriodOfVesting
            );
            return
                (((tokenAmount - initialUnlockAmount) * passePeriod) /
                    info.countPeriodOfVesting) + initialUnlockAmount;
        } else {
            return 0;
        }
    }

    function _calculateIntervalUnlock(
        Interval[] memory intervals,
        uint256 tokenAmount,
        uint256 intervalIndex
    ) internal view virtual returns (uint256) {
        uint256 unlockPercentage = _initialPercentage;
        if (intervalIndex > 0) {
            require(
                intervals[intervalIndex].timeStamp < block.timestamp,
                "Incorrect interval index"
            );
            unlockPercentage = intervals[intervalIndex].percentage;
        } else {
            for (uint256 i = 0; i < intervals.length; i++) {
                if (block.timestamp > intervals[i].timeStamp) {
                    unlockPercentage = intervals[i].percentage;
                } else {
                    break;
                }
            }
        }

        return (tokenAmount * unlockPercentage) / MAX_INITIAL_PERCENTAGE;
    }

    function _convertToCorrectDecimals(
        uint256 _amount,
        uint256 _fromDecimals,
        uint256 _toDecimals
    ) internal pure virtual returns (uint256) {
        if (_fromDecimals < _toDecimals) {
            _amount = _amount * (10**(_toDecimals - _fromDecimals));
        } else if (_fromDecimals > _toDecimals) {
            _amount = _amount / (10**(_fromDecimals - _toDecimals));
        }
        return _amount;
    }

    function _isVestingStarted() internal view virtual returns (bool) {
        return block.timestamp > _endDate && _endDate != 0;
    }

    function _isSale() internal view virtual returns (bool) {
        return block.timestamp >= _startDate && block.timestamp < _endDate;
    }

    function _isValidSigner(
        address _sender,
        uint256 _amount,
        bool _fiat,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view virtual returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(_CONTAINER_TYPEHASE, _sender, _amount, _fiat, _nonce)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address messageSigner = ECDSAUpgradeable.recover(hash, _v, _r, _s);

        return messageSigner == signer;
    }

    function _isValidAmount(uint256 _amount)
        internal
        view
        virtual
        returns (bool)
    {
        uint256 maxAllocation = specificAllocation[_msgSender()] > 0
            ? specificAllocation[_msgSender()]
            : _maxAllocation;
        uint256 depositAmount = deposited[_msgSender()];
        uint256 remainingAmount = Math.min(
            maxAllocation - depositAmount,
            convertToCurrency(_totalSupply) - _totalDeposited
        );
        return
            (_amount < _minAllocation && depositAmount == 0) ||
                (_amount > maxAllocation || _amount > remainingAmount)
                ? false
                : true;
    }

    function _setVesting(
        VestingInfo storage info,
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        uint256 cliffDuration_,
        Interval[] calldata _intervals
    ) internal virtual {
        if (VestingType.LINEAR_VESTING == _vestingType) {
            require(
                countPeriodOfVesting_ > 0 && periodDuration_ > 0,
                "Incorrect linear vesting setup"
            );
            info.periodDuration = periodDuration_;
            info.countPeriodOfVesting = countPeriodOfVesting_;
            info.cliffDuration = cliffDuration_;
        } else {
            delete info.unlockIntervals;
            uint256 lastUnlockingPart = _initialPercentage;
            uint256 lastIntervalStartingTimestamp = _endDate;
            for (uint256 i = 0; i < _intervals.length; i++) {
                uint256 percent = _intervals[i].percentage;
                require(
                    percent > lastUnlockingPart &&
                        percent <= MAX_INITIAL_PERCENTAGE,
                    "Invalid interval unlocking part"
                );
                require(
                    _intervals[i].timeStamp > lastIntervalStartingTimestamp,
                    "Invalid interval starting timestamp"
                );
                lastUnlockingPart = percent;
                info.unlockIntervals.push(_intervals[i]);
            }
            require(
                lastUnlockingPart == MAX_INITIAL_PERCENTAGE,
                "Invalid interval unlocking part"
            );
        }
    }

    function _harvest(address _addr, uint256 intervalIndex) internal virtual {
        require(_isVestingStarted(), "Vesting can't be started");

        uint256 amountToTransfer = _calculateUnlock(_addr, intervalIndex);

        require(amountToTransfer > 0, "Amount is zero");

        rewardsPaid[_addr] += amountToTransfer;

        _rewardToken.safeTransfer(_addr, amountToTransfer);

        emit Harvest(_addr, amountToTransfer);
    }
}
