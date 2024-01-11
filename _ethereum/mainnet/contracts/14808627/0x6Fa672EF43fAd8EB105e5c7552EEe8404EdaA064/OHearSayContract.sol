// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC2981.sol";
import "./Strings.sol";

/// @title Objection Hearsay

contract OHearSayContract is
    ERC721A,
    IERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    /// @dev === CONTRACT META ===
    string public contractURIstr = "ipfs://QmaZHKj7dM3DbbBPGVL1VF999ZbEqz2rbxNHACafmnoEHU";
    string public baseExtension = ".json";
    string public notRevealedUri = "ipfs://QmaZHKj7dM3DbbBPGVL1VF999ZbEqz2rbxNHACafmnoEHU";
    string private baseURI;

    mapping(address => uint256) private _mintTracker;

    /// @dev === PRICE CONFIGURATION ===
    uint256 public constant MINT_PRICE = 0.015 ether;
    uint256 public royalty = 10;

    /// @dev === RESERVE/DROPS CONFIGURATION ===
    uint256 public constant NUMBER_RESERVED_TOKENS = 10;

    /// @dev === SALE CONFIGURATION ===
    bool public revealed = false;
    bool public saleIsActive = false;
    uint256 public constant MAX_SUPPLY = 1984;
    uint256 public maxPerTransaction = 2;
    uint256 public maxPerWallet = 2;

    /// @dev === Stats ===
    uint256 public currentId = 0;
    uint256 public reservedTokensMinted = 0;

    /// @dev === ACCEPTANCE TEST  ====
    bool public testWithDraw = false;
    bool public testReserved = false;

    constructor() ERC721A("OHearsay", "OHearsay") {}

    /// @dev === Minting Function - Input ====
    function mint(
        uint256 numberOfTokens
    )
        external
        payable
        isSaleActive(saleIsActive)
        canClaimToken(numberOfTokens)
        isCorrectPayment(MINT_PRICE, numberOfTokens)
        isCorrectAmount(numberOfTokens)
        isSupplyRemaining(numberOfTokens)
        nonReentrant
        whenNotPaused
    {
        _safeMint(msg.sender, numberOfTokens);
        currentId = currentId + numberOfTokens;
        _mintTracker[msg.sender] =
            _mintTracker[msg.sender] +
            numberOfTokens;
    }

    function mintReservedToken(address to, uint256 numberOfTokens)
        external
        canReserveToken(numberOfTokens)
        isNonZero(numberOfTokens)
        nonReentrant
        onlyOwner
    {
        testReserved = true;
        _safeMint(to, numberOfTokens);
        reservedTokensMinted = reservedTokensMinted + numberOfTokens;
    }

    /// @dev === Withdraw - Output  ====

    function withdraw() external onlyOwner {
        // This is a test to ensure we have atleast withdrawn the amount once in production.
        testWithDraw = true;
        payable(owner()).transfer(address(this).balance);
    }

    /// @dev === Override ERC721A ===

    /**
        We want our tokens to start at 1 not zero.
    */
    function _startTokenId() 
        internal 
        view 
        virtual 
        override 
        returns (uint256) 
    {
        return 1;
    }

    /// @dev === PUBLIC READ-ONLY ===

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /// @dev This is based on https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() 
        external 
        view 
        returns 
        (string memory) 
    {
        return contractURIstr;
    }

    function numberMinted(address owner) 
        public 
        view 
        returns 
        (uint256) 
    {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    /// @dev === INTERNAL READ-ONLY ===
    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return baseURI;
    }

    /// @dev === Owner Control/Configuration Functions ===

    function setReveal(bool _reveal) 
        public 
        onlyOwner 
    {
        revealed = _reveal;
    }

    function setBaseURI(string memory _newBaseURI) 
        public 
        onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) 
        public 
        onlyOwner 
    {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setContractURI(string calldata newuri) 
        external 
        onlyOwner
    {
        contractURIstr = newuri;
    }

    function pause() 
        external 
        onlyOwner 
    {
        _pause();
    }

    function unpause() 
        external 
        onlyOwner 
    {
        _unpause();
    }

    function flipSaleState() 
        external 
        onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    /// @dev Royalty should be added as whole number example 8.8 should be added as 88
    function updateSaleDetails(
        uint256 _royalty,
        uint256 _maxPerTransaction,
        uint256 _maxPerWallet
    )
        external
        isNonZero(_royalty)
        isNonZero(_maxPerTransaction)
        isNonZero(_maxPerWallet)
        onlyOwner
    {
        royalty = _royalty;
        maxPerTransaction = _maxPerTransaction;
        maxPerWallet = _maxPerWallet;
    }

    /// @dev === Marketplace Functions ===
    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) 
        public 
        override 
        view 
        returns 
        (bool isOperator) 
    {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721A.isApprovedForAll(_owner, _operator);
    }

    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    )
        external
        view
        override(IERC2981)
        returns (address Receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * royalty) / 100);
    }


    modifier canClaimToken(uint256 numberOfTokens) {
        require(
            _mintTracker[msg.sender] + numberOfTokens <= maxPerWallet,
            "Cannot claim more than allowed limit per address"
        );
        _;
    }

    modifier canReserveToken(uint256 numberOfTokens) {
        require(
            reservedTokensMinted + numberOfTokens <= NUMBER_RESERVED_TOKENS,
            "Cannot reserve more than 10 tokens"
        );
        _;
    }

    modifier isCorrectPayment(
        uint256 price, 
        uint256 numberOfTokens
    ) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isCorrectAmount(uint256 numberOfTokens) {
        require(
            numberOfTokens > 0 && numberOfTokens <= maxPerTransaction,
            "Max per transaction reached, sale not allowed"
        );
        _;
    }

    modifier isSupplyRemaining(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <=
                MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted),
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier isSaleActive(bool active) {
        require(active, "Sale must be active to mint");
        _;
    }

    modifier isNonZero(uint256 num) {
        require(num > 0, "Parameter value cannot be zero");
        _;
    }

    /// @dev === Support Functions ==
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}
