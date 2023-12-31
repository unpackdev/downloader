// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Errors.sol";
import "./IInitializable.sol";
import "./DABotCommon.sol";
import "./IDABot.sol";
import "./IBotTemplateController.sol";
import "./StorageSlot.sol";

import "./Strings.sol";

contract BotTokenProxy is IDABotComponent {

    bytes32 internal constant _BOT_SLOT = 0x84cd0839c5432c05dfc85be460bd2c37dfb6394383a0e3e821818b5ea2e2d509;

    bytes32 public immutable IMPL_MODULE_ID;
    string public name;

    constructor(string memory _name, bytes32 implModuleId) {
        IMPL_MODULE_ID = implModuleId;
        name = _name;
    }

    function moduleInfo() external view override virtual
        returns(string memory, string memory, bytes32)
    {
        return (string(abi.encodePacked(name, " (BotTokenProxy)")), "v0.1.20220401", IMPL_MODULE_ID);
    }

    function _fallback() internal virtual {
        address bot = _getBot();
        require(bot != address(0),
                string(abi.encodePacked('proxy method ', 
                    Strings.toHexString(uint32(msg.sig), 4), 
                    ': BotTokenProxy not initialized'))
            );
        _delegate(_getImpl(bot));
    }

    function _delegate(address implementation) internal virtual {
        require(implementation != address(0), "BotTokenProxy: impl module not found");
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function init(bytes calldata data) external payable {
        require(_getBot()  == address(0), Errors.CM_CONTRACT_HAS_BEEN_INITIALIZED);
        (address bot) = abi.decode(data, (address));
        _setBot(bot);
        _delegate(_getImpl(bot));
    }

    function _getImpl(address _bot) private view returns (address impl) {
        IDABot bot = IDABot(_bot);
        BotMetaData memory meta = bot.metadata();
        return IBotTemplateController(meta.botTemplate).module(IMPL_MODULE_ID);
    }

    function _getBot() private view returns(address) {
        return StorageSlot.getAddressSlot(_BOT_SLOT).value;
    }

    function _setBot(address bot) private {
        StorageSlot.getAddressSlot(_BOT_SLOT).value = bot;
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }
}
