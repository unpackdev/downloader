// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./Initializable.sol";
import "./IERC721.sol";
import "./IPool.sol";
import "./IPoolFactory.sol";
import "./ReentrancyGuard.sol";

/**
 * SAILOR SWAP v1.0-alpha
 *  WARNING: UNAUDITED CODE USE AT YOUR OWN RISK
 */
contract Pool is IPool, Ownable, Initializable, ReentrancyGuard {
    uint256 public totalContributions;

    mapping(address => uint256) public contributions;
    address public collection;

    address private factory;

    constructor(address _collection) {
        initialize(_collection);

        _disableInitializers();
    }

    function initialize(address _collection) public initializer {
        collection = _collection;

        factory = msg.sender;
    }

    function deposit(uint256[] calldata ids) public nonReentrant {
        _deposit(ids);
    }

    function _deposit(uint256[] calldata ids) private {
        uint256 deposited = ids.length;

        // Call first to prevent reentrancy
        totalContributions += deposited;
        contributions[msg.sender] += deposited;

        for (uint256 i; i < deposited;) {
            IERC721(collection).transferFrom(msg.sender, address(this), ids[i]);
            unchecked {
                ++i;
            }
        }

        emit Deposit(msg.sender, ids);
    }

    function withdraw(uint256[] calldata ids) public payable nonReentrant {
        _withdraw(ids);

        uint256 totalFee = ids.length * fee();

        if (msg.value < totalFee) {
            revert FeeRequired();
        }

        if (msg.value > totalFee) {
            (bool sent,) = msg.sender.call{value: msg.value - totalFee}("");
            if (!sent) {
                revert RefundFailed();
            }
        }

        (bool sentFees,) = paymentReceiver().call{value: totalFee}("");
        if (!sentFees) {
            revert TransferFeesFailed();
        }
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

        for (uint256 i; i < withdrawn;) {
            IERC721(collection).transferFrom(address(this), msg.sender, ids[i]);
            unchecked {
                ++i;
            }
        }

        emit Withdraw(msg.sender, ids);
    }

    function swap(uint256[] calldata depositIDs, uint256[] calldata withdrawIDs) public payable nonReentrant {
        if (depositIDs.length != withdrawIDs.length) {
            revert NotEnoughForSwap();
        }

        uint256 totalFee = depositIDs.length * fee();

        if (msg.value < totalFee) {
            revert FeeRequired();
        }

        // deposit first
        _deposit(depositIDs);

        // withdraw
        _withdraw(withdrawIDs);

        if (msg.value > totalFee) {
            (bool sent,) = msg.sender.call{value: msg.value - totalFee}("");
            if (!sent) {
                revert RefundFailed();
            }
        }

        (bool sentFees,) = paymentReceiver().call{value: totalFee}("");
        if (!sentFees) {
            revert TransferFeesFailed();
        }

        emit Swap(msg.sender, depositIDs, withdrawIDs);
    }

    function fee() public view returns (uint256) {
        return IPoolFactory(factory).fee();
    }

    function paymentReceiver() public view returns (address) {
        return IPoolFactory(factory).sznsDao();
    }
}
