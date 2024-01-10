//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Allowlist {
    mapping(address => bool) private claimed;
    bool public requireAllowlist;
    bytes32 public freeMerkleRoot;
    bytes32 public ogMerkleRoot;
    bytes32 public wlMerkleRoot;

    mapping (address => bool) public _ogMap;
    mapping (address => bool) public _wlMap;
    mapping (address => bool) public _freeMap;

    modifier onlyAllowedPresale(bytes32[] calldata _freeProof, bytes32[] calldata _ogProof, bytes32[] calldata _wlProof, uint amount) {
        if(requireAllowlist) {
            if (amount == 1) {
                if(!_freeMap[msg.sender] && isAllowed(_freeProof, msg.sender, freeMerkleRoot)) {
                    require(isAllowed(_freeProof, msg.sender, freeMerkleRoot), "Allowlist: not found");
                } else if (!_ogMap[msg.sender] && isAllowed(_ogProof, msg.sender, ogMerkleRoot)) {
                    require(isAllowed(_ogProof, msg.sender, ogMerkleRoot), "Allowlist: not found");
                } else {
                   require(isAllowed(_wlProof, msg.sender, wlMerkleRoot), "Allowlist: not found");
                }
            } else if (amount == 2) {
                if(!_freeMap[msg.sender] && isAllowed(_freeProof, msg.sender, freeMerkleRoot)) {
                    if(!_ogMap[msg.sender] && isAllowed(_ogProof, msg.sender, ogMerkleRoot)) {
                        require(isAllowed(_freeProof, msg.sender, freeMerkleRoot), "Allowlist: not found");
                        require(isAllowed(_ogProof, msg.sender, ogMerkleRoot), "Allowlist: not found");
                    } else {
                        require(isAllowed(_freeProof, msg.sender, freeMerkleRoot), "Allowlist: not found");
                        require(isAllowed(_wlProof, msg.sender, wlMerkleRoot), "Allowlist: not found");
                    }
                } else {
                    require(isAllowed(_ogProof, msg.sender, ogMerkleRoot), "Allowlist: not found");
                    require(isAllowed(_wlProof, msg.sender, wlMerkleRoot), "Allowlist: not found");
                }
            } else {
                require(isAllowed(_freeProof, msg.sender, freeMerkleRoot), "Allowlist: not found");
                require(isAllowed(_ogProof, msg.sender, ogMerkleRoot), "Allowlist: not found");
                require(isAllowed(_wlProof, msg.sender, wlMerkleRoot), "Allowlist: not found");
            }
        }
        _;
    } 

    function setFreeMapSenderTrue() internal {
        _freeMap[msg.sender] = true;
    }

    function setOgMapSenderTrue() internal {
        _ogMap[msg.sender] = true;
    }

    function setWlMapSenderTrue() internal {
        _wlMap[msg.sender] = true;
    }

    function isAllowedFree(bytes32[] calldata _proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, freeMerkleRoot, leaf);
    }

    function isAllowedOg(bytes32[] calldata _proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, ogMerkleRoot, leaf);
    }

    function isAllowedWl(bytes32[] calldata _proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, wlMerkleRoot, leaf);
    }

    constructor () {
        requireAllowlist = true;
    }

    function _setRequireAllowlist(bool value) internal {
        requireAllowlist = value;
    }

    function setFreeMerkleRoot(bytes32 root) public {
        freeMerkleRoot = root;
    }

    function setOgMerkleRoot(bytes32 root) public {
        ogMerkleRoot = root;
    }

    function setWlMerkleRoot(bytes32 root) public {
        wlMerkleRoot = root;
    }

    function isAllowed(bytes32[] calldata _proof, address _address, bytes32 root) public pure returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_proof, root, leaf);
    }
}
