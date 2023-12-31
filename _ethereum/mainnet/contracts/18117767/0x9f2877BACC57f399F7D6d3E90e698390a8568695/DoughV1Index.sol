// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Address.sol";

import "./DoughV1Dsa.sol";

contract DoughV1Index is Ownable {
    using Address for address;

    /* ========== CONSTANTS ========== */
    address private deadAddress = address(0x000000000000000000000000000000000000dEaD);
    address private constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    IAaveV3Pool private aave_v3_pool = IAaveV3Pool(AAVE_V3_POOL);

    /* ========== STATE VARIABLES ========== */
    address public TREASURY = address(0);
    address public SHIELD_EXECUTOR = address(0);

    uint256 public SUPPLY_FEE = 0; // 0 %
    uint256 public WITHDRAW_FEE = 0; // 0 %
    uint256 public BORROW_FEE = 0; // 0 %
    uint256 public REPAY_FEE = 0; // 0 %
    uint256 public SWAP_FEE = 0; // 0 %
    uint256 public FLASHLOAN_FEE = 100; // 1 %
    uint256 public SHIELD_FEE = 500; // 5 %
    uint256 public SHIELD_EXECUTE_FEE = 5000000000000000; // 0.005 ETH
    uint256 public SHIELD_SUPPLY_LIMIT = 15000; // $ 15000

    mapping(address => address) private _DoughV1DsaList;
    mapping(uint256 => address) private _connectors;

    uint256 public shield_dsa_cnt = 0;
    address public shield_first_dsa = address(0);
    address public shield_last_dsa = address(0);
    mapping(address => uint256) private _shield_dsa_hf_target;
    mapping(address => uint256) private _shield_dsa_hf_trigger;
    mapping(address => address) private _shield_dsa_prev;
    mapping(address => address) private _shield_dsa_next;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _treasury) {
        TREASURY = _treasury;
        SHIELD_EXECUTOR = _treasury;
    }

    /* ========== VIEWS ========== */
    function getDoughV1Dsa(address _user) external view returns (address) {
        return _DoughV1DsaList[_user];
    }

    function getDoughV1Connector(uint256 _connectorId) external view returns (address) {
        return _connectors[_connectorId];
    }

    function getShieldInfo(address dsa) external view returns (uint256, uint256, address, address) {
        return (_shield_dsa_hf_target[dsa], _shield_dsa_hf_trigger[dsa], _shield_dsa_prev[dsa], _shield_dsa_next[dsa]);
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

    function setSupplyFee(uint256 _supplyFee) external onlyOwner {
        SUPPLY_FEE = _supplyFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        WITHDRAW_FEE = _withdrawFee;
    }

    function setBorrowFee(uint256 _borrowFee) external onlyOwner {
        BORROW_FEE = _borrowFee;
    }

    function setRepayFee(uint256 _repayFee) external onlyOwner {
        REPAY_FEE = _repayFee;
    }

    function setSwapFee(uint256 _swapFee) external onlyOwner {
        SWAP_FEE = _swapFee;
    }

    function setFlashloanFee(uint256 _flashloanFee) external onlyOwner {
        require(_flashloanFee > aave_v3_pool.FLASHLOAN_PREMIUM_TOTAL(), "must be greater than AAVE_V3_FLASHLOAN_PREMIUM_TOTAL.");
        FLASHLOAN_FEE = _flashloanFee;
    }

    function setShieldFee(uint256 _shieldFee) external onlyOwner {
        require(_shieldFee > 0, "must be greater than zero.");
        SHIELD_FEE = _shieldFee;
    }

    function setShieldExecuteFee(uint256 _executeFee) external onlyOwner {
        require(_executeFee > 0, "must be greater than zero.");
        SHIELD_EXECUTE_FEE = _executeFee;
    }

    function setShieldSupplyLimit(uint256 _shieldSupplyLimit) external onlyOwner {
        require(_shieldSupplyLimit > 0, "must be greater than zero.");
        SHIELD_SUPPLY_LIMIT = _shieldSupplyLimit;
    }

    function setConnectors(uint256 _connectorId, address _connectorsAddr) external onlyOwner {
        require(_connectorsAddr != address(0), "addConnectors: _connectors address not vaild");
        _connectors[_connectorId] = _connectorsAddr;
    }

    function buildDoughV1Dsa() external returns (address) {
        require(_DoughV1DsaList[msg.sender] == address(0), "created already");
        DoughV1Dsa newDoughV1Dsa = new DoughV1Dsa(msg.sender, address(this));
        _DoughV1DsaList[msg.sender] = address(newDoughV1Dsa);
        return address(newDoughV1Dsa);
    }

    function setShield(uint256 hf_trigger, uint256 hf_target) external {
        address dsa = _DoughV1DsaList[msg.sender];
        require(dsa != address(0), "DoughV1Index: uncreated dsa");
        require(hf_trigger > 1e18, "Shield: wrong trigger value of health factor");
        require(hf_trigger < hf_target, "Shield: wrong target value of health factor");
        (uint256 totalCollateralBase, , , , , ) = aave_v3_pool.getUserAccountData(dsa);
        require(totalCollateralBase > SHIELD_SUPPLY_LIMIT * 1e8, "Shield: supply amount < SHIELD_SUPPLY_LIMIT");
        if (shield_dsa_cnt == 0) {
            shield_first_dsa = dsa;
            shield_last_dsa = dsa;
            _shield_dsa_prev[dsa] = address(1);
            _shield_dsa_next[dsa] = address(2);
            shield_dsa_cnt++;
        } else {
            if (_shield_dsa_hf_trigger[dsa] == 0) {
                _shield_dsa_next[shield_last_dsa] = dsa;
                _shield_dsa_prev[dsa] = shield_last_dsa;
                _shield_dsa_next[dsa] = address(2);
                shield_last_dsa = dsa;
                shield_dsa_cnt++;
            }
        }
        _shield_dsa_hf_target[dsa] = hf_target;
        _shield_dsa_hf_trigger[dsa] = hf_trigger;
    }

    function unsetShield() external {
        address dsa = _DoughV1DsaList[msg.sender];
        require(dsa != address(0), "DoughV1Index: uncreated dsa");
        require(shield_dsa_cnt > 0, "DoughV1Index: empty list");
        require(_shield_dsa_hf_trigger[dsa] > 1e18, "DoughV1Index: already unset");

        if (shield_dsa_cnt == 1) {
            shield_first_dsa = address(0);
            shield_last_dsa = address(0);
        } else {
            if (dsa == shield_last_dsa) {
                _shield_dsa_next[_shield_dsa_prev[dsa]] = address(2);
                shield_last_dsa = _shield_dsa_prev[dsa];
            } else if (dsa == shield_first_dsa) {
                _shield_dsa_prev[_shield_dsa_next[dsa]] = address(1);
                shield_first_dsa = _shield_dsa_next[dsa];
            } else {
                _shield_dsa_next[_shield_dsa_prev[dsa]] = _shield_dsa_next[dsa];
                _shield_dsa_prev[_shield_dsa_next[dsa]] = _shield_dsa_prev[dsa];
            }
            _shield_dsa_hf_trigger[dsa] = 0;
            _shield_dsa_hf_target[dsa] = 0;
            _shield_dsa_prev[dsa] = address(0);
            _shield_dsa_next[dsa] = address(0);
        }
        shield_dsa_cnt--;
    }
}
