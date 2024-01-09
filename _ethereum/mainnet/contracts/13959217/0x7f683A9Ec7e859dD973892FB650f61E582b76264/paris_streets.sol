// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract ParisStreets is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    mapping (uint256 => uint256) private _salesStages;
    mapping (uint256 => bool) private _idAlreadyMinted;
    mapping (uint256 => uint256) private _tokenByIndex;

    // Global
    bool public preSalesIsActive = false;
    bool public publicSalesIsActive = false;
    uint256 public salesStage = 0;
    uint256 private _totalSupply = 0;
    uint256 private constant MAX_SALES_STAGES = 5;
    uint256 public constant MINT_MAX_STREETS_PRIVATESALES = 4;
    uint256 public constant BATCH_MAX_STREETS_PUBLICSALES = 20;
    uint256 public constant MAX_STREETS = 5520;
    uint256 public constant PRICE_PER_STREET = 10000000000000000;
    string private baseURI;
    
    constructor() ERC721("ParisStreets", "PARST") {
        _salesStages[0] = 1;                // Enable Collection
        _salesStages[1] = 56;               // PreSales
        _salesStages[2] = 606;              // Drop 1
        _salesStages[3] = 2256;             // Drop 2
        _salesStages[4] = MAX_STREETS;      // Drop 3
        _salesStages[5] = 0;                // Disable Mint
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "token not found for given URI query");
        uint256 _tokenId = _tokenByIndex[tokenId];
        string memory base = _baseURI();
        return string(abi.encodePacked(base, _tokenId.toString(), ".json"));
    }

    function setSalesStage (uint256 _stage) external onlyOwner{
        require(_stage <= MAX_SALES_STAGES, "requested stage is out of range");
        if (_stage == 0) {
            publicSalesIsActive = false;
            preSalesIsActive = false;
        } else if (_stage == 1) {
            publicSalesIsActive = false;
            preSalesIsActive = true;
        } else {
            publicSalesIsActive = true;
            preSalesIsActive = false;
        }
        salesStage = _stage;
    }

    function preSalesMint(uint256 _id) external payable nonReentrant {
        if (owner() != msg.sender) {
            require(preSalesIsActive, "preSales is not active");
        }
        uint256 _maxStreets = _salesStages[salesStage];
        require(_totalSupply + 1 <= _maxStreets, "max streets supply is exceeded for given stage");
        require(_id <= (_maxStreets), "ID not allowed for preSales"); 
        require(_idAlreadyMinted[_id] == false, "ID is already minted");
        require(balanceOf(msg.sender) < MINT_MAX_STREETS_PRIVATESALES, "max mint is exceeded for given account");
        if (owner() != msg.sender) {
            require(msg.value >= PRICE_PER_STREET, "amount of ether sent is not correct");
        }

        uint256 _tokenId = _totalSupply;
        _safeMint(msg.sender, _tokenId);
        _totalSupply += 1;
        _tokenByIndex[_tokenId] = _id;
        _idAlreadyMinted[_id] = true;
    }

    function publicSalesMint(uint256 _batch_count) external payable nonReentrant {
        require(publicSalesIsActive, "publicSales is not active");
        uint256 _totalMintedStreets = _totalSupply;
        uint256 _maxStreets = _salesStages[salesStage];
        require(_batch_count > 0, "batching must be greater than 0");
        require(_totalMintedStreets + _batch_count <= _maxStreets, "max streets supply is exceeded for given stage");
        require(_batch_count <= BATCH_MAX_STREETS_PUBLICSALES, "batching max is reached for given transaction");
        if (owner() != msg.sender) {
            require(msg.value >= (PRICE_PER_STREET * _batch_count), "Amount of ether sent is not correct");
        }

        for (uint256 i = 0; i < _batch_count; i++) {
            uint256 _tokenId = _totalSupply;
            _safeMint(msg.sender, _tokenId);
            _totalSupply += 1;
            _tokenByIndex[_tokenId] = _tokenId;
            _idAlreadyMinted[uint256(_tokenId)] = true;
        }
    }

    function mintVerify(uint256 _id) external view returns (bool){
        return _idAlreadyMinted[_id];
    }

    function remainingTokensByDrop (uint256 _stage) external view returns (uint256){
        uint256 _maxStreets = _salesStages[_stage];
        require(_totalSupply <= _maxStreets, "stage is closed");
        return _maxStreets - _totalSupply;
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    function tokenByIndex(uint256 id) external view virtual returns (uint256) {
        require(id < _totalSupply, "global index out of bounds");
        return _tokenByIndex[id];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}