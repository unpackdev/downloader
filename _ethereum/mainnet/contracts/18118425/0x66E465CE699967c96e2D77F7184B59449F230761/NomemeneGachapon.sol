//SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.7;  
  
import "./ERC721A.sol";  
import "./MerkleProof.sol";
import "./IERC721.sol";

import "./IERC1155.sol";

import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract NomemeneGachapon is ERC721A, ERC2981, Ownable, ReentrancyGuard {  
    address public pieContractAddress = 0xfb5aceff3117ac013a387D383fD1643D573bd5b4;
    
    address public split;

    string public baseURI;

    bool public baseURILocked = false;

    uint96 private royaltyBps = 1000;

    uint256 public whitelistPrice = 0.0111 ether;
    uint256 public publicPrice = 0.01 ether;

    uint256 public pieDiscountPct = 10;

    uint256 public maxSupply = 1378;

    bytes32 public whitelistMerkleRoot;

    mapping(address => bool) public gifters;

    mapping (uint256 => uint256) public quantityToDiscountPct;
    mapping (uint256 => bool) public quantityHasDiscount;

    uint256 public giveawaysClaimed = 0;
    uint256 public maxGiveaways = 100;

    mapping(address => bool) public claimedGiveaway;

    bool public mintPaused = true;
    bool public whitelistOnly = true;

    modifier onlyGifter() {
        require(gifters[_msgSender()] || owner() == _msgSender(), "Not a gifter");
        _;
    }

    constructor() ERC721A("NomemeneGachapon", "GACHA") {
        setQuantityDiscount(10, 20);
    }

    function updateMaxGiveaways(uint256 _maxGiveaways) public onlyOwner {
        maxGiveaways = _maxGiveaways;
    }

    function anyGiveawaysLeft() public view returns (bool) {
        return giveawaysClaimed < maxGiveaways;
    }

    function setQuantityDiscount(uint256 _quantity, uint256 _discountPct) public onlyOwner {
        quantityToDiscountPct[_quantity] = _discountPct;
        quantityHasDiscount[_quantity] = true;
    }

    function removeQuantityDiscount(uint256 _quantity) public onlyOwner {
        quantityToDiscountPct[_quantity] = 0;
        quantityHasDiscount[_quantity] = false;
    }

    function updateMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function updatePieContractAddress(address _address) public onlyOwner {
        pieContractAddress = _address;
    }

    function updatePieDiscountPct(uint256 _discountPct) public onlyOwner {
        pieDiscountPct = _discountPct;
    }

    function updatePublicPrice(uint256 _price) public onlyOwner {
        publicPrice = _price;
    }

    function updateWhitelistPrice(uint256 _price) public onlyOwner {
        whitelistPrice = _price;
    }

    function checkPieHolder(address user) public view returns (bool) {
        IERC721 pieContract = IERC721(pieContractAddress);
        bool hasPie = pieContract.balanceOf(user) > 0;
        return hasPie;
    }

    function setGifter(address gifter, bool isGifter) public onlyOwner {
        gifters[gifter] = isGifter;
    }

    function updateMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function updateMintPaused(bool _mintPaused) public onlyOwner {
        mintPaused = _mintPaused;
    }

    function updateWhitelistOnly(bool _whitelistOnly) public onlyOwner {
        whitelistOnly = _whitelistOnly;
    }

    function checkPrice(bool whitelisted, uint256 quantity, address user) public view returns (uint256) {
        uint256 paidQuantity = quantity;
        
        uint256 basePrice = whitelisted ? whitelistPrice : publicPrice;

        bool giveawaysLeft = anyGiveawaysLeft();

        if(whitelisted && giveawaysLeft && !claimedGiveaway[user]) {
            paidQuantity = quantity > 1 ? quantity - 1 : 0;
        }

        bool hasPie = checkPieHolder(user);

        uint256 total = basePrice * paidQuantity;

        uint256 discountPct = 0;

        if(hasPie) {
            discountPct += pieDiscountPct;
        }

        if(quantityHasDiscount[quantity]) {
            discountPct += quantityToDiscountPct[quantity];
        }

        uint256 discountAmt = (total * discountPct) / 100;

        total -= discountAmt;

        return total;
    }

    function mintWL(uint256 quantity, bytes32[] calldata merkleProof) public payable nonReentrant {
        require(!mintPaused, "minting paused");
        require(quantity > 0, "quantity must be greater than 0");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf), "invalid proof");

        require(totalSupply() + quantity <= maxSupply, "not enough supply");

        bool giveawaysLeft = anyGiveawaysLeft();

        uint256 totalPrice = checkPrice(true, quantity, msg.sender);
        require(msg.value == totalPrice, "did not send correct amount of eth");
        
        //claim giveaway after computing price
        if(giveawaysLeft && !claimedGiveaway[msg.sender]) {
            claimedGiveaway[msg.sender] = true;
            giveawaysClaimed++;
        }

        _safeMint(msg.sender, quantity);
    }

    function mintPublic(uint256 quantity) public payable nonReentrant {
        require(!mintPaused, "minting paused");
        require(!whitelistOnly, "whitelist only");
        require(quantity > 0, "quantity must be greater than 0");
        require(totalSupply() + quantity <= maxSupply, "max supply reached");

        uint256 totalPrice = checkPrice(false, quantity, msg.sender);

        require(msg.value == totalPrice, "not enough eth sent");

        _safeMint(msg.sender, quantity);
    }

    function gift(address[] memory recipients) public onlyGifter {
        require(recipients.length > 0, "no recipients");
        require(totalSupply() + recipients.length <= maxSupply, "max supply reached");

        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], 1);
        }
    }

    function updateRoyalty(uint96 _royaltyBps) public onlyOwner {
        require(split!=address(0), "split address not set, please set split address before updating royalty");
        royaltyBps = _royaltyBps;
        _setDefaultRoyalty(split, royaltyBps);
    }

    function updateBaseURI(string calldata givenBaseURI) public onlyOwner {
        require(!baseURILocked, "base uri locked");
       
        baseURI = givenBaseURI;
    }

    function lockBaseURI() public onlyOwner {
        baseURILocked = true;
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
    }
 
    function setSplitAddress(address _address) public onlyOwner {
        split = _address;
        _setDefaultRoyalty(split, royaltyBps);
    }

    function withdraw() public onlyOwner {
        require(split != address(0), "split address not set");

        (bool success, ) = split.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}