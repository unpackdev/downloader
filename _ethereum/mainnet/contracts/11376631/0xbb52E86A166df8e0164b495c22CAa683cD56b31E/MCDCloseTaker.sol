pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MCDSaverProxy.sol";
import "./DefisaverLogger.sol";
import "./ILendingPool.sol";
import "./DFSExchangeData.sol";


abstract contract IMCDSubscriptions {
    function unsubscribe(uint256 _cdpId) external virtual ;

    function subscribersPos(uint256 _cdpId) external virtual returns (uint256, bool);
}


contract MCDCloseTaker is MCDSaverProxyHelper {

    address public constant SUBSCRIPTION_ADDRESS_NEW = 0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // solhint-disable-next-line const-name-snakecase
    Manager public constant manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(DEFISAVER_LOGGER);

    struct CloseData {
        uint cdpId;
        address joinAddr;
        uint collAmount;
        uint daiAmount;
        uint minAccepted;
        bool wholeDebt;
        bool toDai;
    }

    Vat public constant vat = Vat(VAT_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    function closeWithLoan(
        DFSExchangeData.ExchangeData memory _exchangeData,
        CloseData memory _closeData,
        address payable mcdCloseFlashLoan
    ) public payable {
        mcdCloseFlashLoan.transfer(msg.value); // 0x fee

        if (_closeData.wholeDebt) {
            _closeData.daiAmount = getAllDebt(
                VAT_ADDRESS,
                manager.urns(_closeData.cdpId),
                manager.urns(_closeData.cdpId),
                manager.ilks(_closeData.cdpId)
            );

            (_closeData.collAmount, )
                = getCdpInfo(manager, _closeData.cdpId, manager.ilks(_closeData.cdpId));
        }

        manager.cdpAllow(_closeData.cdpId, mcdCloseFlashLoan, 1);

        bytes memory packedData  = _packData(_closeData, _exchangeData);
        bytes memory paramsData = abi.encode(address(this), packedData);

        lendingPool.flashLoan(mcdCloseFlashLoan, DAI_ADDRESS, _closeData.daiAmount, paramsData);

        manager.cdpAllow(_closeData.cdpId, mcdCloseFlashLoan, 0);

        // If sub. to automatic protection unsubscribe
        unsubscribe(SUBSCRIPTION_ADDRESS_NEW, _closeData.cdpId);

        logger.Log(address(this), msg.sender, "MCDClose", abi.encode(_closeData.cdpId, _closeData.collAmount, _closeData.daiAmount, _closeData.toDai));
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(uint256 _cdpId, bytes32 _ilk) public view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(_ilk);
        (, , uint256 spot, , ) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    function unsubscribe(address _subContract, uint _cdpId) internal {
        (, bool isSubscribed) = IMCDSubscriptions(_subContract).subscribersPos(_cdpId);

        if (isSubscribed) {
            IMCDSubscriptions(_subContract).unsubscribe(_cdpId);
        }
    }

    function _packData(
        CloseData memory _closeData,
        DFSExchangeData.ExchangeData memory _exchangeData
    ) internal pure returns (bytes memory) {

        return abi.encode(_closeData, _exchangeData);
    }

}
