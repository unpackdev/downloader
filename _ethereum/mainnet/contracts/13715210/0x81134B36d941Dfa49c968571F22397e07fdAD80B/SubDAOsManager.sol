// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ISubDAOsManager.sol";
import "./ISubDAO.sol";
import "./LazyInitCapableElement.sol";
import "./GeneralUtilities.sol";

contract SubDAOsManager is ISubDAOsManager, LazyInitCapableElement {
    using ReflectionUtilities for address;

    mapping(bytes32 => address[]) private _history;
    mapping(address => bytes32) public override keyOf;

    mapping(bytes32 => address) public override get;
    mapping(bytes32 => bool) public override keyExists;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) override internal virtual returns(bytes memory) {
        if(lazyInitData.length > 0) {
            SubDAOEntry[] memory subDaos = abi.decode(lazyInitData, (SubDAOEntry[]));
            for(uint256 i = 0; i < subDaos.length; i++) {
                _set(subDaos[i]);
            }
        }
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) override internal pure returns(bool) {
        return
            interfaceId == type(ISubDAOsManager).interfaceId ||
            interfaceId == this.keyOf.selector ||
            interfaceId == this.history.selector ||
            interfaceId == this.batchHistory.selector ||
            interfaceId == this.get.selector ||
            interfaceId == this.list.selector ||
            interfaceId == this.exists.selector ||
            interfaceId == this.keyExists.selector ||
            interfaceId == this.set.selector ||
            interfaceId == this.batchSet.selector;
    }

    function history(bytes32 key) override external view returns(address[] memory subdaosAddresses) {
        return _history[key];
    }

    function batchHistory(bytes32[] calldata keys) override external view returns(address[][] memory subdaosAddresses) {
        subdaosAddresses = new address[][](keys.length);
        for(uint256 i = 0; i < subdaosAddresses.length; i++) {
            subdaosAddresses[i] = _history[keys[i]];
        }
    }

    function list(bytes32[] calldata keys) override external view returns(address[] memory subdaosAddresses) {
        subdaosAddresses = new address[](keys.length);
        for(uint256 i = 0; i < subdaosAddresses.length; i++) {
            subdaosAddresses[i] = get[keys[i]];
        }
    }

    function exists(address componentAddress) override public view returns(bool) {
        return get[keyOf[componentAddress]] == componentAddress && keyExists[keyOf[componentAddress]];
    }

    function set(bytes32 key, address location, address newHost) override authorizedOnly external returns(address replacedSubdaoAddress) {
        replacedSubdaoAddress = _set(SubDAOEntry(key, location, newHost));
    }

    function batchSet(SubDAOEntry[] calldata subdaos) override authorizedOnly external returns (address[] memory replacedSubdaoAddresses) {
        replacedSubdaoAddresses =  _set(subdaos);
    }

    function submit(bytes32 key, bytes calldata payload, address restReceiver) override authorizedOnly external payable returns(bytes memory response) {
        uint256 oldBalance = address(this).balance - msg.value;
        response = get[key].submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }

    function _set(SubDAOEntry[] memory subdaos) private returns(address[] memory replacedSubdaoAddresses) {
        replacedSubdaoAddresses = new address[](subdaos.length);
        for(uint256 i = 0; i < subdaos.length; i++) {
            replacedSubdaoAddresses[i] = _set(subdaos[i]);
        }
    }

    function _set(SubDAOEntry memory subdao) private returns(address replacedSubdaoAddress) {
        require(subdao.key != bytes32(0), "key");
        if(subdao.location == address(0)) {
            delete keyExists[subdao.key];
        }
        replacedSubdaoAddress = get[subdao.key];
        get[subdao.key] = subdao.location;
        if(subdao.location != address(0)) {
            ISubDAO subDAO = ISubDAO(subdao.location);
            if(subDAO.host() != address(this)) {
                subDAO.finalizeInit(address(this));
            }
            keyExists[keyOf[subdao.location] = subdao.key] = true;
            _history[subdao.key].push(subdao.location);
        }
        if(replacedSubdaoAddress != address(0)) {
            ILazyInitCapableElement(replacedSubdaoAddress).setHost(subdao.newHost);
        }
        emit SubDAOSet(subdao.key, replacedSubdaoAddress, subdao.location);
    }
}