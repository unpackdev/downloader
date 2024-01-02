// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./Interfaces.sol";

contract DoughV2Dsa {
    using SafeERC20 for IERC20;

    /* ========== Layout ========== */
    address public owner;
    address public doughV2Index = address(0);

    /* ========== Constant ========== */
    address private constant _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private constant _USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IAaveV3Pool private constant _I_AAVE_V3_POOL = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    IAaveV3DataProvider private constant _I_AAVE_V3_DATA_PROVIDER = IAaveV3DataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _owner, address _doughV2Index) {
        if (_owner == address(0)) revert CustomError("invalid owner");
        if (_doughV2Index == address(0)) revert CustomError("invalid _doughV2Index");
        owner = _owner;
        doughV2Index = _doughV2Index;
    }

    receive() external payable {}

    /* ========== DelegateCall ========== */
    function doughCall(uint256 _connectorId, uint256 _actionId, address _token, uint256 _amount, bool _opt) external payable {
        if (_connectorId == 2) {
            (, , , , , uint256 _healthFactor) = _I_AAVE_V3_POOL.getUserAccountData(address(this));
            (, uint256 _shieldDsaHfTrigger, , ) = IDoughV2Index(doughV2Index).getShieldInfo(address(this));
            if (_healthFactor < _shieldDsaHfTrigger && _actionId == 1) {
                address shieldExecutor = IDoughV2Index(doughV2Index).shieldExecutor();
                if (owner != msg.sender && shieldExecutor != msg.sender) revert CustomError("Ownable: caller is not the owner or Shield executor");
            } else {
                if (owner != msg.sender) revert CustomError("Ownable: caller is not the owner");
            }
        } else {
            if (owner != msg.sender) revert CustomError("Ownable: caller is not the owner");
        }
        address _contract = IDoughV2Index(doughV2Index).getDoughV2Connector(_connectorId);
        if (_contract == address(0)) revert CustomError("doughCall: unregistered connector");
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature("delegateDoughCall(uint256,address,uint256,bool)", _actionId, _token, _amount, _opt));
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
    }

    function executeAction(address tokenIn, uint256 inAmount, address tokenOut, uint256 outAmount, uint256 funcId) external {
        // get connectorV2Flashloan address
        address _connectorV2Flashloan = IDoughV2Index(doughV2Index).getDoughV2Connector(2);
        if (_connectorV2Flashloan == address(0)) revert CustomError("doughV2Dsa: executeAction : unregistered connectorV2Flashloan");
        if (msg.sender != _connectorV2Flashloan) revert CustomError("wrong doughFlashloan");

        //  Loop: funcId = 0 , DeLoop: funcId = 1; Switch: funcId = 2;
        if (funcId > 2) revert CustomError("flashloanReq : invalid-id");

        IERC20(tokenIn).safeTransferFrom(_connectorV2Flashloan, address(this), inAmount);
        IERC20(tokenIn).approve(address(_I_AAVE_V3_POOL), inAmount);
        if (funcId == 0) {
            // Loop
            _I_AAVE_V3_POOL.supply(tokenIn, inAmount, address(this), 0);
            _I_AAVE_V3_POOL.borrow(tokenOut, outAmount, 2, 0, address(this));
            // Check Health Factor
            (, , , , , uint256 _healthFactor) = _I_AAVE_V3_POOL.getUserAccountData(address(this));
            (, uint256 _shieldDsaHfTrigger, , ) = IDoughV2Index(doughV2Index).getShieldInfo(address(this));
            if (_healthFactor <= _shieldDsaHfTrigger) revert CustomError("error: HealthFactor <=  hfTrigger");
        } else if (funcId == 1) {
            // Deloop
            if (tokenIn == _USDC && tokenOut == _USDC) {
                _I_AAVE_V3_POOL.repay(_USDC, inAmount, 2, address(this));
                _I_AAVE_V3_POOL.withdraw(_USDC, outAmount, address(this));
            } else if (tokenIn == _USDC && tokenOut == _WETH) {
                _I_AAVE_V3_POOL.repay(_USDC, inAmount, 2, address(this));
                // get USDC Position
                (uint256 currentATokenBalance, , , , , , , , ) = _I_AAVE_V3_DATA_PROVIDER.getUserReserveData(_USDC, address(this));
                if (currentATokenBalance > 0) {
                    _I_AAVE_V3_POOL.withdraw(_USDC, currentATokenBalance, address(this));
                    IERC20(_USDC).approve(_connectorV2Flashloan, currentATokenBalance);
                }
                _I_AAVE_V3_POOL.withdraw(_WETH, outAmount, address(this));
            }
        } else {
            // Switch
            _I_AAVE_V3_POOL.supply(tokenIn, inAmount, address(this), 0);
            _I_AAVE_V3_POOL.withdraw(tokenOut, outAmount, address(this));
        }
        IERC20(tokenOut).approve(_connectorV2Flashloan, outAmount);
    }
}
