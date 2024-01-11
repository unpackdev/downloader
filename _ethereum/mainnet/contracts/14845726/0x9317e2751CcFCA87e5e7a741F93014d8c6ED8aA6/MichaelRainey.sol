//SPDX-License-Identifier: MIT

// @title: Whereis22?

// .----------------.  .----------------.  .----------------.  .----------------.  .----------------.   .----------------.  .----------------.   .----------------.  .----------------.  
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | | .--------------. || .--------------. | | .--------------. || .--------------. |
// | | _____  _____ | || |  ____  ____  | || |  _________   | || |  _______     | || |  _________   | | | |     _____    | || |    _______   | | | |    _____     | || |    _____     | |
// | ||_   _||_   _|| || | |_   ||   _| | || | |_   ___  |  | || | |_   __ \    | || | |_   ___  |  | | | |    |_   _|   | || |   /  ___  |  | | | |   / ___ `.   | || |   / ___ `.   | |
// | |  | | /\ | |  | || |   | |__| |   | || |   | |_  \_|  | || |   | |__) |   | || |   | |_  \_|  | | | |      | |     | || |  |  (__ \_|  | | | |  |_/___) |   | || |  |_/___) |   | |
// | |  | |/  \| |  | || |   |  __  |   | || |   |  _|  _   | || |   |  __ /    | || |   |  _|  _   | | | |      | |     | || |   '.___`-.   | | | |   .'____.'   | || |   .'____.'   | |
// | |  |   /\   |  | || |  _| |  | |_  | || |  _| |___/ |  | || |  _| |  \ \_  | || |  _| |___/ |  | | | |     _| |_    | || |  |`\____) |  | | | |  / /____     | || |  / /____     | |
// | |  |__/  \__|  | || | |____||____| | || | |_________|  | || | |____| |___| | || | |_________|  | | | |    |_____|   | || |  |_______.'  | | | |  |_______|   | || |  |_______|   | |
// | |              | || |              | || |              | || |              | || |              | | | |              | || |              | | | |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | | '--------------' || '--------------' | | '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------'   '----------------'  '----------------'   '----------------'  '----------------'

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract WhereIs22 is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public _tokenUriBase;

    uint256 public _maxTokens = 10000;
    uint256 public _maxPublicTokens = 7778;
    uint256 public _maxPresaleTokens = 2222;

    uint256 public _mintPricePreSale = 0.25 ether;
    uint256 public _mintPricePublic = 0.5 ether;
    
    uint256 public _maxMints = 10;
    
    mapping(address => bool) private _freeMintList;

    bool public _saleActive;
    bool private _preSaleActive;
    
    constructor() ERC721A("whereis22?", "22?") {
        // set ipfs base url
        _tokenUriBase = "ipfs://bafybeifecsz5k5hcquxlbjvfl52s25yikcv7de6qcd7y3tl3bnv52jlbmu";
    }
    
    // ------- Modifiers -------
    modifier canMintPublic() {
        require(_saleActive, "Sale inactive");
        require(totalSupply() + 1 <= _maxTokens, "Max exceeded");
        _;
    }

    modifier isCorrectPrice(uint256 count, uint256 price) {
        if (!_freeMintList[_msgSender()]) {
            require(msg.value >= count * price, "Invalid price");
        }
        _;
    }

    modifier canMintPresale() {
        require(_preSaleActive, "Sale inactive");
        require(!_saleActive, "Sale inactive");
        require(totalSupply() + 1 <= _maxPresaleTokens, "Max exceeded");
        _;
    }

    // ------------------------------------------

    // ------- Public read-only function --------
    function getBaseURI() external view returns (string memory) {
        return _tokenUriBase;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return string(abi.encodePacked(_tokenUriBase, "/", Strings.toString(tokenId), ".json"));
    }
    // ------------------------------------------

    function presaleMint(uint256 quantity) external payable canMintPresale() isCorrectPrice(quantity, _mintPricePreSale) nonReentrant {
        require(quantity <= _maxMints, "Max exceeded");
        _safeMint(_msgSender(), quantity);
    }

    function presaleMint() external payable canMintPresale() isCorrectPrice(1, _mintPricePreSale) nonReentrant {
        _safeMint(_msgSender(), 1);
    }

    function mint(uint256 quantity) external payable canMintPublic() isCorrectPrice(quantity, _mintPricePublic) nonReentrant {
        require(quantity <= _maxMints, "Max exceeded");
        _safeMint(_msgSender(), quantity);
    }
    
    function mint() external payable canMintPublic() isCorrectPrice(1, _mintPricePublic) nonReentrant {
        _safeMint(_msgSender(), 1);
    }

    // ------- Owner functions --------
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenUriBase = baseURI;
    }
    
    function setPreSale(bool preSaleActive) external onlyOwner {
        _preSaleActive = preSaleActive;
    }

    function setSale(bool saleActive) external onlyOwner {
        _saleActive = saleActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function setTotalTokens(uint256 newTotalTokens) external onlyOwner {
        require (
            newTotalTokens >= _maxTokens,
            "Cant destroy"
        );
        _maxTokens = newTotalTokens;
    }
    
    function toggleFreeMint(address a, bool b) external onlyOwner {
        _freeMintList[a] = b;
    }
    
    function changeMintPrice(uint256 mintPrice) external onlyOwner {
        _mintPricePublic = mintPrice;
    }
    // ------------------------------------------

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}