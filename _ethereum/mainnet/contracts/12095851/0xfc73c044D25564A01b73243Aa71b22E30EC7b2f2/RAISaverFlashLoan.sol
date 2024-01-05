pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./RAISaverTaker.sol";
import "./RAISaverProxy.sol";
import "./ISoloMargin.sol";
import "./DFSExchangeCore.sol";

contract RAISaverFlashLoan is RAISaverProxy, AdminAuth {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function callFunction(
        address,
        Account.Info memory,
        bytes memory _params
    ) public {

        (
            bytes memory exDataBytes ,
            RAISaverTaker.SaverData memory saverData
        )
         = abi.decode(_params, (bytes, RAISaverTaker.SaverData));


        ExchangeData memory exchangeData = unpackExchangeData(exDataBytes);

        address managerAddr = getManagerAddr(saverData.managerType);
        address userProxy = ISAFEManager(managerAddr).ownsSAFE(saverData.safeId);

        if (saverData.isRepay) {
            repayWithLoan(exchangeData, saverData);
        } else {
            boostWithLoan(exchangeData, saverData);
        }

        // payback FL, assumes we have weth
        TokenInterface(WETH_ADDR).deposit{value: (address(this).balance)}();
        ERC20(WETH_ADDR).safeTransfer(userProxy, (saverData.flAmount + 2));
    }

    function boostWithLoan(
        ExchangeData memory _exchangeData,
        RAISaverTaker.SaverData memory _saverData
    ) internal {

        address managerAddr = getManagerAddr(_saverData.managerType);
        address user = getOwner(ISAFEManager(managerAddr), _saverData.safeId);
        bytes32 collType = ISAFEManager(managerAddr).collateralTypes(_saverData.safeId);

        addCollateral(managerAddr, _saverData.safeId, _saverData.joinAddr, _saverData.flAmount, false);

        // Draw users Rai
        uint raiDrawn = drawRai(managerAddr, _saverData.safeId, collType, _exchangeData.srcAmount);

        // Swap
        _exchangeData.srcAmount = raiDrawn - takeFee(_saverData.gasCost, raiDrawn);
        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;

        (, uint swapedAmount) = _sell(_exchangeData);

        // Return collateral
        addCollateral(managerAddr, _saverData.safeId, _saverData.joinAddr, swapedAmount, true);
        // Draw collateral to repay the flash loan
        drawCollateral(managerAddr, _saverData.safeId, _saverData.joinAddr, _saverData.flAmount, false);

        logger.Log(address(this), msg.sender, "RAIFlashBoost", abi.encode(_saverData.safeId, user, _exchangeData.srcAmount, swapedAmount));
    }

    function repayWithLoan(
        ExchangeData memory _exchangeData,
        RAISaverTaker.SaverData memory _saverData
    ) internal {

        TokenInterface(WETH_ADDR).withdraw(_saverData.flAmount);

        address managerAddr = getManagerAddr(_saverData.managerType);

        address user = getOwner(ISAFEManager(managerAddr), _saverData.safeId);
        bytes32 collType = ISAFEManager(managerAddr).collateralTypes(_saverData.safeId);

        // Swap
        _exchangeData.srcAmount = _saverData.flAmount;
        _exchangeData.user = user;

        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;

        (, uint paybackAmount) = _sell(_exchangeData);

        paybackAmount -= takeFee(_saverData.gasCost, paybackAmount);
        paybackAmount = limitLoanAmount(managerAddr, _saverData.safeId, collType, paybackAmount, user);

        // Payback the debt
        paybackDebt(managerAddr, _saverData.safeId, collType, paybackAmount, user);

        // Draw collateral to repay the flash loan
        drawCollateral(managerAddr, _saverData.safeId, _saverData.joinAddr, _saverData.flAmount, false);

        logger.Log(address(this), msg.sender, "RAIFlashRepay", abi.encode(_saverData.safeId, user, _exchangeData.srcAmount, paybackAmount));
    }

    /// @notice Handles that the amount is not bigger than cdp debt and not dust
    function limitLoanAmount(address _managerAddr, uint _safeId, bytes32 _collType, uint _paybackAmount, address _owner) internal returns (uint256) {
        uint debt = getAllDebt(address(safeEngine), ISAFEManager(_managerAddr).safes(_safeId), ISAFEManager(_managerAddr).safes(_safeId), _collType);

        if (_paybackAmount > debt) {
            ERC20(RAI_ADDRESS).transfer(_owner, (_paybackAmount - debt));
            return debt;
        }

        uint debtLeft = debt - _paybackAmount;

        (,,,, uint dust,) = safeEngine.collateralTypes(_collType);
        dust = dust / 10**27;

        // Less than dust value
        if (debtLeft < dust) {
            uint amountOverDust = (dust - debtLeft);

            ERC20(RAI_ADDRESS).transfer(_owner, amountOverDust);

            return (_paybackAmount - amountOverDust);
        }

        return _paybackAmount;
    }

    receive() external override(DFSExchangeCore) payable {}

}
