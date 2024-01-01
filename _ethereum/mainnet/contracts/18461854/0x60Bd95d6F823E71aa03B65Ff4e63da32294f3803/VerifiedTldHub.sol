// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";

contract VerifiedTldHub is Ownable{

    struct TldInfo {
        string tld;
        uint256 identifier;
        uint256 chainId;
        address registry;
    }

    struct chainInfo {
        uint256 chainId;
        string defaultRpc;
        address sann;
    }

    struct completeTldInfo {
        string tld;
        uint256 identifier;
        uint256 chainId;
        string defaultRpc;
        address registry;
        address sann;
    }

    mapping(string => TldInfo) private tldInfos;
    mapping(uint256 => string[]) private chainTlds;
    mapping(uint256 => chainInfo) private chainInfos;
    string[] private tlds;


    constructor(){}

    function updateTldInfo(string calldata tldName, uint256 identifier, uint256 chainId, address registry) public onlyOwner {
        if (tldInfos[tldName].identifier == 0) {
            tlds.push(tldName);
            chainTlds[chainId].push(tldName);
        }
        tldInfos[tldName] = TldInfo(tldName, identifier, chainId, registry);
    }

    function removeTldInfo(uint256 chainId, string calldata tldName) public onlyOwner {
        delete tldInfos[tldName];
        for (uint i = 0; i < tlds.length; i++) {
            if (keccak256(abi.encodePacked(tlds[i])) == keccak256(abi.encodePacked(tldName))) {
                tlds[i] = tlds[tlds.length - 1];
                tlds.pop();
                break;
            }
        }
        for (uint i = 0; i < chainTlds[chainId].length; i++) {
            if (keccak256(abi.encodePacked(chainTlds[chainId][i])) == keccak256(abi.encodePacked(tldName))) {
                chainTlds[chainId][i] = chainTlds[chainId][chainTlds[chainId].length - 1];
                chainTlds[chainId].pop();
                break;
            }
        }
    }

    function updateChainInfo(uint256 chainId, string calldata defaultRpc, address sann) public onlyOwner {
        chainInfos[chainId] = chainInfo(chainId, defaultRpc, sann);
    }

    function updateDefaultRpc(uint256 chainId, string calldata defaultRpc) public onlyOwner {
        chainInfos[chainId].defaultRpc = defaultRpc;
    }

    function getChainTlds(uint256 chainId) public view returns (string[] memory) {
        string[] memory tlds = new string[](chainTlds[chainId].length);
        for (uint i = 0; i < chainTlds[chainId].length; i++) {
            tlds[i] = chainTlds[chainId][i];
        }
        return tlds;
    }

    function getTlds() public view returns (string[] memory) {
        return tlds;
    }

    function getChainInfo(uint256 chainId) public view returns (chainInfo memory) {
        return chainInfos[chainId];
    }

    function getTldInfo(string[] calldata tlds) public view returns (completeTldInfo[] memory) {
        completeTldInfo[] memory infos = new completeTldInfo[](tlds.length);
        for (uint i = 0; i < tlds.length; i++) {
            string memory tld = tlds[i];
            uint256 chainId = tldInfos[tlds[i]].chainId;
            uint256 identifier = tldInfos[tlds[i]].identifier;
            address registry = tldInfos[tlds[i]].registry;
            infos[i] = completeTldInfo(tld, identifier, chainId, chainInfos[chainId].defaultRpc, registry, chainInfos[chainId].sann);
        }
        return infos;
    }
}
