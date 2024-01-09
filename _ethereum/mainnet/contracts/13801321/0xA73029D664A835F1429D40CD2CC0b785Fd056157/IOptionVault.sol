// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IOptionVault {
    enum MarginLevel {
        Maintenance,
        Initial,
        Safe
    }

    struct Expiration {
        uint128 expiryId;
        uint64 expiry;
        uint256[] seriesIds;
    }

    struct OptionSeries {
        uint64 strike;
        bool isPut;
        uint64 iv;
        uint128 expiryId;
    }

    struct Account {
        address owner;
        uint256 settledCount;
        mapping(uint256 => Vault) vaults;
    }

    struct Vault {
        // is settled or not
        bool isSettled;
        // seriesId => short amount
        mapping(uint256 => uint128) shorts;
        // seriesId => long amount
        mapping(uint256 => uint128) longs;
        //
        uint128 collateral;
        //
        int256 hedgePosition;
        //
        uint128 shortLiquidity;
    }

    // view struct

    struct OptionSeriesParams {
        uint256 id;
        uint64 maturity;
        uint128 strike;
        bool isPut;
        uint128 iv;
    }

    struct OptionSeriesView {
        uint256 expiryId;
        uint256 seriesId;
        uint64 expiry;
        uint64 maturity;
        uint128 strike;
        bool isPut;
        uint64 iv;
    }

    struct AccountView {
        address owner;
        uint256 settledCount;
    }

    struct VaultView {
        address owner;
        bool isSettled;
        uint128 collateral;
        int256 hedgePosition;
        uint128 shortLiquidity;
    }

    function getExpiration(uint256 _expiryId) external view returns (IOptionVault.Expiration memory);

    function getOptionSeries(uint256 _seriesId) external view returns (IOptionVault.OptionSeriesView memory);

    function getAccount(uint256 _vaultId) external view returns (AccountView memory);

    function getVault(uint256 _vaultId, uint256 _expiryId) external view returns (VaultView memory);

    function getCollateralValueQuote(uint256 _vaultId) external view returns (uint128);

    function getRequiredMargin(
        uint256 _vaultId,
        uint256 _expiryId,
        IOptionVault.MarginLevel _marginLevel
    ) external view returns (uint128);

    function calRequiredMarginForASeries(
        uint256 _seriesId,
        int128 _amount,
        IOptionVault.MarginLevel _marginLevel
    ) external view returns (uint128);

    function getTotalPayout(uint256 _vaultId, uint256 _expiryId) external view returns (uint128);

    function getPositionSize(uint256 _vaultId, uint256 _seriesId) external view returns (uint128, uint128);

    function getLiveOptionSerieses() external view returns (IOptionVault.Expiration[] memory);

    function getLastExpiry() external view returns (uint64);

    function createAccount() external returns (uint256);

    function setIV(uint256 _seriesId, uint128 _iv) external;

    function deposit(
        uint256 _vaultId,
        uint256 _expiryId,
        uint128 _collateral
    ) external;

    function withdraw(
        uint256 _vaultId,
        uint256 _expiryId,
        uint128 _collateral
    ) external;

    function closeShortPosition(
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _cRatio
    ) external returns (uint128);

    function write(
        uint256 _vaultId,
        uint256 _seriesId,
        uint128 _amount,
        address _recepient
    ) external;

    function depositAndWrite(
        uint256 _vaultId,
        uint256 _seriesId,
        uint128 _collateral,
        uint128 _amount,
        address _recepient
    ) external returns (uint128);

    function settleVault(uint256 _vaultId, uint256 _expiryId) external returns (uint128);

    function claim(uint256 _seriesId, uint128 _size) external returns (uint128);

    function addLong(
        uint256 _vaultId,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _amount
    ) external;

    function removeLong(
        uint256 _vaultId,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _amount
    ) external;

    function calculateVaultDelta(uint256 _vaultId, uint256 _expiryId) external view returns (int256);
}
