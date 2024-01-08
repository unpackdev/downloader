/*
 ██████╗██████╗  ██████╗  ██████╗ ██████╗ ██████╗ ██╗██╗     ███████╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔═══██╗██╔══██╗██║██║     ██╔════╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
██║     ██████╔╝██║   ██║██║     ██║   ██║██║  ██║██║██║     █████╗      ██║  ███╗███████║██╔████╔██║█████╗  
██║     ██╔══██╗██║   ██║██║     ██║   ██║██║  ██║██║██║     ██╔══╝      ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
╚██████╗██║  ██║╚██████╔╝╚██████╗╚██████╔╝██████╔╝██║███████╗███████╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
 ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/


pragma solidity ^0.8.10;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721Enumerable.sol";

import "ICrocodileGamePiranha.sol";
import "ICrocodileGameNFT.sol";
import "ICrocodileGame.sol";

contract CrocodileGameNFT is ICrocodileGameNFT, ERC721Enumerable, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint256;

  uint16 public minted;
  uint16 public crocodileminted;
  uint16 public crocodilebirdminted;

  uint16 public constant MAX_GEN0_TOKENS = 10000;

  uint16 public constant MAX_TOKENS = 20000;

  // OnChain trick
  uint256[MAX_TOKENS+1] public virtualTokenId;
  mapping(uint256 => bool) public ExistvirtualTokenId; 
  mapping(uint256 => bool) public ExistRandId;



  // External contracts
  ICrocodileGamePiranha private immutable crocodilePirinha;
  ICrocodileGame private crocodileGame;

  uint256 public constant MINT_PRICE = 0.07 ether;

  uint32 public constant maxMINT = 10;

  mapping(uint256 => Traits) public tokenTraits;

    constructor(address Piranha, address game) ERC721("CrocodileGame", "CROCO") {
      crocodilePirinha = ICrocodileGamePiranha(Piranha);
      crocodileGame = ICrocodileGame(game);
    }


  function setGameContract(address _address) external onlyOwner {
    crocodileGame = ICrocodileGame(_address);
  }

  function getTraits(uint16 tokenId) external view override returns (Traits memory) {
    return tokenTraits[virtualTokenId[tokenId]];
  }

  function getMaxGEN0Players() external pure override returns (uint16) {
    return MAX_GEN0_TOKENS;
  }

  function _mint(uint32 amount, bool stake, bool dilemma) internal {
    //Kind kind;
    uint16[] memory tokenIdsToStake = stake? new uint16[](amount) : new uint16[](0);
    uint8[] memory dilemmas = stake? new uint8[](amount) : new uint8[](0);
    uint256 PiranhaCost;

    uint8 kind;
    uint256 seed;
    
    for (uint32 i=0; i < amount; i++) {
      minted++;
      seed = uint256(keccak256(abi.encodePacked(block.timestamp, minted, i)));  
      PiranhaCost += getMintPiranhaCost(minted);
      kind = _SetPhaseOneTraits(minted, seed).kind;

      address recipient = _selectRecipient(seed);
      if (!stake || recipient != msg.sender) {
        _safeMint(recipient, minted);
      } 

      else {
        // When Stake, dilemma==true => Cooperate, dilemma==false => Betraay
        _safeMint(address(crocodileGame), minted);
        tokenIdsToStake[i]=minted;
        if (dilemma)
          {dilemmas[i]=1;}
        else if (!dilemma)
          {dilemmas[i]=2;}
      }
    }
    if (PiranhaCost > 0) {
      crocodilePirinha.burn(msg.sender, PiranhaCost);
    }
    if (stake) {
      crocodileGame.stakeTokens(msg.sender, tokenIdsToStake, dilemmas);
    }
  }
  

  /**
   * Mint your players.
   * stake == 0 : Mint then No Staking
   * stake == 1 : Mint then Stake - Cooperate
   * stake == 2 : Mint then Stake - Betray
   */
  function mint(uint32 amount, bool stake, bool dilemma) external payable nonReentrant {
    require(tx.origin == msg.sender, "eos only");
    require(amount > 0 && amount <= maxMINT, "invalid mint amount");
    require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
    require(minted + amount <= MAX_TOKENS, "minted out");
    
    _mint(amount, stake, dilemma);
  }

  function burn(uint16 tokenId) external nonReentrant{
    if (msg.sender != address(crocodileGame)) {
      require(_isApprovedOrOwner(msg.sender, tokenId), "transfer not owner nor approved");
    }
    _burn(tokenId);
  }


  function getMintPiranhaCost(uint16 tokenId) public pure returns (uint256) {
    if (tokenId <= MAX_GEN0_TOKENS) return 0;
    if (tokenId <= MAX_TOKENS * 3 / 4) return 40000 ether;
    return 80000 ether;
  }

  /**
   * This function sets the OnChain variables for the 'Phase1: Prisoner's Dilemma'
   * And, the virtual tokenID for the Semi-OnChain implementation.
   * @param tokenId id of the token to generate traits
   * @return t player trait struct
   */
  function _SetPhaseOneTraits(uint16 tokenId, uint256 seed) internal returns (Traits memory t) {    
    uint256 randid;
    uint256 seed_nonce = 0;
    uint256 mod = seed % 50;

    if (crocodilebirdminted == 10000 || mod >= 25)
      {
       t.kind = 0;
       crocodileminted++;
      // OnChain Trick - Sampling the crocodile.
      while (!ExistvirtualTokenId[minted]){
        // generate the random number between 1~10000
        randid = uint256(keccak256(abi.encodePacked(msg.sender, seed, seed_nonce, block.timestamp))) % (MAX_TOKENS/2);
        if (!ExistRandId[randid])
          {
            // map the random token index to the current token index
            virtualTokenId[minted] = randid;
            ExistvirtualTokenId[minted] = true;
          }
        else 
          {seed_nonce++;}
        }      
      }
    else if (crocodileminted == 10000 || mod < 25)
      {
      t.kind = 1;
      crocodilebirdminted++;
      // OnChain Trick - Sampling the crocodile bird.
      while (!ExistvirtualTokenId[minted]){
        // generate random number between 10001~20000
        randid = 10000 + uint256(keccak256(abi.encodePacked(msg.sender, seed, seed_nonce, block.timestamp))) % (MAX_TOKENS/2);
        if (!ExistRandId[randid])
          {
            // map the random token index to the current token index
            virtualTokenId[minted] = randid;
            ExistvirtualTokenId[minted] = true;
          }
        else 
          {seed_nonce++;}
        }      
      }

    t.dilemma = 0;
    t.karmaP = 0;
    t.karmaM = 0;

    tokenTraits[virtualTokenId[tokenId]] = t;
  
    return t;
    }


  function enrollPhaseTwoTraits(uint16 tokenId, string[100] memory traits_distribution) public onlyOwner returns (Traits memory t) {
    // Enroll the trait variables on the blcokchain.
    // To interact with the blockchain, the traits of ERC721 token should be enrolled in the blockchain.
    // But, storing the token level information to the blockchain is extremely expensive.
    // Basically, it's O(nk), where n: #tokens, k: #traits.
    // This is why the gamified NFT projects have lots of gas fee.
    
    // To lower the players' gas burden, we excluded this trait sampling and storing parts in the minting function.
    // By virtues of this tweak, we expect the player's gas burden is significantly lowered.
    // Note that, The storing of single digit in the blockchain costs ~= 20,000 gas.

    // Phase2: Rapport System
    for (uint16 i = 0; i < traits_distribution.length; i++) {
      t.traits = traits_distribution[i];
      tokenTraits[virtualTokenId[tokenId]] = t;}
    return t;
  }

  function _selectRecipient(uint256 seed) internal view returns (address) {
    if (minted <= MAX_GEN0_TOKENS || ((seed >> 245) % 10) != 0) {
      return msg.sender; // top 10 bits haven't been used
    }
    address thief = crocodileGame.randomKarmaOwner(seed >> 144);
    if (thief == address(0x0)) {
      return msg.sender;
    }
    return thief;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, ICrocodileGameNFT) {
    if (msg.sender != address(crocodileGame)) {
      require(_isApprovedOrOwner(msg.sender, tokenId), "transfer not owner nor approved");
    }
    _transfer(from, to, tokenId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, virtualTokenId[tokenId].toString())) : "";
  }

  function tokensOf(address owner) external view returns (uint16[] memory) {
    uint32 tokenCount = uint32(balanceOf(owner));
    uint16[] memory tokensId = new uint16[](tokenCount);
    for (uint32 i = 0; i < tokenCount; i++){
      tokensId[i] = uint16(tokenOfOwnerByIndex(owner, i));
    }
    return tokensId;
  }


  function ownerOf(uint256 tokenId) public view override(ERC721, ICrocodileGameNFT) returns (address) {
    return super.ownerOf(tokenId);
  }


  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721, ICrocodileGameNFT) {
    super.safeTransferFrom(from, to, tokenId, _data);
  }

  function setDilemma(uint16 tokenId, uint8 dilemma) public override(ICrocodileGameNFT){
    require(msg.sender == address(crocodileGame), "Not approved address");
    tokenTraits[virtualTokenId[tokenId]].dilemma = dilemma;
  }

  function setKarmaP(uint16 tokenId, uint8 karmaP) public override(ICrocodileGameNFT){
    require(msg.sender == address(crocodileGame), "Not approved address");
    tokenTraits[virtualTokenId[tokenId]].karmaP = karmaP;
  }
  function setKarmaM(uint16 tokenId, uint8 karmaM) public override(ICrocodileGameNFT){
    require(msg.sender == address(crocodileGame), "Not approved address");
    tokenTraits[virtualTokenId[tokenId]].karmaM = karmaM;
  }
  function _baseURI() override internal pure returns (string memory) {
    //TODO change baseURI
    return "https://raw.githubusercontent.com/crocodilegame/crocodilegame/main/tokenuri/";
  }
}