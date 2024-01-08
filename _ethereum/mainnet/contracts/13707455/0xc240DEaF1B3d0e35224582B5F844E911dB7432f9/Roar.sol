// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.7;



import "./Initializable.sol";

// Utility Libraries
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";


// Security Libraries 
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";


// Token Libraries
import "./IERC20Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./VRFConsumerBaseUpgradeable.sol";


interface ISalmon {
  function burn(address from, uint256 amount) external;
}

interface IRiver {
  function addManyToRiverSideAndFishing(address account, uint16[] calldata tokenIds) external;
  function randomBearOwner(uint256 seed) external view returns (address);
}

interface IRiverOld {
  function randomBearOwner(uint256 seed) external view returns (address);
}

contract Roar is ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable, VRFConsumerBaseUpgradeable {

  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; 
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using AddressUpgradeable for address;


  // mint variables      
  mapping (address => bool) whitelistedContracts;              
  uint256 public  MAX_TOKENS;                                            // max number of tokens that can be minted - 50000 in production
  uint16 public minted;                                                  // number of tokens have been minted so far
  string public baseURI;

  // mappings
  mapping(uint256 => ManBear) private tokenTraits;                       // mapping from tokenId to a struct containing the token's traits
  mapping(uint256 => uint256) private existingCombinations;              // mapping from hashed(tokenTrait) to the tokenId it's associated with, Why? used to ensure there are no duplicates
  mapping(address => uint256[]) public _mints;

  
  struct ManBear {bool isFisherman; uint8[14] traitarray; uint8 alphaIndex;}

  // Pobabilities & Aliases
  // 0 - 8 are associated with fishermen, 9 - 13 are associated with Bears
  uint8[][18] public rarities;
  uint8[][18] public aliases;

  IRiverOld public oldRiver;
  IRiver public river;                                                      
  ISalmon public salmon;                                                    

  //Chainlink Setup:
  bytes32 internal keyHash;
  uint256 public fee;
  uint256 internal randomResult;
  uint256 internal randomNumber;
  address public linkToken;
  uint256 public vrfcooldown;
  CountersUpgradeable.Counter public vrfReqd;


  function initialize(address _salmon, uint256 _maxTokens, address _vrfCoordinator, address _link) initializer public {

   __ERC721_init("Bear Game Gen Y", "BEARGENY");
   __ERC721Enumerable_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    __VRFConsumerBase_init(_vrfCoordinator,_link);


    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    fee = 2 * 10 ** 18; // 2 LINK (Varies by network)
    linkToken = _link;
    vrfcooldown = 300;


    // Initate Interfaces
    salmon = ISalmon(_salmon);

    minted = 10498;
    MAX_TOKENS = _maxTokens;  

    rarities[0] = [31,49,51,69,113,187,204,207,225]; 
    rarities[1] = [35,48,67,115,189,208,221];
    rarities[2] = [59,97,136,159,197];
    rarities[3] = [85,113,131,143,169];
    rarities[4] = [255,255,255,255];
    rarities[5] = [34,59,118,164,197,222];
    rarities[6] = [59,111,145,197];
    rarities[7] = [57,93,163,199];
    rarities[8] = [255];

    aliases[0] = [8,7,6,5,4,3,2,1,0];
    aliases[1] = [6,5,4,3,2,1,0];
    aliases[2] = [4,3,2,1,0];
    aliases[3] = [4,3,2,1,0];
    aliases[4] = [3,2,1,0];
    aliases[5] = [5,4,3,2,1,0];
    aliases[6] = [3,2,1,0];
    aliases[7] = [3,2,1,0];
    aliases[8] = [0];

    rarities[9] = [255,255,255,255,255];
    rarities[10] = [39,51,59,67,125,131,189,197,204,217];
    rarities[11] = [51,54,57,64,72,90,194,199,202,207,212];
    rarities[12] = [48,60,96,160,196,208];
    rarities[13] = [51,102,153,204];

    aliases[9] = [0,1,2,3,4];
    aliases[10] = [9,8,7,6,5,4,3,2,1,0];
    aliases[11] = [10,9,8,7,6,5,4,3,2,1,0];
    aliases[12] = [5,4,3,2,1,0];
    aliases[13] = [3,2,1,0];
    
  
  }    
  // Calculates Mint Cost using $SALMON
  function mintCost(uint256 tokenId) public pure returns (uint256) {              
    if (tokenId <= 17000) return 20000 ether;              
    if (tokenId <= 27000) return 40000 ether;          
    if (tokenId <= 37000) return 60000 ether;         
    return 80000 ether;                                            
  }

  // Main Mint Functions
  function mint(uint256 amount, bool stake) external payable whenNotPaused nonReentrant() {

    address msgSender = _msgSender();

    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(tx.origin == msgSender, "Only EOA");
    require(minted + amount <= MAX_TOKENS, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");
    require(msg.value == 0);

    getRandomChainlink();
    
    uint256 totalSalmonCost = 0;                                                          // $SALMON Cost to mint. 0 is Gen0
    uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);          
    uint256 seed;

    for (uint i = 0; i < amount; i++) {
      minted++;
      seed = random(minted);                                                             // NOTES: SUS
      generate(minted, seed);                                                            // Generates Token Traits and adds it to the array
      address recipient = selectRecipient(seed);                                         // Selects who the NFT is going to. Gen0 always will be minter. 
      if (!stake || recipient != msgSender) {                                            // recipient != _msgSender()
        _safeMint(recipient, minted);
      } else {
        _safeMint(address(river), minted);
        tokenIds[i] = minted;
      }
      totalSalmonCost += mintCost(minted);
    }
    
    if (totalSalmonCost > 0) salmon.burn(msgSender, totalSalmonCost);
    if (stake) river.addManyToRiverSideAndFishing(msgSender, tokenIds);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    // Hardcode the River's approval so that users don't have to waste gas approving
    if (_msgSender() != address(river))
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }

  // generates traits for a specific token, checking to make sure it's unique
  function generate(uint256 tokenId, uint256 seed) private returns (ManBear memory t) {

    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }

    t = selectTraits(seed);
    if (existingCombinations[structToHash(t.isFisherman, t.traitarray, t.alphaIndex)] == 0) {
      tokenTraits[tokenId] = t;
      existingCombinations[structToHash(t.isFisherman, t.traitarray, t.alphaIndex)] = tokenId;
      return t;
    }
    return generate(tokenId, random(seed));
  }

  // Selects Trait using A.J. Walker's Alias algorithm for O(1) rarity table lookup
  function selectTrait(uint16 seed, uint8 traitType) private view returns (uint8) {

    uint8 trait = uint8(seed) % uint8(rarities[traitType].length);           
    if (seed >> 8 < rarities[traitType][trait]) return trait;                 
    return aliases[traitType][trait];

  }


  // selects the species and all of its traits based on the seed value
  function selectTraits(uint256 seed) private view returns (ManBear memory t) {    
    t.isFisherman = (seed & 0xFFFF) % 10 != 0;
    uint8 shift = t.isFisherman ? 0 : 9;                                          // 0 if its a Fisherman, 9 if its Bear

    seed >>= 16;
    if (t.isFisherman) {

      // / 0 - 8 are associated with fishermen, 


      t.traitarray[0] = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
      seed >>= 16;
      t.traitarray[1] = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
      seed >>= 16;
      t.traitarray[2] = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
      seed >>= 16;
      t.traitarray[3] = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
      seed >>= 16;
      t.traitarray[4] = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
      seed >>= 16;
      t.traitarray[5] = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
      seed >>= 16;
      t.traitarray[6] = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
      seed >>= 16;
      t.traitarray[7] = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
      seed >>= 16;
      t.traitarray[8] = selectTrait(uint16(seed & 0xFFFF), 8 + shift);

      t.alphaIndex = 0;




    } else {
      // 9 - 13 are associated with Bears

      t.traitarray[9] = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
      seed >>= 16;
      t.traitarray[10] = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
      seed >>= 16;
      t.traitarray[11] = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
      seed >>= 16;
      t.traitarray[12] = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
      seed >>= 16;
      t.traitarray[13] = selectTrait(uint16(seed & 0xFFFF), 4 + shift);

      t.alphaIndex = t.traitarray[13];
      
      
    }

  }


  // converts a struct to a 256 bit hash to check for uniqueness
  function structToHash(bool isFisherman, uint8[14] memory traitarray, uint8 alphaIndex) internal pure returns (uint256) {
    if(isFisherman){
      return uint256(bytes32(abi.encodePacked(true,
        traitarray[0],
        traitarray[1],
        traitarray[2],
        traitarray[3],
        traitarray[4],
        traitarray[5],
        traitarray[6],
        traitarray[7],
        traitarray[8],
        "0",
        "0",
        "0",
        "0",
        "0",
        alphaIndex)));
    }
    else{
      return uint256(bytes32(abi.encodePacked(false,
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        "0",
        traitarray[9],
        traitarray[10],
        traitarray[11],
        traitarray[12],
        traitarray[13],
        alphaIndex)));
    }
    
  }
  // Select who the NFT goes to --- The first 20% (ETH purchases) go to the minter & the remaining 80% have a 10% chance to be given to a random staked Bear
  function selectRecipient(uint256 seed) private view returns (address) {

    
    require(tx.origin == msg.sender && !_msgSender().isContract(), "Contracts are not allowed big man");
     
    if (((seed >> 245) % 10) != 0) return _msgSender();                 // top 10 bits haven't been used
    if (random(seed) & 1 == 1) {                                           
        address thiefGenX = oldRiver.randomBearOwner(seed >> 144);
        return thiefGenX;
    }
    
    address thief = river.randomBearOwner(seed >> 144);                                       
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }

  /** READ */


  function setWhitelistContract(address contract_address, bool status) public onlyOwner{
      whitelistedContracts[contract_address] = status;
  }

  function getTokenTraits(uint256 tokenId) public returns (ManBear memory) {
  
      if (tx.origin != msg.sender) {
          require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
      }

      return tokenTraits[tokenId];
  }

  function setRiver(address _river, address _oldRiver) external onlyOwner {
    river = IRiver(_river);
    oldRiver = IRiverOld(_oldRiver); 
    getRandomChainlink();
  }

  function setSalmon(address erc20Address) public onlyOwner {
    salmon = ISalmon(erc20Address);
  }
  
  // Set Base URL
  function setURI(string memory _newBaseURI) external onlyOwner {
		  baseURI = _newBaseURI;
  }

  // enables owner to pause / unpause minting
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }


  /** RENDER */

  function setBaseURI(string memory newUri) public onlyOwner {
      baseURI = newUri;
  }


  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }


  function getTokenIds(address _owner) public view returns (uint256[] memory _tokensOfOwner) {
        _tokensOfOwner = new uint256[](balanceOf(_owner));
        for (uint256 i;i<balanceOf(_owner);i++){
            _tokensOfOwner[i] = tokenOfOwnerByIndex(_owner, i);
        }
  }


      
  /** RANDOMNESSSS */

  function random(uint256 seed) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed,
      randomNumber
    )));
  }

  function changeLinkFee(uint256 _fee) external onlyOwner {
    // fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    fee = _fee;
  }

  function initChainLink() external onlyOwner returns (bytes32 requestId){
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    return requestRandomness(keyHash, fee);
  }

  function getRandomChainlink() internal returns (bytes32 requestId) {

    if (vrfReqd.current() <= vrfcooldown) {
      vrfReqd.increment();
      return 0x000;
    }

    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    vrfReqd.reset();
    return requestRandomness(keyHash, fee);
  }

  function changeVrfCooldown(uint256 _cooldown) external onlyOwner{
      vrfcooldown = _cooldown;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
      bytes32 reqId = requestId;
      randomNumber = randomness;
  }

  function withdrawLINK() external onlyOwner {
    uint256 tokenSupply = IERC20Upgradeable(linkToken).balanceOf(address(this));
    IERC20Upgradeable(linkToken).transfer(msg.sender, tokenSupply);
  }
  
  function changeLinkAddress(address _newaddress) external onlyOwner{
      linkToken = _newaddress;
  }

  function changeMaxtokens(uint256 _maxTokens) external onlyOwner {

    MAX_TOKENS = _maxTokens;
    
  }

}