// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./SafeMath.sol";

import "./GovIdentity.sol";
import "./SmartPoolStorage.sol";
import "./StandardERC20.sol";
pragma abicoder v2;
/// @title Basic Vault - Abstract Vault definition
/// @notice This contract extends ERC20, defines basic vault functions and rewrites ERC20 transferFrom function
abstract contract BasicVault is StandardERC20, GovIdentity {

    using SafeMath for uint256;

    event CapChanged(address indexed setter, uint256 oldCap, uint256 newCap);
    event TakeFee(SmartPoolStorage.FeeType ft, address owner, uint256 fee);
    event FeeChanged(address indexed setter, uint256 oldRatio, uint256 oldDenominator, uint256 newRatio, uint256 newDenominator);

    constructor(
        string memory name_,
        string memory symbol_
    )StandardERC20(name_, symbol_) {
        super._init();
    }

    /// @notice restricted vault issuance
    modifier withinCap() {
        _;
        uint256 cap = SmartPoolStorage.load().cap;
        bool check = cap == 0 || totalSupply() <= cap ? true : false;
        require(check, "Cap limit");
    }

    /// @notice Prohibition of vault circulation
    modifier deny() {
        require(!SmartPoolStorage.load().suspend, "suspend");
        _;
    }

    /// @notice is allow join
    modifier isAllowJoin() {
        require(checkAllowJoin(), "not allowJoin");
        _;
    }

    /// @notice is allow exit
    modifier isAllowExit() {
        require(checkAllowExit(), "not allowExit");
        _;
    }

    /// @notice Check allow join
    /// @return bool
    function checkAllowJoin()public view returns(bool){
        return SmartPoolStorage.load().allowJoin;
    }

    /// @notice Check allow exit
    /// @return bool
    function checkAllowExit()public view returns(bool){
        return SmartPoolStorage.load().allowExit;
    }

    /// @notice Update weighted average net worth
    /// @dev This function is used by the new transferFrom/transfer function
    /// @param account Account address
    /// @param addAmount Newly added vault amount
    /// @param newNet New weighted average net worth
    function _updateAvgNet(address account, uint256 addAmount, uint256 newNet) internal {
        uint256 balance = balanceOf(account);
        uint256 oldNet = SmartPoolStorage.load().nets[account];
        uint256 total = balance.add(addAmount);
        if (total != 0) {
            uint256 nextNet = oldNet.mul(balance).add(newNet.mul(addAmount)).div(total);
            SmartPoolStorage.load().nets[account] = nextNet;
        }
    }


    /// @notice Overwrite transfer function
    /// @dev The purpose is to update weighted average net worth
    /// @param sender Sender address
    /// @param recipient Recipient address
    /// @param amount Transfer amount
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override deny {
        uint256 newNet = SmartPoolStorage.load().nets[sender];
        _updateAvgNet(recipient, amount, newNet);
        super._transfer(sender, recipient, amount);
        if (balanceOf(sender) == 0) {
            SmartPoolStorage.load().nets[sender] = 0;
        }
    }

    /// @notice Overwrite mint function
    /// @dev the purpose is to set the initial net worth of the vault. It also limit the max vault cap
    /// @param recipient Recipient address
    /// @param amount Mint amount
    function _mint(address recipient, uint256 amount) internal virtual override withinCap deny {
        uint256 newNet = globalNetValue();
        if (newNet == 0) newNet = 1e18;
        _updateAvgNet(recipient, amount, newNet);
        super._mint(recipient, amount);
    }

    /// @notice Overwrite burn function
    /// @dev The purpose is to set the net worth of vault to 0 when the balance of the account is 0
    /// @param account Account address
    /// @param amount Burn amount
    function _burn(address account, uint256 amount) internal virtual override deny {
        super._burn(account, amount);
        if (balanceOf(account) == 0) {
            SmartPoolStorage.load().nets[account] = 0;
        }
    }

    /// @notice Overwrite vault transferFrom function
    /// @dev The overwrite is to simplify the transaction behavior, and the authorization operation behavior can be avoided when the vault transaction payer is the function initiator
    /// @param sender Sender address
    /// @param recipient Recipient address
    /// @param amount Transfer amount
    /// @return Transfer result
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(
            _msgSender() == sender || amount <= allowance(sender, _msgSender()),
            "ERR_KTOKEN_BAD_CALLER"
        );
        _transfer(sender, recipient, amount);
        if (_msgSender() != sender) {
            _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "BasicVault: transfer amount exceeds allowance"));
        }
        return true;
    }

    /// @notice Vault cap
    /// @dev The max number of vault to be issued
    /// @return Max vault cap
    function getCap() public view returns (uint256){
        return SmartPoolStorage.load().cap;
    }

    /// @notice Set max vault cap
    /// @dev To set max vault cap
    /// @param cap Max vault cap
    function setCap(uint256 cap) external onlyAdminOrGovernance() {
        uint256 oldCap = SmartPoolStorage.load().cap;
        SmartPoolStorage.load().cap = cap;
        emit CapChanged(msg.sender, oldCap, cap);
    }

    /// @notice The net worth of the vault from the time the last fee collected
    /// @dev This is used to calculate the performance fee
    /// @param account Account address
    /// @return The net worth of the vault
    function accountNetValue(address account) public view returns (uint256){
        return SmartPoolStorage.load().nets[account];
    }

    /// @notice The current vault net worth
    /// @dev This is used to update and calculate account net worth
    /// @return The net worth of the vault
    function globalNetValue() public view returns (uint256){
        return convertToCash(1e18);
    }

    /// @notice Get fee by type
    /// @dev (0=JOIN_FEE,1=EXIT_FEE,2=MANAGEMENT_FEE,3=PERFORMANCE_FEE,4=TURNOVER_FEE)
    /// @param ft Fee type
    function getFee(SmartPoolStorage.FeeType ft) public view returns (SmartPoolStorage.Fee memory){
        return SmartPoolStorage.load().fees[ft];
    }

    /// @notice Set fee by type
    /// @dev Only Governance address can set fees (0=JOIN_FEE,1=EXIT_FEE,2=MANAGEMENT_FEE,3=PERFORMANCE_FEE,4=TURNOVER_FEE)
    /// @param ft Fee type
    /// @param ratio Fee ratio
    /// @param denominator The max ratio limit
    /// @param minLine The minimum line to charge a fee
    function setFee(SmartPoolStorage.FeeType ft, uint256 ratio, uint256 denominator, uint256 minLine) external onlyAdminOrGovernance {
        require(ratio <= denominator, "ratio<=denominator");
        SmartPoolStorage.Fee storage fee = SmartPoolStorage.load().fees[ft];
        require(fee.denominator == 0, "already initialized ");
        emit FeeChanged(msg.sender, fee.ratio, fee.denominator, ratio, denominator);
        fee.ratio = ratio;
        fee.denominator = denominator;
        fee.minLine = minLine;
        fee.lastTimestamp = block.timestamp;
    }

    /// @notice Collect outstanding management fee
    /// @dev The outstanding management fee is calculated from the time the last fee is collected.
    function takeOutstandingManagementFee() public returns (uint256){
        SmartPoolStorage.Fee storage fee = SmartPoolStorage.load().fees[SmartPoolStorage.FeeType.MANAGEMENT_FEE];
        uint256 outstandingFee = calcManagementFee();
        if (outstandingFee == 0 || outstandingFee < fee.minLine) return 0;
        _mint(getRewards(), outstandingFee);
        fee.lastTimestamp = block.timestamp;
        emit TakeFee(SmartPoolStorage.FeeType.MANAGEMENT_FEE, address(0), outstandingFee);
        return outstandingFee;
    }

    /// @notice Collect performance fee
    /// @dev Performance fee is calculated by each address. The new net worth of the address is updated each time the performance is collected.
    /// @param target Account address to collect performance fee
    function takeOutstandingPerformanceFee(address target) public returns (uint256){
        if (target == getRewards()) return 0;
        uint256 netValue = globalNetValue();
        SmartPoolStorage.Fee storage fee = SmartPoolStorage.load().fees[SmartPoolStorage.FeeType.PERFORMANCE_FEE];
        uint256 outstandingFee = calcPerformanceFee(target, netValue);
        if (outstandingFee == 0 || outstandingFee < fee.minLine) return 0;
        _transfer(target, getRewards(), outstandingFee);
        fee.lastTimestamp = block.timestamp;
        SmartPoolStorage.load().nets[target] = netValue;
        emit TakeFee(SmartPoolStorage.FeeType.PERFORMANCE_FEE, target, outstandingFee);
        return outstandingFee;
    }

    /// @notice Collect Join fee
    /// @dev The join fee is collected each time a user buys the vault
    /// @param target Account address to collect join fee
    /// @param vaultAmount Vault amount
    function _takeJoinFee(address target, uint256 vaultAmount) internal returns (uint256){
        if (target == getRewards()) return 0;
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.JOIN_FEE);
        uint256 payFee = calcRatioFee(SmartPoolStorage.FeeType.JOIN_FEE, vaultAmount);
        if (payFee == 0 || payFee < fee.minLine) return 0;
        _mint(getRewards(), payFee);
        emit TakeFee(SmartPoolStorage.FeeType.JOIN_FEE, target, payFee);
        return payFee;
    }

    /// @notice Collect Redeem fee
    /// @dev The redeem fee is collected when a user redeems the vault
    /// @param target Account address to collect redeem fee
    /// @param vaultAmount Vault amount
    function _takeExitFee(address target, uint256 vaultAmount) internal returns (uint256){
        if (target == getRewards()) return 0;
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.EXIT_FEE);
        uint256 payFee = calcRatioFee(SmartPoolStorage.FeeType.EXIT_FEE, vaultAmount);
        if (payFee == 0 || payFee < fee.minLine) return 0;
        _transfer(target, getRewards(), payFee);
        emit TakeFee(SmartPoolStorage.FeeType.EXIT_FEE, target, payFee);
        return payFee;
    }

    /// @notice Calculate management fee
    /// @dev Outstanding management fee is calculated from the time the last fee is collected.
    function calcManagementFee() public view returns (uint256){
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.MANAGEMENT_FEE);
        uint256 denominator = fee.denominator == 0 ? 1000 : fee.denominator;
        if (fee.lastTimestamp == 0) return 0;
        uint256 diff = block.timestamp.sub(fee.lastTimestamp);
        return totalSupply().mul(diff).mul(fee.ratio).div(denominator * 365.25 days);
    }

    /// @notice Calculate performance fee
    /// @dev Performance fee is calculated by each address. The new net worth line of the address is updated each time the performance is collected.
    /// @param target Account address to collect performance fee
    /// @param newNet New net worth
    function calcPerformanceFee(address target, uint256 newNet) public view returns (uint256){
        if (newNet == 0) return 0;
        uint256 balance = balanceOf(target);
        uint256 oldNet = accountNetValue(target);
        uint256 diff = newNet > oldNet ? newNet.sub(oldNet) : 0;
        SmartPoolStorage.Fee memory fee = getFee(SmartPoolStorage.FeeType.PERFORMANCE_FEE);
        uint256 denominator = fee.denominator == 0 ? 1000 : fee.denominator;
        uint256 cash = diff.mul(balance).mul(fee.ratio).div(denominator);
        return cash.div(newNet);
    }

    /// @notice Calculate the fee by ratio
    /// @dev This is used to calculate join and redeem fee
    /// @param ft Fee type
    /// @param vaultAmount vault amount
    function calcRatioFee(SmartPoolStorage.FeeType ft, uint256 vaultAmount) public view returns (uint256){
        if (vaultAmount == 0) return 0;
        SmartPoolStorage.Fee memory fee = getFee(ft);
        uint256 denominator = fee.denominator == 0 ? 1000 : fee.denominator;
        uint256 amountRatio = vaultAmount.div(denominator);
        return amountRatio.mul(fee.ratio);
    }

    /// @notice vault maintenance
    /// @dev stop and open vault circulation
    /// @param _value status value
    function maintain(bool _value) external onlyAdminOrGovernance {
        SmartPoolStorage.load().suspend = _value;
    }

    /// @notice vault allowJoin
    /// @dev stop and open vault circulation
    /// @param _value status value
    function allowJoin(bool _value) external onlyAdminOrGovernance {
        SmartPoolStorage.load().allowJoin = _value;
    }

    /// @notice vault allowExit
    /// @dev stop and open vault circulation
    /// @param _value status value
    function allowExit(bool _value) external onlyAdminOrGovernance {
        SmartPoolStorage.load().allowExit = _value;
    }

    /// @notice Convert vault amount to cash amount
    /// @dev This converts the user vault amount to cash amount when a user redeems the vault
    /// @param vaultAmount Redeem vault amount
    /// @return Cash amount
    function convertToCash(uint256 vaultAmount) public virtual view returns (uint256);

    /// @notice Convert cash amount to share amount
    /// @dev This converts cash amount to share amount when a user buys the vault
    /// @param cashAmount Join cash amount
    /// @return share amount
    function convertToShare(uint256 cashAmount) public virtual view returns (uint256);

}
