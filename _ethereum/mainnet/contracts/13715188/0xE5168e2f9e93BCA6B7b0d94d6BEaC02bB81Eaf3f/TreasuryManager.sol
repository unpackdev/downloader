// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ITreasuryManager.sol";
import "./LazyInitCapableElement.sol";
import "./GeneralUtilities.sol";
import "./KnowledgeBase.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

contract TreasuryManager is ITreasuryManager, IERC721Receiver, IERC1155Receiver, LazyInitCapableElement {
    using ReflectionUtilities for address;
    using Uint256Utilities for uint256;

    bytes32 private constant INTERNAL_SELECTOR_MANAGER_SALT = 0x93e9e71b539687571ead6f20e97c4672f2b76a6b58dd6502ea8a456e2f0cd2c7;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns(bytes memory) {
        if(lazyInitData.length > 0) {
            (bytes4[] memory selectors, address[] memory locations) = abi.decode(lazyInitData, (bytes4[], address[]));
            require(selectors.length == locations.length, "length");
            for(uint256 i = 0; i < selectors.length; i++) {
                _setAdditionalFunction(selectors[i], locations[i], true);
            }
        }
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override view returns(bool) {
        return
            interfaceId == type(ITreasuryManager).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == this.onERC1155Received.selector ||
            interfaceId == this.onERC1155BatchReceived.selector ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == this.onERC721Received.selector ||
            interfaceId == 0x00000000 ||
            interfaceId == this.transfer.selector ||
            interfaceId == this.batchTransfer.selector ||
            interfaceId == this.setAdditionalFunction.selector ||
            (additionalFunctionsServerManager().isContract() && AdditionalFunctionsServerManager(additionalFunctionsServerManager()).get(interfaceId) != address(0));
    }

    receive() external payable {
        (bool result, bytes memory returnData) = _trySandboxedCall(false);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    fallback() authorizedOnly external payable {
        (bool result, bytes memory returnData) = _trySandboxedCall(true);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function transfer(address token, uint256 value, address receiver, uint256 tokenType, uint256 objectId, bool safe, bool withData, bytes calldata data) external override authorizedOnly returns(bool result, bytes memory returnData) {
        (result, returnData) = _trySandboxedCall(false);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
        (result, returnData) = _transfer(TransferEntry(token, tokenType == 0 ? new uint256[](0) : objectId.asSingletonArray(), tokenType == 1 ? new uint256[](0) : value.asSingletonArray(), receiver, safe, false, withData, data));
    }

    function batchTransfer(TransferEntry[] calldata transferEntries) external override authorizedOnly returns(bool[] memory results, bytes[] memory returnDatas) {
        (bool result, bytes memory returnData) = _trySandboxedCall(false);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
        results = new bool[](transferEntries.length);
        returnDatas = new bytes[](transferEntries.length);
        for(uint256 i = 0; i < transferEntries.length; i++) {
            (results[i], returnDatas[i]) = _transfer(transferEntries[i]);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        (bool result, bytes memory returnData) = _trySandboxedCall(false);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override returns(bytes4) {
        (bool result, bytes memory returnData) = _trySandboxedCall(false);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address , address, uint256[] calldata, uint256[] calldata, bytes calldata) external override returns (bytes4) {
        (bool result, bytes memory returnData) = _trySandboxedCall(false);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
        return this.onERC1155BatchReceived.selector;
    }

    function setAdditionalFunction(bytes4 selector, address newServer, bool log) external override authorizedOnly returns (address oldServer) {
        (bool result, bytes memory returnData) = _trySandboxedCall(false);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
        oldServer = _setAdditionalFunction(selector, newServer, log);
    }

    function submit(address location, bytes calldata payload, address restReceiver) override authorizedOnly external payable returns(bytes memory response) {
        (bool result, bytes memory returnData) = _trySandboxedCall(false);
        if(result) {
            assembly {
                return(add(returnData, 0x20), mload(returnData))
            }
        }
        uint256 oldBalance = address(this).balance - msg.value;
        response = location.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }

    function additionalFunctionsServerManager() public view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            INTERNAL_SELECTOR_MANAGER_SALT,
            keccak256(type(AdditionalFunctionsServerManager).creationCode)
        )))));
    }

    function _setAdditionalFunction(bytes4 selector, address newServer, bool log) private returns (address oldServer) {
        oldServer = _getOrCreateAdditionalFunctionsServerManager().set(selector, newServer);
        if(log) {
            emit AdditionalFunction(msg.sender, selector, oldServer, newServer);
        }
    }

    function _transfer(TransferEntry memory transferEntry) private returns(bool result, bytes memory returnData) {
        if(transferEntry.values.length == 0 && transferEntry.objectIds.length == 0) {
            return (result, returnData);
        }
        if(transferEntry.token == address(0)) {
            if(transferEntry.values.length != 0 && transferEntry.values[0] != 0) {
                returnData = transferEntry.receiver.submit(transferEntry.values[0], "");
                result = true;
            }
            return (result, returnData);
        }
        if(transferEntry.objectIds.length == 0) {
            if(transferEntry.values.length != 0 && transferEntry.values[0] != 0) {
                returnData = transferEntry.token.submit(0, abi.encodeWithSelector(IERC20(address(0)).transfer.selector, transferEntry.receiver, transferEntry.values[0]));
                result = true;
            }
            return (result, returnData);
        }
        if(transferEntry.values.length == 0) {
            if(!transferEntry.safe) {
                returnData = transferEntry.token.submit(0, abi.encodeWithSelector(IERC721(address(0)).transferFrom.selector, address(this), transferEntry.receiver, transferEntry.objectIds[0]));
                result = true;
                return (result, returnData);
            }
            if(transferEntry.withData) {
                returnData = transferEntry.token.submit(0, abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", address(this), transferEntry.receiver, transferEntry.objectIds[0], transferEntry.data));
                result = true;
                return (result, returnData);
            }
            returnData = transferEntry.token.submit(0, abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(this), transferEntry.receiver, transferEntry.objectIds[0]));
            result = true;
            return (result, returnData);
        }
        if(transferEntry.batch) {
            returnData = transferEntry.token.submit(0, abi.encodeWithSelector(IERC1155(address(0)).safeBatchTransferFrom.selector, address(this), transferEntry.receiver, transferEntry.objectIds, transferEntry.values, transferEntry.data));
            result = true;
            return (result, returnData);
        }
        if(transferEntry.values[0] != 0) {
            returnData = transferEntry.token.submit(0, abi.encodeWithSelector(IERC1155(address(0)).safeTransferFrom.selector, address(this), transferEntry.receiver, transferEntry.objectIds[0], transferEntry.values[0], transferEntry.data));
            result = true;
        }
    }

    function _trySandboxedCall(bool launchErrorIfNone) internal returns(bool result, bytes memory returnData) {
        AdditionalFunctionsServerManager _additionalFunctionsServerManager = AdditionalFunctionsServerManager(additionalFunctionsServerManager());
        address subject = address(_additionalFunctionsServerManager).isContract() ? _additionalFunctionsServerManager.get(msg.sig) : address(0);
        if(subject == address(0)) {
            require(!launchErrorIfNone, "none");
            return (false, "");
        }
        address _initializer = initializer;
        address _maintainer = host;
        bytes32 reentrancyLockKey = _additionalFunctionsServerManager.setReentrancyLock();
        (result, returnData) = subject.delegatecall(msg.data);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
        initializer = _initializer;
        host = _maintainer;
        require(_additionalFunctionsServerManager.releaseReentrancyLock(reentrancyLockKey) == reentrancyLockKey);
    }

    function _getOrCreateAdditionalFunctionsServerManager() private returns (AdditionalFunctionsServerManager _additionalFunctionsServerManager) {
        _additionalFunctionsServerManager = AdditionalFunctionsServerManager(additionalFunctionsServerManager());
        if(!address(_additionalFunctionsServerManager).isContract()) {
            bytes memory bytecode = type(AdditionalFunctionsServerManager).creationCode;
            bytes32 salt = INTERNAL_SELECTOR_MANAGER_SALT;
            address addr;
            assembly {
                addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            }
        }
    }
}

contract AdditionalFunctionsServerManager {
    address immutable private _creator = msg.sender;
    bytes32 private _reentrancyLockKey;
    uint256 private _keyIndex;
    mapping (bytes4 => address) public get;

    modifier creatorOnly() {
        require(msg.sender == _creator);
        _;
    }

    function set(bytes4 selector, address newServer) external creatorOnly returns (address oldServer) {
        oldServer = get[selector];
        get[selector] = newServer;
    }

    function setReentrancyLock() external creatorOnly returns (bytes32) {
        require(_reentrancyLockKey == bytes32(0));
        return _reentrancyLockKey = BehaviorUtilities.randomKey(_keyIndex++);
    }

    function releaseReentrancyLock(bytes32 reentrancyLockKey) external creatorOnly returns(bytes32 lastReentrancyLockKey) {
        require((lastReentrancyLockKey = _reentrancyLockKey) != bytes32(0) && _reentrancyLockKey == reentrancyLockKey);
        _reentrancyLockKey = bytes32(0);
    }
}