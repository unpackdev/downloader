// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.7;


import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./VRFConsumerBaseUpgradeable.sol";

interface IZombie {
  function addZombie(address account, uint256 tokenId) external;
}

interface IGold {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISlime {
  function bigSlime(uint256 xyz) external returns (uint256 slime);
}

interface ICave {
  function addManyToCave(address account, uint16[] calldata tokenIds) external;
  function randomDragonOwner(uint256 seed) external view returns (address);
}

contract DragonsDenV2 is ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable  {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; 
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using AddressUpgradeable for address;



  struct BigDragon {uint8 alphaIndex; bool isKnight; bool isDonkey; bool isZombie; }
  struct LastWrite {uint64 time; uint64 blockNum;}

  string public baseURI;
  uint256 public MAX_TOKENS;                                                                         
  uint16  public minted;                                                 
  uint256 public MINT_PRICE;
  uint256 private PAID_TOKENS;  
  uint256 public wlFreeMint;


  uint8[] private rarities;
  uint8[] private aliases; 
  
  mapping(address => bool)      public  whitelists;
  mapping (address => bool)     private whitelistedContracts;  
  mapping(uint256 => BigDragon) private tokenTraits;                              
  mapping(address => LastWrite) private lastWriteAddress;
  mapping(uint256 => LastWrite) private lastWriteToken;
  mapping(address => uint256[]) private _mints;

  ICave public cave;                                          
  IGold public gold;         
  ISlime public slime;                       
  IZombie public zombie;     


  event tokenStolen (address owner,  address thief, uint256 tokenId);


  function initialize(address _gold, address _bigSlime, uint256 _maxTokens) initializer public {

   __ERC721_init("DragonsGame", "KnightsDragon");
   __ERC721Enumerable_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    gold = IGold(_gold);
    slime = ISlime(_bigSlime);

    MINT_PRICE = 0.0777 ether;   
    wlFreeMint = 1;

    MAX_TOKENS = _maxTokens;
    PAID_TOKENS = _maxTokens / 5;

    rarities = [210,182,153,74,46];
    aliases = [4,3,2,1,0];




    _pause();


  }


  // If she catch me minting ill never tell her sorry
  function mint(uint256 amount, bool stake) external payable whenNotPaused {
  
    address msgSender = _msgSender();
    require(!msgSender.isContract(), "Contracts are not");
    require(tx.origin == msgSender, "Only EOA");
    require(minted + amount <= MAX_TOKENS, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");

    if (minted < PAID_TOKENS) {
      uint256 mintCostEther = MINT_PRICE * amount;
      
      if (whitelists[msgSender]) {
          mintCostEther = ( amount - wlFreeMint) * MINT_PRICE;
          whitelists[msgSender] = false;
      }
    
      require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
      require(mintCostEther == msg.value, "Invalid payment amount");


    } else {

      require(msg.value == 0);

    }

    uint256 totalGoldCost = 0;                                                       
    uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);          
    uint256 seed;

    for (uint i = 0; i < amount; i++) {
      minted++;
      seed = slime.bigSlime(minted);                                                             
      BigDragon memory t = generate(seed);                                                                   
      address recipient = selectRecipient(seed);    

      if (recipient == address(zombie)) {
  
        _safeMint(address(zombie), minted);
        zombie.addZombie(msgSender,minted);
        t.isZombie = true;
       
      
      } else if (!stake || recipient != msgSender) {                                           
        _safeMint(recipient, minted);

      } else {
        _safeMint(address(cave), minted);
        tokenIds[i] = minted;
      }
      totalGoldCost += mintCost(minted);
      tokenTraits[minted] = t;
      if (recipient != msgSender)  emit tokenStolen(msgSender,recipient,minted);
    }
    
    if (totalGoldCost > 0) {
      gold.burn(_msgSender(), totalGoldCost);
      gold.updateOriginAccess();
    }

    _updateOriginAccess(tokenIds);
    if (stake) cave.addManyToCave(msgSender, tokenIds);

    

  }

  function selectRecipient(uint256 seed) private view returns (address) {

    require(tx.origin == msg.sender && !_msgSender().isContract(), "Contracts are not allowed");
    if (minted <= PAID_TOKENS || (seed >> 252) >= 6 ) return _msgSender();  

    if ((seed >> 252) <= 2) return address(zombie);

    address thief = cave.randomDragonOwner(seed >> 144);                                         
    if (thief == address(0x0)) return _msgSender();
    return thief;

  }



  /** Gameplay VIEW Functions */
  function mintCost(uint256 tokenId) public view returns (uint256) {
    if (tokenId <= PAID_TOKENS) return 0;                           
    if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;          
    if (tokenId <= MAX_TOKENS * 4 / 5) return 40000 ether;         
    return 80000 ether;                                            
  }

  function generate(uint256 seed) private view blockExternalContracts returns (BigDragon memory t) {

    t.isZombie = false;
    t.isKnight = (seed & 0xFFFF) % 10 != 0;
    seed >>= 16;
    uint8 trait = uint8(seed) % uint8(rarities.length);           

    if (seed >> 8 < rarities[trait]) {
      t.alphaIndex = trait; 
      return t;
    }        

    t.alphaIndex = aliases[trait];
    
    return t;
  }

  function getTokenTraits(uint256 tokenId) public view blockIfChangingAddress blockIfChangingToken(tokenId) blockExternalContracts returns (BigDragon memory) {

    return tokenTraits[tokenId];
  }

  function getPaidTokens() external view blockExternalContracts returns (uint256) {
    return PAID_TOKENS;
  }

  function getTokenIds(address _owner) public view blockExternalContracts returns (uint256[] memory _tokensOfOwner) {
      _tokensOfOwner = new uint256[](balanceOf(_owner));
      for (uint256 i;i<balanceOf(_owner);i++){
          _tokensOfOwner[i] = tokenOfOwnerByIndex(_owner, i);
      }
  }

  /** ERC 721 Functions  */

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721Upgradeable) blockIfChangingToken(tokenId) {
        if(!whitelistedContracts[_msgSender()]) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override(ERC721EnumerableUpgradeable) blockIfChangingAddress blockExternalContracts returns (uint256) {
    uint256 tokenId = super.tokenOfOwnerByIndex(owner, index);
    require(whitelistedContracts[_msgSender()] || lastWriteAddress[owner].blockNum < block.number, "Go Find God. Come back after you found god");
    return tokenId;
  }

  function balanceOf(address owner) public view virtual override(ERC721Upgradeable) blockIfChangingAddress blockExternalContracts returns (uint256) {
    require(whitelistedContracts[_msgSender()] || lastWriteAddress[owner].blockNum < block.number, "Go Find God. Come back after you found god");
    return super.balanceOf(owner);
  }

  function ownerOf(uint256 tokenId) public view virtual override(ERC721Upgradeable) blockIfChangingAddress blockIfChangingToken(tokenId) blockExternalContracts returns (address) {
      address addr = super.ownerOf(tokenId);
      require(whitelistedContracts[_msgSender()] || lastWriteAddress[addr].blockNum < block.number, "Go Find God. Come back after you found god");
      return addr;
  }

  function tokenByIndex(uint256 index) public view virtual override(ERC721EnumerableUpgradeable) blockExternalContracts returns (uint256) {
    uint256 tokenId = super.tokenByIndex(index);
    require(whitelistedContracts[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "Go Find God. Come back after you found god");
    return tokenId;
  }

  function safeTransferFrom(address from,address to, uint256 tokenId) public virtual override(ERC721Upgradeable) blockIfChangingToken(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data ) public virtual override(ERC721Upgradeable) blockIfChangingToken(tokenId) {
      super.safeTransferFrom(from, to, tokenId, _data);
  }

  /** ADMIN FUNCTIONS */

  function changeMintETH(uint256 newPrice) external onlyOwner {
    MINT_PRICE = newPrice;

  }

  function setBaseURI(string memory newUri) public onlyOwner {
      baseURI = newUri;
  }

  function setWhitelistContract(address contract_address, bool status) public onlyOwner{
      whitelistedContracts[contract_address] = status;
  }

  function setCave(address _cave) external onlyOwner {
    cave = ICave(_cave);
  }

  function setZombie(address _zombie) external onlyOwner {
    zombie = IZombie(_zombie);
  }

  function setSlime(address _slime) external onlyOwner {
      slime = ISlime(_slime);
  }

  function setGold(address _gold) external onlyOwner {
      gold = IGold(_gold);  
  }

  function setInit(address _cave, address erc20Address, address _slime, address _zombie) public onlyOwner {
    cave = ICave(_cave);
    gold = IGold(erc20Address);
    slime = ISlime(_slime);
    zombie = IZombie(_zombie);

  }
  
  function setURI(string memory _newBaseURI) external onlyOwner {
		  baseURI = _newBaseURI;
  }

  function setPaidTokens(uint256 _paidTokens) external onlyOwner {
    PAID_TOKENS = _paidTokens;
  }

  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function addWhitelist(address[] calldata addressArrays) external onlyOwner {
    uint256 addylength = addressArrays.length;
    for (uint256 i; i < addylength; i++ ){
          whitelists[addressArrays[i]] = true;
    }
  }

  function withdraw() public payable onlyOwner {

		payable(_msgSender()).transfer(address(this).balance );

  }

  /** SECURITY BIG SLIME */
  // It’s an evil world we live in.

  function _updateOriginAccess(uint16[] memory tokenIds) internal blockExternalContracts {

    uint64 blockNum = uint64(block.number);
    uint64 time = uint64(block.timestamp);
    lastWriteAddress[tx.origin] = LastWrite(time, blockNum);
    for (uint256 i = 0; i < tokenIds.length; i++) {
        lastWriteToken[tokenIds[i]] = LastWrite(time, blockNum);
    }
  }

  modifier requireContractsSet() {
      require(address(slime) != address(0) && address(gold) != address(0) && address(cave) != address(0), "Contracts not set");
      _;
  }

  modifier blockIfChangingAddress() {
      require(whitelistedContracts[_msgSender()] || lastWriteAddress[tx.origin].blockNum < block.number, "Go Find God. Come back after you found god");
      _;
  }

  modifier blockIfChangingToken(uint256 tokenId) {
      require(whitelistedContracts[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "Go Find God. Come back after you found god");
      _;
  }

  modifier blockExternalContracts() {
    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
      _;
      
    } else {

      _;

    }
    
  }

  function getTokenWriteBlock(uint256 tokenId) external view returns(uint64) {
      require(whitelistedContracts[_msgSender()], "Only admins can call this");
      return lastWriteToken[tokenId].blockNum;
  }

  function test() external onlyOwner  {

    __ERC721_init("DragonsGame", "KnightsDragon");

  }




  


}