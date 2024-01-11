// SPDX-License-Identifier: MIT
/// @title Creat00r Blacklist ERC-721 token
/// @author Bitstrays Team

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                 ,▄▄                                              //
//                                 ▓███▄▄▓██▄                                       //
//                            ,╔▄██████▌     ║████Γ                                 //
//                         ╔██▀   █████▌     ║████      ╟██▄                        //
//                      ╓█▀╙     ]██████     ║███▌      ╟█████▓,                    //
//                   ,▄█▀        ║██████⌐    ║███▌      ▐████████▄                  //
//                  ▄█╙          ╟██████▒    ║███▌       ██████████▄                //
//                ╓█▀            ║██████▌    ║███▒       ████████████▄              //
//               ▐█              ╫██████▌    ║███▒       ██████████████             //
//              ▄█               ╟██████▌    ║███▒       ███████████████            //
//             ╔█                ╟██████▌    ║███▌       ████████████████           //
//            ,█⌐                ║██████⌐    ║███▌      ▐████████████████▌          //
//            ║▌                 ╙██████     ║███▌      ║█████████████████          //
//            █▌                  █████▌     ║████      ╟█████████████████▌         //
//           ]█     ]▄            ╟████▌     ║████▒    ]████████████╙╟████▌         //
//           ▐█     ▐█             ████      ║█████    ╟███████████▌ ▐████▌         //
//            ▓▒     █▒            └▀▀       ║██████,,▓████████████▌ ╟████▌         //
//            ╟▌     ║█                      ║█████████████████████ ]█████⌐         //
//            ╙█      ╟█                     ║████████████████████╜ ╣████▌          //
//             ╟▌      ╫▌                    ║███████████████████⌐ ▓█████           //
//              ╫▌      ╚█µ                  ║█████████████████▀ ,▓█████`           //
//               ╟█      └▀█                 ║████████████████` ▄██████             //
//                ╚█µ      `▀█▄              ║█████████████▀ ,▄██████▀              //
//                 `██        ╙▀█▄,          ║█████████▀╙ ,▄████████╙               //
//                   ╙█▄         `╙▀██▄▄╦╓╓,╓╚▀▀▀▀▀╙  ,╗▄█████████╙                 //
//                     "▀█╦              ╙╙╙╙╔▄▄▄▓█████████████▀                    //
//                        ╙▀█▄,              ║█████████████▀▀                       //
//                           `╙▀█▄╦╓         ║████████▀▀╙                           //
//                                 ╙▀▀▀█████▓                                       //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////

pragma solidity 0.8.9;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./IProxyRegistry.sol";

/** @author Bitstrays Team
* @title This is the Creat00r $Blacklist NFT contract
* collection of 333 IPFS based NFT's
* 100 claimed by merkle proof claim mechanim
* 100 minted during gen1 minting event
* 100 minted during gen2 minting event
* 33 tresuray reserve
*/
contract Blacklist is IERC2981, Ownable, ReentrancyGuard, ERC721Enumerable {
    using Strings for uint256;

    string private baseURI;
    uint16 public constant CLAIMABLE_TOKEN = 100;
    uint16 public constant GENERATION_ONE = 200;
    uint16 public constant TREASURY = 33;
    address[3] public creat00rs;

    uint256 public PUBLIC_SALE_PRICE = 1 ether;
    string public verificationHash;
    address private openSeaProxyRegistryAddress;
    address private royaltyPayout;
    bool private isOpenSeaProxyActive = true;
    bool private isBulkPriceActive = false;
    uint public immutable claimExpiration;
    // seller fee basis points 100 == 10%
    uint16 public sellerFeeBasisPoints = 100;

    bool public isGen1SaleActive;
    bool public isGen2SaleActive;
    bool public isClaimActive;
    bool public isBlacklistActive;

    uint256 public maxBlacklist;

    bytes32 public claimListMerkleRoot;
    bytes32 public blacklistMerkleRoot;
    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // IPFS content hash of contract-level metadata
    string private contractURIHash = 'QmQNdhY8RHi8arMZ58c36pJNDCFHLtomk2qfgMuEtKrDmx';

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier gen1SaleActive() {
        require(isGen1SaleActive, "Generation 1 sale is not open");
        _;
    }

    modifier gen2SaleActive() {
        require(isGen2SaleActive, "Generation 2 sale is not open");
        _;
    }

    /**
     * @notice
     * fails claim after claimExpiration
     * Unclaimed NFT will never exists
     */
    modifier claimIsActive() {
        require(isClaimActive, "$Blacklist claim is not enabled");
        require(block.timestamp <= claimExpiration, "$Blacklist claim window expired");
        _;
    }

    modifier blacklistIsActive() {
        require(isBlacklistActive, "$Blacklist lottery is not enabled");
        _;
    }

    modifier canMintBlacklistGen1(uint256 tokenId) {
        require(
            tokenId > CLAIMABLE_TOKEN && tokenId <= GENERATION_ONE,
            "Can't mint blacklisted tokenId's in range [1,100]"
        );
        require(_exists(tokenId) == false, "tokenId already exists");
        _;
    }

    /**
     * @notice
     * Prevent future changes to [1,100] claim mechanism
     * 1-100 have to be claimed using the claim method
     * no cheating here :-)
     */
    modifier tokenIdInRange(uint256 tokenId, uint256 start, uint256 end) {
        require(
            tokenId > start && tokenId <= end,
            "$Blacklist lottery only available for range (100,300]"
        );
        require(_exists(tokenId) == false, "$Blacklist already claimed");
        _;
    }

    modifier canMintBlacklistGen2(uint256 tokenId) {
        require(
            tokenId > GENERATION_ONE && tokenId <= maxBlacklist-TREASURY,
            "Can't mint blacklisted tokenId's in range [1, 100] & [301,333]"
        );
        require(_exists(tokenId) == false, "tokenId already exists");
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 tokenId) {
        require(
            price == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(uint256 tokenId, bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender, tokenId))
            ),
            "Invalid claim proof address or tokenId"
        );
        _;
    }

    /**
     * @dev
     * @param _openSeaProxyRegistryAddress address for OpenSea proxy.
     * @param _maxBlacklist total number of tokens
     * @param _claimDuration claiming window
     */
    constructor(
        IProxyRegistry _openSeaProxyRegistryAddress,
        uint256 _maxBlacklist,
        uint256 _claimDuration,
        address[3] memory _creat00rs
    ) ERC721("$Blacklist", "$BLACKLIST") {
        proxyRegistry = _openSeaProxyRegistryAddress;
        maxBlacklist = _maxBlacklist;
        claimExpiration = block.timestamp + _claimDuration;
        royaltyPayout = address(this);
        require(_creat00rs[0] != address(0) && _creat00rs[1] != address(0) && _creat00rs[2] != address(0), "ZERO_ADDRESS not allowed");
        creat00rs = _creat00rs;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    /**
     * @notice
     * only claim for blacklisted users
     * validate merkleProof based on address/tokenId
     * No payment required
     * @dev
     * @param tokenId in range [1 100]
     */
    function claim(uint256 tokenId, bytes32[] calldata merkleProof)
        external
        nonReentrant
        claimIsActive
        isValidMerkleProof(tokenId, merkleProof, claimListMerkleRoot)
    {
        require(_exists(tokenId) == false, "$Blacklist already claimed");
        _safeMint(msg.sender, tokenId);
    }


    /**
     * @notice
     * only claim for blacklisted users
     * validate merkleProof based on address/tokenId
     * No payment required
     * @dev
     * @param tokenId in range [101, 200]
     */
    function blacklist(uint256 tokenId, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        blacklistIsActive
        tokenIdInRange(tokenId, CLAIMABLE_TOKEN, maxBlacklist-TREASURY)
        isCorrectPayment(PUBLIC_SALE_PRICE, tokenId)
        isValidMerkleProof(tokenId, merkleProof, blacklistMerkleRoot)
    {
        require(_exists(tokenId) == false, "$Blacklist already claimed");
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice
     * only allow minting for tokenId in range (100 200]
     * when publicSaleActive is True and
     * correct payment is provided
     * @dev
     * @param tokenId in range (100 200]
     */
    function mintGen1(uint256 tokenId)
        external
        payable
        nonReentrant
        gen1SaleActive
        canMintBlacklistGen1(tokenId)
        isCorrectPayment(getPriceForTokenId(tokenId), tokenId)
    {
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice
     * only allow minting for tokenId's in range (215 300]
     * when gen2SaleActive is True and
     * correct payment is provided
     * @dev
     * @param tokenId in range (215 300]
     */
    function mintGen2(uint256 tokenId)
        external
        payable
        nonReentrant
        gen2SaleActive
        canMintBlacklistGen2(tokenId)
        isCorrectPayment(getPriceForTokenId(tokenId), tokenId)
    {
        _safeMint(msg.sender, tokenId);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', contractURIHash));
    }

    /**
     * @notice
     * Calculate price for token which is either
     * flat price PUBLIC_SALE_PRICE or
     * price cliff 0.01 ,0.1, 1, 10, 100 over 100 available pieces
     * Used for gen1 and gen2 minting cycle
     * @dev
     * @param tokenId in range [100-300]
     */
    function getPriceForTokenId(uint256 tokenId) public view returns (uint256) {
        uint256 base = 0.001 ether;

        if (tokenId<= CLAIMABLE_TOKEN){
            return 0;
        }

        // if we switch to bulk selling all same price
        if (isBulkPriceActive) {
            return PUBLIC_SALE_PRICE;
        }

        // price cliff model for all groups
        uint256 modTokenId = tokenId % 100;

        if (modTokenId > 0 && modTokenId <= 2) {
            return base;
        }
        if (modTokenId > 2 && modTokenId <= 5) {
            return SafeMath.mul(base, 10);
        }
        if (modTokenId > 5 && modTokenId <= 10) {
            return SafeMath.mul(base, 100);
        }
        if (modTokenId > 10 && modTokenId <= 90) {
            return SafeMath.div(SafeMath.mul(base, 1000),2);
        }
        if (modTokenId > 90 && modTokenId <= 95) {
            return SafeMath.mul(base, 1000);
        }
        if (modTokenId > 95 && modTokenId <= 98) {
            return SafeMath.mul(base, 10000);
        }
        if (modTokenId > 98 && modTokenId <= 99) {
            return SafeMath.mul(base, 100000);
        }
        // 200 and 300
        return SafeMath.mul(base, 100000);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    /**
     * @notice
     * treasury mint
     * only allow minting for tokenId's in range [301,333]
     * @dev
     * @param tokenId in range [301,333]
     */
    function treasuryMint(uint256 tokenId)
        external
        onlyOwner
        nonReentrant
    {
        require(tokenId > maxBlacklist-TREASURY && tokenId<= maxBlacklist,  "tokenId not in treasury range [300, 333]");
        require(_exists(tokenId) == false, "tokenId already exists");
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice
     * treasury mint to
     * only allow minting for tokenId's in range [301,333]
     * @dev
     * @param tokenId in range [301,333]
     */
    function treasuryMintTo(uint256 tokenId, address to)
        external
        onlyOwner
        nonReentrant
    {
        require(tokenId > maxBlacklist-TREASURY && tokenId<= maxBlacklist,  "tokenId not in treasury range [300, 333]");
        require(to != address(0), "Zero address not allowed");
        require(_exists(tokenId) == false, "tokenId already exists");
        _safeMint(to, tokenId);
    }


    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory _contractURIHash) external onlyOwner {
        contractURIHash = _contractURIHash;
    }

    /** 
     * @notice 
     *  function to disable gasless listings for security in case
     *  opensea ever shuts down or is compromised
     * @dev Only callable by the owner.
     */
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setVerificationHash(string memory _verificationHash)
        external
        onlyOwner
    {
        verificationHash = _verificationHash;
    }

    function setIsGen1SaleActive(bool _isGen1SaleActive)
        external
        onlyOwner
    {
        isGen1SaleActive = _isGen1SaleActive;
    }

    function setIsGen2SaleActive(bool _isGen2SaleActive)
        external
        onlyOwner
    {
        isGen2SaleActive = _isGen2SaleActive;
    }

    function setPublicSalePrice(uint256 _publicSalePrice)
        external
        onlyOwner
    {
        require(_publicSalePrice > 0, "PUBLIC_SALE_PRICE can't be zero");
        PUBLIC_SALE_PRICE = _publicSalePrice;
    }

    function setIsBulkPriceActive(bool _isBulkPriceActive)
        external
        onlyOwner
    {
        isBulkPriceActive = _isBulkPriceActive;
    }

    function setSellerFeeBasisPoints(uint16 _sellerFeeBasisPoints)
        external
        onlyOwner
    {
        require(_sellerFeeBasisPoints<=200, "Max Roalty check failed! > 20%");
        sellerFeeBasisPoints = _sellerFeeBasisPoints;
    }

    function setClaimActive(bool _isClaimActive)
        external
        onlyOwner
    {
        isClaimActive = _isClaimActive;
    }

    function setBlacklistActive(bool _isBlacklistActive)
        external
        onlyOwner
    {
        isBlacklistActive = _isBlacklistActive;
    }

    function setCreat00r(address creat00r_) external onlyOwner {
        require(creat00r_!= address(0), "Invalid creat00r address");
        creat00rs[0] = creat00r_;
    }

    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    function setBlacklistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        blacklistMerkleRoot = merkleRoot;
    }

    function setRoyaltyPayout(address _royaltyPayout) external onlyOwner {
        require(_royaltyPayout != address(0), "Zero Address not allowed");
        royaltyPayout = _royaltyPayout;
    }

    function withdraw() public onlyOwner {
        address _creat00r = creat00rs[0];
        address _dev1 = creat00rs[1];
        address _dev2 = creat00rs[2];
        uint256 _balance = address(this).balance;

        uint256 _creat00rShare = _balance * 90/100; //90% shares to creat00r
        uint256 _devShare = _balance * 10/200; // 5% shares each
        payable(_creat00r).transfer(_creat00rShare);
        payable(_dev1).transfer(_devShare);
        payable(_dev2).transfer(_devShare);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        address _creat00r = creat00rs[0];
        address _dev1 = creat00rs[1];
        address _dev2 = creat00rs[2];
        uint256 _tokenBalance = token.balanceOf(address(this));

        uint256 _creat00rShare = _tokenBalance* 90/100; //90% shares to creat00r
        uint256 _devShare = _tokenBalance* 10/200; // 5% shares each
        
        token.transfer(_creat00r, _creat00rShare);
        token.transfer(_dev1, _devShare);
        token.transfer(_dev2, _devShare);
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        if (isOpenSeaProxyActive &&
            proxyRegistry.proxies(owner) == operator) {
                return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (royaltyPayout, SafeMath.div(SafeMath.mul(salePrice, sellerFeeBasisPoints), 1000));
    }
}