// SPDX-License-Identifier: MIT

/// @title  ETHTerrestrials by Kye NFT (ERC721) contract
/// @notice A gas-conscious contract for an entirely "on-chain" NFT implementing a custom commit-reveal scheme (see CRSeeder.sol).
/// @dev Tokens are minted to users immediately, metadata seeds are committed at mint and revealed by subsequent mints.
/// @dev Mint gas savings achieved by utilizing a custom commit-reveal scheme and the ERC721A contract (https://github.com/chiru-labs/ERC721A).
/// @dev Images/metadata stored in two separate descriptor contracts

pragma solidity ^0.8.0;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./VRFConsumerBase.sol";
import "./IERC1155.sol";
import "./PaymentSplitter.sol";
import "./CRSeeder.sol";

interface GenesisDescriptor {
   function generateTokenURI(uint256 tokenId) external view returns (string memory);

   function getSvg(uint256 tokenId) external view returns (string memory);
}

interface V2Descriptor {
   function generateTokenURI(
      uint256 tokenId,
      uint256 rawSeed,
      uint256 tokenType
   ) external view returns (string memory);

   function processRawSeed(uint256 rawseed) external view returns (uint8[10] memory);

   function getSvgCustomToken(uint256 tokenId) external view returns (string memory);

   function getSvgFromSeed(uint8[10] memory seed) external view returns (string memory);
}

interface ENS_Registrar {
   function setName(string calldata name) external returns (bytes32);
}

contract EthTerrestrials is ERC721A, CommitRevealSeeder, Ownable, ReentrancyGuard, VRFConsumerBase, PaymentSplitter {
   enum TOKENTYPE {
      GENESIS,
      V2ONEOFONE,
      V2COMMON
   }

   //Addresses
   address public address_genesis_descriptor;
   address public address_v2_descriptor;
   address public address_opensea_token;
   address public authorizedMinter;

   //Interfaces
   GenesisDescriptor genesis_descriptor;
   V2Descriptor v2_descriptor;
   IERC1155 OS_token;

   //Integers
   //Token numbering scheme:
   // 1 - 100 Genesis upgraded tokens
   // 101 - 111 - v2 one of ones
   // 112 - end - v2 common
   uint256 public constant genesisSupply = 100;
   uint256 public constant v2supplyMax = 4169;
   uint256 public constant v2oneOfOneCount = 11;
   uint256 public constant maxMintsPerTransaction = 10;

   uint256 private constant oneOfOneStart = genesisSupply + 1; //101
   uint256 private constant oneOfOneEnd = oneOfOneStart + v2oneOfOneCount - 1; //111
   uint256 private constant publicTokenStart = oneOfOneEnd + 1; //112

   uint256 public constant maxTokens = genesisSupply + v2supplyMax; //4269
   uint256 public v2price = 0.14 ether;

   //Booleans
   bool public _UFOhasArrived; //toggles the public mint
   bool public _mothershipHasArrived; //toggles the ability to upgrade genesis tokens
   bool public _contractsealed; //seals contract from changes

   //Map of OSSS tokenIds to genesis tokenIds (out of 100)
   mapping(uint256 => uint256) public genesisTokenOSSStoNewTokenId;

   //Chainlink Config
   bytes32 internal keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
   uint256 public VRF_randomness;
   uint256 private fee = 2 ether;
   address public VRF_coordinator_address = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
   address public LINK_address = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

   modifier onlyOwnerWhileUnsealed() {
      require(!_contractsealed && msg.sender == owner(), "Not owner or locked");
      _;
   }

   constructor(address[] memory _payees, uint256[] memory _shares)
      public
      ERC721A("ETHTerrestrials", "ETHT")
      PaymentSplitter(_payees, _shares)
      VRFConsumerBase(VRF_coordinator_address, LINK_address)
   {

   }

   /*
    *   .___  ___.  __  .__   __. .___________. __  .__   __.   _______
    *   |   \/   | |  | |  \ |  | |           ||  | |  \ |  |  /  _____|
    *   |  \  /  | |  | |   \|  | `---|  |----`|  | |   \|  | |  |  __
    *   |  |\/|  | |  | |  . `  |     |  |     |  | |  . `  | |  | |_ |
    *   |  |  |  | |  | |  |\   |     |  |     |  | |  |\   | |  |__| |
    *   |__|  |__| |__| |__| \__|     |__|     |__| |__| \__|  \______|
    */

   /// @notice Callback function for upgrading Genesis tokens (on OpenSea shared storefront contract).
   /// @dev Users must transfer genesis tokens to this contract via safeTransferFrom in order to receive an upgrade
   /// @dev Upgraded genesis tokens are permanently locked; no method exists to remove them.
   function onERC1155Received(
      address operator,
      address from,
      uint256 tokenId,
      uint256 value,
      bytes calldata data
   ) public nonReentrant returns (bytes4) {
      require(_mothershipHasArrived, "Mothership has not arrived, too early to beam up!");
      require(msg.sender == address_opensea_token, "Not the correct token contract");
      require(value == 1, "Quantity error");
      beamUp(tokenId);
      //Issue a free v2 mint if still available
      if (totalSupply() < maxTokens) {
         mintInternal(tx.origin, 1);
      }
      return this.onERC1155Received.selector;
   }

   function beamUp(uint256 tokenId) internal {
      uint256 newTokenId = genesisTokenOSSStoNewTokenId[tokenId];
      require(newTokenId != 0, "Not a valid tokenId");
      genesisTokenOSSStoNewTokenId[tokenId] = 0;

      //Issue the replacement token
      IERC721(address(this)).safeTransferFrom(address(this), tx.origin, newTokenId);
   }

   /// @notice Public mint.
   /// @param quantity, the number of tokens to be purchased.
   function abduct(uint256 quantity) external payable nonReentrant {
      require(totalSupply() + quantity <= maxTokens, "Exceeds Supply");
      require(tx.origin == msg.sender, "No contract minters");
      require(_UFOhasArrived, "UFO hasn't arrived, abductions haven't started yet!");
      require(quantity <= maxMintsPerTransaction);
      require(msg.value == v2price * quantity, "Incorrect ETH sent");
      mintInternal(msg.sender, quantity);
   }

   /// @notice Administrative mint. Allows team to add on a separate mint contract if needed, or mint directly to team.
   /// @param quantity, the number of tokens to be purchased.
   /// @param to, the address to mint to
   function mintAdmin(address to, uint256 quantity) external nonReentrant {
      require(totalSupply() + quantity <= maxTokens, "Exceeds Supply");
      require(msg.sender == authorizedMinter, "Unauthorized");
      mintInternal(to, quantity);
   }

   function mintInternal(address to, uint256 quantity) private {
      _commitTokens(_currentIndex); //commit the tokens for a pseudorandom seed
      _safeMint(to, quantity);
   }

   /*
    *   .______       _______     ___       _______
    *   |   _  \     |   ____|   /   \     |       \
    *   |  |_)  |    |  |__     /  ^  \    |  .--.  |
    *   |      /     |   __|   /  /_\  \   |  |  |  |
    *   |  |\  \----.|  |____ /  _____  \  |  '--'  |
    *   | _| `._____||_______/__/     \__\ |_______/
    */

   /// @notice View a token's tokenURI
   /// @param tokenId, the desired tokenId.
   /// @return a JSON string tokenURI
   function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      TOKENTYPE tokenType = checkType(tokenId);

      if (tokenType == TOKENTYPE.GENESIS) return genesis_descriptor.generateTokenURI(tokenId);

      uint256 rawSeed = tokenType == TOKENTYPE.V2ONEOFONE ? 0 : _rawSeedForTokenId(tokenId);

      return v2_descriptor.generateTokenURI(tokenId, rawSeed, uint256(tokenType));
   }

   /// @notice Displays the attribute seed for a given token
   /// @param tokenId, the desired tokenId.
   /// @dev This seed shows the chosen attributes for the given tokenId.
   function getTokenSeed(uint256 tokenId) public view returns (uint8[10] memory) {
      TOKENTYPE tokenType = checkType(tokenId);
      require(tokenType == TOKENTYPE.V2COMMON, "This type of token does not have a pseudorandom seed");

      uint256 rawSeed = _rawSeedForTokenId(tokenId);
      require(rawSeed != 0, "Seed not yet established");
      return v2_descriptor.processRawSeed(rawSeed);
   }

   /// @notice Displays an unencoded SVG image for a given token
   /// @param tokenId, the desired tokenId.
   /// @param background, for v2 common tokens, whether the background should be included. Has no impact on genesis/one-of-one tokens.
   function tokenSVG(uint256 tokenId, bool background) external view returns (string memory) {
      require(_exists(tokenId), "query for nonexistent token");
      TOKENTYPE tokenType = checkType(tokenId);

      if (tokenType == TOKENTYPE.GENESIS) return genesis_descriptor.getSvg(tokenId);
      else if (tokenType == TOKENTYPE.V2ONEOFONE) return v2_descriptor.getSvgCustomToken(tokenId);

      uint8[10] memory seed = getTokenSeed(tokenId);
      if (!background) seed[0] = 0;
      return v2_descriptor.getSvgFromSeed(seed);
   }

   /// @notice Check the type of token, based on tokenid
   /// @param tokenId, the desired tokenId.
   function checkType(uint256 tokenId) public pure returns (TOKENTYPE) {
      if (tokenId <= genesisSupply) return TOKENTYPE.GENESIS;
      else if (tokenId <= oneOfOneEnd) return TOKENTYPE.V2ONEOFONE;
      else return TOKENTYPE.V2COMMON;
   }

   function tokenIdToBlockhashIndex(uint256 tokenId) external view returns (uint16) {
      require(_exists(tokenId), "query for nonexistent token");
      TOKENTYPE tokenType = checkType(tokenId);
      require(tokenType == TOKENTYPE.V2COMMON, "This type of token does not have a pseudorandom seed");
      return _tokenIdToBlockhashIndex(tokenId);
   }

   function rawSeedForTokenId(uint256 tokenId) external view returns (uint256) {
      require(_exists(tokenId), "query for nonexistent token");
      TOKENTYPE tokenType = checkType(tokenId);
      require(tokenType == TOKENTYPE.V2COMMON, "This type of token does not have a pseudorandom seed");
      return _rawSeedForTokenId(tokenId);
   }

   // Required for ERC721A to begin minting at a number other than zero.
   function _startTokenId() internal view override returns (uint256) {
      return 1;
   }


   /*  
  ______  __    __       ___       __  .__   __.  __       __  .__   __.  __  ___ 
 /      ||  |  |  |     /   \     |  | |  \ |  | |  |     |  | |  \ |  | |  |/  / 
|  ,----'|  |__|  |    /  ^  \    |  | |   \|  | |  |     |  | |   \|  | |  '  /  
|  |     |   __   |   /  /_\  \   |  | |  . `  | |  |     |  | |  . `  | |    <   
|  `----.|  |  |  |  /  _____  \  |  | |  |\   | |  `----.|  | |  |\   | |  .  \  
 \______||__|  |__| /__/     \__\ |__| |__| \__| |_______||__| |__| \__| |__|\__\
 */

   /// @notice Initiates a f to Chainlink VRF in order to randomly distribute one of one tokens and set the final commit-reveal seed
   /// @dev The VRF seed cannot be re-requested once set in order to prevent tampering
   function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
      LINK.transferFrom(owner(), address(this), fee);
      require(VRF_randomness == 0, "Cannot request a random number once it has been set");
      require(totalSupply() == maxTokens, "Not sold out");
      return requestRandomness(keyHash, fee);
   }

   /// @notice VRF Callback function
   /// @dev Stores seed for random distribution of one-of-one tokens
   /// @dev Also sets final commit-reveal seed
   function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
      VRF_randomness = randomness;

      _commitFinalBlockHash();
   }

   /// @notice Following receipt of a VRF random seed, determine the recipients and mint one of ones directly to them
   /// @dev Only v2 common tokens are eligible to receive a one-of-one token.
   function distributeOneOfOnes() external onlyOwner {
      require(VRF_randomness != 0, "Random seed not established");
      for (uint256 i; i < v2oneOfOneCount; i++) {
         uint256 recipientToken = (uint256(keccak256(abi.encode(VRF_randomness, i))) % (v2supplyMax - v2oneOfOneCount)) + publicTokenStart;

         address recipient = ownerOf(recipientToken);

         IERC721(address(this)).transferFrom(address(this), recipient, i + oneOfOneStart); //uses transferFrom instead of safeTransferFrom so that a contract recipient doesn't break the function
      }
   }

   /// @notice Modifies the Chainlink configuration if needed
   function changeLinkFee(
      uint256 _fee,
      address _VRF_coordinator_address,
      bytes32 _keyhash
   ) external onlyOwner {
      fee = _fee;
      VRF_coordinator_address = _VRF_coordinator_address;
      keyHash = _keyhash;
   }

   /*
  ______   ____    __    ____ .__   __.  _______ .______      
 /  __  \  \   \  /  \  /   / |  \ |  | |   ____||   _  \     
|  |  |  |  \   \/    \/   /  |   \|  | |  |__   |  |_)  |    
|  |  |  |   \            /   |  . `  | |   __|  |      /     
|  `--'  |    \    /\    /    |  |\   | |  |____ |  |\  \----.
 \______/      \__/  \__/     |__| \__| |_______|| _| `._____|                                                              
*/

   function mintToContract() external onlyOwner {
      // Mints genesis and one-of-one tokens to the contract so that they may be claimed by genesis token holders to be upgraded
      require(totalSupply() == 0);
      _mint(address(this), oneOfOneEnd, "", false);
   }

   /// @notice Set address for external contracts
   function setAddresses(
      address _genesis_descriptor,
      address _v2_descriptor,
      address _os_address,
      address _authorizedMinter
   ) external onlyOwnerWhileUnsealed {
      address_genesis_descriptor = _genesis_descriptor;
      address_v2_descriptor = _v2_descriptor;
      genesis_descriptor = GenesisDescriptor(address_genesis_descriptor);
      v2_descriptor = V2Descriptor(address_v2_descriptor);
      address_opensea_token = _os_address;
      OS_token = IERC1155(address_opensea_token);
      authorizedMinter = _authorizedMinter;
   }

   /// @notice Setup old tokenIds for upgrades
   function setGenesisTokenIds(uint256[] memory _OSSS_id, uint256[] memory _newTokenId) external onlyOwnerWhileUnsealed {
      require(_OSSS_id.length == _newTokenId.length, "Length mismatch");
      for (uint256 i; i < _OSSS_id.length; i++) {
         uint256 genesisId = _OSSS_id[i];
         uint256 newId = _newTokenId[i];
         genesisTokenOSSStoNewTokenId[genesisId] = newId;
      }
   }

   /// @notice Toggles the public mint state
   function togglePublicMint() external onlyOwner {
      _UFOhasArrived = !_UFOhasArrived;
   }

   /// @notice Toggles the ability to upgrade Genesis tokens
   function toggleUpgrade() external onlyOwner {
      _mothershipHasArrived = !_mothershipHasArrived;
   }

   /// @notice Changes the mint price
   function setv2Price(uint256 _price) external onlyOwner {
      v2price = _price;
   }

   /// @notice Seals contract so that owner cannot make changes
   function seal() external onlyOwnerWhileUnsealed {
      _contractsealed = true;
   }

   /// @notice Emergency function in case a genesis or one of one token is inadvertently stuck in the contract
   /// @dev This function remains callable after sealing contract in case of emergency
   function emergencyWithdraw(uint256 tokenId) external onlyOwner {
      IERC721(address(this)).transferFrom(address(this), owner(), tokenId);
   }

   /// @notice Allow the owner contract to set a reverse ENS record
   function setReverseRecord(string calldata _name, address registrar_address) external onlyOwner {
      ENS_Registrar(registrar_address).setName(_name);
   }
}
