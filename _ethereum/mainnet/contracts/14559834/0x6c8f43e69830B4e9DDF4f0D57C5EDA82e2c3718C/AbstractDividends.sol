//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IDividends.sol";
import "./CCMath.sol";

abstract contract AbstractDividends is IDividends {
    using CCMath for uint256;

    struct Account {
        uint256 withdrawn;
        int256 ptsCorrection;
    }

    mapping (address => Account) private _stakeHolders;

    uint256 constant private PM = type(uint128).max;
    uint256 private _pointsPerShare = 0;

    uint256 private _expectedBalance = 0;
    uint256 private _totalDistributed = 0;
    uint256 private _ownerBalance = 0;

    event PaymentDistributed(uint256 amount);
    event Withdrawn(address holder, uint256 amount);

    modifier correctPts(address holder, int256 shares) {
        _stakeHolders[holder].ptsCorrection += int256(_pointsPerShare) * shares;
        _;
    }

    function _sharesOf(address holder) internal virtual view returns (int256);
    function _totalShares() internal virtual view returns (uint256);

    function totalDistributed() external view override returns (uint256) {
        return _totalDistributed;
    }

    function withdrawableBy(address holder) public view override returns (uint256) {
        int256 correction = _stakeHolders[holder].ptsCorrection;
        int256 cumulative = (int256(_pointsPerShare) * _sharesOf(holder) + correction) / int256(PM);
        int256 withdrawn = int256(withdrawnBy(holder));
        uint256 r = cumulative > withdrawn ? uint256(cumulative - withdrawn) : 0;
        return r;
    }

    function withdrawnBy(address holder) public view override returns (uint256) {
        return _stakeHolders[holder].withdrawn;
    }

    function undistributedBalance() public view override returns (uint256) {
        uint256 contractBalance = address(this).balance.sub(_ownerBalance);
        uint256 undistributed = contractBalance > _expectedBalance ? contractBalance.sub(_expectedBalance) : 0;
        return undistributed;
    }

    function distribute() external override {
        _distribute(undistributedBalance());
    }

    function _distribute(uint256 amount) internal {
        require(_totalShares() > 0, "no stakeholders");
        if (amount > 0) {
            _totalDistributed += amount;
            _expectedBalance += amount;
            _pointsPerShare = amount.mul(PM).div(_totalShares()).add(_pointsPerShare);
            emit PaymentDistributed(amount);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    function _stake(address holder, uint256 shares) internal correctPts(holder, -int256(shares)) {
    }

    // solhint-disable-next-line no-empty-blocks
    function _unstake(address holder, uint256 shares) internal correctPts(holder, int256(shares)) {
    }

    function _increaseOwnerBalance(uint256 amount) internal {
        _ownerBalance = _ownerBalance.add(amount);
    }

    function _decreaseOwnerBalance(uint256 amount) internal {
        _ownerBalance = _ownerBalance.sub(amount);
    }

    function _getOwnerBalance() internal view returns (uint256) {
        return _ownerBalance;
    }

    function _withdrawFor(address payable holder) internal {
        uint256 amount = withdrawableBy(holder);
        if (amount == 0) return;

        uint256 contractBalance = address(this).balance - _ownerBalance;
        require(contractBalance >= amount, "unexpected balance state");

        _stakeHolders[holder].withdrawn += amount;
        _expectedBalance -= amount;
        emit Withdrawn(holder, amount);
        holder.transfer(amount);
    }
}
