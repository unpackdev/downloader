// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract CelestialEntities is ERC721Enumerable, Ownable {
    address public vault;
    bytes32 public merkleRoot;
    string public baseTokenURI;
    uint public price;
    uint public status;

    mapping(uint => mapping(address => bool)) public denylist;

    constructor() ERC721("CelestialEntities", "CE") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setStatus(uint _status) external onlyOwner {
        status = _status;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function claim(bytes32[] calldata _merkleProof, uint256 _amount) external {
        uint256 supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        require(status == 1, 'Not Active');
        require(!denylist[0][msg.sender], 'Mint Claimed');
        require(supply + _amount < 3334, 'Supply Denied');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }

        denylist[0][msg.sender] = true;
    }

    function presale(bytes32[] calldata _merkleProof, uint _amount) external payable {
        uint supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(status == 2, 'Not Active');
        require(_amount < 4, 'Amount Denied');
        require(!denylist[1][msg.sender], 'Mint Claimed');
        require(supply + _amount < 3334, 'Supply Denied');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(msg.value >= price * _amount, 'Ether Amount Denied');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

        for(uint i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }

        denylist[1][msg.sender] = true;
    }

    function mint(uint _amount) external payable {
        uint supply = totalSupply();

        require(status == 3, 'Not Active');
        require(_amount < 21, 'Amount Denied');
        require(supply + _amount < 3334, 'Supply Denied');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(msg.value >= price * _amount, 'Ether Amount Denied');

        for(uint i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function withdraw() external payable onlyOwner {
        require(vault != address(0), 'Vault Invalid');
        payable(vault).transfer(address(this).balance);
    }
}
