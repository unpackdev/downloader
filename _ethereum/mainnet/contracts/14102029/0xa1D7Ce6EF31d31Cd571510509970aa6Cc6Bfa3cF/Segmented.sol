// SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.4;

/*


 .oooooo..o                                                                  .                   .o8  
d8P'    `Y8                                                                .o8                  "888  
Y88bo.       .ooooo.   .oooooooo ooo. .oo.  .oo.    .ooooo.  ooo. .oo.   .o888oo  .ooooo.   .oooo888  
 `"Y8888o.  d88' `88b 888' `88b  `888P"Y88bP"Y88b  d88' `88b `888P"Y88b    888   d88' `88b d88' `888  
     `"Y88b 888ooo888 888   888   888   888   888  888ooo888  888   888    888   888ooo888 888   888  
oo     .d8P 888    .o `88bod8P'   888   888   888  888    .o  888   888    888 . 888    .o 888   888  
8""88888P'  `Y8bod8P' `8oooooo.  o888o o888o o888o `Y8bod8P' o888o o888o   "888" `Y8bod8P' `Y8bod88P" 
                      d"     YD                                                                       
                      "Y88888P'                                                                       
                                                                                                                                                                                                             
                                                                                                                  

*/

import "./ERC721URIStorage.sol";
import "./IERC2981.sol";

import "./Ownable.sol";

import "./Counters.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract Segmented is ERC721URIStorage, IERC2981, Ownable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string private baseURI;

    address private ownerAddress = 0x437381F8798a55a5695Ea7F0756c5a6cD7eCA566;
    address private managerAddress = 0xa7E458A1b32070387e7548063E1F5e7f3982E6D1;

    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    uint256 public constant MAX_SEGMENTS_PER_WALLET = 2;
    // TODO: add real maxSegments
    uint256 public constant maxSegments = 91;

    // TODO set price to 0.15
    uint256 public constant SALE_PRICE = 0.15 ether;
    
    bool public isPublicSaleActive;
    bool public isFamSaleActive;

    // The winner of the auction has claimed the One of Ones
    bool public hasMintedOneOfOneSegments;

    mapping(address => bool) public allowList;

    struct TokenDataBase {
        uint tokenId;
        uint set;
        uint number;
    }
    
    struct TokenData {
        uint set;
        uint number;
    }

    mapping (uint => TokenData) public tokenDataMap;


    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier famSaleActive() {
        require(isFamSaleActive, "PreMint is not open");
        _;
    }

    modifier allowListAddress(address messageSender) {
        require(allowList[messageSender], "You're not on the Pre Sale List");
        _;
    }

    modifier maxSegmentsPerWallet(uint256 numberOfTokens) {
        require(
            msg.sender == ownerAddress || balanceOf(msg.sender) + numberOfTokens <= MAX_SEGMENTS_PER_WALLET,
            "Max segments to mint is two"
        );
        _;
    }

    // TODO might have to update this
    modifier canMintSegments(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxSegments,
            "Not enough Segments remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value || msg.sender == ownerAddress,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isOwnerOfTokenOne(uint tokenId, address messageSender) {
        require(tokenId == 1 && ownerOf(tokenId) == messageSender, "Not allowed");
        _;
    }

    modifier oneOfOneSegmentsMinted() {
        require(!hasMintedOneOfOneSegments, "One of One segments have already been minted");
        _;
    }
    
    // TODO: Add openseaProxyRegistryAddress a la 
    // https://etherscan.io/address/0x5180db8f5c931aae63c74266b211f580155ecac8#code
    constructor(
        address _openSeaProxyRegistryAddress
    ) ERC721("Segmented", "SGMNT") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MANAGER_ROLE, msg.sender);
        grantRole(MANAGER_ROLE, managerAddress);
    }
    // TODO: add isCorrectPayment
    // isCorrectPayment(SALE_PRICE, numberOfTokens)
    // add payable to dane
    // https://stackoverflow.com/questions/69268578/how-to-send-eth-directly-from-erc721-openzeppelin-contract-to-the-paymentsplit
    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mint(uint256 numberOfTokens)
        external
        payable
        publicSaleActive
        canMintSegments(numberOfTokens)
        maxSegmentsPerWallet(numberOfTokens)
        isCorrectPayment(SALE_PRICE, numberOfTokens)
    {
        payable(address(ownerAddress)).transfer(msg.value);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function famMint(uint256 numberOfTokens)
        external
        payable
        famSaleActive
        allowListAddress(msg.sender)
        canMintSegments(numberOfTokens)
        maxSegmentsPerWallet(numberOfTokens)
        isCorrectPayment(SALE_PRICE, numberOfTokens)
    {
        payable(address(ownerAddress)).transfer(msg.value);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function artistMint(uint256 numberOfTokens)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(ownerAddress, nextTokenId());
        }
        
    }

    // TODO: test this
    function claimOneOfOneSegments(uint tokenId)
        external
        isOwnerOfTokenOne(tokenId, msg.sender)
    {
            for (uint256 i = 102; i <= 104; i++) {
                _safeMint(msg.sender, i);
            }
            hasMintedOneOfOneSegments = true;
    }

    function burnAndFuse(uint[] calldata tokenIdArray) 
        external
    {
        // Ensure three tokens are in array
        require(tokenIdArray.length == 3, "Fusing requires three segments");
        // ensure all tokens are owned by msg.sender
        require(msg.sender == ownerOf(tokenIdArray[0]) && ownerOf(tokenIdArray[0]) == ownerOf(tokenIdArray[1]) && ownerOf(tokenIdArray[1]) == ownerOf(tokenIdArray[2]), "You must own all three segments");
        // ensure all tokens are in same set, set Set name
        require(tokenDataMap[tokenIdArray[0]].set == tokenDataMap[tokenIdArray[1]].set && tokenDataMap[tokenIdArray[1]].set == tokenDataMap[tokenIdArray[2]].set, "All Segments must be from the same set");
        // ensure all tokens are different and represent all numbers
        require(tokenDataMap[tokenIdArray[0]].number + tokenDataMap[tokenIdArray[1]].number + tokenDataMap[tokenIdArray[2]].number == 6, "All tokens from the Set need to be included");
        // burn segments
        for (uint i = 0; i < tokenIdArray.length; i++) {
            _burn(tokenIdArray[i]);
        }
        // mint fused piece
        _safeMint(msg.sender, tokenDataMap[tokenIdArray[0]].set);
        // emit fused piece created

    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ MANAGER-ONLY ADMIN FUNCTIONS ============
    function setBaseURI(string memory _baseURI) public onlyRole(MANAGER_ROLE) {
        baseURI = _baseURI;
    }

    function allowListUser(address[] calldata userList) public onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < userList.length; i++) {
            allowList[userList[i]] = true;
        }
    }

    // This is the function that creates the mapping of tokenId => tokenDataMap struct
    function setFusedData(TokenDataBase[] calldata tokenDataArray) public onlyRole(MANAGER_ROLE) {
        for (uint i = 0; i < tokenDataArray.length; i++) {
                tokenDataMap[tokenDataArray[i].tokenId].set =tokenDataArray[i].set;
                tokenDataMap[tokenDataArray[i].tokenId].number =tokenDataArray[i].number;
        }
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
        onlyRole(MANAGER_ROLE)
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsFamSaleActive(bool _isFamSaleActive)
        external
        onlyRole(MANAGER_ROLE)
    {
        isFamSaleActive = _isFamSaleActive;
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
        override(ERC721, IERC165, AccessControl)
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

        return (address(ownerAddress), SafeMath.div(SafeMath.mul(salePrice, 10), 100));
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}