// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./IPool.sol";
import "./IPoolFactory.sol";

/**
 * SAILORSWAP v1.0-alpha
 * WARNING: UNAUDITED CODE USE AT YOUR OWN RISK
 */
contract Pool is IPool, OwnableUpgradeable, ReentrancyGuard {
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public accumulated;
    mapping(address => uint256) public claimable;
    mapping(uint256 => address) public originalDepositor;
    mapping(address => uint256) public points;

    uint256 public totalContributions;
    uint256 public totalPoints;
    uint256 public accumulator;
    uint256 public leftOver;
    address public collection;
    address public factory;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _collection) public initializer {
        __Ownable_init();
        collection = _collection;
        factory = msg.sender;

        transferOwnership(OwnableUpgradeable(factory).owner());
    }

    function deposit(uint256[] calldata ids) public whenNotPaused nonReentrant {
        _doTransferIn(msg.sender, ids);

        _accrue();

        uint256 deposited = ids.length;
        totalContributions += deposited;
        contributions[msg.sender] += deposited;

        emit Deposit(msg.sender, ids);
    }

    function withdraw(uint256[] calldata ids) public whenNotPaused nonReentrant {
        _claim();
        _withdraw(ids);
        _reducePoints(ids.length);
    }

    function _withdraw(uint256[] calldata ids) private {
        uint256 withdrawn = ids.length;
        // Check share of user
        if (contributions[msg.sender] < withdrawn) {
            revert NotEnoughStake();
        }

        // Call first to prevent reentrancy
        totalContributions -= withdrawn;
        contributions[msg.sender] -= withdrawn;

        _doTransferOut(msg.sender, ids);

        _assignPoints(ids);

        emit Withdraw(msg.sender, ids);
    }

    function _doTransferIn(address from, uint256[] calldata ids) private {
        uint256 deposited = ids.length;

        for (uint256 i; i < deposited;) {
            IERC721(collection).transferFrom(from, address(this), ids[i]);
            originalDepositor[ids[i]] = from;
            unchecked {
                ++i;
            }
        }
    }

    function _doTransferOut(address to, uint256[] calldata ids) private {
        uint256 withdrawn = ids.length;

        for (uint256 i; i < withdrawn;) {
            IERC721(collection).transferFrom(address(this), to, ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _assignPoints(uint256[] calldata ids) private {
        uint256 withdrawn = ids.length;
        for (uint256 i; i < withdrawn;) {
            address depositor = originalDepositor[ids[i]];
            if (depositor != address(0) && depositor != msg.sender) {
                points[depositor] += 1;
                totalPoints += 1;
            } else {
                delete originalDepositor[ids[i]];
            }

            unchecked {
                ++i;
            }
        }
    }

    function _reducePoints(uint256 amountPoints) private {
        uint256 userPoints = points[msg.sender];
        uint256 pointsToWithdraw = Math.min(userPoints, amountPoints);
        points[msg.sender] = userPoints - pointsToWithdraw;
        totalPoints -= pointsToWithdraw;
    }

    function claim() public nonReentrant {
        _claim();
    }

    function _claim() internal {
        uint256 userClaim = _accrue();

        delete claimable[msg.sender];

        emit Claimed(msg.sender, userClaim);
        payable(msg.sender).transfer(userClaim);
    }

    function getClaimable(address user) public view returns (uint256 newClaimable) {
        uint256 balance = contributions[user];
        balance += points[user];

        uint256 claimAccumulator = (accumulator - accumulated[user]);

        uint256 userClaim = claimAccumulator * balance;
        newClaimable = userClaim + claimable[user];
    }

    function _accrue() internal returns (uint256 newClaimable) {
        newClaimable = getClaimable(msg.sender);
        accumulated[msg.sender] = accumulator;
        claimable[msg.sender] = newClaimable;
    }

    function swap(uint256[] calldata depositIDs, uint256[] calldata withdrawIDs)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        if (depositIDs.length != withdrawIDs.length) {
            revert NotEnoughForSwap();
        }

        uint256 totalFee = swapFee() * withdrawIDs.length;
        uint256 _daoFee = totalFee * daoFeeRate() / 1e18;
        uint256 _poolFee = totalFee - _daoFee;

        if (msg.value < totalFee) {
            revert FeeRequired();
        }

        _doTransferIn(msg.sender, depositIDs);
        _doTransferOut(msg.sender, withdrawIDs);
        _assignPoints(withdrawIDs);

        if (msg.value > totalFee) {
            (bool sent,) = msg.sender.call{value: msg.value - totalFee}("");
            if (!sent) {
                revert RefundFailed();
            }
        }

        _distribute(_poolFee);

        (bool sentFees,) = paymentReceiver().call{value: _daoFee}("");
        if (!sentFees) {
            revert TransferFeesFailed();
        }

        emit Swap(msg.sender, depositIDs, withdrawIDs);
    }

    function _distribute(uint256 amount) internal {
        // if total weight is 0, then the pool is empty and we can't distribute fees
        // ie: the user is depositing and withdrawing the same NFT
        uint256 totalWeight = totalContributions + totalPoints;

        // Increase the accumulator for every deposited fee.
        uint256 _leftOver = leftOver;
        accumulator += (amount + _leftOver) / totalWeight;
        leftOver = (amount + _leftOver) % totalWeight;
    }

    function daoFeeRate() public view returns (uint256) {
        return IPoolFactory(factory).daoFeeRate();
    }

    function swapFee() public view returns (uint256) {
        return IPoolFactory(factory).swapFee();
    }

    function paymentReceiver() public view returns (address) {
        return IPoolFactory(factory).sznsDao();
    }

    // Used only in the case SZNS Dao needs to transfer out assets
    // Should never be used unless necessary to return assets to original owners
    function returnAssets(uint256[] calldata tokenIDs, address to) public onlyOwner {
        uint256 totalDeposited = tokenIDs.length;
        contributions[to] -= totalDeposited;
        totalContributions -= totalDeposited;

        _doTransferOut(to, tokenIDs);
    }

    modifier whenNotPaused() {
        if (IPoolFactory(factory).paused()) {
            revert PoolFactoryPaused();
        }
        _;
    }
}
