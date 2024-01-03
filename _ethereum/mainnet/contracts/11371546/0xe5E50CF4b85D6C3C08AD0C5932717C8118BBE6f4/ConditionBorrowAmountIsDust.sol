// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./GelatoConditionsStandard.sol";
import "./GelatoBytes.sol";
import "./FMaker.sol";

contract ConditionBorrowAmountIsDust is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    function getConditionData(
        address _dsa,
        uint256 _fromVaultId,
        uint256 _destVaultId,
        string calldata _destColType
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.isBorrowAmountDust.selector,
                _dsa,
                _fromVaultId,
                _destVaultId,
                _destColType
            );
    }

    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (
            address _dsa,
            uint256 _fromVaultId,
            uint256 _destVaultId,
            string memory _destColType
        ) = abi.decode(_conditionData[4:], (address, uint256, uint256, string));

        return
            isBorrowAmountDust(_dsa, _fromVaultId, _destVaultId, _destColType);
    }

    function isBorrowAmountDust(
        address _dsa,
        uint256 _fromVaultId,
        uint256 _destVaultId,
        string memory _destColType
    ) public view returns (string memory) {
        _destVaultId = _isVaultOwner(_destVaultId, _dsa) ? _destVaultId : 0;

        uint256 wDaiToBorrow = _getMakerVaultDebt(_fromVaultId);

        return
            borrowAmountIsDustExplicit(_destVaultId, wDaiToBorrow, _destColType)
                ? "DebtNotGreaterThanDust"
                : OK;
    }

    function borrowAmountIsDustExplicit(
        uint256 _vaultId,
        uint256 _wDaiToBorrow,
        string memory _colType
    ) public view returns (bool) {
        return
            _vaultId == 0
                ? _debtIsDustNewVault(_colType, _wDaiToBorrow)
                : _debtIsDust(_vaultId, _wDaiToBorrow);
    }
}
