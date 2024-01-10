pragma solidity ^0.8.12;

import "./EGGS.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./Strings.sol";

contract ChickenDAOv2 is ERC721PresetMinterPauserAutoId {

    EGGS public EGGS_TOKEN = EGGS(0x4Ae258F6616Fc972aF90b60bFfc598c140C79def);

    using Strings for uint256;
   
    uint16 public maxSupply = 7777;
    uint256 public price = 128000000000000000; // start at 0.128ETH
    address payable treasury = payable(0x64108034f4e255DAa4425057a0297E5F74f2822c); // chicken dao treasury
    address payable bank = payable(0x0cDe89C36A0f63BC14A847f5114ac21326B06Cf5); // chicken dao bank

    string URIRoot = "https://goldeneye.mypinata.cloud/ipfs/QmWJreWETyXRUK8jRsoVXC7PBbYe8PBbrZ5qir2X8MBu9K/";
    struct Chicken {
        uint color;
        uint256 eggsPerDay;
        uint256 eggsCollectedLast;
        uint256 tokenId;
    }

    mapping(uint256 => Chicken) public chickens;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721PresetMinterPauserAutoId("Chicken DAO", "CHICKENDAO", URIRoot) {
    }

    function updateBank(address payable _b) 
    public 
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        bank = _b;
    }

    function updateEggs(address _e) 
    public 
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        EGGS_TOKEN = EGGS(_e);
    }

    function collectEggs(uint256 id)
    public 
    {   Chicken memory chicken = chickens[id];
        uint32 dayInSeconds = 86400;
        require(ownerOf(id) == msg.sender, "only owner can collect eggs.");
        require(block.timestamp > (chicken.eggsCollectedLast + dayInSeconds), "eggs already collected.");
        EGGS_TOKEN.mint(msg.sender, chicken.eggsPerDay);
        chickens[id].eggsCollectedLast = block.timestamp;
    }

    function collectAll()
    public 
    {
        uint256 eggs = 0;
        for (uint8 i = 0; i < balanceOf(msg.sender); i++) {
            uint256 index = tokenOfOwnerByIndex(msg.sender, i);
            Chicken memory chicken = chickens[index];
            uint32 dayInSeconds = 86400;
            if (block.timestamp > (chicken.eggsCollectedLast + dayInSeconds)) {
                eggs += chicken.eggsPerDay;
                chickens[index].eggsCollectedLast = block.timestamp;
            }
        }
        EGGS_TOKEN.mint(msg.sender, eggs);
    }
    
    function changePrice(uint256 _price) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        price = _price;
    }
    
    function updateURI(string memory _newURI) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        URIRoot = _newURI;
    }
    
    function buy(uint8 quantity) payable external {
        require(quantity > 0, "Quantity must be more than 1.");
        require(quantity <= 30, "Quantity must be less than 30.");
        require(msg.value >= price * quantity, "Not enough ETH.");
        mintNFT(quantity);
        payAccounts();
    }
    
    function mintNFT(uint16 amount)
    private
    {
        // enforce supply limit
        uint256 totalMinted = totalSupply();
        require((totalMinted + amount) <= maxSupply, "Sold out.");
        
        for (uint i = 0; i < amount; i++) { 
            uint256 currentID = _tokenIds.current();
            uint color = getChickenColor(currentID);
            _mint(msg.sender, currentID);
            createChicken(currentID, color);
            _tokenIds.increment();
        }
    }

    function migrateNFT(uint color, address _ownerAddr) public {
        require((totalSupply() + 1) <= maxSupply, "Sold out.");
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        uint256 currentID = _tokenIds.current();
        _mint(_ownerAddr, currentID);
        createChicken(currentID, color);
        _tokenIds.increment();
    }

    function createChicken(uint256 id, uint color) 
    private
    {
        uint256 eggsPerDay = getEggsPerDay(color);
        uint32 dayInSeconds = 86400;
        chickens[id] = Chicken(
            color,
            eggsPerDay,
            block.timestamp - dayInSeconds,
            id
        );
    }

    function getEggsPerDay(uint color) 
    private
    view
    returns (uint256)
    {
        if (color == 0) {
            return 1000000000000000000000; // gold
        }
        else if (color == 1) {
            return 100000000000000000000; // red
        }
        else if (color == 2) {
            return 100000000000000000000; // blue
        }
        else if (color == 3) {
            return 100000000000000000000; // green
        }
        else if (color == 4) {
            return 20000000000000000000; // black
        }
        else if (color == 5) {
            return 20000000000000000000; // white
        }
        else {
            return 20000000000000000000; // brown
        }
    }

    function getChickenColor(uint256 i) 
    private
    returns (uint)
    {
        uint256 j = i;
        if (j % 100 == 0) {
            return 0; // GOLD
        }
        else if (j % 13 == 0) {
            return 1; // RED
        }
        else if (j % 12 == 0) {
            return 2; // BLUE
        }
        else if (j % 11 == 0) {
            return 3; // GREEN
        }
        else if (j % 3 == 0) {
            return 4; // BLACK
        }
        else if (j % 2 == 0) {
            return 5; // WHITE
        }
        else {
            return 6; // BROWN
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        string memory color = Strings.toString(chickens[tokenId].color);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(URIRoot, color, ".json")) : "";
    }
    
    function payAccounts() public payable {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            uint256 devCut = balance * 30 / 100;
            uint256 bankCut = balance * 70 / 100;
            treasury.transfer(devCut);
            bank.transfer(bankCut);
        }
    }
}