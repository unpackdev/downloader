// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoConditionsStandard.sol";
import "./GelatoBytes.sol";
import "./FIsDebtAmtDust.sol";
import "./FMaker.sol";

contract ConditionDebtAmtIsDust is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    function getConditionData(
        address _dsa,
        uint256 _fromVaultId,
        uint256 _destVaultId,
        string calldata _destColType
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.isDebtAmtDust.selector,
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

        return isDebtAmtDust(_dsa, _fromVaultId, _destVaultId, _destColType);
    }

    function isDebtAmtDust(
        address _dsa,
        uint256 _fromVaultId,
        uint256 _destVaultId,
        string memory _destColType
    ) public view returns (string memory) {
        return
            _isDebtAmtDust(
                _dsa,
                _destVaultId,
                _destColType,
                _getMakerVaultDebt(_fromVaultId)
            )
                ? "DebtAmtIsDust"
                : OK;
    }
}
