// SPDX-License-Identifier: MIT
/**********************************************
 * Samurai Steam Polka
 * -- EG NFT Project Vol.1 --
 **********************************************/
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";

contract SSP is ERC721A, ERC2981, Ownable(msg.sender), AccessControl {
    uint256 public price = 0.055 ether;
    uint256 public maxSupply;
    uint256 public maxMintAmount = 2;
    bool public revealed = false;
    bool public paused = false;
    string public notRevealedURI;
    uint256 public privateStartTime;
    uint256 public publicStartTime;
    string private _baseTokenURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private _merkleRoot;
    mapping(address => uint256) public alMintedCount;
    using MerkleProof for bytes32[];

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedURI,
        uint256 _maxSupply,
        uint256 _privateStartTime,
        uint256 _publicStartTime,
        address _minterAddress
    ) ERC721A(_name, _symbol) {
        _baseTokenURI = _initBaseURI;
        notRevealedURI = _initNotRevealedURI;
        maxSupply = _maxSupply;
        privateStartTime = _privateStartTime;
        publicStartTime = _publicStartTime;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, _minterAddress);
        _setDefaultRoyalty(msg.sender, 500);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, AccessControl) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            super.supportsInterface(interfaceId);
    }

    function mint(uint256 _quantity) external payable {
        require(!paused, "Mint is paused");
        require(isPublicSaleStarted(), "Public Sale not started");
        require(_quantity > 0, "1 or more purchases needed");
        require(_quantity <= maxMintAmount, "Exceeded max available to purchase");
        require(_totalMinted() + _quantity <= maxSupply, "Exceeded max supply");
        require(msg.value >= price * _quantity, "Incorrect payment amount");
        require(tx.origin == msg.sender, "The caller is another contract");

        _mint(msg.sender, _quantity);
    }

    function alMint(uint256 _quantity, bytes32[] memory _proof) external payable {
        require(!paused, "Mint is paused");
        require(isPrivateSaleStarted(), "Private Sale not started");
        require(_quantity > 0, "1 or more purchases needed");
        require(_totalMinted() + _quantity <= maxSupply, "Exceeded max supply");

        require(isAllowedAddress(msg.sender, _proof),"Not in allowed list");
        require(hasWithinMaxMint(msg.sender, _quantity), "Exceeded max availables for allow-listed user");
        require(msg.value >= price * _quantity, "Incorrect payment amount");

        alMintedCount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function prepaidMint(address _user, uint256 _quantity) external onlyRole(MINTER_ROLE) {
        require(!paused, "Mint is paused");
        require(isPublicSaleStarted(), "Public Sale not started");
        require(_quantity > 0, "1 or more purchases needed");
        require(_quantity <= maxMintAmount, "Exceeded max available to purchase");
        require(_totalMinted() + _quantity <= maxSupply, "Exceeded max supply");

        _mint(_user, _quantity);
    }

    function alPrepaidMint(address _user, uint256 _quantity, bytes32[] memory _proof) external onlyRole(MINTER_ROLE) {
        require(!paused, "Mint is paused");
        require(isPrivateSaleStarted(), "Private Sale not started");
        require(_quantity > 0, "1 or more purchases needed");
        require(_totalMinted() + _quantity <= maxSupply, "Exceeded max supply");

        require(isAllowedAddress(_user, _proof),"Not in allowed list");
        require(hasWithinMaxMint(_user, _quantity), "Exceeded max availables for allow-listed user");

        alMintedCount[_user] += _quantity;
        _mint(_user, _quantity);
    }

    function isAllowedAddress(address _user, bytes32[] memory _proof) public view returns (bool) {
        return _proof.verify(_merkleRoot, keccak256(abi.encodePacked(_user)));
    }

    function hasWithinMaxMint(address _user, uint256 _addingMintNum) public view returns (bool) {
        return alMintedCount[_user] + _addingMintNum <= maxMintAmount;
    }

    function isPrivateSaleStarted() public view returns (bool) {
        return block.timestamp >= privateStartTime;
    }

    function isPublicSaleStarted() public view returns (bool) {
        return block.timestamp >= publicStartTime;
    }

    function isSoldOut() public view returns (bool) {
        return _totalMinted() >= maxSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721AMetadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory result = revealed ?
            string(abi.encodePacked(baseURI, _toString(_tokenId), '.json')) :
            string(abi.encodePacked(notRevealedURI, '?id=', _toString(_tokenId)));

        return bytes(baseURI).length != 0 ? result : '';
    }

    /**
     * Only Owner Functions
     */
    function adminMint(address _user, uint256 _quantity) external onlyOwner {
        require(_quantity > 0, "1 or more purchases needed");
        require(_quantity <= maxMintAmount, "Exceeded max available to purchase");
        require(_totalMinted() + _quantity <= maxSupply, "Exceeded max supply");

        _mint(_user, _quantity);
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setPrivateStartTime(uint256 _newPrivateStartTime) external onlyOwner {
        privateStartTime = _newPrivateStartTime;
    }

    function setPublicStartTime(uint256 _newPublicStartTime) external onlyOwner {
        publicStartTime = _newPublicStartTime;
    }

    function setAlRoot(bytes32 _newRoot) external onlyOwner {
        _merkleRoot = _newRoot;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}