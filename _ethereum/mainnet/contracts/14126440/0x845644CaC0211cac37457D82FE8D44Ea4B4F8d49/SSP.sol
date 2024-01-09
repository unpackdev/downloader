// Be name Khoda
// Bime Abolfazl

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ======================= SSP ======================
// ==================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

import "./AccessControl.sol";
import "./IERC20.sol";
import "./IDEI.sol";
import "./ISSP.sol";

contract SSP is ISSP, AccessControl {

    /* ========== STATE VARIABLES ========== */

    bytes32 private constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 private constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
    address private deiAddress;
    address private usdcAddress;
    uint private collateralMissingDecimalD18 = 1e12; // missing decimal of collateral token
    uint private scale = 1e18;
    uint public fee = 1e16;
    uint public virtualDei;


    /* ========== EVENTS ========== */

    event FeeSet(uint fee);
    event ScaleSet(uint scale);
    event VirtualDeiSet(uint virtualDei);
    event CollateralMissingDecimalD18Set(uint collateralMissingDecimalD18);
    event WithdrawERC20(address token, address recv, uint amount);
    event WithdrawETH(address recv, uint amount);


    /* ========== CONSTRUCTOR ========== */

    constructor(
        address deiAddress_, 
        address usdcAddress_,
        address swapperAddress,
        address trustyAddress
    ) {
        deiAddress = deiAddress_;
        usdcAddress = usdcAddress_;
        _setupRole(DEFAULT_ADMIN_ROLE, trustyAddress);
        _setupRole(SWAPPER_ROLE, swapperAddress);
        _setupRole(TRUSTY_ROLE, trustyAddress);
    }

    receive() external payable { }


    /* ========== PUBLIC FUNCTIONS ========== */

    function swapUsdcForExactDei(uint deiNeededAmount) external returns (uint usdcAmount) {
        require(hasRole(SWAPPER_ROLE, msg.sender), "Caller is not a swapper");
        usdcAmount = getAmountIn(deiNeededAmount);
        IERC20(usdcAddress).transferFrom(msg.sender, address(this), usdcAmount);
        IDEIStablecoin(deiAddress).pool_mint(msg.sender, deiNeededAmount);
        virtualDei += deiNeededAmount;
    }


    /* ========== VIEWS ========== */

    function getAmountIn(uint deiNeededAmount) public view returns (uint usdcAmount) {
        usdcAmount = deiNeededAmount * scale / ((scale - fee) * collateralMissingDecimalD18);
    }

    function getAmountOut(uint usdcAmount) public view returns (uint deiAmount) {
        deiAmount = collateralMissingDecimalD18 * usdcAmount * (scale - fee) / scale;
    }

    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
        return virtualDei * IDEIStablecoin(deiAddress).global_collateral_ratio() / 1e6;
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function setFee(uint fee_) external {
        require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
        fee = fee_;
        emit FeeSet(fee);
    }

    function setScale(uint scale_) external {
        require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
        scale = scale_;
        emit ScaleSet(scale);
    }

    function setCollateralMissingDecimalD18(uint collateralMissingDecimalD18_) external {
        require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
        collateralMissingDecimalD18 = collateralMissingDecimalD18_;
        emit CollateralMissingDecimalD18Set(collateralMissingDecimalD18);
    }

    function withdrawCollateral(address recv) external {
        require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
        virtualDei = 0;
        IERC20(usdcAddress).transfer(msg.sender, IERC20(usdcAddress).balanceOf(address(this)));
    }

    function setVirtualDei(uint virtualDei_) external {
        require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
        virtualDei = virtualDei_;
        emit VirtualDeiSet(virtualDei);
    }

    function emergencyWithdrawERC20(address token, address recv, uint amount) external {
        require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
        IERC20(token).transfer(recv, amount);
        emit WithdrawERC20(token, recv, amount);
    }

    function emergencyWithdrawETH(address recv, uint amount) external {
        require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
        payable(recv).transfer(amount);
        emit WithdrawETH(recv, amount);
    }
}

// Dar panahe khoda