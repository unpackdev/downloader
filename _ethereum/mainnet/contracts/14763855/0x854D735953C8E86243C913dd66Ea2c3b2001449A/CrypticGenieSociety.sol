// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract CrypticGenieSociety is ERC721Enumerable, Pausable, Ownable {
    using Strings for uint256;

    string public _contractURI;
    string public _tokenBaseURI;
    string public _notRevealedURI;

    uint256 public PRICE = 0.04 ether;
    uint256 public constant SUPPLY_GIFT = 688;
    uint256 public constant SUPPLY_PRESALE = 200;
    uint256 public constant SUPPLY_PUBLIC = 9000;
    uint256 public MAX_PER_MINT = 5;
    uint256 public constant PRESALE_MAX_PER_MINT = 2;

    uint256 public _giftMinted;
    uint256 public _preSaleMinted;
    uint256 public _publicMinted;

    mapping(address => bool) public _preSaleList;
    mapping(address => uint256) public _preSaleListPurchases;

    bool public isPreSaleLive = false;
    bool public isPublicSaleLive = false;
    bool public isRevealed = false;

    address private _masterAddress = 0xc1b21365a57D29FCfeeD53139e7456dbB36c2C2f;

    modifier whenPreSaleIsLive() {
        require(isPreSaleLive, "PRESALE_NOT_STARTED");
        _;
    }

    modifier whenPublicSaleIsLive() {
        require(isPublicSaleLive, "SALE_NOT_STARTED");
        _;
    }

    constructor(
        string memory _initTokenBaseURI,
        string memory _initContractURI,
        string memory _initNotRevealedURI
    ) ERC721("Cryptic Genie Society", "CGS") {
        setTokenBaseURI(_initTokenBaseURI);
        setContractURI(_initContractURI);
        setNotRevealedURI(_initNotRevealedURI);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= SUPPLY_PUBLIC + SUPPLY_PRESALE + SUPPLY_GIFT, "EXCEED_SUPPLY_LIMIT");
        require(_giftMinted + receivers.length <= SUPPLY_GIFT, "EXCEED_GIFT_LIMIT");

        for (uint256 i = 0; i < receivers.length; i++) {
            _giftMinted++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function addToPreSaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            require(entries[i] != address(0), "INVALID_ADDRESS");
            require(!_preSaleList[entries[i]], "DUPLICATE_ENTRY");
            _preSaleList[entries[i]] = true;
        }
    }

    function removeFromPreSaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            require(entries[i] != address(0), "INVALID_ADDRESS");
            _preSaleList[entries[i]] = false;
        }
    }

    function mintPreSale(uint256 tokenQuantity) external payable whenPreSaleIsLive {
        require(_preSaleList[msg.sender], "PRESALE_ELIGIBLE");
        require(totalSupply() <= SUPPLY_PUBLIC + SUPPLY_PRESALE + SUPPLY_GIFT, "OUT_OF_STOCK");
        require(_preSaleMinted + tokenQuantity <= SUPPLY_PRESALE, "EXCEED_PRESALE_LIMIT");
        require(_preSaleListPurchases[msg.sender] + tokenQuantity <= PRESALE_MAX_PER_MINT, "PER_MINT_LIMIT");
        require(PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETHER");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _preSaleMinted++;
            _preSaleListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function mint(uint256 tokenQuantity) external payable whenPublicSaleIsLive {
        require(!paused(), "Pausable: paused");
        require(totalSupply() <= SUPPLY_PUBLIC + SUPPLY_PRESALE + SUPPLY_GIFT, "OUT_OF_STOCK");
        require(totalSupply() + tokenQuantity <= SUPPLY_PUBLIC + SUPPLY_PRESALE + SUPPLY_GIFT, "EXCEED_SUPPLY_LIMIT");
        require(tokenQuantity <= MAX_PER_MINT, "PER_MINT_LIMIT");
        require(PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETHER");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _publicMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function togglePause(bool state) public onlyOwner {
        if (state == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function toggleReveal() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function togglePreSaleLive() public onlyOwner {
        isPreSaleLive = !isPreSaleLive;
    }

    function togglePublicSaleLive() public onlyOwner {
        isPublicSaleLive = !isPublicSaleLive;
    }

    function setPrice(uint256 cost) public onlyOwner {
        PRICE = cost;
    }

    function setMaxPerMint(uint256 qty) public onlyOwner {
        MAX_PER_MINT = qty;
    }

    function setTokenBaseURI(string memory URI) public onlyOwner {
        _tokenBaseURI = URI;
    }

    function setContractURI(string memory URI) public onlyOwner {
        _contractURI = URI;
    }

    function setNotRevealedURI(string memory URI) public onlyOwner {
        _notRevealedURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (isRevealed == false) {
            return _notRevealedURI;
        }

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json"));
    }

    function setMasterAddress(address addr) external onlyOwner {
        _masterAddress = addr;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "INSUFFICIENT_ETHER");
        (bool success, ) = payable(_masterAddress).call{value: amount}("");
        require(success, "ETHER_WITHDRAW_FAILED");
    }
}
