// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./IVariableTokenRecords.sol";
import "./BalanceManagement.sol";
import "./Errors.sol";


contract VariableTokenRecords is BalanceManagement, IVariableTokenRecords {

    error OnlyActionExecutorError();

    address public actionExecutor;

    // Keys: account address, vault type
    mapping(address => mapping(uint256 => uint256)) public variableTokenBalanceTable;
    mapping(address => mapping(uint256 => uint256)) public fallbackCountTable;

    constructor(
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    ) {
        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    modifier onlyActionExecutor {
        if (msg.sender != actionExecutor) {
            revert OnlyActionExecutorError();
        }

        _;
    }

    function setActionExecutor(address _actionExecutor) external onlyManager {
        actionExecutor = _actionExecutor;
    }

    function increaseBalance(
        address _account,
        uint256 _vaultType,
        uint256 _tokenAmount,
        bool _isFallback
    )
        external
        onlyActionExecutor
    {
        variableTokenBalanceTable[_account][_vaultType] += _tokenAmount;

        if (_isFallback) {
            fallbackCountTable[_account][_vaultType]++;
        }
    }

    function clearBalance(address _account, uint256 _vaultType) external onlyActionExecutor {
        variableTokenBalanceTable[_account][_vaultType] = 0;
        fallbackCountTable[_account][_vaultType] = 0;
    }

    function getAccountState(address _account, uint256 _vaultType)
        external
        view
        returns(uint256 balance, uint256 fallbackCount)
    {
        balance = variableTokenBalanceTable[_account][_vaultType];
        fallbackCount = fallbackCountTable[_account][_vaultType];
    }

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress =
            _ownerAddress == address(0) ?
                msg.sender :
                _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}
