// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Parsing.sol";


contract ArrLandNFTv2 is ERC721Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    
    uint256 public CURRENT_SALE_PIRATE_TYPE;
    uint256 public MAX_PRESALE;
    uint256 public PRE_SALE_MAX;
    uint256 public PUBLIC_SALE_MAX;
    uint256 public CURRENT_TOKEN_ID;

    struct ArrLander {
        uint256 generation;
        uint256 breed_count;
        uint256 bornAt;
        uint256 pirate_type;  
    }

    struct PirateType {
        uint256 team_reserve;
        uint256 max_supply;
        bool exists;
        uint256 supply;
        uint256 preSalePrice;
        uint256 publicSalePrice;
    }

    mapping(uint256 => ArrLander) public arrLanders;
    mapping(uint256 => PirateType) public pirate_types;
    mapping(address => bool) public whitelist;
    mapping(address => bool) private spawnPirateAllowedCallers;
    mapping(uint256 => mapping(uint256 => string)) private BASE_URLS; // base urls per generation and type

    bool public hasSaleStarted;
	bool public hasPresaleStarted;

	uint256 public preSalePrice;
    uint256 public publicSalePrice;

    event Sold(address to, uint256 tokenCount, uint256 amount, uint256 timestamp);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory baseURI, uint256 _team_tokens, uint256 _max_per_type) initializer public {
        __ERC721_init("ArrLandNFT","ARRLDNFT");     
        __Ownable_init();
    }

    modifier isAllowedCaller() {
        require(spawnPirateAllowedCallers[_msgSender()] == true, "Wrong external call");
        _;
    }

    function mint(uint256 numArrlanders) public payable{
        revert("mint on L2");
    }

    function setPirateSaleType(uint256 pirate_sale_type, uint256 _teamReserve, uint256 _maxPerType, uint256 _preSalePrice, uint256 _publicSalePrice) public onlyOwner {
        require(pirate_sale_type > 0, "Pirate sale type must be greater then 0");
        CURRENT_SALE_PIRATE_TYPE = pirate_sale_type;
        if (pirate_types[CURRENT_SALE_PIRATE_TYPE].exists == false) {
            preSalePrice = _preSalePrice;
            publicSalePrice = _publicSalePrice;
            pirate_types[pirate_sale_type] = PirateType(_teamReserve, _maxPerType.sub(_teamReserve), true, 0, _preSalePrice, _publicSalePrice);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = BASE_URLS[arrLanders[tokenId].generation][arrLanders[tokenId].pirate_type];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function setBaseURI(string memory _baseURI, uint256 generation, uint256 pirate_type_id) public onlyOwner {
        BASE_URLS[generation][pirate_type_id] = _baseURI;    
    }

    function setPUBLIC_SALE_MAX(uint256 _PUBLIC_SALE_MAX) public onlyOwner {
        revert("mint on L2");
    }

    function setSpawnPirateAllowedCallers(address _externalCaller) public onlyOwner {
        require(_externalCaller != address(0), "Wrong address");
        spawnPirateAllowedCallers[_externalCaller] = true;
    }

    function flipSaleStarted() public onlyOwner {
        revert("mint on L2");
    }

    function flipPreSaleStarted() public onlyOwner {
        revert("mint on L2");
    }

    function addWalletsToWhiteList(address[] memory _wallets) public onlyOwner{
        revert("mint on L2");
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function reserveTokens(uint256 tokenCount) external isAllowedCaller {
        _reserveTokens(tokenCount);
    }

    function sendGiveAway(address _to, uint256 _tokenCount, uint256 _generation) external isAllowedCaller
    {
        revert("mint on L2");
    }

    function _reserveTokens(uint256 _tokenCount) private {
        revert("mint on L2");
    }

    function spawn_pirate(
        address _to, uint256 generation, uint256 pirate_type
    )
        external isAllowedCaller
        returns (uint256)
    {
        revert("mint on L2");
        return 0;
    }

    function _spawn_pirate(address to, uint256 tokenID, uint256 _pirate_type) private returns (uint256) {
        require(_pirate_type == 1 || _pirate_type == 2, "Only type 1 and 2");
        PirateType storage pirate_type = pirate_types[_pirate_type];
        pirate_type.supply = pirate_type.supply.add(1);
        _safeMint(to, tokenID);
        arrLanders[tokenID] = ArrLander(0, 0, block.timestamp, _pirate_type);
        return tokenID;
    }
    // new code 
    address public imx;

    function setImx(address _imx) public onlyOwner {
        imx = _imx;
    }

    function totalSupply() public view returns (uint256){ 
        PirateType storage pirate_type1 = pirate_types[1];
        PirateType storage pirate_type2 = pirate_types[2];
        return pirate_type1.supply+pirate_type2.supply;
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external {
        require(quantity == 1, "Invalid quantity");
        require(msg.sender == imx, "Function can only be called by IMX");
        (uint256 tokenId, uint256 pirate_type) = Parsing.split(mintingBlob);
        require(pirate_type == 1 || pirate_type == 2, "Only type 1 and 2");
        PirateType storage pirate_type_struct = pirate_types[pirate_type];
        if (pirate_type == 1){
            require(pirate_type_struct.supply < 10000, "max supply");
        }
        if (pirate_type == 2){
            require(pirate_type_struct.supply < 5000, "max supply");
        }

        _spawn_pirate(user, tokenId, pirate_type);
    }
}


