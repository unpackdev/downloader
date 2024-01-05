pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MCDSaverProxyHelper.sol";
import "./Spotter.sol";

contract MCDLoanInfo is MCDSaverProxyHelper {

    Manager public constant manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    Vat public constant vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Spotter public constant spotter = Spotter(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    struct VaultInfo {
        address owner;
        uint256 ratio;
    	uint256 collateral;
    	uint256 debt;
    	bytes32 ilk;
    	address urn;
    }

	/// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    /// @notice Gets CDP ratio
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getRatio(uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint price = getPrice( _ilk);

        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        if (debt == 0) return 0;

        return rdiv(wmul(collateral, price), debt);
    }

    /// @notice Gets CDP info (collateral, debt, price, ilk)
    /// @param _cdpId Id of the CDP
    function getVaultInfo(uint _cdpId) public view returns (VaultInfo memory vaultInfo) {
        address urn = manager.urns(_cdpId);
        bytes32 ilk = manager.ilks(_cdpId);

        (uint256 collateral, uint256 debt) = vat.urns(ilk, urn);
        (,uint rate,,,) = vat.ilks(ilk);

        debt = rmul(debt, rate);

        vaultInfo = VaultInfo({
            owner: manager.owns(_cdpId),
            ratio: getRatio(_cdpId, ilk),
            collateral: collateral,
            debt: debt,
            ilk: ilk,
            urn: urn
        });
    }

    function getVaultInfos(uint256[] memory _cdps) public view returns (VaultInfo[] memory vaultInfos) {
    	vaultInfos = new VaultInfo[](_cdps.length);

    	for (uint256 i = 0; i < _cdps.length; i++) {
    		vaultInfos[i] = getVaultInfo(_cdps[i]);
    	}
    }

    function getRatios(uint256[] memory _cdps) public view returns (uint[] memory ratios) {
    	ratios = new uint256[](_cdps.length);

    	for (uint256 i = 0; i<_cdps.length; i++) {
    		bytes32 ilk = manager.ilks(_cdps[i]);

    		ratios[i] = getRatio(_cdps[i], ilk);
    	}
    }
}