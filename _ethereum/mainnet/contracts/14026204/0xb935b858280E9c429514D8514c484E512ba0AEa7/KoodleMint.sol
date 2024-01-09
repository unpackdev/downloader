//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
                                                                              
,--. ,--.                 ,--.,--.           ,--. ,--.          ,--.          
|  .'   / ,---.  ,---.  ,-|  ||  | ,---.     |  .'   / ,--,--.,-'  '-. ,---.  
|  .   ' | .-. || .-. |' .-. ||  || .-. :    |  .   ' ' ,-.  |'-.  .-'(  .-'  
|  |\   \' '-' '' '-' '\ `-' ||  |\   --.    |  |\   \\ '-'  |  |  |  .-'  `) 
`--' '--' `---'  `---'  `---' `--' `----'    `--' '--' `--`--'  `--'  `----'  
,------.         ,--.        ,--.                                             
|  .-.  \ ,--.--.`--',--,--, |  |,-.     ,--. ,--.,---. ,--.,--.,--.--.       
|  |  \  :|  .--',--.|      \|     /      \  '  /| .-. ||  ||  ||  .--'       
|  '--'  /|  |   |  ||  ||  ||  \  \       \   ' ' '-' ''  ''  '|  |          
`-------' `--'   `--'`--''--'`--'`--'    .-'  /   `---'  `----' `--'          
,------. ,--.   ,--.,--.,--.,--.         `---'                                
|  .--. '|   `.'   |`--'|  ||  |,-.                                           
|  '--'.'|  |'.'|  |,--.|  ||     /                                           
|  |\  \ |  |   |  ||  ||  ||  \  \                                           
`--' '--'`--'   `--'`--'`--'`--'`--'                                          
                                                                              

*/

import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

interface ILooks {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRMilk {
    function mint(address _to, uint _amount) external;
}

contract KoodleKats is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI;
    string public verificationHash;
    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    uint256 public constant MAX_KOODLE_PRESALE = 3;
    uint256 public maxKoodles;

    uint256 public constant SALE_PRICE = 0.04 ether;
    bool public isPublicSaleActive;

    uint256 public constant LOOK_SALE_PRICE = 30 ether;
    uint256 public maxCommunitySaleKoodles;
    bytes32 public communitySaleMerkleRoot;
    bool public isCommunitySaleActive;

    address public koodleAddress;
    ILooks public looks;
    IRMilk public rMilk;

    uint256 public rMilkAllowance = 5 ether;


    mapping(address => uint256) public communityMintCounts;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier communitySaleActive() {
        require(isCommunitySaleActive, "Community sale is not open");
        _;
    }

    modifier canMintKoodles(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxKoodles,
            "Not enough koodles remaining to mint"
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
        uint256 _maxKoodles,
        uint256 _maxCommunitySaleKoodles
    ) ERC721("Koodle Kats", "KOODLE") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxKoodles = _maxKoodles;
        maxCommunitySaleKoodles = _maxCommunitySaleKoodles;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(SALE_PRICE, numberOfTokens)
        canMintKoodles(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());

        }
        mintRMilk(numberOfTokens*rMilkAllowance);
    }

    function mintLooks(uint256 numberOfTokens)
        external
        nonReentrant
        canMintKoodles(numberOfTokens)
    {
        payLooks(numberOfTokens * LOOK_SALE_PRICE);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());

        }
        mintRMilk(numberOfTokens*rMilkAllowance);
    }

    function mintCommunitySale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        communitySaleActive
        canMintKoodles(numberOfTokens)
        isCorrectPayment(SALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, communitySaleMerkleRoot)
    {
        uint256 numAlreadyMinted = communityMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_KOODLE_PRESALE,
            "Max koodles to mint in community sale is three"
        );

        require(
            tokenCounter.current() + numberOfTokens <= maxCommunitySaleKoodles,
            "Not enough koodles remaining to mint"
        );

        communityMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
        mintRMilk(numberOfTokens*rMilkAllowance);
    }

    function mintCommunitySaleLooks(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof
    )
        external
        nonReentrant
        communitySaleActive
        canMintKoodles(numberOfTokens)
        isValidMerkleProof(merkleProof, communitySaleMerkleRoot)
    {
        uint256 numAlreadyMinted = communityMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_KOODLE_PRESALE,
            "Max koodles to mint in community sale is three"
        );

        require(
            tokenCounter.current() + numberOfTokens <= maxCommunitySaleKoodles,
            "Not enough koodles remaining to mint"
        );
        uint256 lPrice = numberOfTokens * LOOK_SALE_PRICE;

        payLooks(lPrice);
        communityMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
        mintRMilk(numberOfTokens*rMilkAllowance);
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

    function setLooks(address _looks) external onlyOwner {
        looks = ILooks(_looks);
    }

    function setKoodleAddress(address _koodle) external onlyOwner {
        koodleAddress = _koodle;
    }

    function setRMilk(address _rmilk) external onlyOwner {
        rMilk = IRMilk(_rmilk);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    function mintRMilk(uint256 mintAllowance) internal{
        rMilk.mint(msg.sender, mintAllowance);

    }

    function payLooks(uint256 looksPrice) internal{
        looks.transferFrom(msg.sender, koodleAddress, looksPrice);

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