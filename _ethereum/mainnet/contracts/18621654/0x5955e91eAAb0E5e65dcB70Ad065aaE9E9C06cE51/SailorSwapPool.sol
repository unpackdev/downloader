// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./ISailorSwapPool.sol";
import "./ISailorSwapPoolFactory.sol";

/**
 * SAILORSWAP v1.0-alpha
 */
contract SailorSwapPool is ISailorSwapPool, OwnableUpgradeable, ReentrancyGuard {
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public accumulated;
    mapping(address => uint256) public claimable;
    mapping(uint256 => address) public originalDepositor;
    mapping(address => uint256) public points;
    mapping(address => uint256) public lastDeposited;

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
        collection = _collection;
        factory = msg.sender;
        __Ownable_init(OwnableUpgradeable(msg.sender).owner());
    }

    function deposit(uint256[] calldata ids) public whenNotPaused nonReentrant {
        _doTransferIn(msg.sender, ids);
        _assignOwners(ids);

        _accrue();

        uint256 deposited = ids.length;
        totalContributions += deposited;
        contributions[msg.sender] += deposited;
        lastDeposited[msg.sender] = block.timestamp;

        emit Deposit(msg.sender, ids);
    }

    function withdraw(uint256[] calldata ids) public payable whenNotPaused nonReentrant {
        uint256 _poolFee;
        if (block.timestamp - lastDeposited[msg.sender] < depositLockup()) {
            _poolFee = _collectFees(swapFee() * ids.length);
            emit EarlyWithdraw(msg.sender, ids);
        }
        _claim();
        _withdraw(ids);
        _distribute(_poolFee); // Distribute fees to contributors after reducing points
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

        _reducePoints(withdrawn);

        _doTransferOut(msg.sender, ids);

        emit Withdraw(msg.sender, ids);
    }

    function _reducePoints(uint256 amountWithdrawn) private {
        uint256 pointsToRemove = Math.min(points[msg.sender], amountWithdrawn);
        if (pointsToRemove > 0) {
            points[msg.sender] -= pointsToRemove;
            totalPoints -= pointsToRemove;
        }
    }

    function _doTransferIn(address from, uint256[] calldata ids) private {
        uint256 deposited = ids.length;

        for (uint256 i; i < deposited;) {
            IERC721(collection).transferFrom(from, address(this), ids[i]);
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

    function _assignOwners(uint256[] calldata ids) private {
        uint256 withdrawn = ids.length;
        for (uint256 i; i < withdrawn;) {
            originalDepositor[ids[i]] = msg.sender;

            unchecked {
                ++i;
            }
        }
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

        uint256 _poolFee = _collectFees(swapFee() * withdrawIDs.length);

        _doTransferIn(msg.sender, depositIDs);
        _doTransferOut(msg.sender, withdrawIDs);
        _assignPoints(withdrawIDs);

        _distribute(_poolFee); // Distribute fees to contributors after assigning points

        emit Swap(msg.sender, depositIDs, withdrawIDs);
    }

    function _collectFees(uint256 totalFee) internal returns (uint256) {
        uint256 _daoFee = totalFee * daoFeeRate() / 1e18;
        uint256 _poolFee = totalFee - _daoFee;

        if (msg.value < totalFee) {
            revert FeeRequired();
        }

        if (msg.value > totalFee) {
            (bool sent,) = msg.sender.call{value: msg.value - totalFee}("");
            if (!sent) {
                revert RefundFailed();
            }
        }

        (bool sentFees,) = paymentReceiver().call{value: _daoFee}("");
        if (!sentFees) {
            revert TransferFeesFailed();
        }

        return _poolFee;
    }

    function _distribute(uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        // if total weight is 0, then the pool is empty and we can't distribute fees
        // ie: the user is depositing and withdrawing the same NFT
        uint256 totalWeight = totalContributions + totalPoints;

        if (totalWeight == 0) {
            // send to dao
            (bool sent,) = paymentReceiver().call{value: amount}("");
            if (!sent) {
                revert TransferFeesFailed();
            }
            return;
        }

        // Increase the accumulator for every deposited fee.
        uint256 _leftOver = leftOver;
        accumulator += (amount + _leftOver) / totalWeight;
        leftOver = (amount + _leftOver) % totalWeight;
    }

    function daoFeeRate() public view returns (uint256) {
        return ISailorSwapPoolFactory(factory).daoFeeRate();
    }

    function swapFee() public view returns (uint256) {
        return ISailorSwapPoolFactory(factory).swapFee();
    }

    function paymentReceiver() public view returns (address) {
        return ISailorSwapPoolFactory(factory).sznsDao();
    }

    function depositLockup() public view returns (uint256) {
        return ISailorSwapPoolFactory(factory).depositLockup();
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
        if (ISailorSwapPoolFactory(factory).paused()) {
            revert PoolFactoryPaused();
        }
        _;
    }
}
