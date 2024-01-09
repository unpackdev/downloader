//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.0;

/*

 __                 ___          ___     ___     __   __   __   __  
|__) |     /\  |\ |  |     |\ | |__  \_/  |     |  \ /  \ /  \ |__) 
|    |___ /~~\ | \|  |     | \| |___ / \  |     |__/ \__/ \__/ |  \ 

                  _(_)_                          wWWWw   _  
      @@@@       (_)@(_)   vVVVv     _     @@@@  (___) _(_)_
     @@()@@ wWWWw  (_)\    (___)   _(_)_  @@()@@   Y  (_)@(_)
      @@@@  (___)     `|/    Y    (_)@(_)  @@@@   \|/   (_)\
       /      Y       \|    \|/    /(_)    \|      |/      |
    \ |     \ |/       | / \ | /  \|/       |/    \|      \|/
jgs \\|//   \\|///  \\\|//\\\|/// \|///  \\\|//  \\|//  \\\|//
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Thanks to CryptoCoven for providing reference code for this contract.

*/

import "./ERC721Enumerable.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Strings.sol";
import "./Math.sol";
import "./SafeMath.sol";

contract PlantNextDoor is ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public constant PROVENANCE_HASH =
        "f9bc0787149da2c2355d945ae6f6f691362b2e7cecbba798acea3a92c2bdf316";
    uint256 public constant MAX_PLANTS_PER_WALLET = 5;
    uint256 public constant NUM_PLACEHOLDER_VARIATIONS = 10;
    bool private isOpenSeaProxyActive = true;

    string private placeholderURI;
    address private openSeaProxyRegistryAddress;
    bool public isPublicSaleActive;
    bytes32 public claimListMerkleRoot;
    address public validBurner;

    uint256 public maxPlants;
    uint256 public maxGiftedPlants;
    uint256 public numGiftedPlants;
    uint256 public publicSalePrice;

    uint256 private revealBucketSize;
    uint256 private numRevealBuckets;

    mapping(address => bool) public claimed;
    mapping(uint256 => string) public staggeredRevealUrls;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier maxPlantsPerWallet(uint256 numberOfTokens) {
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_PLANTS_PER_WALLET,
            "Max plants to mint is five"
        );
        _;
    }

    modifier canMintPlants(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <= maxPlants - maxGiftedPlants,
            "Not enough plants remaining to mint"
        );
        _;
    }

    modifier canGiftPlants(uint256 num) {
        require(
            numGiftedPlants + num <= maxGiftedPlants,
            "All gifted plants have been given"
        );
        require(
            totalSupply() + num <= maxPlants,
            "Not enough plants remaining to gift"
        );
        _;
    }

    modifier isCorrectPayment(uint256 numberOfTokens) {
        require(
            publicSalePrice * numberOfTokens == msg.value,
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

    modifier isPlantAlreadyClaimed(address claimer) {
        require(!claimed[claimer], "Plant already claimed by this wallet");
        _;
    }

    constructor(
        address _openSeaProxyRegistryAddress,
        string memory _placeholderURI,
        uint256 _maxPlants,
        uint256 _maxGiftedPlants,
        uint256 _revealBucketSize
    ) ERC721("PlantNextDoor", "PND") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        placeholderURI = _placeholderURI;
        maxPlants = _maxPlants;
        maxGiftedPlants = _maxGiftedPlants;
        revealBucketSize = _revealBucketSize;
        numRevealBuckets = Math.ceilDiv(maxPlants, revealBucketSize);
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        publicSaleActive
        isCorrectPayment(numberOfTokens)
        canMintPlants(numberOfTokens)
        maxPlantsPerWallet(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function burnToken(uint256 tokenId) external {
        require(msg.sender == validBurner, "Invalid burner address");
        _burn(tokenId);
    }

    function claim(bytes32[] calldata merkleProof)
        external
        isValidMerkleProof(merkleProof, claimListMerkleRoot)
        isPlantAlreadyClaimed(msg.sender)
        canGiftPlants(1)
    {
        claimed[msg.sender] = true;
        numGiftedPlants += 1;

        _safeMint(msg.sender, totalSupply() + 1);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getLastTokenId() external view returns (uint256) {
        return totalSupply();
    }

    function getMintPrice() public view publicSaleActive returns (uint256) {
        return publicSalePrice;
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        require(tokenId < maxPlants, "tokenId outside bounds");
        return _exists(tokenId);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    // Function to disable gasless listings for security in case
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

    function setPublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
    }

    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    function setPlaceholderURI(string memory URI) external onlyOwner {
        placeholderURI = URI;
    }

    function setRevealBucketSize(uint256 bucketSize) external onlyOwner {
        revealBucketSize = bucketSize;
        numRevealBuckets = Math.ceilDiv(maxPlants, revealBucketSize);
    }

    function setStaggeredRevealBucket(uint256 bucket, string memory baseURI)
        external
        onlyOwner
    {
        staggeredRevealUrls[bucket] = baseURI;
    }

    function setValidBurner(address burner) external onlyOwner {
        validBurner = burner;
    }

    function testMint()
        external
        payable
        nonReentrant
        onlyOwner
        canMintPlants(1)
        maxPlantsPerWallet(1)
    {
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function giftPlants(address[] calldata addresses, uint256 numPerAddress)
        external
        nonReentrant
        onlyOwner
        canGiftPlants(addresses.length * numPerAddress)
    {
        uint256 numToGift = addresses.length * numPerAddress;
        numGiftedPlants += numToGift;

        for (uint256 i = 0; i < addresses.length; i++) {
            for (uint256 j = 0; j < numPerAddress; j++) {
                _safeMint(addresses[i], totalSupply() + 1);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
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

        uint256 revealTier = SafeMath.div(tokenId - 1, revealBucketSize);
        string memory baseURI = staggeredRevealUrls[revealTier];

        if (bytes(baseURI).length > 0) {
            return
                string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        } else {
            uint256 placeholderIdx = SafeMath.mod(
                tokenId - 1,
                NUM_PLACEHOLDER_VARIATIONS
            );
            return
                string(
                    abi.encodePacked(
                        placeholderURI,
                        placeholderIdx.toString(),
                        ".json"
                    )
                );
        }
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

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
