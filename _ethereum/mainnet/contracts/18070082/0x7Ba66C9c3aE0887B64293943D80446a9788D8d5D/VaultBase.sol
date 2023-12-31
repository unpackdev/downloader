// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Arrays.sol";
import "./SafeERC20.sol";
import "./IRoboFiERC20.sol";
import "./Ownable.sol";
import "./Errors.sol";
import "./IDABotManager.sol";
import "./IBotVault.sol";

interface IBotToken {
    function owner() external view returns(address);
}

abstract contract VaultBase is Context, Ownable {

    using Arrays for uint[];
    using SafeERC20 for IERC20;

    struct DepositSnapshots {
        uint[] ids;
        uint[] values;
    }

    struct Vault {
        VaultData data;
        uint totalDeposit;
        uint totalDebtPoint;
        uint accRewardPerShare;
        uint lastRewardTime;
        mapping(address => UserInfo) users;
        mapping(address => DepositSnapshots) userDepositSnapshots;
        uint currentSnapshotId;
    }

    struct VaultManagerData {
        IDABotManager botManager;
        mapping(uint => Vault) vaults;
        mapping(bytes4 => address) vaultHandlers;
    }

    modifier botOnly() {
        require(data().botManager.isRegisteredBot(_msgSender()), Errors.VB_CALLER_IS_NOT_DABOT);
        _;
    }

    modifier ownedBotOnly(uint vID) {
        Vault storage vault = _vaultOf(vID);
        require(IBotToken(vault.data.botToken).owner() == _msgSender(), Errors.VB_CALLER_IS_NOT_OWNER_BOT);
        _;
    }

    modifier _validVault(uint vID) {
        require(__isValidVaultId(vID), string(abi.encodePacked(Errors.VB_INVALID_VAULT_ID, Strings.toHexString(vID, 32))));
        _;
    }

    bytes32 constant VAULT_MANAGER_SLOT = keccak256('vault.manager');

    function data() internal pure returns(VaultManagerData storage ds) {
        bytes32 position = VAULT_MANAGER_SLOT;
        assembly {
            ds.slot := position
        }
    }

    function _vaultId(address botToken, uint8 vaultIndex) internal pure returns(uint) {
        return (uint160(botToken) << 8) | uint(vaultIndex);
    }

    function _vaultOf(uint vID) internal view returns(Vault storage) {
        return data().vaults[vID];
    }

    function _vaultHandler(uint vID) internal view returns(address result) {
        result = data().vaultHandlers[_vaultOf(vID).data.vaultType];
        require(address(result) != address(0), Errors.VB_INVALID_VAULT_TYPE);
    }

    function __isValidVaultId(uint vID) internal view returns(bool) {
        Vault storage vault = _vaultOf(vID);
        return vault.data.botToken != address(0);
    }

    function getUserInfo(uint vID, address account) external view returns(UserInfo memory result) {
        Vault storage vault = _vaultOf(vID);
        return vault.users[account];
    }

    function balanceOf(uint vID, address account) external view returns(uint) {
        Vault storage vault = _vaultOf(vID);
        if (vault.data.botToken == address(0))
            return 0;
        return vault.users[account].deposit;
    }

    function balanceOfAt(uint vID, address account, uint snapshotId) external view returns(uint) {
        Vault storage vault = _vaultOf(vID);
        if (snapshotId > vault.currentSnapshotId || snapshotId == 0)
            return vault.users[account].deposit;
        DepositSnapshots storage snapshots = vault.userDepositSnapshots[account];
        uint index = snapshots.ids.findUpperBound(snapshotId);
        if (index == snapshots.ids.length)
            return vault.users[account].deposit;
        return snapshots.values[index];
    }
}