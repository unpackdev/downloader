//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Uniman is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    // URI
    // ------------------------------------------------------------------------
    string public baseTokenURI;

    // Constants
    // ------------------------------------------------------------------------
    uint256 private constant PRIVATE_UNIMAN = 25;
    uint256 private constant PRESALE_UNIMAN = 200;
    uint256 public constant MAX_UNIMAN = 888;
    uint256 private constant PRICE = 0.025 ether;

    // State variables
    // ------------------------------------------------------------------------
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;
    bool public isMetadataLocked = false;

    // Presale arrays
    // ------------------------------------------------------------------------
    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _presaleClaimed;

    // Error messages
    // ------------------------------------------------------------------------
    string private constant ALL_TOKENS_MINTED = "All uniman minted";
    string private constant TOKEN_LIMIT_EXCEEDED =
        "Not enough uniman left to mint";
    string private constant PRESALE_NOT_ACTIVE = "Presale is not active";
    string private constant PUBLIC_SALE_NOT_ACTIVE =
        "Public sale is not active";
    string private constant NOT_ELIGIBLE_FOR_PRESALE =
        "You are not eligible for presale";
    string private constant PRESALE_SOLD_OUT = "Presale is sold out";
    string private constant METADATA_LOCKED = "Metadata is locked";
    string private constant INVALID_ETH_AMOUNT =
        "Invalid eth amount. Price is 0.025 per uniman.";

    constructor(string memory baseURI) ERC721("uniman", "uniman") {
        setBaseURI(baseURI);

        // Withdraw 25 tokens for the team, giveaways, promos, etc.
        _mintTokensToAddr(PRIVATE_UNIMAN, msg.sender);
    }

    // Withdraws eth from the contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address payable to = payable(msg.sender);
        to.transfer(balance);
    }

    function _mintTokensToAddr(uint256 amount, address receiver) internal {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _safeMint(receiver, newTokenId);
        }
    }

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyPresale() {
        require(isPresaleActive, PRESALE_NOT_ACTIVE);
        _;
    }

    modifier onlyPublicSale() {
        require(isPublicSaleActive, PUBLIC_SALE_NOT_ACTIVE);
        _;
    }

    modifier notLockedMetadata() {
        require(!isMetadataLocked, METADATA_LOCKED);
        _;
    }

    // State toggling
    // ------------------------------------------------------------------------
    function togglePresaleStatus() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }

    // Presale utilities
    // ------------------------------------------------------------------------
    function addToPresaleAndTogglePresaleStatus(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "NULL_ADDRESS");
            require(!_presaleEligible[addresses[i]], "DUPLICATE_ENTRY");

            _presaleEligible[addresses[i]] = true;
            _presaleClaimed[addresses[i]] = 0;
        }
        isPresaleActive = true;
    }

    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "NULL_ADDRESS");
            require(!_presaleEligible[addresses[i]], "DUPLICATE_ENTRY");

            _presaleEligible[addresses[i]] = true;
            _presaleClaimed[addresses[i]] = 0;
        }
    }

    function removeFromPresaleList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "NULL_ADDRESS");
            require(_presaleEligible[addresses[i]], "NOT_IN_PRESALE");

            _presaleEligible[addresses[i]] = false;
        }
    }

    function isEligibleForPresale(address addr) external view returns (bool) {
        require(addr != address(0), "NULL_ADDRESS");

        return _presaleEligible[addr];
    }

    function hasClaimedPresale(address addr) external view returns (bool) {
        require(addr != address(0), "NULL_ADDRESS");

        return _presaleClaimed[addr] == 1;
    }

    // Minting functions
    // ------------------------------------------------------------------------
    function claimPresale(uint256 numberOfTokens) external payable onlyPresale {
        require(numberOfTokens > 0, "Number of tokens must be positive");
        require(_presaleEligible[msg.sender], NOT_ELIGIBLE_FOR_PRESALE);

        require(
            totalSupply() + numberOfTokens <= PRESALE_UNIMAN + PRIVATE_UNIMAN,
            PRESALE_SOLD_OUT
        );
        require(msg.value >= PRICE * numberOfTokens, INVALID_ETH_AMOUNT);

        _presaleClaimed[msg.sender] += numberOfTokens;
        _mintTokensToAddr(numberOfTokens, msg.sender);
    }

    function mint(uint256 numberOfTokens) public payable onlyPublicSale {
        require(
            totalSupply() + numberOfTokens <= MAX_UNIMAN,
            TOKEN_LIMIT_EXCEEDED
        );

        require(numberOfTokens > 0, "Number of tokens must be positive");
        require(msg.value >= PRICE * numberOfTokens, INVALID_ETH_AMOUNT);

        _mintTokensToAddr(numberOfTokens, msg.sender);
    }

    // Mint an amount of tokens for free to an address `to`
    function mintTokensToAddress(uint256 numberOfTokens, address to)
        external
        onlyOwner
    {
        require(
            totalSupply() + numberOfTokens <= MAX_UNIMAN,
            TOKEN_LIMIT_EXCEEDED
        );
        _mintTokensToAddr(numberOfTokens, to);
    }

    // Mint one token for free to multiple addresses
    function mintTokenToAddresses(address[] memory addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(totalSupply() + 1 <= MAX_UNIMAN, TOKEN_LIMIT_EXCEEDED);
            address to = addresses[i];
            _mintTokensToAddr(1, to);
        }
    }

    // URI functions
    // ------------------------------------------------------------------------
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Only callable when the metadata is still unlocked
    // Will be locked after reveal
    function setBaseURI(string memory baseURI)
        public
        onlyOwner
        notLockedMetadata
    {
        baseTokenURI = baseURI;
    }
}
