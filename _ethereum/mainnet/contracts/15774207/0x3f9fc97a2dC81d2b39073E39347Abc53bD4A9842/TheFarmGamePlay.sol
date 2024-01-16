// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,_@       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at farmhand@thefarm.game
 * Found a broken egg in our contracts? We have a bug bounty program bugs@thefarm.game
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./ERC165Storage.sol";
import "./IEGGToken.sol";
import "./IEggShop.sol";
import "./IFarmAnimals.sol";
import "./IHenHouse.sol";
import "./ITheFarmGameMint.sol";
import "./SafeMath.sol";

contract TheFarmGamePlay is Ownable, ERC165Storage, ReentrancyGuard, Pausable {
  using SafeMath for uint256;

  using Counters for Counters.Counter;

  event Sacrificed(address indexed owner, uint16 indexed tokenId, string indexed kind);
  event EggShopAward(address indexed recipient, uint16 indexed typeId);

  event EggShopBroken(address indexed owner, uint16 indexed typeId);
  event AdvantageUpdated(
    address indexed owner,
    uint16 indexed tokenId,
    string indexed kind,
    uint256 previousAdvantage,
    uint256 newAdvantage
  );
  event InitializedContract(address thisContract);

  // address => can call allowedToCallFunctions
  mapping(address => bool) public controllers;

  // Egg shop type IDs
  uint16 public applePieTypeId = 1;
  uint16 public bronzeEggTypeId = 1;
  uint16 public platinumEggTypeId = 5;
  uint16 public rainbowEggTypeId = 6;
  uint16 public silverEggTypeId = 7;

  // Interfaces
  ITheFarmGameMint public theFarmGameMint;
  IHenHouse public henHouse; // reference to the Hen House for choosing random Coyote thieves
  IEGGToken public eggToken; // reference to $EGG for burning on mint
  IFarmAnimals public farmAnimalsNFT; // reference to NFT collection
  IEggShop public eggShop; // reference to eggShop collection

  /** MODIFIERS */

  /**
   * @dev Modifer to require contract to be set before a transfer can happen
   */

  modifier requireContractsSet() {
    require(
      address(eggToken) != address(0) &&
        address(farmAnimalsNFT) != address(0) &&
        address(henHouse) != address(0) &&
        address(eggShop) != address(0) &&
        address(theFarmGameMint) != address(0),
      'Contracts not set'
    );
    _;
  }

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  /**
   * @dev Modifer to require all Gen 0 tokens to be minted
   */
  modifier onlyAfterGen0() {
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 currentSupply = farmAnimalsNFT.totalSupply();
    require(currentSupply >= gen0Supply, 'All Gen 0 tokens must mint first');
    _;
  }

  /**
   * Instantiates contract
   * Emits InitilizeContracts event to kickstart subgraph
   */
  constructor(
    IEGGToken _eggToken,
    IEggShop _eggShop,
    IFarmAnimals _farmAnimalsNFT,
    IHenHouse _henHouse,
    ITheFarmGameMint _theFarmGameMint
  ) {
    eggToken = _eggToken;
    eggShop = _eggShop;
    farmAnimalsNFT = _farmAnimalsNFT;
    henHouse = _henHouse;
    theFarmGameMint = _theFarmGameMint;
    controllers[_msgSender()] = true;

    _pause();

    emit InitializedContract(address(this));
  }

  /**
   *   ██████   █████  ███    ███ ███████
   *  ██       ██   ██ ████  ████ ██
   *  ██   ███ ███████ ██ ████ ██ █████
   *  ██    ██ ██   ██ ██  ██  ██ ██
   *   ██████  ██   ██ ██      ██ ███████
   * This section has all the game play
   */

  /**
   * @notice Mint Apple Pie EggShop Token with $EGG Mint Price
   * @param qty quantity to mint Apple Pie
   * TODO: PayTrubite duplicates this, also Apple pie price should be the same price of gen x mint
   */

  function bakeApplePies(uint256 eggAmt, uint16 qty) external whenNotPaused onlyAfterGen0 nonReentrant {
    require(tx.origin == _msgSender(), 'Only EOA');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 pieMintCost = theFarmGameMint.mintCostEGG(minted);

    require(eggAmt >= pieMintCost * qty, 'Not enough egg given');
    // $EGG exchange amount handled within eggShop contract
    // Will fail if sender doesn't have enough $EGG
    // Transfer does not need approved,
    // as there is established trust between this contract and the eggShop contract
    eggShop.mint(applePieTypeId, qty, _msgSender(), eggAmt);
  }

  /**
   * @notice Burn Apple Pie EggShop Token with $EGG Burn Price. Caller will be received $EGG token.
   * @param qty quantity to sell Apple Pie
   */

  function burnApplePies(uint16 qty) external onlyAfterGen0 whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), 'Only EOA');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 pieMintCost = theFarmGameMint.mintCostEGG(minted);
    uint256 pieBurnRefund = pieMintCost.div(100).mul(80);
    // $EGG transfer handled within eggShop contract
    eggShop.burn(applePieTypeId, qty, _msgSender(), pieBurnRefund);
  }

  /**
   * @notice Sacrifice caller's NFT with sacrificing $EGG price
   * @param tokenId Token ID to be sacrificed
   */

  function sacrifice(uint16 tokenId) external whenNotPaused nonReentrant {
    require(_msgSender() == farmAnimalsNFT.ownerOf(tokenId), 'TheFarmGame: caller not owner of token');
    require(tx.origin == _msgSender(), 'TheFarmGame: Only EOA');
    uint64 lastTokenWrite = farmAnimalsNFT.getTokenWriteBlock(tokenId);
    require(lastTokenWrite < block.number, 'TheFarmGame: what u doing?');

    IFarmAnimals.Kind kind;
    kind = _getKind(tokenId);

    if (kind == IFarmAnimals.Kind.HEN) {
      // This will check if origin is the owner of the token
      farmAnimalsNFT.burn(tokenId);
      eggShop.mint(rainbowEggTypeId, 1, _msgSender(), uint256(0));
      IEggShop.TypeInfo memory rainbowTypeInfo = eggShop.getInfoForType(rainbowEggTypeId);
      if ((rainbowTypeInfo.mints + rainbowTypeInfo.burns) <= rainbowTypeInfo.maxSupply) {
        eggShop.mint(rainbowEggTypeId, 1, _msgSender(), uint256(0));
        emit EggShopAward(_msgSender(), uint16(rainbowEggTypeId));
      }
      emit Sacrificed(_msgSender(), uint16(tokenId), 'HEN');
    }
  }

  /**
   * @notice Scrabmle some EGG get Silver Egg in return
   */
  function scrambleEGG(uint256 eggAmt) external onlyAfterGen0 whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), 'Only EOA');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 eggMintCost = theFarmGameMint.mintCostEGG(minted);
    require(eggMintCost > 0, 'Need egg to scramble');
    require(eggAmt >= eggMintCost, 'Not enough egg given');
    eggToken.burn(_msgSender(), eggAmt);
    if (eggAmt >= eggMintCost) {
      eggShop.mint(silverEggTypeId, 1, _msgSender(), eggMintCost);
    }
  }

  /**
   * @notice Upgrade the advantage of traits by caller's tokenId
   * @param tokenId the ID of the token to upgrade
   */

  function upgradeAdvantage(uint16 tokenId) external onlyAfterGen0 {
    require(_msgSender() == farmAnimalsNFT.ownerOf(tokenId), 'Caller not owner');
    IFarmAnimals.Kind kind = _getKind(tokenId);
    require(kind == IFarmAnimals.Kind.HEN || kind == IFarmAnimals.Kind.COYOTE, 'Not a Hen or Coyote');
    uint8 _advantage = farmAnimalsNFT.getTokenTraits(tokenId).advantage;
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    if (tokenId > gen0Supply) require(_advantage < 4, 'Hen already at max production');
    else require(_advantage < 5, 'Gen 0 Hen already at max production');
    if (kind == IFarmAnimals.Kind.HEN) {
      uint256 silverEggBalance = eggShop.balanceOf(_msgSender(), silverEggTypeId);
      require(silverEggBalance > 0, 'Not enough Silver Egg');
      eggShop.burn(silverEggTypeId, 1, _msgSender(), uint256(0));
      emit EggShopBroken(_msgSender(), uint16(silverEggTypeId));
      farmAnimalsNFT.updateAdvantage(tokenId, uint8(1), false);
      uint8 _upgradeAdvantage = farmAnimalsNFT.getTokenTraits(tokenId).advantage;
      emit AdvantageUpdated(_msgSender(), uint16(tokenId), 'HEN', _advantage + 5, _upgradeAdvantage + 5);
    } else if (kind == IFarmAnimals.Kind.COYOTE) {
      uint256 rainbowBalance = eggShop.balanceOf(_msgSender(), rainbowEggTypeId);
      require(rainbowBalance > 0, 'Not enough Rainbow Egg');
      eggShop.burn(rainbowEggTypeId, 1, _msgSender(), uint256(0));
      emit EggShopBroken(_msgSender(), uint16(rainbowEggTypeId));
      farmAnimalsNFT.updateAdvantage(tokenId, uint8(1), false);
      uint8 _upgradeAdvantage = farmAnimalsNFT.getTokenTraits(tokenId).advantage;
      emit AdvantageUpdated(_msgSender(), uint16(tokenId), 'COYOTE', _advantage + 5, _upgradeAdvantage + 5);
    } else if (kind == IFarmAnimals.Kind.ROOSTER) {
      uint256 _upgradeCost = upgradeAdvCost(_advantage);
      require(eggToken.balanceOf(_msgSender()) > _upgradeCost * 2, 'Not enough $EGG');
      uint256 rescuedPool = _upgradeCost.mul(30).div(100);
      henHouse.addRescuedEggPool(rescuedPool);
      eggToken.burn(_msgSender(), _upgradeCost);
      farmAnimalsNFT.updateAdvantage(tokenId, uint8(1), false);
      uint8 _upgradeAdvantage = farmAnimalsNFT.getTokenTraits(tokenId).advantage;
      emit AdvantageUpdated(_msgSender(), uint16(tokenId), 'ROOSTER', _advantage + 5, _upgradeAdvantage + 5);
    }
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /**
   * @notice Get token kind (chicken, coyote, rooster)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(uint16 tokenId) internal view returns (IFarmAnimals.Kind) {
    return farmAnimalsNFT.getTokenTraits(tokenId).kind;
  }

  /**
   * @notice Transfer ETH and return the success status.
   * @dev This function only forwards 30,000 gas to the callee.
   * @param to Address for ETH to be send to
   * @param value Amount of ETH to send
   */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
    return success;
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @notice The $EGG mint price to upgrade advantage of nft
   * @param _advantage Current advantage score -5
   */

  function upgradeAdvCost(uint8 _advantage) public pure returns (uint256) {
    if (_advantage == 0) return 20000 ether;
    else if (_advantage == 1) return 30000 ether;
    else if (_advantage == 2) return 50000 ether;
    else if (_advantage == 3) return 80000 ether;
    else if (_advantage == 4) return 130000 ether;
    else return 0 ether;
  }

  /**
   * @notice Get current mint & burn price for Apple pie
   */
  struct PiePrice {
    uint256 pieMintCost;
    uint256 pieBurnRefund;
  }

  function getApplePiePrice() public view returns (PiePrice memory) {
    uint16 minted = farmAnimalsNFT.minted();
    uint256 pieMintCost = theFarmGameMint.mintCostEGG(minted);
    uint256 pieBurnRefund = pieMintCost.div(100).mul(80);
    PiePrice memory piePrice;
    piePrice.pieMintCost = pieMintCost;
    piePrice.pieBurnRefund = pieBurnRefund;
    return piePrice;
  }

  /**
   *   ██████  ██     ██ ███    ██ ███████ ██████
   *  ██    ██ ██     ██ ████   ██ ██      ██   ██
   *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
   *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
   *   ██████   ███ ███  ██   ████ ███████ ██   ██
   * This section will have all the internals set to onlyOwner
   */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyController {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }
}
