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
    IAaveV3Pool private constant _I_AAVE_V3_POOL = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _owner, address _doughV2Index) {
        if (_owner == address(0)) revert CustomError("invalid owner");
        if (_doughV2Index == address(0)) revert CustomError("invalid _doughV2Index");
        owner = _owner;
        doughV2Index = _doughV2Index;
    }

    receive() external payable {}

    /* ========== DelegateCall ========== */
    function doughCall(uint256 _connectorId, uint256 _actionId, address _token1, address _token2, uint256 _amount, bool _opt) external payable {
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
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature("delegateDoughCall(uint256,address,address,uint256,bool)", _actionId, _token1, _token2, _amount, _opt));
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
    }

    function executeAction(address loanToken, uint256 inAmount, uint256 outAmount, uint256 funcId) external {
        // get connectorV2Flashloan address
        address _connectorV2Flashloan = IDoughV2Index(doughV2Index).getDoughV2Connector(2);
        if (_connectorV2Flashloan == address(0)) revert CustomError("doughV2Dsa: executeAction : unregistered connectorV2Flashloan");
        if (msg.sender != _connectorV2Flashloan) revert CustomError("wrong doughFlashloan");
        IERC20(loanToken).safeTransferFrom(_connectorV2Flashloan, address(this), inAmount);
        IERC20(loanToken).approve(address(_I_AAVE_V3_POOL), inAmount);
        if (funcId == 0) {
            // Loop
            _I_AAVE_V3_POOL.supply(loanToken, inAmount, address(this), 0);
            _I_AAVE_V3_POOL.borrow(loanToken, outAmount, 2, 0, address(this));
            // Check Health Factor
            (, , , , , uint256 _healthFactor) = _I_AAVE_V3_POOL.getUserAccountData(address(this));
            (, uint256 _shieldDsaHfTrigger, , ) = IDoughV2Index(doughV2Index).getShieldInfo(address(this));
            if (_healthFactor <= _shieldDsaHfTrigger) revert CustomError("error: HealthFactor <=  hfTrigger");
        } else {
            // Deloop
            _I_AAVE_V3_POOL.repay(loanToken, inAmount, 2, address(this));
            _I_AAVE_V3_POOL.withdraw(loanToken, outAmount, address(this));
        }

        IERC20(loanToken).approve(_connectorV2Flashloan, outAmount);
    }
}
