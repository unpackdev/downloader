// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";


//  ███████████ █████                  ███████████  ████                    █████             
// ░█░░░███░░░█░░███                  ░░███░░░░░███░░███                   ░░███              
// ░   ░███  ░  ░███████    ██████     ░███    ░███ ░███   ██████   ██████  ░███ █████  █████ 
//     ░███     ░███░░███  ███░░███    ░██████████  ░███  ███░░███ ███░░███ ░███░░███  ███░░  
//     ░███     ░███ ░███ ░███████     ░███░░░░░███ ░███ ░███ ░███░███ ░░░  ░██████░  ░░█████ 
//     ░███     ░███ ░███ ░███░░░      ░███    ░███ ░███ ░███ ░███░███  ███ ░███░░███  ░░░░███
//     █████    ████ █████░░██████     ███████████  █████░░██████ ░░██████  ████ █████ ██████ 
//    ░░░░░    ░░░░ ░░░░░  ░░░░░░     ░░░░░░░░░░░  ░░░░░  ░░░░░░   ░░░░░░  ░░░░ ░░░░░ ░░░░░░  


contract TheBlocks is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    event Gift(address[] receivers);
    event GiftMultiple(address indexed receiver, uint256 quantity);

    event PublicPurchase(address indexed user, uint256 indexed quantity);


    uint256 private _totalMinted;

    uint256 public constant GIFT = 100;
    uint256 public constant PUBLIC = 3233;


    uint256 public constant MAX = GIFT + PUBLIC;

    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant WHITELIST_PRICE = 0.04 ether;
    uint256 public constant PUBLIC_PER_MINT = 10;
    uint256 public constant PRESALE_PURCHASE_LIMIT = 10;

    mapping(address => uint256) public presalerListPurchases;
    mapping(address => uint256) public publicListPurchases;


    string private baseExtension = ".json";

    string private _tokenBaseURI = "";
    string private notRevealedUri = "https://ipfs.io/ipfs/QmSxaRduPjkHcigiiquUzKMXUPYMTfdZhC6oJkcsGyNwDf";

    uint256 public giftedAmount;
    uint256 public publicAmountMinted;

    bool public presaleLive;
    bool public saleLive;
    bool public revealed;
    bool public locked;

    string public proof;

    constructor() ERC721("The Blocks", "BLOCKS") {
        setNotRevealedURI(notRevealedUri);
    }

    modifier notLocked() {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    function getPrice() public view returns(uint) {
        return presaleLive ? WHITELIST_PRICE: PRICE; 
    }

    function buy(uint256 tokenQuantity) external payable nonReentrant {
        require(saleLive || presaleLive, "SALE_CLOSED_OR_ONLY_PRESALE");
        require(_totalMinted + tokenQuantity <= MAX, "OUT_OF_STOCK");
        require(publicAmountMinted + tokenQuantity <= PUBLIC, "EXCEED_MINT");
        require(
            publicListPurchases[_msgSender()] + tokenQuantity <=
            PUBLIC_PER_MINT,
            "EXCEED_PUBLIC_ALLOC"
        );
        require(getPrice() * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            publicListPurchases[_msgSender()]++;
            _safeMint(_msgSender(), ++_totalMinted);
        }

        emit PublicPurchase(msg.sender, tokenQuantity);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(_totalMinted + receivers.length <= MAX, "OUT_OF_STOCK");
        require(giftedAmount + receivers.length <= GIFT, "GIFTS_EMPTY");

        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], ++_totalMinted);
        }

        emit Gift(receivers);
    }

    function giftMultiple(address receiver, uint256 quantity) external onlyOwner {
        require(_totalMinted + quantity <= MAX, "OUT_OF_STOCK");
        require(giftedAmount + quantity <= GIFT, "GIFTS_EMPTY");

        for (uint256 i = 0; i < quantity; i++) {
            giftedAmount++;
            _safeMint(receiver, ++_totalMinted);
        }

        emit GiftMultiple(receiver, quantity);
    }

    function burn(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), baseExtension));
    }

    function totalSupply() external view returns (uint256) {
        return _totalMinted;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
        proof = hash;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner notLocked {
        notRevealedUri = _notRevealedURI;
    }
}