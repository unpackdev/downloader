// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./FallbackManager.sol";
import "./ICoreStorage.sol";

import "./Utils.sol";

/// @title Cyan Wallet Core - A Cyan wallet's core features.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract Core is ICoreStorage, IFallbackManager {
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    constructor() ICoreStorage(msg.sender) {}

    /// @notice Initiates new wallet.
    /// @param owner Address of the wallet owner.
    function initiate(address owner) external {
        require(_owner == address(0x0), "Wallet already initialized.");
        require(owner != address(0x0), "Invalid owner address.");

        _owner = owner;
        emit SetOwner(owner);
    }

    /// @notice Main transaction handling method of the wallet.
    ///      Note: All the non-core transactions go through this method.
    /// @param to Destination contract address.
    /// @param value Native token value of the transaction.
    /// @param data Data payload of the transaction.
    /// @return Result of the transaction.
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) public payable onlyDelegateCall onlyOwner returns (bytes memory) {
        require(address(this).balance >= value, "Not enough balance.");
        if (data.length == 0) {
            return Utils._execute(to, value, data);
        }

        bytes4 funcHash = Utils.parseFunctionSelector(data);
        address module = Core(_this).getModule(to, funcHash);
        require(module != address(0x0), "Not supported method.");

        (bool success, bytes memory result) = module.delegatecall(
            abi.encodeWithSignature("handleTransaction(address,uint256,bytes)", to, value, data)
        );
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
        return result;
    }

    function executeBatch(Call[] calldata data) external payable onlyDelegateCall onlyOwner {
        for (uint8 i = 0; i < data.length; ++i) {
            execute(data[i].to, data[i].value, data[i].data);
        }
    }

    /// @inheritdoc IModuleManager
    function executeModule(bytes calldata data) external override onlyDelegateCall onlyOperator returns (bytes memory) {
        bytes4 funcHash = Utils.parseFunctionSelector(data);
        address module = Core(_this).getInternalModule(funcHash);
        require(module != address(0x0), "Not supported method.");

        (bool success, bytes memory result) = module.delegatecall(data);
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
        return result;
    }

    /// @inheritdoc IFallbackManager
    function setFallbackHandler(address handler) external override noDelegateCall onlyAdmin {
        require(handler != address(0x0), "Invalid handler address.");
        _setFallbackHandler(handler);
    }

    fallback() external payable onlyDelegateCall {
        address handler = Core(_this).getFallbackHandler();
        assembly {
            if iszero(handler) {
                return(0, 0)
            }

            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), handler, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if gt(success, 0) {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}
