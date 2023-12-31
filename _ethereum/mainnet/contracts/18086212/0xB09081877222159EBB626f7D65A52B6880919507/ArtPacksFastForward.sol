// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
 *   @author   0xtp
 *   @title    ArtPacks FastForward
 *
 *   █████╗     ██████╗     ████████╗    ██████╗      █████╗      ██████╗    ██╗  ██╗    ███████╗
 *  ██╔══██╗    ██╔══██╗    ╚══██╔══╝    ██╔══██╗    ██╔══██╗    ██╔════╝    ██║ ██╔╝    ██╔════╝
 *  ███████║    ██████╔╝       ██║       ██████╔╝    ███████║    ██║         █████╔╝     ███████╗
 *  ██╔══██║    ██╔══██╗       ██║       ██╔═══╝     ██╔══██║    ██║         ██╔═██╗     ╚════██║
 *  ██║  ██║    ██║  ██║       ██║       ██║         ██║  ██║    ╚██████╗    ██║  ██╗    ███████║
 *  ╚═╝  ╚═╝    ╚═╝  ╚═╝       ╚═╝       ╚═╝         ╚═╝  ╚═╝     ╚═════╝    ╚═╝  ╚═╝    ╚══════╝
 *
 */

import "./Counters.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./AccessControl.sol";

contract ArtPacksFastForward is ERC721, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _packId;

    /*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ S T A T E @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

    string  public _baseTokenURI;
    uint256 public _currentSupply;
    uint256 public _mintedPacksCount;
    uint256 public _mintedReserveCount;

    uint256 public _maxPerMint;
    uint256 public _maxPackSupply;
    uint256 public _maxReserveSupply;
    bool    public _isPublicSaleActive;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");       // RoleID = 1
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");     // RoleID = 2
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");   // RoleID = 3

    mapping(string => uint256) public price;
    mapping(address => uint256) public minted;
    mapping(uint256 => address) public ownerOfPack;
    mapping(uint256 => bool) public packOpenedStatus;
    mapping(address => uint256[]) public mintedPacks;
    mapping(address => uint256[]) public mintedArtWorks;

    /*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ E V E N T S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

    event MintedArtWorks(address indexed account, uint256[] tokenIds);
    event MintAndOpenedPack(address indexed account, uint256[] packIds);
    event MintedReservePacks(address indexed account, uint256[] packIds);
    event MintPacksAndArtWorks(address indexed account, uint256[] tokenIds);
    event AridroppedArtWorks(address[] indexed accounts, uint256[] tokenIds);

    constructor() public ERC721("ArtPacks FastForward", "APF") {
        _init();
    }

    function _init() internal {
        _maxPerMint = 5;
        _maxPackSupply = 250;
        _maxReserveSupply = 10;

        _isPublicSaleActive = true;

        price["public"] = 0.12 ether;

        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(AIRDROP_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, 0x9385eb301b34700E7E497C70d7937d8DDca688b0);
    }

    function mintAndOpenPack(
        uint256 quantity) 
        external 
        payable 
        returns (uint256[] memory) 
    {
        require(_isPublicSaleActive, "Sale Not Active");
        require(_maxPerMint >= quantity, "Exceeding Max Per Mint");
        require(_maxPackSupply >= _mintedPacksCount + quantity, "Exceeding Max Pack Supply");
        require(msg.value == price["public"] * quantity, "Public Sale - Incorrect ETH value");

        uint256[] memory packIds = new uint256[](quantity);
        _mintedPacksCount += quantity;

        for (uint256 i; i < quantity; i++) {
            _packId.increment();
            uint256 newPackId = _packId.current();
            packIds[i] = newPackId;
            ownerOfPack[newPackId] = msg.sender;
            packOpenedStatus[newPackId] = false;
            mintedPacks[msg.sender].push(newPackId);
        }

        emit MintAndOpenedPack(msg.sender, packIds);
        return packIds;
    }

    

    function mintArtWorks(
        address to,
        uint256[] calldata packIds,
        uint256[] calldata tokenIds) 
        external
        onlyRole(MINTER_ROLE) 
    {
        uint256 quantity = tokenIds.length;
        _currentSupply += quantity;
        minted[to] += quantity;

        for (uint256 i; i < packIds.length; i++) {
            require(ownerOfPack[packIds[i]] == to, "Address is not Owner of the Pack");
            require(!packOpenedStatus[packIds[i]], "Pack already opened.!");
            packOpenedStatus[packIds[i]] = true;
        }

        for (uint256 i; i < quantity; i++) {
            mintedArtWorks[to].push(tokenIds[i]);
            _mint(to, tokenIds[i]);
        }

        emit MintedArtWorks(to, tokenIds);
    }

    function mintPacksAndArtWorks(
        address to,
        uint256 noOfPacks,
        uint256[] calldata tokenIds) 
        external  
        onlyRole(MINTER_ROLE) 
    {
        uint256 tokenQuantity = tokenIds.length;
        _currentSupply += tokenQuantity;
        minted[to] += tokenQuantity;
        _mintedPacksCount += noOfPacks;

        for (uint256 i; i < noOfPacks; i++) {
            _packId.increment();
            uint256 newPackId = _packId.current();
            ownerOfPack[newPackId] = to;
            packOpenedStatus[newPackId] = true;
            mintedPacks[to].push(newPackId);
        }

        for (uint256 i; i < tokenQuantity; i++) {
            mintedArtWorks[to].push(tokenIds[i]);
            _mint(to, tokenIds[i]);
        }

        emit MintPacksAndArtWorks(to, tokenIds);
    }

    function mintReservePacks(
        address to,
        uint256 quantity) 
        external 
        onlyRole(ADMIN_ROLE)
        returns (uint256[] memory)  
    {
        require(_maxReserveSupply >= _mintedReserveCount + quantity, "Exceeding Max Reserve Supply");

        uint256[] memory packIds = new uint256[](quantity);
        _mintedReserveCount += quantity;

        for (uint256 i; i < quantity; i++) {
            _packId.increment();
            uint256 newPackId = _packId.current();
            packIds[i] = newPackId;
            ownerOfPack[newPackId] = to;
            packOpenedStatus[newPackId] = false;
            mintedPacks[to].push(newPackId);
        }
        emit MintedReservePacks(to, packIds);
        return packIds;
    }

    function airdropArtWorks(
        address[] calldata recipients,
        uint256[] calldata tokenIds) 
        external
        onlyRole(AIRDROP_ROLE) 
    {
        uint256 quantity = tokenIds.length;
        require(recipients.length == quantity, "Invalid Arguments");

        _currentSupply += quantity;

        for (uint256 i; i < quantity; i++) {
            uint256 tokenId = tokenIds[i];
            address to = recipients[i];
            minted[to] += 1;
            mintedArtWorks[to].push(tokenId);
            _mint(to, tokenId);
        }

        emit AridroppedArtWorks(recipients, tokenIds);
    }

    function getMintedArtWorks(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return mintedArtWorks[_account];
    }

    function getMintedPacks(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return mintedPacks[_account];
    }

    function getTotalMintedPacks()
        public
        view
        returns (uint256)
    {
        return _mintedPacksCount + _mintedReserveCount;
    }

    function setPackMaxSupply(uint256 newPackSupply)
        public
        onlyRole(ADMIN_ROLE)
    {
        _maxPackSupply = newPackSupply;
    }

    function setPackReserveSupply(uint256 newReserveSupply)
        public
        onlyRole(ADMIN_ROLE)
    {
        _maxReserveSupply = newReserveSupply;
    }

    function setSaleStatus(bool publicSaleStatus)
        public
        onlyRole(ADMIN_ROLE)
    {
        _isPublicSaleActive = publicSaleStatus;
    }

    function setPrice(string memory priceType, uint256 mintPrice)
        public
        onlyRole(ADMIN_ROLE)
    {
        price[priceType] = mintPrice;
    }

    function setBaseURI(string memory baseURI) public onlyRole(ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenUri = string.concat(super.tokenURI(tokenId), ".json");
        return tokenUri;
    }

    function assignRole(address account, uint256 roleId) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(roleId == 1){
            _grantRole(ADMIN_ROLE, account);
        }
        else if(roleId == 2){
            _grantRole(MINTER_ROLE, account);
        }
        else if(roleId == 3){
            _grantRole(AIRDROP_ROLE, account);
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(payable(msg.sender).send(address(this).balance));
    }

    function recoverERC20(
        IERC20 tokenContract,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenContract.transfer(to, tokenContract.balanceOf(address(this)));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
