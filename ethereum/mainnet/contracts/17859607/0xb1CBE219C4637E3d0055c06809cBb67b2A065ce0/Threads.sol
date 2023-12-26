// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./OperatorFilterer.sol";
import "./ERC721A.sol";

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

error NotAllowedByRegistry();
error RegistryNotSet();

error SaleNotActive();
error InvalidTokenId();
error MaxMintExceeded();
error MaxSupplyExceeded();
error InsufficientFunds();
error InvalidMerkle();

interface IRegistry {
    function isAllowedOperator(address operator) external view returns (bool);
}

contract Threads is ERC2981, ERC721A, Ownable, OperatorFilterer {
    using Strings for uint256;

    enum Status {
        Inactive,
        AllowList,
        Public
    }

    bool public operatorFilteringEnabled = true;
    bool public isRegistryActive = false;
    address public registryAddress;

    uint8 public constant MAX_MINT = 10;
    uint16 public constant MAX_SUPPLY = 777;
    uint256 public constant PRICE = 0.07 ether;

    mapping(address => uint8) public userMints;
    Status public status;

    string private _baseTokenURI = "https://data.threads.profjun.com/metadata/";
    bytes32 private _merkleRoot;

    constructor(string memory _name, string memory _symbol, bytes32 _root) ERC721A(_name, _symbol) {
        _merkleRoot = _root;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(0x955eD71D27DEc086F540bC322764b90A444b5248, 750);
        _mint(0x05293eeEE552f6CB86Da8Cf495b1823928A16feb, 1);
    }

    // Mint Options

    function mintAllowlist(uint8 _mints, bytes32[] calldata _proof) external payable {
        if(status != Status.AllowList) revert SaleNotActive();
        if(totalSupply() + _mints > MAX_SUPPLY) revert MaxSupplyExceeded();

        uint8 _totalMints = userMints[msg.sender] + _mints;
        if(_totalMints > MAX_MINT) revert MaxMintExceeded();
        if(msg.value < _mints * PRICE) revert InsufficientFunds();
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if(!MerkleProof.verify(_proof, _merkleRoot, leaf)) revert InvalidMerkle();

        userMints[msg.sender] = _totalMints;
        _mint(msg.sender, _mints);
    }

    function mintPublic(uint8 _mints) external payable {
        if(status != Status.Public) revert SaleNotActive();
        if(totalSupply() + _mints > MAX_SUPPLY) revert MaxSupplyExceeded();

        uint8 _totalMints = userMints[msg.sender] + _mints;
        if(_totalMints > MAX_MINT) revert MaxMintExceeded();
        if(msg.value < _mints * PRICE) revert InsufficientFunds();

        userMints[msg.sender] = _totalMints;
        _mint(msg.sender, _mints);
    }

    // Sale Functions

    function setStatus(Status _newStatus) external onlyOwner {
        status = _newStatus;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        _merkleRoot = _root;
    }

    function withdrawAll(address _artist, address _dev) external onlyOwner {
        payable(_dev).transfer(address(this).balance / 20);
        payable(_artist).transfer(address(this).balance);
    }

    // URI

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // EIP-165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // EIP-2981
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // OperatorFilterer overrides (overrides, values etc.)
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    // Registry check
    function transferFrom(address from, address to, uint256 id) public payable override onlyAllowedOperator(from) {
        if (isRegistryActive && !IRegistry(registryAddress).isAllowedOperator(msg.sender)) revert NotAllowedByRegistry();

        super.transferFrom(from, to, id);
    }

    function setIsRegistryActive(bool _isRegistryActive) external onlyOwner {
        if (registryAddress == address(0)) revert RegistryNotSet();

        isRegistryActive = _isRegistryActive;
    }

    function setRegistryAddress(address _registryAddress) external onlyOwner {
        registryAddress = _registryAddress;
    }
}