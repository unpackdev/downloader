// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TwoStageOwnable.sol";

contract OMGrantsEscrow is TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Claim {
        uint256 amount;
        uint256 applicableAt;
    }

    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    uint256 public timelock;

    uint256 private _pool;
    uint256 private _withdrawalsCount;
    IERC20 private _token;
    Claim[] private _claims;

    function pool() public view returns (uint256) {
        return _pool;
    }

    function withdrawalsCount() public view returns (uint256) {
        return _withdrawalsCount;
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function claimsCount() public view returns (uint256) {
        return _claims.length;
    }

    function allClaims() public view returns (Claim[] memory) {
        return _claims;
    }

    function getClaimByIndex(uint256 index) public view returns (Claim memory) {
        return _claims[index];
    }

    function calculateWithdrawalWithLimit(uint256 limit)
        public
        view
        returns (uint256 withdrawedAmount, uint256 withdrawalsCount_)
    {
        require(limit > 0, "Limit is zero");
        uint256 claimsCount_ = _claims.length;
        withdrawalsCount_ = _withdrawalsCount;
        while (limit > 0 && withdrawalsCount_ < claimsCount_) {
            Claim memory claim = _claims[withdrawalsCount_];
            if (claim.applicableAt > getTimestamp()) break;
            withdrawedAmount = withdrawedAmount.add(claim.amount);
            withdrawalsCount_ += 1;
            limit -= 1;
        }
    }

    function calculateWithdrawal() public view returns (uint256 withdrawedAmount, uint256 withdrawalsCount_) {
        return calculateWithdrawalWithLimit(uint256(-1));
    }

    event Claimed(uint256 amount, uint256 applicableAt);
    event PoolIncreased(address payer, uint256 amount);
    event Withdrawed(uint256 amount);

    constructor(IERC20 token_, address owner_, uint256 timelock_) public TwoStageOwnable(owner_) {
        _token = token_;
        timelock = timelock_;
    }

    function claim(uint256 amount) external onlyOwner returns (uint256 applicableAt) {
        require(_pool >= amount, "Pool is extinguished");
        applicableAt = getTimestamp().add(timelock);
        _claims.push(Claim({amount: amount, applicableAt: applicableAt}));
        emit Claimed(amount, applicableAt);
    }

    function increasePool(uint256 amount) external returns (bool success) {
        require(amount > 0, "Amount is zero");
        _pool = _pool.add(amount);
        address payer = msg.sender;
        emit PoolIncreased(payer, amount);
        _token.safeTransferFrom(payer, address(this), amount);
        return true;
    }

    function withdraw() external onlyOwner returns (uint256 withdrawedAmount) {
        return _withdrawWithLimit(uint256(-1));
    }

    function withdrawWithLimit(uint256 limit) external onlyOwner returns (uint256 withdrawedAmount) {
        return _withdrawWithLimit(limit);
    }

    function _withdrawWithLimit(uint256 limit) internal returns (uint256 withdrawedAmount) {
        (withdrawedAmount, _withdrawalsCount) = calculateWithdrawalWithLimit(limit);
        require(withdrawedAmount > 0, "Nothing to withdraw");
        _pool = _pool.sub(withdrawedAmount);
        emit Withdrawed(withdrawedAmount);
        _token.safeTransfer(owner, withdrawedAmount);
    }
}
