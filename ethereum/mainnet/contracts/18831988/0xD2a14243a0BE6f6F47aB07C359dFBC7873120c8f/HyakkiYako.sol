// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Psi.sol";

interface zukanContract {
    function balanceOf(address _address) external view returns (uint256);
    function tokenOfOwnerByIndex(address _address, uint256 _index) external view returns (uint256);
    function account(uint256 _tokenId) external view returns (address);
}

contract HyakkiYako is ERC721Psi, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public maxSupply = 777;
    bool public saleStart = true;
    mapping(address => uint256) public claimed;
    bytes32 public merkleRoot;
    mapping(uint256 => bool) public evolved;
    string private baseTokenURI;
    mapping(uint256 => string) private evolvedURI;
    address public otherContractAddress;

    constructor(
        bytes32 _merkleRoot,
        string memory _baseTokenURI,
        address _otherContractAddress
    ) ERC721Psi("HYAKKI YAKO", "HY") {
        merkleRoot = _merkleRoot;
        baseTokenURI = _baseTokenURI;
        otherContractAddress = _otherContractAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721Psi) returns (string memory) {
        if (evolved[_tokenId] == false) {
            return string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
        } else {
            return string(evolvedURI[_tokenId]);
        }
    }

    function mintCheck(address _address, uint256 _count, bytes32[] memory _proof) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_address, _count));
        for (uint256 i = 0; i < _proof.length; i++) {
            _leaf = _leaf < _proof[i] ? keccak256(abi.encodePacked(_leaf, _proof[i])) : keccak256(abi.encodePacked(_proof[i], _leaf));
        }
        return _leaf == merkleRoot;
    }

    function mint(uint256 _amount, uint256 _count, bytes32[] memory _proof) external virtual nonReentrant {
        require(saleStart, "Sale is paused");
        require(mintCheck(msg.sender, _count, _proof), "Invalid count");
        require(_count > 0, "You have no AL");
        require(_count >= _amount, "Over max mint per wallet");
        require(_count >= claimed[msg.sender] + _amount, "You have no mint left");
        require((_amount + totalSupply()) <= (maxSupply), "No more NFTs");
        claimed[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= maxSupply, "Max supply over");
        _safeMint(_address, _quantity);
    }

    function setBaseURI(string calldata _uri) public onlyOwner {
        baseTokenURI = _uri;
    }

    function setEvolvedURI(uint256 _tokenId, string memory _uri) public onlyOwner {
        evolvedURI[_tokenId] = _uri;
    }

    function evolve(uint256 _tokenId ,bool _bool) public onlyOwner {
        evolved[_tokenId] = _bool;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSaleStart(bool _state) public onlyOwner {
        saleStart = _state;
    }

    function getBalanceOf(address _address) public view returns (uint256) {
        uint256 balance = zukanContract(otherContractAddress).balanceOf(_address);
        return balance;
    }

    function getTokenOfOwnerByIndex(address _address, uint256 _index) public view returns (uint256) {
        uint256 tokenID = zukanContract(otherContractAddress).tokenOfOwnerByIndex(_address, _index);
        return tokenID;
    }

    function getAccount(uint256 _tokenId) public view returns (address) {
        address account = zukanContract(otherContractAddress).account(_tokenId);
        return account;
    }

    function setOtherContractAddress(address _address) public onlyOwner {
        otherContractAddress = _address;
    }
}