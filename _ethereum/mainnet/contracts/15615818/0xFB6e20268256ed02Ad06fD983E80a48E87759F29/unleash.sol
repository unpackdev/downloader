////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                                                      ///
///                                                                                                                                      ///
///                                                                                                                                      ///
///                               █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█                               ///
///                               █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█                               ///
///                               █░░░░                                                              ░░░░█                               ///
///                               █░░░░  ██╗░░░██╗███╗░░██╗██╗░░░░░███████╗░█████╗░░██████╗██╗░░██╗  ░░░░█                               ///
///                               █░░░░  ██║░░░██║████╗░██║██║░░░░░██╔════╝██╔══██╗██╔════╝██║░░██║  ░░░░█                               ///
///                               █░░░░  ██║░░░██║██╔██╗██║██║░░░░░█████╗░░███████║╚█████╗░███████║  ░░░░█                               ///
///                               █░░░░  ██║░░░██║██║╚████║██║░░░░░██╔══╝░░██╔══██║░╚═══██╗██╔══██║  ░░░░█                               ///
///                               █░░░░  ╚██████╔╝██║░╚███║███████╗███████╗██║░░██║██████╔╝██║░░██║  ░░░░█                               ///
///                               █░░░░  ░╚═════╝░╚═╝░░╚══╝╚══════╝╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝  ░░░░█                               ///
///                               █░░░░                                                              ░░░░█                               ///
///                               █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█                               ///
///                               █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█                               ///
///                                                                                                                                      ///
///                                                                                                                                      ///
///                                                                                                                                      ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC2981.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract ProjectUnleash is
    ERC721A,
    IERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    string private contractURIstr = "";
    string public baseExtension = ".json";
    string public notRevealedUri = "ipfs://Qmbudj6tQ2XGB5ru37Mtd1weXgUxRxF9Bn3Bm5PVW57YZH/";
    string private baseURI;

    bytes32 public premintlistMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    uint256 public PUBLIC_PRICE = 0.03 ether;  
    uint256 public PREMINT_PRICE = 0.027 ether;  
    uint256 public constant WHITELIST_PRICE = 0.000 ether;  

    uint256 public royalty = 65; 

    uint256 public constant NUMBER_RESERVED_TOKENS = 1000; // Team Reverse 

    bool public revealed = false;
    bool public publicListSaleisActive = true;
    bool public whiteListSaleisActive = false;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public maxPerTransaction = 3;
    uint256 public maxPerWallet = 3;
    uint256 public maxPerTransactionWL = 1;
    uint256 public maxPerWalletWL = 1;


    uint256 public currentId = 0;
    uint256 public publiclistMint = 0;
    uint256 public whitelistMint = 0;
    uint256 public reservedTokensMinted = 0;

    bool public testWithDraw = false;
    bool public testReserved = false;

    mapping(address => uint256) private _publiclistMintTracker;
    mapping(address => uint256) private _whitelistMintTracker;

    constructor( string memory _name, string memory _symbol) ERC721A("Project Unleash", "ULH"){}
    
    function publicMint(
        uint256 numberOfTokens
    )
        external
        payable
        isSaleActive(publicListSaleisActive)
        canClaimTokenPublic(numberOfTokens)
        isCorrectPayment(PUBLIC_PRICE, numberOfTokens)
        isCorrectAmount(numberOfTokens)
        isSupplyRemaining(numberOfTokens)
        nonReentrant
        whenNotPaused
    {
        _safeMint(msg.sender, numberOfTokens);
        currentId = currentId + numberOfTokens;
        publiclistMint = publiclistMint + numberOfTokens;
        _publiclistMintTracker[msg.sender] =
            _publiclistMintTracker[msg.sender] +
            numberOfTokens;
    }

    function preMint(
        bytes32[] calldata merkleProof,
        uint256 numberOfTokens
    )
        external
        payable
        isSaleActive(publicListSaleisActive)
        isValidMerkleProof(merkleProof, premintlistMerkleRoot)
        canClaimTokenPublic(numberOfTokens)
        isCorrectPayment(PREMINT_PRICE, numberOfTokens)
        isCorrectAmount(numberOfTokens)
        isSupplyRemaining(numberOfTokens)
        nonReentrant
        whenNotPaused
    {
        _safeMint(msg.sender, numberOfTokens);
        currentId = currentId + numberOfTokens;
        publiclistMint = publiclistMint + numberOfTokens;
        _publiclistMintTracker[msg.sender] =
            _publiclistMintTracker[msg.sender] +
            numberOfTokens;
    }

    function wlMint(
        bytes32[] calldata merkleProof,
        uint256 numberOfTokens
    )
        external
        payable
        isSaleActive(whiteListSaleisActive)
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        canClaimTokenWL(numberOfTokens)
        isCorrectPayment(WHITELIST_PRICE, numberOfTokens)
        isCorrectAmountWL(numberOfTokens)
        isSupplyRemainingWL(numberOfTokens)
        nonReentrant
        whenNotPaused
    {
        _safeMint(msg.sender, numberOfTokens);
        currentId = currentId + numberOfTokens;
        whitelistMint = whitelistMint + numberOfTokens;
        _whitelistMintTracker[msg.sender] =
            _whitelistMintTracker[msg.sender] +
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

    function withdraw() external onlyOwner {
        testWithDraw = true;
        payable(owner()).transfer(address(this).balance);
    }


    function _startTokenId() 
        internal 
        view 
        virtual 
        override 
        returns (uint256) 
    {
        return 1;
    }

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

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return baseURI;
    }

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

    function setWhitelistMerkleRoot(bytes32 merkleRoot) 
        external 
        onlyOwner 
    {
        whitelistMerkleRoot = merkleRoot;
    }

    function setPremintMerkleRoot(bytes32 merkleRoot) 
        external 
        onlyOwner 
    {
        premintlistMerkleRoot = merkleRoot;
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

    function flipPubliclistSaleState() 
        external 
        onlyOwner 
    {
        publicListSaleisActive = !publicListSaleisActive;
    }

    function flipWhitelistSaleState() 
        external 
        onlyOwner 
    {
        whiteListSaleisActive = !whiteListSaleisActive;
    }

    function updateSaleDetails(
        uint256 _royalty
    )
        external
        isNonZero(_royalty)
        onlyOwner
    {
        royalty = _royalty;
    }

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
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
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
        return (owner(), (_salePrice * royalty) / 1000); //100*10 = 1000
    }

    modifier isValidMerkleProof(
        bytes32[] calldata merkleProof, 
        bytes32 root
    ) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier canClaimTokenPublic(uint256 numberOfTokens) {
        require(
            _publiclistMintTracker[msg.sender] + numberOfTokens <= maxPerWallet,
            "Cannot claim more than allowed limit per address"
        );
        _;
    }

    modifier canClaimTokenWL(uint256 numberOfTokens) {
        require(
            _whitelistMintTracker[msg.sender] + numberOfTokens <= maxPerWalletWL,
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
                price * numberOfTokens== msg.value,
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

    modifier isCorrectAmountWL(uint256 numberOfTokens) {
        require(
            numberOfTokens > 0 && numberOfTokens <= maxPerTransactionWL,
            "Max per transaction reached, sale not allowed"
        );
        _;
    }

    modifier isSupplyRemaining(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <=
                MAX_SUPPLY - 1000 - (NUMBER_RESERVED_TOKENS - reservedTokensMinted),
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier isSupplyRemainingWL(uint256 numberOfTokens) {
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

    function setPrice(uint256 _price)
         public 
         onlyOwner 
    {
        PUBLIC_PRICE = _price;
    }

    function setPremintPrice(uint256 _price)
         public 
         onlyOwner 
    {
        PREMINT_PRICE = _price;
    }


}