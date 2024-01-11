// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

contract DontFundAmber is ERC721A, Ownable, ReentrancyGuard {
    bool public isOpenMint = false;
    string public uriPrefix = "";
    string public uriExt = ".json";

    uint256 public constant max_Supply = 8888;
    uint256 public freeSupply = 6666;
    uint256 public public_Limit = 10;
    uint256 public free_Limit = 2;
    uint256 public totalFreeMinted = 0;
    uint256 public constant mint_Price = 0.0044 ether;

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public publicMinted;

    constructor (string memory _uriPrefix) ERC721A ("DontFundAmber.wtf", "DFAW") {
        setUri(_uriPrefix);
    }

    function setUri(string memory _newUri) public onlyOwner {
        uriPrefix = _newUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setOpenMint(bool status) public onlyOwner {
        isOpenMint = status;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setPublic_Limit(uint256 _public_Limit) public onlyOwner {
        public_Limit = _public_Limit;
    }

    function setFree_Limit(uint256 _free_Limit) public onlyOwner {
        free_Limit = _free_Limit;
    }

    function setFreeSupply (uint256 _freeSupply) public onlyOwner {
        freeSupply = _freeSupply;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token unavailable.");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI,  _toString(tokenId), uriExt))
            : '';
    }

    function freeMint(uint256 _quantity) public payable {
        require(isOpenMint, "Mint_Is_Not_Live.");
        require(_quantity > 0, "Must_Mint_Atleast_One.");
        require(totalFreeMinted + _quantity <= freeSupply, "No_More_Free_Supply.");
        require(totalSupply() + _quantity <= max_Supply, "No_More_Supply.");

        require(freeMinted[msg.sender] + _quantity <= free_Limit, "Free_Limit_Reached.");
        totalFreeMinted += _quantity;
        freeMinted[msg.sender] += _quantity;
        _safeMint(_msgSender(), _quantity);
    }

    function mint(uint256 _quantity) public payable {
        require(isOpenMint, "Mint_Is_Not_Live.");
        require(_quantity > 0, "Must_Mint_Atleast_One.");
        require(totalSupply() + _quantity <= max_Supply, "No_More_Supply.");

        require(publicMinted[msg.sender] + _quantity <= public_Limit, "Mint_Limit_Reached.");
        require(msg.value >= mint_Price * _quantity, "Insufficient_ETH");
        publicMinted[msg.sender] += _quantity;
        _safeMint(_msgSender(), _quantity);
    }

    function ownerMint(uint256 _quantity) external onlyOwner {
        require(_quantity + totalSupply() <= max_Supply, "Not_Enough_Supply.");
        _safeMint(_msgSender(), _quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, "Withdrawal_Failed.");
    }
}