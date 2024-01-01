// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./Interfaces.sol";

// ConnectorId : 1
contract ConnectorV2AaveV3 {
    using SafeERC20 for IERC20;

    /* ========== Layout ========== */
    address public owner;
    address public doughV2Index = address(0);

    /* ========== Constant ========== */
    address private constant _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 private constant _PRECISION = 10000; // x * 2% -> x * 200 /100 /100 = x * 200 / 10000
    IAaveV3Pool private constant _I_AAVE_V3_POOL = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    IAaveV3DataProvider private constant _I_AAVE_V3_DATA_PROVIDER = IAaveV3DataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _doughV2Index) {
        if (_doughV2Index == address(0)) revert CustomError("invalid _doughV2Index");
        doughV2Index = _doughV2Index;
    }

    function getOwner() public view returns (address) {
        return IDoughV2Index(doughV2Index).owner();
    }

    function withdrawToken(address _tokenAddr, uint256 _amount) external {
        if (msg.sender != getOwner()) revert CustomError("ConnectorV2AaveV3: not owner of doughV2Index");
        if (_amount == 0 || _amount > IERC20(_tokenAddr).balanceOf(address(this))) revert CustomError("ConnectorV2AaveV3:withdrawTokenFromDsa: invalid amount");
        IERC20(_tokenAddr).safeTransfer(getOwner(), _amount);
    }

    // delegate Call
    function delegateDoughCall(uint256 _actionId, address _token1, address _token2, uint256 _amount, bool _opt) external payable {
        if (_amount == 0) revert CustomError("ConnectorV2AaveV3: invalid amount");
        if (_actionId > 3) revert CustomError("ConnectorV2AaveV3: invalid actionId");
        if (_token1 == address(0)) revert CustomError("ConnectorV2AaveV3: invalid token1");
        if (_token1 != _token2) revert CustomError("ConnectorV2AaveV3: invalid token2");

        if (_actionId == 0) {
            uint256 _feeSupply = IDoughV2Index(doughV2Index).supplyFee();
            uint256 _feeAmount = (_amount * _feeSupply) / _PRECISION;
            // Deposit token to dsa
            if (_token1 == _WETH) {
                if (msg.value != _amount + _feeAmount) revert CustomError("ConnectorV2AaveV3: invalid amount");
                IWETH(_WETH).deposit{value: _amount + _feeAmount}();
            } else {
                IERC20(_token1).safeTransferFrom(owner, address(this), _amount + _feeAmount);
            }
            // send Fee to Treasury
            if (_feeAmount > 0) {
                IERC20(_token1).safeTransfer(IDoughV2Index(doughV2Index).treasury(), _feeAmount);
            }
            // Supply to AaveV3
            IERC20(_token1).approve(address(_I_AAVE_V3_POOL), _amount);
            _I_AAVE_V3_POOL.supply(_token1, _amount, address(this), 0);
        } else if (_actionId == 1) {
            uint256 _withdrawAmount = _amount;
            if (_opt) {
                (_withdrawAmount, , , , , , , , ) = _I_AAVE_V3_DATA_PROVIDER.getUserReserveData(_token1, address(this));
            }
            // Withdraw from AaveV3
            _I_AAVE_V3_POOL.withdraw(_token1, _withdrawAmount, address(this));
            // Check Health Factor
            (, , , , , uint256 _healthFactor) = _I_AAVE_V3_POOL.getUserAccountData(address(this));
            (, uint256 _shieldDsaHfTrigger, , ) = IDoughV2Index(doughV2Index).getShieldInfo(address(this));
            if (_healthFactor <= _shieldDsaHfTrigger) revert CustomError("error: HealthFactor <=  hfTrigger");
            // send Fee to Treasury
            uint256 _feeWithdraw = IDoughV2Index(doughV2Index).withdrawFee();
            uint256 _feeAmount = (_withdrawAmount * _feeWithdraw) / _PRECISION;
            if (_feeAmount > 0) {
                IERC20(_token1).safeTransfer(IDoughV2Index(doughV2Index).treasury(), _feeAmount);
            }
            // Withdraw token from dsa to wallet
            if (_token1 == _WETH) {
                IWETH(_WETH).withdraw(_withdrawAmount - _feeAmount);
                payable(owner).transfer(_withdrawAmount - _feeAmount);
            } else {
                IERC20(_token1).safeTransfer(owner, _withdrawAmount - _feeAmount);
            }
        } else if (_actionId == 2) {
            // Borrow from AaveV3
            _I_AAVE_V3_POOL.borrow(_token1, _amount, 2, 0, address(this));
            // Check Health Factor
            (, , , , , uint256 _healthFactor) = _I_AAVE_V3_POOL.getUserAccountData(address(this));
            (, uint256 _shieldDsaHfTrigger, , ) = IDoughV2Index(doughV2Index).getShieldInfo(address(this));
            if (_healthFactor <= _shieldDsaHfTrigger) revert CustomError("error: HealthFactor <=  hfTrigger");
            // send Fee to Treasury
            uint256 _feeBorrow = IDoughV2Index(doughV2Index).borrowFee();
            uint256 _feeAmount = (_amount * _feeBorrow) / _PRECISION;
            if (_feeAmount > 0) {
                IERC20(_token1).safeTransfer(IDoughV2Index(doughV2Index).treasury(), _feeAmount);
            }
            // Withdraw token from dsa to wallet
            if (_token1 == _WETH) {
                IWETH(_WETH).withdraw(_amount - _feeAmount);
                payable(owner).transfer(_amount - _feeAmount);
            } else {
                IERC20(_token1).safeTransfer(owner, _amount - _feeAmount);
            }
        } else {
            uint256 _repayAmount = _amount;
            if (_opt) {
                (, , _repayAmount, , , , , , ) = _I_AAVE_V3_DATA_PROVIDER.getUserReserveData(_token1, address(this));
            }
            // get Fee to Treasury
            uint256 _feeRepay = IDoughV2Index(doughV2Index).repayFee();
            uint256 _feeAmount = (_repayAmount * _feeRepay) / _PRECISION;
            // Deposit token to dsa
            if (_token1 == _WETH) {
                if (msg.value < _repayAmount + _feeAmount) revert CustomError("ConnectorV2AaveV3: invalid amount");
                IWETH(_WETH).deposit{value: _repayAmount + _feeAmount}();
                if (_opt) {
                    payable(owner).transfer(msg.value - _repayAmount - _feeAmount);
                }
            } else {
                IERC20(_token1).safeTransferFrom(owner, address(this), _repayAmount + _feeAmount);
            }
            // send Fee to Treasury
            if (_feeAmount > 0) {
                IERC20(_token1).safeTransfer(IDoughV2Index(doughV2Index).treasury(), _feeAmount);
            }
            // Repay to AaveV3
            IERC20(_token1).approve(address(_I_AAVE_V3_POOL), _repayAmount);
            _I_AAVE_V3_POOL.repay(_token1, _repayAmount, 2, address(this));
        }
    }
}
