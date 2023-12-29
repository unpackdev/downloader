// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract MetaSkulls is ERC721A, Ownable, PaymentSplitter {
    using ECDSA for bytes32;

    address private _signer;
    address[] private _wallets = [
        0x68f28943D9a6EfD00bA2A9834AA99Eb9daa4ef53,
        0x7e9517D8d54Ed59AF049E689Cc7Cc681decA8e3f,
        0x7CB2E5241AA316151db08D6b7B7c8c047f284E00
    ];
    uint256[] private _walletShares = [40, 20, 40];

    string public baseURI;
    bool public baseURIAlreadySet = false;
    uint256 public immutable collectionSize;
    bool public isPublicSaleOn;
    uint256 public maxMint;
    uint256 public price = 0.2 ether;
    uint256 public tokensReserved;
    uint256 public immutable reserveAmount;

    event BaseURIChanged(string newBaseURI);
    event Minted(address minter, uint256 amount);
    event PriceChanged(uint256 price);
    event SignerChanged(address signer);
    event ReservedToken(address minter, address recipient, uint256 amount);

    constructor(
        string memory initBaseURI,
        address signer,
        uint256 _reserveAmount,
        uint256 _maxMint,
        uint256 _collectionSize
    ) ERC721A('MetaSkulls', 'SKULLISH') PaymentSplitter(_wallets, _walletShares) {
        _signer = signer;
        baseURI = initBaseURI;
        maxMint = _maxMint;
        reserveAmount = _reserveAmount;
        collectionSize = _collectionSize;
        isPublicSaleOn = false;
    }

    function _hash(string calldata salt, address _address) internal view returns (bytes32) {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (bool) {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function whitelistMint(
        uint256 amount,
        string calldata salt,
        bytes calldata token
    ) external payable {
        require(tx.origin == msg.sender, 'contract not allowed to mint');
        require(_verify(_hash(salt, msg.sender), token), 'invalid token');
        require(amount > 0, 'invalid amount');
        require(totalSupply() + amount + reserveAmount - tokensReserved <= collectionSize, 'max supply exceeded');
        require(numberMinted(msg.sender) + amount <= maxMint, 'cannot mint that many');

        _safeMint(msg.sender, amount);
        refundIfOver(price * amount);
        emit Minted(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(tx.origin == msg.sender, 'contract not allowed to mint');
        require(amount > 0, 'invalid amount');
        require(isPublicSaleOn, 'public sale has not yet started');
        require(totalSupply() + amount + reserveAmount - tokensReserved <= collectionSize, 'max supply exceeded');

        _safeMint(msg.sender, amount);
        refundIfOver(price * amount);
        emit Minted(msg.sender, amount);
    }

    function reserve(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), 'zero address');
        require(amount > 0, 'invalid amount');
        require(totalSupply() + amount <= collectionSize, 'exceeds max supply');
        require(tokensReserved + amount <= reserveAmount, 'max reserve amount exceeded');

        _safeMint(recipient, amount);
        tokensReserved += amount;
        emit ReservedToken(msg.sender, recipient, amount);
    }

    function refundIfOver(uint256 totalPrice) private {
        require(msg.value >= totalPrice, 'not enough ETH');

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        require(!baseURIAlreadySet, 'cannot change baseURI');

        baseURI = newBaseURI;
        baseURIAlreadySet = true;
        emit BaseURIChanged(newBaseURI);
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleOn = !isPublicSaleOn;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceChanged(newPrice);
    }

    function setMaxMint(uint256 newMaxMint) external onlyOwner {
        require(newMaxMint > 0, 'cannot be zero');

        maxMint = newMaxMint;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
