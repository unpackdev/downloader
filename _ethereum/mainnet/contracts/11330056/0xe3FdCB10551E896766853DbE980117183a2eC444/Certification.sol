//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721.sol";
import "./Counters.sol";

interface ENS {
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function owner(bytes32 node) external view returns (address);
}

contract Certification is Ownable, ERC721 {
    using Counters for Counters.Counter;

    mapping(bytes32 => string) public graduations;
    mapping(address => bytes32) public registration;
    mapping(address => bool) public hasMinted;

    ENS ens;
    string cid;
    Counters.Counter private _tokenIds;

    // namehash of chainshot.eth
    bytes32 node = 0x94dbba951baaab08bb17e607f270ebe323bf4f90dc7ee482add342d350de44e8;

    constructor(address _ens, string memory _cid) public ERC721("ChainShot Bootcamp", "CS") {
      ens = ENS(_ens);
      cid = _cid;
    }

    function graduate(bytes32 _hash, string memory _cid) public onlyOwner {
        graduations[_hash] = _cid;
    }

    function isCertified(bytes32[] memory proof, bytes32 root) public view returns(bool) {
        require(bytes(graduations[root]).length > 0, "merkle root not found in graduations!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }

    function register(string memory name, bytes32[] memory proof, bytes32 root) public {
        require(isCertified(proof, root), "msg.sender must be certified!");
        bytes32 label = keccak256(abi.encodePacked(name));
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        // this subdomain is already registered
        require(ens.owner(subnode) == address(0x0), "this subnode is already registered to another address!");
        _unregisterSubnode();
        // register new subdomain
        registration[msg.sender] = label;
        ens.setSubnodeOwner(node, label, msg.sender);
    }

    function _unregisterSubnode() private {
        if(registration[msg.sender] != 0) {
            ens.setSubnodeOwner(node, registration[msg.sender], address(0x0));
        }
    }

    function mintToken(bytes32[] memory proof, bytes32 root) public {
        require(isCertified(proof, root), "msg.sender must be certified!");
        require(!hasMinted[msg.sender], "msg.sender has already minted an NFT!");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked("ipfs://ipfs/", cid)));
    }
}
