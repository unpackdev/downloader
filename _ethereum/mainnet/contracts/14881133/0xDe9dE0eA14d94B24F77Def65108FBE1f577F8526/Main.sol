pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract WizardTown is Ownable, ERC721A, ReentrancyGuard {
    constructor() ERC721A("Wizard Town", "WTOWN") {}

    string private baseURI;

    bool public publicSaleActive;

    uint256 public constant maxMintPerTx = 10;
    uint256 public constant maxMintPerAddress = 10;

    uint256 public constant MAX_PUBLIC_SALE_AMOUNT = 10000;

    uint256 public mintPrice = 0.003 ether;

    mapping(address => uint256) public mintedPerAddress;
    string public baseUri;

    modifier callerIsUser () {
        require(msg.sender == tx.origin, "Not allowed");
        _;
    }

    modifier whenPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string memory _base) external onlyOwner {
        baseUri = _base;
    }

    function ownerMint(uint256 quantity) external onlyOwner callerIsUser {
        uint256 mintedAmount = totalSupply();

        require(mintedAmount + quantity <= MAX_PUBLIC_SALE_AMOUNT, "Minting would exceed max supply");

        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable callerIsUser whenPublicSaleActive nonReentrant {
        uint256 mintedAmount = totalSupply();

        require(mintedAmount + quantity <= MAX_PUBLIC_SALE_AMOUNT, "Minting would exceed max supply");
        require(quantity <= maxMintPerTx, "Token amount should not exceed maxMintPerTx");
        require(quantity + mintedPerAddress[msg.sender] <= maxMintPerAddress, "Sender address cannot mint more than maxMintPerAddress");
     
        if (mintedAmount >= 5000) {
            require(msg.value >= quantity * mintPrice, "Not enough ether sent");
        }

        mintedPerAddress[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}