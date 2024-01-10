// SPDX-License-Identifier: MIT
//         .__                                 .___           
//    ____ |  |   ____ _____    _____        __| _/_______  __
//  / ___\|  | _/ __ \\__  \  /     \      / __ |/ __ \  \/ /
//  / /_/  >  |_\  ___/ / __ \|  Y Y  \    / /_/ \  ___/\   / 
//  \___  /|____/\___  >____  /__|_|  / /\ \____ |\___  >\_/  
// /_____/           \/     \/      \/  \/      \/    \/      
// 2022 - GLEAM.DEV - ERC721A

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ERC721Pausable.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";

contract FratApes is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;

    uint256 private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 3333;
    uint256 public constant WL_ELEMENTS = 3000;
    uint256 public constant WL_PRICE = 0.07 ether;
    uint256 public constant PRICE = 0.09 ether;
    uint256 public constant MAX_MINT = 10;
    
    string public baseTokenURI;

    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public whitelistClaimed;
    bool public publicSaleOpen;

    address public constant creatorAddress = 0x6b0A6Bd88B915788F7a5BaAC86AA83ac0E8a1458;
    address public constant marketingAddress = 0x99EA14829aD4879161511D0BfdB23D106c33996E;

    event CreateApe(uint256 indexed id);
    constructor()
    ERC721("Fraternity Apes", "FRAT") {

        setBaseURI('https://api.fraternityapes.io/ape/');
        pause(true);

    }

    modifier saleIsOpen {

        require(totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;

    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker;
    }

    function apeMint(uint256 _count) public payable saleIsOpen {

        uint256 total = totalSupply();
        require(publicSaleOpen, "Public sale not open yet");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(_count <= MAX_MINT, "Exceeds number");
        require(msg.value == PRICE * _count, "Value is over or under price.");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }

    }

    function whitelistMint(uint256 _count, bytes32[] calldata proof) public payable saleIsOpen  {

        uint256 total = totalSupply();
        require(_count <= MAX_MINT, "Exceeds number");
        require(total + _count <= WL_ELEMENTS, "Max limit");
        require(verifySender(proof), "MerkleWhitelist: Caller is not whitelisted");
        require(canMintAmount(_count), "Sender max presale mint amount already met");
        require(msg.value == WL_PRICE * _count, "Value is over or under price.");

        whitelistClaimed[msg.sender] += _count;
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }


    }

    function teamClaim(uint256 _count) public onlyOwner {

        uint256 total = _tokenIdTracker;
        require(total + _count <= MAX_ELEMENTS, "Sale end");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }

    }

    function _mintAnElement(address _to) private {

        uint id = totalSupply();
        _tokenIdTracker += 1;
        _mint(_to, id);
        emit CreateApe(id);

    }

    function verifySender(bytes32[] calldata proof) public view returns (bool) {

        return _verify(proof, _hash(msg.sender));

    }

    function canMintAmount(uint256 _count) public view returns (bool) {

        return whitelistClaimed[msg.sender] + _count <= MAX_MINT;
        
    }

    function _verify(bytes32[] calldata proof, bytes32 addressHash)
        internal
        view
        returns (bool) {

        return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);

    }

    function _hash(address _address) internal pure returns (bytes32) {

        return keccak256(abi.encodePacked(_address));

    }

    function _baseURI() internal view virtual override returns (string memory) {

        return baseTokenURI;

    }

    function setBaseURI(string memory baseURI) public onlyOwner {

        baseTokenURI = baseURI;

    }

    function setPublicSale(bool val) public onlyOwner {

        publicSaleOpen = val;

    }

    function pause(bool val) public onlyOwner {

        if (val == true) {
            _pause();
            return;
        }
        _unpause();

    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 creatorShare = balance.mul(82).div(100);
        uint256 marketingShare = balance.mul(18).div(100);
        require(balance > 0);
        _withdraw(creatorAddress, creatorShare);
        _withdraw(marketingAddress, marketingShare);
    }

    function _withdraw(address _address, uint256 _amount) private {

        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
        
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {

        whitelistMerkleRoot = merkleRoot;

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}