// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./OwnableManagement.sol";
import "./IERC20.sol";
import "./ISyncus.sol";
import "./IVESYNC.sol";
import "./IDistributor.sol";
import "./IWarmup.sol";

contract SyncusStaking is OwnableManagement {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    address public immutable Sync;
    address public immutable veSync;

    struct Epoch {
        uint number;
        uint distribute;
        uint32 length;
        uint32 endTime;
    }
    Epoch public epoch;

    address public distributor;

    address public locker;
    uint public totalBonus;

    address public warmupContract;
    uint public warmupPeriod;

    address taxReceiver;

    uint public taxOnStake = 250; // 2.5%
    uint public taxOnUnstake = 250; // 2.5%

    function setTaxOnStake(uint _taxOnStake) external onlyManager {
        require(_taxOnStake <= 10000, "Tax cannot be greater than 100%");
        taxOnStake = _taxOnStake;
    }

    function setTaxOnUnstake(uint _taxOnUnstake) external onlyManager {
        require(_taxOnUnstake <= 10000, "Tax cannot be greater than 100%");
        taxOnUnstake = _taxOnUnstake;
    }

    function setTaxReceiver(address _taxReceiver) external onlyManager {
        taxReceiver = _taxReceiver;
    }

    modifier onlyDistributor() {
        require(msg.sender == distributor, "Only distributor");
        _;
    }

    constructor(
        address _Sync,
        address _veSync,
        uint32 _epochLength,
        uint _firstEpochNumber,
        uint32 _firstEpochTime,
        address _taxReceiver
    ) {
        require(_Sync != address(0));
        Sync = _Sync;
        require(_veSync != address(0));
        veSync = _veSync;

        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            endTime: _firstEpochTime,
            distribute: 0
        });

        taxReceiver = _taxReceiver;
    }

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }
    mapping(address => Claim) public warmupInfo;

    /**
        @notice stake SYNC to enter warmup
        @param _amount uint
        @return bool
     */
    function stake(uint _amount, address _recipient) external returns (bool) {
        rebase();

        uint tax = _amount.mul(taxOnStake).div(10000);
        uint amountAfterTax = _amount.sub(tax);

        IERC20(Sync).safeTransferFrom(
            msg.sender,
            address(this),
            amountAfterTax
        );
        IERC20(Sync).safeTransferFrom(msg.sender, taxReceiver, tax);

        Claim memory info = warmupInfo[_recipient];
        require(!info.lock, "Deposits for account are locked");

        warmupInfo[_recipient] = Claim({
            deposit: info.deposit.add(amountAfterTax),
            gons: info.gons.add(IVESYNC(veSync).gonsForBalance(amountAfterTax)),
            expiry: epoch.number.add(warmupPeriod),
            lock: false
        });

        IERC20(veSync).safeTransfer(warmupContract, amountAfterTax);
        return true;
    }

    /**
        @notice retrieve veSYNC from warmup
        @param _recipient address
     */
    function claim(address _recipient) public {
        Claim memory info = warmupInfo[_recipient];
        if (epoch.number >= info.expiry && info.expiry != 0) {
            delete warmupInfo[_recipient];
            IWarmup(warmupContract).retrieve(
                _recipient,
                IVESYNC(veSync).balanceForGons(info.gons)
            );
        }
    }

    /**
        @notice forfeit veSYNC in warmup and retrieve SYNC
     */
    function forfeit() external {
        Claim memory info = warmupInfo[msg.sender];
        delete warmupInfo[msg.sender];

        IWarmup(warmupContract).retrieve(
            address(this),
            IVESYNC(veSync).balanceForGons(info.gons)
        );
        IERC20(Sync).safeTransfer(msg.sender, info.deposit);
    }

    /**
        @notice prevent new deposits to address (protection from malicious activity)
     */
    function toggleDepositLock() external {
        warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
    }

    /**
        @notice redeem veSYNC for SYNC
        @param _amount uint
        @param _trigger bool
     */
    function unstake(uint _amount, bool _trigger) external {
        if (_trigger) {
            rebase();
        }
        IERC20(veSync).safeTransferFrom(msg.sender, address(this), _amount);

        uint tax = _amount.mul(taxOnUnstake).div(10000);
        uint amountAfterTax = _amount.sub(tax);

        IERC20(Sync).safeTransfer(msg.sender, amountAfterTax);
        IERC20(Sync).safeTransfer(taxReceiver, tax);
    }

    /**
        @notice returns the veSYNC index, which tracks rebase growth
        @return uint
     */
    function index() public view returns (uint) {
        return IVESYNC(veSync).index();
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if (epoch.endTime <= uint32(block.timestamp)) {
            IVESYNC(veSync).rebase(epoch.distribute, epoch.number);

            epoch.endTime = epoch.endTime.add32(epoch.length);
            epoch.number++;

            if (distributor != address(0)) {
                IDistributor(distributor).distribute();
            }

            uint balance = contractBalance();
            uint staked = IVESYNC(veSync).circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked);
            }
        }
    }

    /**
        @notice returns contract SYNC holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns (uint) {
        return IERC20(Sync).balanceOf(address(this)).add(totalBonus);
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus(uint _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.add(_amount);
        IERC20(veSync).safeTransfer(locker, _amount);
    }

    /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
    function returnLockBonus(uint _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.sub(_amount);
        IERC20(veSync).safeTransferFrom(locker, address(this), _amount);
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
    function setContract(
        CONTRACTS _contract,
        address _address
    ) external onlyManager {
        if (_contract == CONTRACTS.DISTRIBUTOR) {
            // 0
            distributor = _address;
        } else if (_contract == CONTRACTS.WARMUP) {
            // 1
            require(
                warmupContract == address(0),
                "Warmup cannot be set more than once"
            );
            warmupContract = _address;
        } else if (_contract == CONTRACTS.LOCKER) {
            // 2
            require(
                locker == address(0),
                "Locker cannot be set more than once"
            );
            locker = _address;
        }
    }

    /**
     * @notice set warmup period in epoch's numbers for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup(uint _warmupPeriod) external onlyManager {
        warmupPeriod = _warmupPeriod;
    }
}
