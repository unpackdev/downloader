//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract BaoHu is ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private nftCounter;

    string private baseURI;
    address private openSeaProxyRegAddr;
    bool private isOpenSeaProxyActive = true;

    uint256 private MAX_PER_ADDR_LMT  = 1;
    uint256 public constant MAX_SUPPLY = 8888;
    
    // ExpireAt 
    uint256 public claimExpireAt = 1656518400;
    bool private isClaimActive = true;

    // BaoHuDAO Project
    uint256 public projectId = 301;
    bool public juiceboxOption = true;

    address public juiceboxProject = 0x40CB429c193c5c2b383e17362488735933EAeB67;
    address public juiceboxBooth = 0xee2eBCcB7CDb34a8A822b589F9E8427C24351bfc;
    
    mapping(address => bool) public claimed;

    constructor(
        address _openSeaProxyRegAddr,        
        string memory _baseURI
    ) ERC721("BaoHu", "BAOHU") {
        openSeaProxyRegAddr = _openSeaProxyRegAddr;        
        baseURI = _baseURI;
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier claimActive() {
        require(isClaimActive, "claim is not open");
        _;
    }

    modifier maxNFTsPerWallet(uint256 num) {
        require(balanceOf(msg.sender) + num <= MAX_PER_ADDR_LMT, "Exceeding Max NFTs to hold");
        _;
    }

    modifier canClaim(uint256 num) {        
        require(
            totalSupply() + num <= MAX_SUPPLY,
            "Not enough NFTs remaining to mint"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function claim(address _address)
        external
        nonReentrant
        claimActive
        canClaim(1)
    {        
        require(isWhitelisted(_address), "Not contributor of BaoHuDAO juicebox project");
        require(!claimed[_address], "NFT already claimed by this wallet");

        claimed[_address] = true;

        _safeMint(_address, nextTokenId());
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function isWhitelisted(address _user) public view returns (bool){      
                        
        //check balance by project contract
        bool state = IERC20(juiceboxProject).balanceOf(_user) > 0;

        //check balance by juiceboxbooth
        if(juiceboxOption && !state){
            (bool success, bytes memory returnedData) = juiceboxBooth.staticcall(
                abi.encodeWithSignature("balanceOf(address,uint256)",_user,projectId)
            );

            if(success) {
                state = abi.decode(returnedData, (uint256))>0;
            }
        }

        return state;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setMAX_PER_ADDR_LMT(uint256 _limit) public onlyOwner() {
        MAX_PER_ADDR_LMT = _limit;
    }

    function setClaimExpireAt(uint256 _limit) public onlyOwner() {
        claimExpireAt = _limit;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setIsClaimActive(bool _active)
        external
        onlyOwner
    {
        isClaimActive = _active;
    }

     function setJuiceboxOption(bool _active)
        external
        onlyOwner
    {
        juiceboxOption = _active;
    }

    function setJuiceboxProject(address _address, address _booth, uint256 _projectId) public onlyOwner {
        juiceboxProject = _address;
        juiceboxBooth = _booth;
        projectId = _projectId;
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
        nftCounter.increment();
        return nftCounter.current();
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
            openSeaProxyRegAddr
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
        require(_exists(tokenId), "Non existent token");

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