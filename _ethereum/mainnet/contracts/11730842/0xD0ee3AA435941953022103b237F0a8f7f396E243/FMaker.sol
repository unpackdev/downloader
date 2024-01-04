// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./CMaker.sol";
import "./CInstaDapp.sol";
import "./ITokenJoinInterface.sol";
import "./IMcdManager.sol";
import "./IInstaDapp.sol";
import "./IVat.sol";
import "./DSMath.sol";
import "./Convert.sol";

function _getMakerVaultDebt(uint256 _vaultId) view returns (uint256 wad) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 rad = sub(mul(art, rate), dai);
    wad = rad / RAY;

    wad = mul(wad, RAY) < rad ? wad + 1 : wad;
}

function _getMakerRawVaultDebt(uint256 _vaultId) view returns (uint256 tab) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);

    uint256 rad = mul(art, rate);

    tab = rad / RAY;
    tab = mul(tab, RAY) < rad ? tab + 1 : tab;
}

function _getMakerVaultCollateralBalance(uint256 _vaultId)
    view
    returns (uint256)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    IVat vat = IVat(manager.vat());
    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    (uint256 ink, ) = vat.urns(ilk, urn);

    return ink;
}

function _vaultWillBeSafe(
    uint256 _vaultId,
    uint256 _colAmt,
    uint256 _daiDebtAmt
) view returns (bool) {
    require(_vaultId != 0, "_vaultWillBeSafe: invalid vault id.");

    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);

    ITokenJoinInterface tokenJoinContract =
        ITokenJoinInterface(InstaMapping(INSTA_MAPPING).gemJoinMapping(ilk));

    IVat vat = IVat(manager.vat());
    (, uint256 rate, uint256 spot, , ) = vat.ilks(ilk);
    (uint256 ink, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 dink = _convertTo18(tokenJoinContract.dec(), _colAmt);
    uint256 dart = _getDebtAmt(_daiDebtAmt, dai, rate);

    ink = add(ink, dink);
    art = add(art, dart);

    uint256 tab = mul(rate, art);

    return tab <= mul(ink, spot);
}

function _newVaultWillBeSafe(
    string memory _colType,
    uint256 _colAmt,
    uint256 _daiDebtAmt
) view returns (bool) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (, uint256 rate, uint256 spot, , ) = vat.ilks(ilk);

    ITokenJoinInterface tokenJoinContract =
        ITokenJoinInterface(InstaMapping(INSTA_MAPPING).gemJoinMapping(ilk));

    uint256 ink = _convertTo18(tokenJoinContract.dec(), _colAmt);
    uint256 art = _getDebtAmt(_daiDebtAmt, 0, rate);

    uint256 tab = mul(rate, art);

    return tab <= mul(ink, spot);
}

function _debtCeilingIsReachedNewVault(
    string memory _colType,
    uint256 _daiDebtAmt
) view returns (bool) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (uint256 Art, uint256 rate, , uint256 line, ) = vat.ilks(ilk);
    uint256 Line = vat.Line();
    uint256 debt = vat.debt();

    uint256 dart = _getDebtAmt(_daiDebtAmt, 0, rate);
    uint256 dtab = mul(rate, dart);

    debt = add(debt, dtab);
    Art = add(Art, dart);

    return mul(Art, rate) > line || debt > Line;
}

function _debtCeilingIsReached(uint256 _vaultId, uint256 _daiDebtAmt)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);

    (uint256 Art, uint256 rate, , uint256 line, ) = vat.ilks(ilk);
    uint256 dai = vat.dai(urn);
    uint256 Line = vat.Line();
    uint256 debt = vat.debt();

    uint256 dart = _getDebtAmt(_daiDebtAmt, dai, rate);
    uint256 dtab = mul(rate, dart);

    debt = add(debt, dtab);
    Art = add(Art, dart);

    return mul(Art, rate) > line || debt > Line;
}

function _debtIsDustNewVault(string memory _colType, uint256 _daiDebtAmt)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (, uint256 rate, , , uint256 dust) = vat.ilks(ilk);
    uint256 art = _getDebtAmt(_daiDebtAmt, 0, rate);

    uint256 tab = mul(rate, art);

    return tab < dust;
}

function _debtIsDust(uint256 _vaultId, uint256 _daiDebtAmt)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    (, uint256 art) = vat.urns(ilk, urn);
    (, uint256 rate, , , uint256 dust) = vat.ilks(ilk);

    uint256 dai = vat.dai(urn);
    uint256 dart = _getDebtAmt(_daiDebtAmt, dai, rate);
    art = add(art, dart);
    uint256 tab = mul(rate, art);

    return tab < dust;
}

function _getVaultData(IMcdManager _manager, uint256 _vault)
    view
    returns (bytes32 ilk, address urn)
{
    ilk = _manager.ilks(_vault);
    urn = _manager.urns(_vault);
}

function _getDebtAmt(
    uint256 _amt,
    uint256 _dai,
    uint256 _rate
) pure returns (uint256 dart) {
    dart = sub(mul(_amt, RAY), _dai) / _rate;
    dart = mul(dart, _rate) < mul(_amt, RAY) ? dart + 1 : dart;
}

function _isVaultOwner(uint256 _vaultId, address _owner) view returns (bool) {
    if (_vaultId == 0) return false;

    try IMcdManager(MCD_MANAGER).owns(_vaultId) returns (address owner) {
        return _owner == owner;
    } catch Error(string memory error) {
        revert(string(abi.encodePacked("FMaker._isVaultOwner:", error)));
    } catch {
        revert("FMaker._isVaultOwner:undefined");
    }
}
