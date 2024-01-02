// contracts/VestingToken.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "ERC20.sol";
import "Addresses.sol";
import "IVestingWallet.sol";

struct VestingWalletInfo {
    uint256 total;
    uint256 released;
    uint256 startDuration;
    uint256 duration;
}

contract VestingWallet is ERC20, Addresses, IVestingWallet {
    mapping(address => VestingWalletInfo) public _vesting;
    bool public cliffStarted = false;
    uint256 public cliffStartTime = 0;
    constructor(string memory Name, string memory Symbol) ERC20(Name, Symbol) {
    }
    function getLockedBalance(address _address) public view override returns(uint256) {
        VestingWalletInfo memory _vest = _vesting[_address];
        return _vest.total - _vest.released;
    }
    function getReleaseableBalance(address _address) public view override returns(uint256) {
        return _getReleaseableBalance(_address);
    }
    function releaseBalance() external override {
        _releaseBalance(_msgSender());
    }
    function balanceOf(address account) virtual public view override returns(uint256) {
        VestingWalletInfo memory _vest = _vesting[account];
        return (super.balanceOf(account) + _vest.released) - _vest.total;
    }
    function getCompleteBalance(address account) virtual public view returns(uint256) {
        return super.balanceOf(account);
    }
    function initiateVesting() internal {
        addFundsWithVesting(Seed, 10000000, 1000000, 86400 * 30 * 12, 86400 * 30 * 36); // cliff: 12 months, duration: 36 months
        addFundsWithVesting(Private, 5000000, 500000, 86400 * 30 * 6, 86400 * 30 * 30); // cliff: 6 months, duration: 30 months
        addFundsWithVesting(Team, 20000000, 0, 86400 * 30 * 12, 86400 * 30 * 36); // cliff: 12 months, duration: 36 months
        addFundsWithVesting(Advisors, 5000000, 0, 86400 * 30 * 12, 86400 * 30 * 24); // cliff: 12 months, duration: 24 months
        addFundsWithVesting(Partners, 7500000, 0, 86400 * 30 * 12, 86400 * 30 * 12); // cliff: 12 months, duration: 12 months
        addFundsWithVesting(Marketing, 7500000, 500000, 0, 86400 * 30 * 36); // cliff: 0 months, duration: 36 months
        addFundsWithVesting(EcoSystem, 30000000, 0, 0, 86400 * 30 * 48); // cliff: 0 months, duration: 48 months
        addFundsWithVesting(Liquidity, 15000000, 1000000, 0, 86400 * 30 * 48); // cliff: 0 months, duration: 48 months
        _startCliff();
    }
    function addFundsWithVesting(address _address, uint256 totalAmount, uint256 initialAmount, uint256 startDuration, uint256 duration) private {
        uint256 _totalAmount = totalAmount * 1e18;
        uint256 _initialAmount = initialAmount * 1e18;
        _transfer(_msgSender(), _address, _totalAmount);
        if(_totalAmount >= _initialAmount)
            addVesting(_address, _totalAmount - _initialAmount, startDuration, duration);
    }
    function addVesting(address _address, uint256 amount, uint256 startDuration, uint256 duration) private {
        require(amount > 0, "Amount cannot be 0");
        require(_address != address(0), "VestingWallet: beneficiary is zero address");
        require(_vesting[_address].total == 0, "VestingWallet: vesting already added for that beneficiary");
        _vesting[_address] = VestingWalletInfo(amount, 0, startDuration, duration);
    }
    function _releaseBalance(address _address) private {
        require(cliffStarted, "Cliff not started");
        VestingWalletInfo storage _vest = _vesting[_address];
        require(_vest.total > 0, "VestingWallet: No Balance is vested");
        require(block.timestamp >= _getStartTime(_vest.startDuration), "Vesting not started");
        uint256 balance = _getReleaseableBalance(_address);
        require(balance > 0, "Nothing to release");
        require(_vest.released + balance <= _vest.total, "Released cannot be more than total");
        _vest.released += balance;
    }
    function _getReleaseableBalance(address _address) private view returns (uint256) {
        if(!cliffStarted) return 0;
        VestingWalletInfo memory _vest = _vesting[_address];
        uint256 startTime = _getStartTime(_vest.startDuration);
        if(_vest.total == 0 || startTime > block.timestamp)
            return 0;
        if (block.timestamp > (startTime + _vest.duration))
            return _vest.total - _vest.released;
        else {
            return ((_vest.total * (block.timestamp - startTime)) / _vest.duration)  - _vest.released;
        }
    }
    function _getStartTime(uint256 startDuration) private view returns(uint256) {
        return startDuration + cliffStartTime;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if(from != address(0)) {
            require(balanceOf(from) >= amount, "ERC201: transfer amount exceeds balance");
        }
    }
    function _startCliff() private {
        require(!cliffStarted, "Cliff already started");
        cliffStarted = true;
        cliffStartTime = block.timestamp;
    }
}