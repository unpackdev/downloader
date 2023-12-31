// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Address.sol";

import "./DoughV1Dsa.sol";

contract DoughV1Index is Ownable {
    using Address for address;

    /* ========== CONSTANTS ========== */
    address private deadAddress = address(0x000000000000000000000000000000000000dEaD);

    /* ========== STATE VARIABLES ========== */
    address public TREASURY = address(0);
    uint256 public FLASHLOAN_FEE_TOTAL = 100; // 1 %

    mapping(address => address) private _DoughV1DsaList;

    address public doughV1Flashloan = address(0);

    address public doughV1Shield = address(0);
    address public SHIELD_EXECUTOR = address(0);
    uint256 public SHIELD_FEE_TOTAL = 500; // 5 %

    /* ========== CONSTRUCTOR ========== */
    constructor(address _treasury) {
        TREASURY = _treasury;
    }

    /* ========== VIEWS ========== */
    function getDoughV1Dsa(address _owner) external view returns (address) {
        return _DoughV1DsaList[_owner];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function withdrawToken(address _tokenAddr, uint256 _amount) external onlyOwner {
        require(_amount > 0, "must be greater than zero");
        uint256 balanceOfToken = IERC20(_tokenAddr).balanceOf(address(this));
        uint256 transAmount = _amount;
        if (_amount > balanceOfToken) {
            transAmount = balanceOfToken;
        }
        IERC20(_tokenAddr).transfer(owner(), transAmount);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != deadAddress && _treasury != address(0), "treasury account error");
        TREASURY = _treasury;
    }

    function setShieldExecutor(address _shieldExecutor) external onlyOwner {
        require(_shieldExecutor != deadAddress && _shieldExecutor != address(0), "shieldExecutor account error");
        SHIELD_EXECUTOR = _shieldExecutor;
    }

    function setDoughFlashloan(address _doughV1Flashloan) external onlyOwner {
        require(_doughV1Flashloan != deadAddress && _doughV1Flashloan != address(0), "_doughV1Flashloan account error");
        doughV1Flashloan = _doughV1Flashloan;
    }

    function setDoughShield(address _doughV1Shield) external onlyOwner {
        require(_doughV1Shield != deadAddress && _doughV1Shield != address(0), "_doughV1Shield account error");
        doughV1Shield = _doughV1Shield;
    }

    function setFlashloanFeeTotal(uint256 _flashloanFee) external onlyOwner {
        // _flashloanFee > FLASHLOAN_PREMIUM_TOTAL ( in Aave V3 : 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2)
        require(_flashloanFee > 0, "must be greater than zero.");
        FLASHLOAN_FEE_TOTAL = _flashloanFee;
    }

    function setShieldFeeTotal(uint256 _shieldoanFee) external onlyOwner {
        require(_shieldoanFee > 0, "must be greater than zero.");
        SHIELD_FEE_TOTAL = _shieldoanFee;
    }

    function buildDoughV1Dsa() external returns (address) {
        require(doughV1Flashloan != address(0), "_doughV1Flashloan account error");
        require(_DoughV1DsaList[msg.sender] == address(0), "created already");
        DoughV1Dsa newDoughV1Dsa = new DoughV1Dsa(msg.sender, address(this), doughV1Flashloan);
        _DoughV1DsaList[msg.sender] = address(newDoughV1Dsa);
        return address(newDoughV1Dsa);
    }
}
