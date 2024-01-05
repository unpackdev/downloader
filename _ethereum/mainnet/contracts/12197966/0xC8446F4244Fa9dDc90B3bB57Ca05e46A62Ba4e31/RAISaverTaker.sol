pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./RAISaverProxy.sol";
import "./DFSExchangeData.sol";
import "./GasBurner.sol";
import "./ILendingPool.sol";
import "./DydxFlashLoanBase.sol";

contract RAISaverTaker is RAISaverProxy, DydxFlashLoanBase, GasBurner {
    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct SaverData {
        uint256 flAmount;
        bool isRepay;
        uint256 safeId;
        uint256 gasCost;
        address joinAddr;
        ManagerType managerType;
    }

    function boostWithLoan(
        ExchangeData memory _exchangeData,
        uint256 _safeId,
        uint256 _gasCost,
        address _joinAddr,
        ManagerType _managerType,
        address _raiSaverFlashLoan
    ) public payable burnGas(25) {
        address managerAddr = getManagerAddr(_managerType);

        uint256 maxDebt =
            getMaxDebt(managerAddr, _safeId, ISAFEManager(managerAddr).collateralTypes(_safeId));

        if (maxDebt >= _exchangeData.srcAmount) {
            if (_exchangeData.srcAmount > maxDebt) {
                _exchangeData.srcAmount = maxDebt;
            }

            boost(_exchangeData, _safeId, _gasCost, _joinAddr, _managerType);
            return;
        }

        uint256 loanAmount = getAvailableEthLiquidity();

        SaverData memory saverData =
            SaverData({
                flAmount: loanAmount,
                isRepay: false,
                safeId: _safeId,
                gasCost: _gasCost,
                joinAddr: _joinAddr,
                managerType: _managerType
            });

        _flashLoan(_raiSaverFlashLoan, _exchangeData, saverData);
    }

    function repayWithLoan(
        ExchangeData memory _exchangeData,
        uint256 _safeId,
        uint256 _gasCost,
        address _joinAddr,
        ManagerType _managerType,
        address _raiSaverFlashLoan
    ) public payable burnGas(25) {
        address managerAddr = getManagerAddr(_managerType);

        uint256 maxColl =
            getMaxCollateral(
                managerAddr,
                _safeId,
                ISAFEManager(managerAddr).collateralTypes(_safeId),
                _joinAddr
            );

        if (maxColl >= _exchangeData.srcAmount) {
            if (_exchangeData.srcAmount > maxColl) {
                _exchangeData.srcAmount = maxColl;
            }

            repay(_exchangeData, _safeId, _gasCost, _joinAddr, _managerType);
            return;
        }

        uint256 loanAmount = _exchangeData.srcAmount;

        SaverData memory saverData =
            SaverData({
                flAmount: loanAmount,
                isRepay: true,
                safeId: _safeId,
                gasCost: _gasCost,
                joinAddr: _joinAddr,
                managerType: _managerType
            });

        _flashLoan(_raiSaverFlashLoan, _exchangeData, saverData);
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _managerAddr Address of the CDP Manager
    /// @param _safeId Id of the CDP
    /// @param _collType Coll type of the CDP
    function getMaxDebt(
        address _managerAddr,
        uint256 _safeId,
        bytes32 _collType
    ) public override view returns (uint256) {
        (uint256 collateral, uint256 debt) =
            getSafeInfo(ISAFEManager(_managerAddr), _safeId, _collType);

        (, , uint256 safetyPrice, , , ) =
            ISAFEEngine(SAFE_ENGINE_ADDRESS).collateralTypes(_collType);

        return sub(rmul(collateral, safetyPrice), debt);
    }

    /// @notice Fetches Eth Dydx liqudity
    function getAvailableEthLiquidity() internal view returns (uint256 liquidity) {
        liquidity = ERC20(WETH_ADDR).balanceOf(SOLO_MARGIN_ADDRESS);
    }

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must send 2 wei with this transaction
    function _flashLoan(address RAI_SAVER_FLASH_LOAN, ExchangeData memory _exchangeData, SaverData memory _saverData) internal {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        address managerAddr = getManagerAddr(_saverData.managerType);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_saverData.flAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _saverData.flAmount, RAI_SAVER_FLASH_LOAN);
        payable(RAI_SAVER_FLASH_LOAN).transfer(msg.value); // 0x fee

        bytes memory exchangeData = packExchangeData(_exchangeData);
        operations[1] = _getCallAction(abi.encode(exchangeData, _saverData), RAI_SAVER_FLASH_LOAN);

        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        ISAFEManager(managerAddr).allowSAFE(_saverData.safeId, RAI_SAVER_FLASH_LOAN, 1);
        solo.operate(accountInfos, operations);
        ISAFEManager(managerAddr).allowSAFE(_saverData.safeId, RAI_SAVER_FLASH_LOAN, 0);
    }
}
