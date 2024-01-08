pragma solidity ^0.7.4;pragma experimental ABIEncoderV2;

import "./ENS.sol";
import "./ABIResolver.sol";
import "./AddrResolver.sol";
import "./ContentHashResolver.sol";
import "./DNSResolver.sol";
import "./InterfaceResolver.sol";
import "./NameResolver.sol";
import "./PubkeyResolver.sol";
import "./TextResolver.sol";
import "./PublicResolver.sol";

contract ForwardingResolver is PublicResolver {
    PublicResolver public fallbackResolver;

    constructor(ENS _ens, PublicResolver _fallbackResolver) PublicResolver(_ens) {
        fallbackResolver = _fallbackResolver;
    }

    //===============================AddrResolver Forwarding===============================//

    function setAddr(bytes32 node, address a) override external authorised(node) {
        fallbackResolver.setAddr(node, a);
    }

    function addr(bytes32 node) override public view returns (address payable) {
        return fallbackResolver.addr(node);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) override public authorised(node) {
        fallbackResolver.setAddr(node, coinType, a);
    }

    function addr(bytes32 node, uint coinType) override public view returns(bytes memory) {
        return fallbackResolver.addr(node, coinType);
    }

    //===============================NameResolver Forwarding===============================//

    function setName(bytes32 node, string calldata name) override external authorised(node) {
        fallbackResolver.setName(node, name);
    }

    function name(bytes32 node) override external view returns (string memory) {
        return fallbackResolver.name(node);
    }

    //===============================PubkeyResolver Forwarding============================//

    function setPubkey(bytes32 node, bytes32 x, bytes32 y) override external authorised(node) {
        fallbackResolver.setPubkey(node, x, y);
    }

    function pubkey(bytes32 node) override external view returns (bytes32 x, bytes32 y) {
        return fallbackResolver.pubkey(node);
    }

    //===============================ABIResolver Forwarding================================//

    function setABI(bytes32 node, uint256 contentType, bytes calldata data) override external authorised(node) {
        fallbackResolver.setABI(node, contentType, data);
    }

    function ABI(bytes32 node, uint256 contentTypes) override external view returns (uint256, bytes memory) {
        return fallbackResolver.ABI(node, contentTypes);
    }

    //===============================TextResolver Forwarding===============================//

    function setText(bytes32 node, string calldata key, string calldata value) override external authorised(node) {
        fallbackResolver.setText(node, key, value);
    }

    function text(bytes32 node, string calldata key) override external view returns (string memory) {
        return fallbackResolver.text(node, key);
    }

    //===============================ContentHashResolver Forwarding========================//

    function setContenthash(bytes32 node, bytes calldata hash) override external authorised(node) {
        fallbackResolver.setContenthash(node, hash);
    }

    function contenthash(bytes32 node) override external view returns (bytes memory) {
        return fallbackResolver.contenthash(node);
    }

    //===============================DNSResolver Forwarding================================//

    function setDNSRecords(bytes32 node, bytes calldata data) override external authorised(node) {
        fallbackResolver.setDNSRecords(node, data);
    }

    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) override public view returns (bytes memory) {
        return fallbackResolver.dnsRecord(node, name, resource);
    }

    function hasDNSRecords(bytes32 node, bytes32 name) override public view returns (bool) {
        return fallbackResolver.hasDNSRecords(node, name);
    }

    function clearDNSZone(bytes32 node) override public authorised(node) {
        fallbackResolver.clearDNSZone(node);
    }

    function setZonehash(bytes32 node, bytes calldata hash) override external authorised(node) {
        fallbackResolver.setZonehash(node, hash);
    }

    function zonehash(bytes32 node) override external view returns (bytes memory) {
        return fallbackResolver.zonehash(node);
    }
}
