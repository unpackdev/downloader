// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IVault.sol";
import "./IFeeManager.sol";

contract Vault is IVault {

    /* ========== STATES ========== */

    IVaultFactory public immutable override factory;
    address public override owner;
    uint public override deposited;
    uint public override minted;
    uint public constant PRECISION = 1e18;

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        factory = IVaultFactory(msg.sender);
    }

    // Called once by the factory on deployment
    function initialize(address _owner) external override {
        require(msg.sender == address(factory), '!factory');
        owner = _owner;
    }

    /* ========== VIEWS ========== */

    function availableBalance() public view override returns (uint) {
        // In extreme unlike scenario of multiple large negative rebases, vault balance can become < than deposited.
        // In this case vault owner need to transfer in stETH and make up for the diff before withdrawing.
        // This ensures collateral > debt at all times.
        return factory.collateral().balanceOf(address(this)) < deposited ? 0 : deposited - minted;
    }

    function pendingYield() public view override returns (uint) {
        uint balance = factory.collateral().balanceOf(address(this));
        return balance <= deposited ? 0 : balance - deposited;
    }

    function mintRatio() external view override returns (uint) {
        return deposited == 0 ? 0 : minted * PRECISION / deposited;
    }

    /* ========== USER FUNCTIONS ========== */

    // Deposit collateral from msg.sender to vault
    function deposit(uint _amount) external override onlyManagerOrOwner() returns (uint) {
        _claim();
        // stETH have known rounding error on transfers by 1-2 wei
        uint before = factory.collateral().balanceOf(address(this));
        factory.collateral().transferFrom(msg.sender, address(this), _amount);
        uint actualAmount = factory.collateral().balanceOf(address(this)) - before;
        deposited += actualAmount;
        emit Deposit(actualAmount);
        return actualAmount;
    }

    // Withdraw available collateral to owner
    function withdraw(uint _amount) external override onlyManagerOrOwner() {
        _claim();
        _withdraw(_amount, owner);
        emit Withdraw(_amount);
    }

    // Mint token to vault owner using available collateral
    function mint(uint _amount) external override onlyManagerOrOwner() {
        require(availableBalance() >= _amount, "!available");
        _claim();
        factory.token().mint(owner, _amount);
        minted += _amount;
        emit Mint(_amount);
    }

    // Burn token from msg.sender for vault
    function burn(uint _amount) external override onlyManagerOrOwner() {
        _claim();
        _burn(_amount);
        emit Burn(_amount);
    }

    // Claim pending yield into deposited, pay protocol fee
    function claim() external override {
        _claim();
    }

    // Redeem collateral from vault by burning token from msg.sender and paying redemption fee
    function redeem(uint _amount) external {
        IFeeManager feeManager = IFeeManager(factory.feeManager());
        feeManager.beforeRedeem(_amount);
        uint fee = feeManager.redemptionFee(address(this), _amount);
        _claim();
        _burn(_amount);
        _withdraw(_amount - fee, msg.sender);
        uint protocolShare = fee * feeManager.protocolRedemptionFeeShare() / PRECISION;
        _withdraw(protocolShare, feeManager.redemptionFeeTo());
        feeManager.afterRedeem(_amount);
        emit Redeem(msg.sender, _amount, protocolShare, fee - protocolShare);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _claim() internal {
        uint yield = pendingYield();
        if (yield == 0) {
            return;
        }
        IFeeManager feeManager = IFeeManager(factory.feeManager());
        uint fee = feeManager.protocolFee(address(this), yield);
        factory.collateral().transfer(feeManager.protocolFeeTo(), fee);
        deposited += yield - fee;
        emit Claim(yield - fee, fee);
    }

    function _burn(uint _amount) internal {
        require(minted >= _amount, "!minted");
        factory.token().transferFrom(msg.sender, address(this), _amount);
        factory.token().burn(_amount);
        minted -= _amount;
    }

    function _withdraw(uint _amount, address _recipient) internal {
        require(availableBalance() >= _amount, "!available");
        deposited -= _amount;
        factory.collateral().transfer(_recipient, _amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyManagerOrOwner() {
        require(msg.sender == owner || factory.isVaultManager(msg.sender), "!allowed");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(uint amount);
    event Withdraw(uint amount);
    event Mint(uint amount);
    event Burn(uint amount);
    event Claim(uint yieldAfterProtocolFee, uint protocolFee);
    event Redeem(address indexed redeemer, uint amount, uint protocolFee, uint ownerFee);
}
