// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract VIMCard is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI;

    string private collectionURI;

    enum SaleState {
        Active,
        Inactive
    }

    SaleState public saleState = SaleState.Inactive;

    address public royaltyReceiverAddress;

    uint256 public constant MAX_TOTAL_SUPPLY = 50;

    uint256 public constant MAX_PUBLIC_SALE_MINTS = 5;

    uint256 public constant ROYALTY_PERCENTAGE = 5;

    constructor(address _royaltyReceiverAddress) ERC721("VIMCard", "VIM")
    {
        royaltyReceiverAddress = _royaltyReceiverAddress;
    }

    // ============ ACCESS CONTROL MODIFIERS ============
    modifier saleActive() {
        require(saleState == SaleState.Active, "Sale is not open");
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <= MAX_TOTAL_SUPPLY,
            "Insufficient tokens remaining"
        );
        require(
            numberOfTokens <= MAX_PUBLIC_SALE_MINTS,
            "Exceeds max number for public mint"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mintPublicSale(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        saleActive
        canMint(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    /**
     * @dev reserve tokens for self
     */
    function reserveTokens(uint256 numToReserve)
        external
        nonReentrant
        onlyOwner
        canMint(numToReserve)
    {
        for (uint256 i = 0; i < numToReserve; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    /**
     * @dev gift token directly to list of recipients
     */
    function giftTokens(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canMint(addresses.length)
    {
        uint256 numRecipients = addresses.length;

        for (uint256 i = 0; i < numRecipients; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ SUPPORTING FUNCTIONS ============
    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // ============ FUNCTION OVERRIDES ============
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non-existent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }
    
    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    /**
     * @dev support EIP-2981 interface for royalties
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");

        return (
            royaltyReceiverAddress,
            SafeMath.div(SafeMath.mul(salePrice, ROYALTY_PERCENTAGE), 100)
        );
    }

    /**
     * @dev support EIP-2981 interface for royalties
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setSaleActive() external onlyOwner {
        saleState = SaleState.Active;
    }

    function setSaleInactive() external onlyOwner {
        saleState = SaleState.Inactive;
    }

    /**
     * @dev used for art reveals
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setCollectionURI(string memory _collectionURI) external onlyOwner {
        collectionURI = _collectionURI;
    }

    function setRoyaltyReceiverAddress(address _royaltyReceiverAddress)
        external
        onlyOwner
    {
        royaltyReceiverAddress = _royaltyReceiverAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @dev enable contract to receive ethers in royalty
     */
    receive() external payable {}
}
