// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IFlyzStaking.sol";
import "./IsFlyzERC20.sol";

import "./ERC20.sol";
import "./Ownable.sol";

import "./SafeMath.sol";
import "./SafeERC20.sol";

interface IWarmup {
    function retrieve(address staker_, uint256 amount_) external;
}

interface IDistributor {
    function distribute() external returns (bool);
}

contract FlyzStaking is Ownable, IFlyzStaking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable FLYZ;
    address public immutable sFLYZ;

    struct Epoch {
        uint256 length; // in seconds
        uint256 number;
        uint256 endTime; // unix epoch time in seconds
        uint256 distribute;
    }
    Epoch public epoch;

    address public distributor;

    address public locker;
    uint256 public totalBonus;

    address public warmupContract;
    uint256 public warmupPeriod;

    constructor(
        address _FLYZ,
        address _sFLYZ,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime
    ) {
        require(_FLYZ != address(0));
        FLYZ = _FLYZ;
        require(_sFLYZ != address(0));
        sFLYZ = _sFLYZ;

        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            endTime: _firstEpochTime,
            distribute: 0
        });
    }

    struct Claim {
        uint256 deposit;
        uint256 gons;
        uint256 expiry;
        bool lock; // prevents malicious delays
    }
    mapping(address => Claim) public warmupInfo;

    /**
        @notice stake FLYZ to enter warmup
        @param _amount uint
        @return bool
     */
    function stake(uint256 _amount, address _recipient)
        external
        override
        returns (bool)
    {
        rebase();

        IERC20(FLYZ).safeTransferFrom(msg.sender, address(this), _amount);

        Claim memory info = warmupInfo[_recipient];
        require(!info.lock, 'Deposits for account are locked');

        warmupInfo[_recipient] = Claim({
            deposit: info.deposit.add(_amount),
            gons: info.gons.add(IsFlyzERC20(sFLYZ).gonsForBalance(_amount)),
            expiry: epoch.number.add(warmupPeriod),
            lock: false
        });

        IERC20(sFLYZ).safeTransfer(warmupContract, _amount);
        return true;
    }

    /**
        @notice retrieve sFLYZ from warmup
        @param _recipient address
     */
    function claim(address _recipient) external override {
        Claim memory info = warmupInfo[_recipient];
        if (epoch.number >= info.expiry && info.expiry != 0) {
            delete warmupInfo[_recipient];
            IWarmup(warmupContract).retrieve(
                _recipient,
                IsFlyzERC20(sFLYZ).balanceForGons(info.gons)
            );
        }
    }

    /**
        @notice forfeit sFLYZ in warmup and retrieve FLYZ
     */
    function forfeit() external {
        Claim memory info = warmupInfo[msg.sender];
        delete warmupInfo[msg.sender];

        IWarmup(warmupContract).retrieve(
            address(this),
            IsFlyzERC20(sFLYZ).balanceForGons(info.gons)
        );
        IERC20(FLYZ).safeTransfer(msg.sender, info.deposit);
    }

    /**
        @notice prevent new deposits to address (protection from malicious activity)
     */
    function toggleDepositLock() external {
        warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
    }

    /**
        @notice redeem sFLYZ for FLYZ
        @param _amount uint
        @param _trigger bool
     */
    function unstake(uint256 _amount, bool _trigger) external {
        if (_trigger) {
            rebase();
        }
        IERC20(sFLYZ).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(FLYZ).safeTransfer(msg.sender, _amount);
    }

    /**
        @notice returns the sFLYZ index, which tracks rebase growth
        @return uint
     */
    function index() public view returns (uint256) {
        return IsFlyzERC20(sFLYZ).index();
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if (epoch.endTime <= block.timestamp) {
            IsFlyzERC20(sFLYZ).rebase(epoch.distribute, epoch.number);

            epoch.endTime = epoch.endTime.add(epoch.length);
            epoch.number++;

            if (distributor != address(0)) {
                IDistributor(distributor).distribute();
            }

            uint256 balance = contractBalance();
            uint256 staked = IsFlyzERC20(sFLYZ).circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked);
            }
        }
    }

    /**
        @notice returns contract FLYZ holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns (uint256) {
        return IERC20(FLYZ).balanceOf(address(this)).add(totalBonus);
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus(uint256 _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.add(_amount);
        IERC20(sFLYZ).safeTransfer(locker, _amount);
    }

    /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
    function returnLockBonus(uint256 _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.sub(_amount);
        IERC20(sFLYZ).safeTransferFrom(locker, address(this), _amount);
    }

    enum CONTRACTS {
        DISTRIBUTOR,
        WARMUP,
        LOCKER
    }

    /**
        @notice sets the contract address for LP staking
        @param _contract address
     */
    function setContract(CONTRACTS _contract, address _address)
        external
        onlyOwner
    {
        if (_contract == CONTRACTS.DISTRIBUTOR) {
            // 0
            distributor = _address;
        } else if (_contract == CONTRACTS.WARMUP) {
            // 1
            require(
                warmupContract == address(0),
                'Warmup cannot be set more than once'
            );
            warmupContract = _address;
        } else if (_contract == CONTRACTS.LOCKER) {
            // 2
            require(
                locker == address(0),
                'Locker cannot be set more than once'
            );
            locker = _address;
        }
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup(uint256 _warmupPeriod) external onlyOwner {
        warmupPeriod = _warmupPeriod;
    }
}
