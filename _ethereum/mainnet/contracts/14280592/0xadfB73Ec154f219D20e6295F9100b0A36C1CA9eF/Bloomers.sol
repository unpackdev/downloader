
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
pragma solidity ^0.8.0;

/*                                                         
                  _..
             ;-._   .'   `\
           .'    `\/       ;
           |       `\.---._|
        .--;   . ( .'      '. 
       / _  \_  './ _.       `-._
      ( = \  )`""'\;--.         /
      {= (|  )     /`.         /
      ( =_/  )__..-\         .'
       \    }/    / ;.____.-;/\
        '--' |  .'   |       \ \
             \  '    /       |\.\
              )    .'`-.    /  \ \
    jgs      /__.-'     \_.'    \ \
                  .-'''-.        .-'''-.                                                      
         .---.   '   _    \     '   _    \                                                    
/|        |   | /   /` '.   \  /   /` '.   \  __  __   ___         __.....__                   
||        |   |.   |     \  ' .   |     \  ' |  |/  `.'   `.   .-''         '.                 
||        |   ||   '      |  '|   '      |  '|   .-.  .-.   ' /     .-''"'-.  `. .-,.--.       
||  __    |   |\    \     / / \    \     / / |  |  |  |  |  |/     /________\   \|  .-. |      
||/'__ '. |   | `.   ` ..' /   `.   ` ..' /  |  |  |  |  |  ||                  || |  | |  _   
|:/`  '. '|   |    '-...-'`       '-...-'`   |  |  |  |  |  |\    .-------------'| |  | |.' |  
||     | ||   |                              |  |  |  |  |  | \    '-.____...---.| |  '-.   | /
||\    / '|   |                              |__|  |__|  |__|  `.             .' | |  .'.'| |//
|/\'..' / '---'                                                  `''-...... -'   | |.'.'.-'  / 
'  `'-'`                                                                         |_|.'   \_.' 
                                                                    
 <3 contract transmuted from the witches of the crypto coven <3 
(https://www.cryptocoven.xyz)
<3 ascii by joan g stark aka "spunk" <3 
(https://web.archive.org/web/20091028014945/http://www.geocities.com/SoHo/7373/index.htm#home)
*/
 
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract Bloomers is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI;
    string public verificationHash;
    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    uint256 public constant MAX_BLOOMERS_PER_WALLET = 8;
    uint256 public maxBloomers;

    uint256 public constant PUBLIC_SALE_PRICE = 0.033 ether;
    bool public isPublicSaleActive;

    uint256 public constant COMMUNITY_SALE_PRICE = 0.022 ether;
    uint256 public maxCommunitySaleBloomers;
    bytes32 public communitySaleMerkleRoot;
    bool public isCommunitySaleActive;

    uint256 public maxGiftedBloomers;
    uint256 public numGiftedBloomers;
    bytes32 public claimListMerkleRoot;

    mapping(address => uint256) public communityMintCounts;
    mapping(address => bool) public claimed;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier communitySaleActive() {
        require(isCommunitySaleActive, "Community sale is not open");
        _;
    }

    modifier maxBloomersPerWallet(uint256 numberOfTokens) {
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_BLOOMERS_PER_WALLET,
            "Max Bloomers to mint is eight"
        );
        _;
    }

    modifier canMintBloomers(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxBloomers - maxGiftedBloomers,
            "Not enough bloomers remaining to mint"
        );
        _;
    }

    modifier canGiftBloomers(uint256 num) {
        require(
            numGiftedBloomers + num <= maxGiftedBloomers,
            "Not enough bloomers remaining to gift"
        );
        require(
            tokenCounter.current() + num <= maxBloomers,
            "Not enough bloomers remaining to mint"
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

    constructor(
        address _openSeaProxyRegistryAddress,
        uint256 _maxBloomers,
        uint256 _maxCommunitySaleBloomers,
        uint256 _maxGiftedBloomers
    ) ERC721("Bloomers", "BLOOM") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxBloomers = _maxBloomers;
        maxCommunitySaleBloomers = _maxCommunitySaleBloomers;
        maxGiftedBloomers = _maxGiftedBloomers;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintBloomers(numberOfTokens)
        maxBloomersPerWallet(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function mintCommunitySale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        communitySaleActive
        canMintBloomers(numberOfTokens)
        isCorrectPayment(COMMUNITY_SALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, communitySaleMerkleRoot)
    {
        uint256 numAlreadyMinted = communityMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_BLOOMERS_PER_WALLET,
            "Max bloomers to mint in community sale is 8"
        );

        require(
            tokenCounter.current() + numberOfTokens <= maxCommunitySaleBloomers,
            "Not enough bloomers remaining to mint"
        );

        communityMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function claim(bytes32[] calldata merkleProof)
        external
        isValidMerkleProof(merkleProof, claimListMerkleRoot)
        canGiftBloomers(1)
    {
        require(!claimed[msg.sender], "Bloomer already claimed by this wallet");

        claimed[msg.sender] = true;
        numGiftedBloomers += 1;

        _safeMint(msg.sender, nextTokenId());
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
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

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsCommunitySaleActive(bool _isCommunitySaleActive)
        external
        onlyOwner
    {
        isCommunitySaleActive = _isCommunitySaleActive;
    }

    function setCommunityListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        communitySaleMerkleRoot = merkleRoot;
    }

    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    function reserveForGifting(uint256 numToReserve)
        external
        nonReentrant
        onlyOwner
        canGiftBloomers(numToReserve)
    {
        numGiftedBloomers += numToReserve;

        for (uint256 i = 0; i < numToReserve; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function giftBloomers(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canGiftBloomers(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedBloomers += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], nextTokenId());
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

    function rollOverBloomers(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
    {
        require(
            tokenCounter.current() + addresses.length <= 128,
            "All bloomers are already rolled over"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            communityMintCounts[addresses[i]] += 1;
            // use mint rather than _safeMint here to reduce gas costs
            // and prevent this from failing in case of grief attempts
            _mint(addresses[i], nextTokenId());
        }
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
        override(ERC721, IERC165)
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
