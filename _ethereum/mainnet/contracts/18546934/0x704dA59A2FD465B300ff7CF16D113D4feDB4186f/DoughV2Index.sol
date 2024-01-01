// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./DoughV2Dsa.sol";

import "./Interfaces.sol";

contract DoughV2Index is Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */
    address private constant _DEAD_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    IAaveV3Pool private constant _I_AAVE_V3_POOL = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    /* ========== STATE VARIABLES ========== */
    address public treasury = address(0);
    address public shieldExecutor = address(0);

    uint256 public supplyFee = 0; // 0 %
    uint256 public withdrawFee = 0; // 0 %
    uint256 public borrowFee = 0; // 0 %
    uint256 public repayFee = 0; // 0 %
    uint256 public flashloanFee = 100; // 1 %
    uint256 public shieldFee = 500; // 5 %
    uint256 public shieldSupplyLimit = 15000; // $ 15000

    mapping(address => address) private _doughV2DsaList;
    mapping(uint256 => address) private _connectors;

    struct ShieldInfo {
        uint256 hfTrigger;
        uint256 hfTarget;
        address prevShieldDsa;
        address nextShieldDsa;
    }

    uint256 public shieldDsaCnt = 0;
    address public shieldFirstDsa = address(0);
    address public shieldLastDsa = address(0);
    mapping(address => ShieldInfo) private _shieldDsa;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _treasury) {
        if (_treasury == address(0)) revert CustomError("invalid address");
        treasury = _treasury;
    }

    /* ========== VIEWS ========== */
    function getDoughV2Dsa(address _user) external view returns (address) {
        return _doughV2DsaList[_user];
    }

    function getDoughV2Connector(uint256 _connectorId) external view returns (address) {
        return _connectors[_connectorId];
    }

    function getShieldInfo(address dsa) external view returns (uint256, uint256, address, address) {
        return (_shieldDsa[dsa].hfTarget, _shieldDsa[dsa].hfTrigger, _shieldDsa[dsa].prevShieldDsa, _shieldDsa[dsa].nextShieldDsa);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function withdrawToken(address _tokenAddr, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert CustomError("must be greater than zero");
        uint256 balanceOfToken = IERC20(_tokenAddr).balanceOf(address(this));
        uint256 transAmount = _amount;
        if (_amount > balanceOfToken) {
            transAmount = balanceOfToken;
        }
        IERC20(_tokenAddr).safeTransfer(owner(), transAmount);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == _DEAD_ADDRESS || _treasury == address(0)) revert CustomError("treasury account error");
        treasury = _treasury;
    }

    function setShieldExecutor(address _shieldExecutor) external onlyOwner {
        if (_shieldExecutor == _DEAD_ADDRESS || _shieldExecutor == address(0)) revert CustomError("shieldExecutor account error");
        if (_shieldExecutor == address(0)) revert CustomError("_shieldExecutor is zero_address");
        if (_shieldExecutor == _DEAD_ADDRESS) revert CustomError("_shieldExecutor is zero_address");
        shieldExecutor = _shieldExecutor;
    }

    function setSupplyFee(uint256 _supplyFee) external onlyOwner {
        // _supplyFee <= 5%
        if (_supplyFee > 500) revert CustomError("invaid value");
        supplyFee = _supplyFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        // _withdrawFee <= 5%
        if (_withdrawFee > 500) revert CustomError("invaid value");
        withdrawFee = _withdrawFee;
    }

    function setBorrowFee(uint256 _borrowFee) external onlyOwner {
        // _borrowFee <= 5%
        if (_borrowFee > 500) revert CustomError("invaid value");
        borrowFee = _borrowFee;
    }

    function setRepayFee(uint256 _repayFee) external onlyOwner {
        // _repayFee <= 5%
        if (_repayFee > 500) revert CustomError("invaid value");
        repayFee = _repayFee;
    }

    function setFlashloanFee(uint256 _flashloanFee) external onlyOwner {
        // _flashloanFee <= 5%
        if (_flashloanFee > 500) revert CustomError("invaid value");
        flashloanFee = _flashloanFee;
    }

    function setShieldFee(uint256 _shieldFee) external onlyOwner {
        // _shieldFee <= 10%
        if (_shieldFee > 1000) revert CustomError("invaid value");
        shieldFee = _shieldFee;
    }

    function setShieldSupplyLimit(uint256 _shieldSupplyLimit) external onlyOwner {
        if (_shieldSupplyLimit == 0) revert CustomError("must be greater than zero.");
        shieldSupplyLimit = _shieldSupplyLimit;
    }

    function setConnectors(uint256 _connectorId, address _connectorsAddr) external onlyOwner {
        if (_connectorsAddr == address(0)) revert CustomError("addConnectors: _connectors address not vaild");
        _connectors[_connectorId] = _connectorsAddr;
    }

    function buildDoughV2Dsa() external returns (address) {
        if (_doughV2DsaList[msg.sender] != address(0)) revert CustomError("created already");
        DoughV2Dsa newDoughV2Dsa = new DoughV2Dsa(msg.sender, address(this));
        _doughV2DsaList[msg.sender] = address(newDoughV2Dsa);
        return address(newDoughV2Dsa);
    }

    function setShield(uint256 _hfTrigger, uint256 _hfTarget) external {
        address dsa = _doughV2DsaList[msg.sender];
        if (dsa == address(0)) revert CustomError("doughV2Index: uncreated dsa");
        if (_hfTrigger <= 1e18) revert CustomError("Shield: wrong trigger value of health factor");
        if (_hfTrigger >= _hfTarget) revert CustomError("Shield: wrong target value of health factor");
        (uint256 totalCollateralBase, , , , , ) = _I_AAVE_V3_POOL.getUserAccountData(dsa);
        if (totalCollateralBase < shieldSupplyLimit * 1e8) revert CustomError("Shield: supply amount < shieldSupplyLimit");
        ShieldInfo storage _refShieldDsa = _shieldDsa[dsa];
        if (shieldDsaCnt == 0) {
            shieldFirstDsa = dsa;
            shieldLastDsa = dsa;
            _refShieldDsa.prevShieldDsa = address(1);
            _refShieldDsa.nextShieldDsa = address(2);
            shieldDsaCnt++;
        } else {
            if (_refShieldDsa.hfTrigger == 0) {
                _shieldDsa[shieldLastDsa].nextShieldDsa = dsa;
                _refShieldDsa.prevShieldDsa = shieldLastDsa;
                _refShieldDsa.nextShieldDsa = address(2);
                shieldLastDsa = dsa;
                shieldDsaCnt++;
            }
        }
        _refShieldDsa.hfTarget = _hfTarget;
        _refShieldDsa.hfTrigger = _hfTrigger;
    }

    function unsetShield() external {
        address dsa = _doughV2DsaList[msg.sender];
        if (dsa == address(0)) revert CustomError("doughV2Index: uncreated dsa");
        if (shieldDsaCnt == 0) revert CustomError("doughV2Index: empty list");

        ShieldInfo storage _refShieldDsa = _shieldDsa[dsa];

        if (_refShieldDsa.hfTrigger <= 1e18) revert CustomError("doughV2Index: already unset");

        if (shieldDsaCnt == 1) {
            shieldFirstDsa = address(0);
            shieldLastDsa = address(0);
        } else {
            if (dsa == shieldLastDsa) {
                _shieldDsa[_refShieldDsa.prevShieldDsa].nextShieldDsa = address(2);
                shieldLastDsa = _refShieldDsa.prevShieldDsa;
            } else if (dsa == shieldFirstDsa) {
                _shieldDsa[_refShieldDsa.nextShieldDsa].prevShieldDsa = address(1);
                shieldFirstDsa = _refShieldDsa.nextShieldDsa;
            } else {
                _shieldDsa[_refShieldDsa.prevShieldDsa].nextShieldDsa = _refShieldDsa.nextShieldDsa;
                _shieldDsa[_refShieldDsa.nextShieldDsa].prevShieldDsa = _refShieldDsa.prevShieldDsa;
            }
            _refShieldDsa.hfTrigger = 0;
            _refShieldDsa.hfTarget = 0;
            _refShieldDsa.prevShieldDsa = address(0);
            _refShieldDsa.nextShieldDsa = address(0);
        }
        shieldDsaCnt--;
    }
}
