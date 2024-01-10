//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./MerkleProof.sol";

contract PTBExclusiveDrop is ERC1155Supply, Ownable {
    constructor() ERC1155("") Ownable() {}

    string public name = "Pass The Baton NFTs";
    string public symbol = "PTBNFT";

    string[] private _uri;
    string public contractURI;
    uint256[] public claimableUntil;
    bytes32[] public airdropRoot;
    mapping(uint256 => mapping(address => uint256)) public claimed;

    event PermanentURI(string _value, uint256 indexed _id);

    function updateContractURI(string memory uri_) public onlyOwner {
        contractURI = uri_;
    }

    function newAirdrop(
        string memory uri_,
        bytes32 merkleRoot,
        uint256 timestamp
    ) public onlyOwner {
        require(timestamp > block.timestamp, "This is not mintable");
        _uri.push(uri_);
        claimableUntil.push(timestamp);
        airdropRoot.push(merkleRoot);
        emit PermanentURI(uri_, _uri.length - 1);
    }

    function claim(
        uint256 id,
        uint256 amount,
        uint256 allowance,
        bytes32[] memory proof
    ) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, allowance));
        require(claimableUntil[id] > block.timestamp, "Not mintable");
        require(
            claimed[id][msg.sender] + amount <= allowance,
            "Already claimed"
        );
        require(
            MerkleProof.verify(proof, airdropRoot[id], leaf),
            "MerkleProof is not valid"
        );
        claimed[id][msg.sender] += amount;
        _mint(msg.sender, id, amount, "");
    }

    function mintUnclaimed(
        uint256 id,
        uint256 amount,
        uint256 allowance,
        bytes32[] memory proof,
        address claimer,
        address recipient
    ) public onlyOwner {
        bytes32 leaf = keccak256(abi.encodePacked(claimer, allowance));
        require(claimableUntil[id] < block.timestamp, "Still mintable");
        require(claimed[id][claimer] + amount <= allowance, "Already claimed");
        require(
            MerkleProof.verify(proof, airdropRoot[id], leaf),
            "MerkleProof is not valid"
        );
        claimed[id][claimer] += amount;
        _mint(recipient, id, amount, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _uri[id];
    }
}
