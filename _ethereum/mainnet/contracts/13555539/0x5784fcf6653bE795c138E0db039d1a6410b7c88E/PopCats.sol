//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract PopCats is ERC721Enumerable, Ownable {

    using Strings for uint256;

    /// @dev Max mint limit per purchase
    uint256 public constant MAX_MINT = 20;
    /// @dev NFT price
    uint256 public constant PRICE = 0.04 ether;
    /// @dev Gift maximum supply
    uint256 public constant GIFT = 350;
    /// @dev Public sale maximum supply
    uint256 public constant SALE_PUBLIC = 8538;
    /// @dev Total maximum supply
    uint256 public constant SALE_MAX = 8888;
    /// @dev Total maximum supply
    uint256 public constant BOUNS = 20000000000000000000;

    /// @dev White list max mint limit
    uint256 public whiteListMaxMint = 5;

    /// @dev For calculate remain available.
    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;

    /// @dev Sale active flag
    bool public saleActive = false;
    /// @dev White list sale active flag
    bool public whiteListActive = true;
    /// @dev Purchase lock flag
    bool public purchaseLock = false;
    /// @dev proof of hash
    string public proof;

    string private _contractUri = 'https://popcatsnft.com/contracturi';
    string private _tokenBaseUri = 'https://popcatsnft.com/metadata/';

    mapping(address => bool) private _whiteList;
    mapping(address => uint256) private _whiteListClaimed;
    mapping(address => uint256) private _bounsList;

    constructor() ERC721("Pop Cats NFT","PC") {}

    modifier checkkPurchaseLock {
        require(!purchaseLock, "Purchase Locked");
        _;
    }

    function setPurchaseLock() external onlyOwner {
        purchaseLock = true;
    }

    function addToWhiteList(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
        _whiteList[addrs[i]] = true;
        }
    }

    function onWhiteList(address addr) external view returns (bool) {
        return _whiteList[addr];
    }

    function checkBouns(address addr) external view returns (uint256) {
        return _bounsList[addr];
    }

    function whiteListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), 'The address is null on white list Claimed By');
        return _whiteListClaimed[owner];
    }

    function purchase(uint256 tokenQuantity) external payable checkkPurchaseLock {
        require(saleActive, 'Sale is not active');
        require(!whiteListActive, 'Only allowing from white list');
        require(totalSupply() < SALE_MAX, 'Sold Out');
        require(tokenQuantity > 0, 'Purchase Quantity must be greater than 0');
        require(tokenQuantity <= MAX_MINT, 'Purchase limit exceed');
        require(totalPublicSupply < SALE_PUBLIC, 'Public sale exceed');
        require(PRICE * tokenQuantity <= msg.value, 'ETH amount is not sufficient');

        uint256 i = 0;
        for ( i ; i < tokenQuantity; i++) {
            if (totalPublicSupply < SALE_PUBLIC) {
                uint256 tokenId = totalSupply() + 1;
                _safeMint(msg.sender, tokenId);
            }
        }
        totalPublicSupply += i;
        _bounsList[msg.sender] += (BOUNS * i);
    }

    function purchaseWhiteList(uint256 tokenQuantity) external payable checkkPurchaseLock {
        require(saleActive, 'Sale is not active');
        require(_whiteList[msg.sender], 'You are not on the white list');
        require(whiteListActive, 'White list is not active');
        require(tokenQuantity > 0, 'Purchase Quantity must be greater than 0');
        require(totalSupply() < SALE_MAX, 'Sold Out');
        require(tokenQuantity <= whiteListMaxMint, 'Cannot purchase this quantity of tokens on white list');
        require(totalPublicSupply + tokenQuantity <= SALE_PUBLIC, 'Public sale exceed on white list');
        require(_whiteListClaimed[msg.sender] + tokenQuantity <= whiteListMaxMint, 'Total purchase exceeds max limit');
        require(PRICE * tokenQuantity <= msg.value, 'ETH amount is not sufficient');

        uint256 i = 0;
        for ( i ; i < tokenQuantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
        }
        totalPublicSupply += i;
        _whiteListClaimed[msg.sender] += i;
        _bounsList[msg.sender] += (BOUNS * i);
    }

    function gift(address[] calldata to) external onlyOwner {
        require(totalSupply() < SALE_MAX, 'Sold Out');
        require(totalGiftSupply + to.length <= GIFT, 'Not enough tokens left to gift');

        uint256 i = 0;
        for( i ; i < to.length; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(to[i], tokenId);
        }
        totalGiftSupply += i;
    }

    function setSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setWhiteListActive() external onlyOwner {
        whiteListActive = !whiteListActive;
    }

    function setWhiteListMaxMint(uint256 maxMint) external onlyOwner {
        whiteListMaxMint = maxMint;
    }

    function setProof(string calldata proofHash) external onlyOwner {
        proof = proofHash;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setContractUri(string calldata uri) external onlyOwner {
        _contractUri = uri;
    }

    function setBaseUri(string calldata uri) external onlyOwner {
        _tokenBaseUri = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function getBaseUri() public view returns (string memory) {
        return _tokenBaseUri;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token not found');

        return string(abi.encodePacked(_tokenBaseUri, tokenId.toString()));
    }
}
