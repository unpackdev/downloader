//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./ERC721.sol";
import "./IERC20.sol";
import "./IERC165.sol";


import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";


contract ItemERC721 is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI;
    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    uint256 public MAX_ITEMS_PER_WALLET;
    uint256 public maxSupply;

    uint256 public PUBLIC_SALE_PRICE;
    bool public isPublicSaleActive;
    uint256 public MAX_ITEMS_PER_TXN;

    uint256 public PRESALE_PRICE;
    uint256 public maxPresaleSupply;
    bytes32 public presaleMerkleRoot;
    bool public isPresaleActive;

    mapping(address => uint256) public perWalletMintCounts;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale closed");
        _;
    }

    modifier presaleActive() {
        require(isPresaleActive, "Presale closed");
        _;
    }

    modifier maxItemsPerTxn(uint256 numberOfTokens) {
        require(
            numberOfTokens <= MAX_ITEMS_PER_TXN,
            "Minting too many per transaction"
        );
        _;
    }

    modifier canMintItems(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxSupply,
            "Out of supply"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
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

  // ========== CONSTRUCTOR =================


    constructor(
        address _openSeaProxyRegistryAddress,
        uint256 _maxSupply,
        uint256 _maxPresaleSupply,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _publicSalePrice,
        uint256 _presalePrice,
        uint256 _maxItemsPerWallet,
        uint256 _maxItemsPerTxn
    ) ERC721(_name, _symbol) {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxSupply = _maxSupply;
        maxPresaleSupply = _maxPresaleSupply;
        baseURI = _uri;
        PUBLIC_SALE_PRICE = _publicSalePrice;
        PRESALE_PRICE = _presalePrice;
        MAX_ITEMS_PER_WALLET = _maxItemsPerWallet;
        MAX_ITEMS_PER_TXN = _maxItemsPerTxn;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintItems(numberOfTokens)
        maxItemsPerTxn(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function airdrop(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canMintItems(addresses.length)
    {
        uint256 numToGift = addresses.length;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    function mintPresale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        presaleActive
        canMintItems(numberOfTokens)
        isCorrectPayment(PRESALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, presaleMerkleRoot)
    {
        uint256 numAlreadyMinted = perWalletMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_ITEMS_PER_WALLET,
            "Max items to mint exceeded"
        );

        perWalletMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    function totalSupply() external view returns (uint256) {
        return maxSupply;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsPresaleActive(bool _isPresaleActive)
        external
        onlyOwner
    {
        isPresaleActive = _isPresaleActive;
    }

    function setPresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        presaleMerkleRoot = merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function currentTokenId() public view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}