// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./VaultBase.sol";

contract BotVaultManager is VaultBase, IBotVaultManagerEvent, Initializable {

    using Address for address;
    using SafeERC20 for IERC20;

    fallback() external payable {
        uint vID;
        bytes memory _data = msg.data;
        assembly {
            vID := mload(add(_data, 36))
        }
        __fallback(vID);
    }

    function __fallback(uint vID) private _validVault(vID) {
        address handler = data().vaultHandlers[_vaultOf(vID).data.vaultType];
        if (handler != address(0)) {
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(gas(), handler, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                } 
            }
        }
    }

    receive() external payable {}

    function initialize() external payable initializer {
        _transferOwnership(_msgSender());
    }

    function vaultId(address botToken, uint8 vaultIndex) public pure returns(uint) {
        return _vaultId(botToken, vaultIndex);
    }

    function validVault(uint vID) external view returns(bool) {
        Vault storage vault = _vaultOf(vID);
        return vault.data.botToken != address(0) &&
            vault.data.vaultType != 0;
    }

    function createVault(VaultData calldata data) external botOnly returns(uint vID) {
        vID = vaultId(data.botToken, data.index); 
        Vault storage vault = _vaultOf(vID);

        if (vault.data.botToken != address(0)) {
            require(vault.data.botToken == data.botToken &&
                    vault.data.asset == data.asset &&
                    vault.data.bot == data.bot, Errors.VM_VAULT_EXISTS);
            return vID;
        }
        vault.data = data;
        vault.lastRewardTime = block.timestamp;
        emit OpenVault(vID, data);
    }

    function destroyVault(uint vID) external _validVault(vID) ownedBotOnly(vID) {
        VaultManagerData storage _data = data();
        delete _data.vaults[vID];
        emit DestroyVault(vID);
    }

    function registerHandler(bytes4 vaultType, address handler) external onlyOwner {
        VaultManagerData storage _data = data();
        _data.vaultHandlers[vaultType] = handler;
        emit RegisterHandler(vaultType, handler);
    }

    function handlerOf(bytes4 vaultType) external view returns(address) {
        return data().vaultHandlers[vaultType];
    }

    function botManager() external view returns(address) {
        VaultManagerData storage _data = data();
        return address(_data.botManager);
    }

    function setBotManager(IDABotManager botManager_) public onlyOwner {
        VaultManagerData storage _data = data();
        _data.botManager = botManager_;
        emit BotManagerUpdated(address(botManager_)); 
    }

    function vaultOf(uint vID) external view returns(VaultData memory result) {
        Vault storage vault = _vaultOf(vID);
        return vault.data;
    }
}