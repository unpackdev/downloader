// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./DydxFlashloanBase.sol";
import "./IDydx.sol";

import "./IDssCdpManager.sol";
import "./IDssProxyActions.sol";
import "./DssActionsBase.sol";

import "./ICurveFiCurve.sol";

import "./Constants.sol";

contract OpenShortDAI is ICallee, DydxFlashloanBase, DssActionsBase {
    // LeveragedShortDAI Params
    struct OSDParams {
        uint256 cdpId; // CDP Id to leverage
        uint256 initialMargin; // Initial amount of USDC
        uint256 flashloanAmount; // Amount of DAI flashloaned
        address curvePool;
    }

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        OSDParams memory osdp = abi.decode(data, (OSDParams));

        // Step 1.
        // Converts Flashloaned DAI to USDC on CurveFi
        // DAI = 0 index, USDC = 1 index
        require(
            IERC20(Constants.DAI).approve(osdp.curvePool, osdp.flashloanAmount),
            "erc20-approve-curvepool-failed"
        );

        ICurveFiCurve(osdp.curvePool).exchange_underlying(
            int128(0),
            int128(1),
            osdp.flashloanAmount,
            0
        );

        // Step 2.
        // Locks up USDC and borrow just enough DAI to repay flashloan
        uint256 supplyAmount = IERC20(Constants.USDC).balanceOf(address(this));
        uint256 borrowAmount = osdp.flashloanAmount.add(_getRepaymentAmount());
        _lockGemAndDraw(osdp.cdpId, supplyAmount, borrowAmount);
    }

    function flashloanAndOpen(
        address _sender,
        address _solo,
        address _curvePool,
        uint256 _cdpId,
        uint256 _initialMargin,
        uint256 _flashloanAmount
    ) external {
        ISoloMargin solo = ISoloMargin(_solo);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(_solo, Constants.DAI);

        // Calculate repay amount (_flashloanAmount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _flashloanAmount.add(_getRepaymentAmount());
        IERC20(Constants.DAI).approve(_solo, repayAmount);

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _flashloanAmount);
        operations[1] = _getCallAction(
            // Encode OSDParams for callFunction
            abi.encode(
                OSDParams({
                    initialMargin: _initialMargin,
                    flashloanAmount: _flashloanAmount,
                    cdpId: _cdpId,
                    curvePool: _curvePool
                })
            )
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);

        // Refund user any ERC20 leftover
        IERC20(Constants.DAI).transfer(
            _sender,
            IERC20(Constants.DAI).balanceOf(address(this))
        );
        IERC20(Constants.USDC).transfer(
            _sender,
            IERC20(Constants.USDC).balanceOf(address(this))
        );
    }
}
