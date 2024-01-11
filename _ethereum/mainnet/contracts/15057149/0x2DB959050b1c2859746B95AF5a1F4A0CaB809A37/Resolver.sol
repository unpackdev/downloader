// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Strings.sol";
import "./IERC165.sol";

import "./ENS.sol";
import "./Multicallable.sol";
import "./ABIResolver.sol";
import "./AddrResolver.sol";
import "./ContentHashResolver.sol";
import "./IInterfaceResolver.sol";
import "./NameResolver.sol";
import "./PubkeyResolver.sol";
import "./TextResolver.sol";

import "./PhotochromicRegistrar.sol";
import "./Validator.sol";

abstract contract ResolverValidated is AddrResolver, TextResolver, Ownable {
    using Strings for uint256;

    ENS immutable ens;
    PhotochromicRegistrar immutable registrar;

    // A mapping from node => resolver address.
    mapping(bytes32 => address) resolvers;

    constructor(
        ENS _ens,
        PhotochromicRegistrar _registrar
    ) {
        ens = _ens;
        registrar = _registrar;
    }

    function isAuthorised(bytes32 node) internal override view returns(bool) {
        return msg.sender == ens.owner(node) || msg.sender == owner();
    }

    function supportsInterface(bytes4 interfaceId) virtual public override(AddrResolver, TextResolver) pure returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setResolver(bytes32 node, address _resolver) public authorised(node) {
        require(_resolver != address(this));
        resolvers[node] = _resolver;
    }

    function resolver(bytes32 node) public view returns (address) {
        return resolvers[node];
    }

    // AddrResolver (IAddrResolver, IAddressResolver)
    function addr(bytes32 node, uint coinType) public override(AddrResolver) view returns (bytes memory) {
        (, bytes memory a, ) = validatedAddr(node, coinType);
        return a;
    }

    function validatedAddr(bytes32 node, uint coinType) public view returns (ValidationStatus, bytes memory, uint32) {
        bytes memory a = _addresses[node][coinType];
        if (a.length != 0 || resolver(node) == address(0)) {
            (bytes memory v, uint32 t) = Validator.extractTimestamp(a);
            if (t == 0) return (ValidationStatus.UNVALIDATED, v, 0);
            if (t == 1) return (ValidationStatus.INVALID, v, 0);
            if (node != registrar.getNode(ens.owner(node))) return (ValidationStatus.INVALID, v, t);
            return (ValidationStatus.VALIDATED, v, t);
        }
        return (ValidationStatus.UNVALIDATED, IAddressResolver(resolver(node)).addr(node, coinType), 0);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) public override(AddrResolver) authorised(node) {
        _addresses[node][coinType] = Validator.concatTimestamp(a, 0);
        emit AddressChanged(node, coinType, a);
        if (coinType == 60) emit AddrChanged(node, bytesToAddress(a));
    }

    // TextResolver (ITextResolver)
    mapping(bytes32 => string) photochromicTexts;

    function text(bytes32 node, string calldata key) public override(TextResolver) view returns (string memory) {
        (, string memory value, ) = validatedText(node, key);
        return value;
    }

    function validatedText(bytes32 node, string calldata key) public view returns (ValidationStatus, string memory, uint32) {
        string memory value = _text(node, key);
        if (bytes(value).length == 0 && keccak256(abi.encodePacked(key)) == keccak256("avatar")) {
            string memory a = Strings.toHexString(uint160(address(registrar)), 20);
            string memory nodeString = uint256(node).toString();
            ValidationStatus validationStatus = ValidationStatus.VALIDATED;
            if(node != registrar.getNode(ens.owner(node))){
                validationStatus = ValidationStatus.INVALID;
            }
            return (validationStatus, string(abi.encodePacked("eip155:1/erc721:", a, "/", nodeString)), 0);
        }
        if (bytes(value).length != 0 || resolver(node) == address(0)) {
            (bytes memory v, uint32 t) = Validator.extractTimestamp(bytes(value));
            if (t == 0) return (ValidationStatus.UNVALIDATED, string(v), 0);
            if (t == 1) return (ValidationStatus.INVALID, string(v), 0);
            if (node != registrar.getNode(ens.owner(node))) return (ValidationStatus.INVALID, string(v), t);
            return (ValidationStatus.VALIDATED, string(v), t);
        }
        return (ValidationStatus.UNVALIDATED, ITextResolver(resolver(node)).text(node, key), 0);
    }

    function _text(bytes32 node, string calldata key) internal view returns (string memory) {
        if (Validator.isPhotochromicRecord(key)) {
            return Validator.getPhotochromicRecord(key, bytes(photochromicTexts[node]));
        }
        return texts[node][key];
    }

    function setText(bytes32 node, string calldata key, string calldata value) public override(TextResolver) authorised(node) {
        require(!Validator.isIORecord(key));
        if (bytes(value).length == 0 ) {
            delete texts[node][key];
        } else {
            texts[node][key] = string(Validator.concatTimestamp(bytes(value), 0));
        }
        emit TextChanged(node, key, key);
    }
}

abstract contract Resolver is ABIResolver, ContentHashResolver, IInterfaceResolver, NameResolver, PubkeyResolver, Multicallable, ResolverValidated {

    function supportsInterface(bytes4 interfaceId) public override(ABIResolver, ContentHashResolver, NameResolver, PubkeyResolver, Multicallable, ResolverValidated) pure returns (bool) {
        return interfaceId == type(IInterfaceResolver).interfaceId || super.supportsInterface(interfaceId);
    }

    // ABIResolver
    function ABI(bytes32 node, uint256 contentTypes) public override(ABIResolver) view returns (uint256, bytes memory) {
        mapping(uint256=>bytes) storage abiset = abis[node];
        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }
        if (resolver(node) == address(0)) return (0, bytes(""));
        return IABIResolver(resolver(node)).ABI(node, contentTypes);
    }

    // ContentHashResolver
    function contenthash(bytes32 node) public override(ContentHashResolver) view returns (bytes memory) {
        bytes memory h = hashes[node];
        if (h.length != 0 || resolver(node) == address(0)) return h;
        return IContentHashResolver(resolver(node)).contenthash(node);
    }

    // InterfaceResolver (IInterfaceResolver)
    mapping(bytes32=>mapping(bytes4=>address)) interfaces;

    function interfaceImplementer(bytes32 node, bytes4 interfaceID) public view returns (address) {
        address implementer = interfaces[node][interfaceID];
        if(implementer != address(0)) {
            return implementer;
        }
        address a = addr(node);
        if(a == address(0)) {
            return _interfaceImplementer(node, interfaceID);
        }
        (bool success, bytes memory returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC165).interfaceId));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            return _interfaceImplementer(node, interfaceID);
        }
        (success, returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            return _interfaceImplementer(node, interfaceID);
        }
        return a;
    }

    function _interfaceImplementer(bytes32 node, bytes4 interfaceID) internal view returns (address) {
        if (resolver(node) == address(0)) return address(0);
        return IInterfaceResolver(resolver(node)).interfaceImplementer(node, interfaceID);
    }

    function name(bytes32 node) public override(NameResolver) view returns (string memory) {
        string memory name = names[node];
        if (bytes(name).length != 0 || resolver(node) == address(0)) return name;
        return INameResolver(resolver(node)).name(node);
    }

    function pubkey(bytes32 node) public override(PubkeyResolver) view returns (bytes32 x, bytes32 y) {
        PublicKey memory key = pubkeys[node];
        if (key.x != 0 || key.y != 0 || resolver(node) == address(0)) return (key.x, key.y);
        return IPubkeyResolver(resolver(node)).pubkey(node);
    }
}
