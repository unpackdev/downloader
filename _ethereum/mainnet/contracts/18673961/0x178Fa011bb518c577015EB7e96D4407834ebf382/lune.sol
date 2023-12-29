// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Strings.sol";
import "./IERC721A.sol";
import "./ERC721AQueryable.sol";
import "./DefaultOperatorFilterer.sol";

contract LUNECATS is ERC721AQueryable, Ownable(msg.sender), DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public maxFreeMintPerWallet = 2;
    uint256 public publicTokenPrice = 0.002 ether;
    uint256 public maxPublicMintPerWallet = 20;
    uint256 public maxMintPerTx = 20;

    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MAX_FREE = 4444; 

    string private _contractURI;
    bool public saleStarted = false;
    
    uint256 public freeMintCount;
    mapping(address => uint256) public freeMintClaimed;

    string private _baseTokenURI;

    constructor() ERC721A("LUNE CATS", "LUNECAT") {
        _baseTokenURI = "ipfs://bafybeig4ez5rbplzurlxk5zgicqmi64hhglemiydbgjh4cwpq3qokce334/";
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier underMaxSupply(uint256 _quantity) {
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Unable to mint.");
        _;
    }



    function setPublicTokenPrice(uint256 _newPrice) external onlyOwner {
        publicTokenPrice = _newPrice;
    }

    function mint(uint256 _quantity) external payable callerIsUser underMaxSupply(_quantity) {
        require(_quantity <= maxMintPerTx, "Exceeds max mint per transaction");
        require(balanceOf(msg.sender) + _quantity <= maxPublicMintPerWallet, "Exceeds max mint per wallet");
        require(saleStarted, "Sale has not started");
        
        if (_totalMinted() < MAX_SUPPLY) {
            if (freeMintCount >= MAX_FREE || freeMintClaimed[msg.sender] >= maxFreeMintPerWallet) {
                require(msg.value >= _quantity * publicTokenPrice, "Insufficient balance");
                _mint(msg.sender, _quantity);
            } else {
                uint256 _mintableFreeQuantity = maxFreeMintPerWallet - freeMintClaimed[msg.sender];
                if (_quantity <= _mintableFreeQuantity) {
                    freeMintCount += _quantity;
                    freeMintClaimed[msg.sender] += _quantity;
                    _mint(msg.sender, _quantity);
                } else {
                    freeMintCount += _mintableFreeQuantity;
                    freeMintClaimed[msg.sender] += _mintableFreeQuantity;
                    require(
                        msg.value >= (_quantity - _mintableFreeQuantity) * publicTokenPrice,
                        "Balance insufficient"
                    );
                    _mint(msg.sender, _quantity);
                }
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function MINT1(uint256 _numberToMint) external onlyOwner underMaxSupply(_numberToMint) {
        _mint(msg.sender, _numberToMint);
    }


    function setMaxFreePerWallet(uint256 _newMaxFreePerWallet) external onlyOwner {
        maxFreeMintPerWallet = _newMaxFreePerWallet;
    }

    function ownerMintToAddress(address _recipient, uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(_recipient, _numberToMint);
    }

    function setMaxPublicMintPerWallet(uint256 _count) external onlyOwner {
        maxPublicMintPerWallet = _count;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Storefront metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _URI) external onlyOwner {
        _contractURI = _URI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Transfer failed");
    }

    function flipSaleStarted() external onlyOwner {
        saleStarted = !saleStarted;
    }
}
