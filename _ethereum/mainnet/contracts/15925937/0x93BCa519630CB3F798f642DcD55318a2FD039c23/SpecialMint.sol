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

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IEggShop.sol";
import "./IEGGToken.sol";
import "./IFarmAnimals.sol";
import "./IHenHouseAdvantage.sol";
import "./IRandomizer.sol";
import "./IImperialEggs.sol";
import "./ISpecialMint.sol";
import "./ITheFarmGameMint.sol";

contract SpecialMint is Ownable, ISpecialMint, ReentrancyGuard, Pausable {
  // Events
  event Add(uint256 indexed typeId, uint256 maxSupply, uint256 mintFee);
  event Update(uint256 indexed typeId, uint256 maxSupply, uint256 mintFee);
  event MintedSpecial(address indexed owner, uint256 indexed typeId);
  event InitializedContract(address thisContract);

  // address => can call allowedToCallFunctions
  mapping(address => bool) private controllers;
  struct SpecialMints {
    uint256 typeId;
    uint256[] eggShopTypeIds;
    uint16[] eggShopTypeQtys;
    uint16[] farmAnimalTypeIds;
    uint16[] farmAnimalTypeQtys;
    uint256 imperialEggQtys;
    uint256 bonusEGGDuration;
    uint16 bonusEGGPercentage;
    uint256 bonusEGGAmount;
    uint256 specialMintFee;
    uint256 maxSupply;
    uint256 minted;
  }

  SpecialMints[] public specialMints;

  // Interfaces
  IEggShop public eggShop; // ref to eggShop collection
  IEGGToken public eggToken; // ref of egg token
  IFarmAnimals public farmAnimalsNFT; // ref to FarmAnimals collection
  IHenHouseAdvantage public henHouseAdvantage; // ref to the Hen House for choosing random Coyote thieves
  IImperialEggs public imperialEggs; // ref to Imperial Eggs collection
  ITheFarmGameMint public theFarmGameMint; // ref to TheFarmGameMint contract
  IRandomizer public randomizer; // ref to randomizer

  /** MODIFIERS */

  /**
   * @dev Modifer to require contract to be set before a transfer can happen
   */

  modifier requireContractsSet() {
    require(
      address(farmAnimalsNFT) != address(0) &&
        address(henHouseAdvantage) != address(0) &&
        address(eggShop) != address(0) &&
        address(theFarmGameMint) != address(0) &&
        address(randomizer) != address(0),
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
   * Instantiates contract
   * Emits InitilizeContracts event to kickstart subgraph
   */

  constructor(
    IEGGToken _eggToken,
    IEggShop _eggShop,
    IFarmAnimals _farmAnimalsNFT,
    IHenHouseAdvantage _henHouseAdvantage,
    IRandomizer _randomizer,
    IImperialEggs _imperialEggs
  ) {
    eggToken = _eggToken;
    eggShop = _eggShop;
    farmAnimalsNFT = _farmAnimalsNFT;
    henHouseAdvantage = _henHouseAdvantage;
    randomizer = _randomizer;
    imperialEggs = _imperialEggs;
    controllers[_msgSender()] = true;
    _pause();
    emit InitializedContract(address(this));
  }

  /**
   *  ███    ███ ██ ███    ██ ████████
   *  ████  ████ ██ ████   ██    ██
   *  ██ ████ ██ ██ ██ ██  ██    ██
   *  ██  ██  ██ ██ ██  ██ ██    ██
   *  ██      ██ ██ ██   ████    ██
   * This section has everything to do with Character minting and burning
   */

  /**
   * @notice mint function for the special mint
   * @param _typeId typeId for the special mint reward
   * @param _recipient address to recieve mints
   */

  function mint(uint256 _typeId, address _recipient) external payable whenNotPaused nonReentrant {
    require(theFarmGameMint.canMint() && theFarmGameMint.allowListTime() <= block.timestamp, 'TFG Mint not miting');
    _mint(_typeId, _recipient);
  }

  /**
   * @notice mint function for the special mint
   * @dev internal function
   * @param _typeId typeId for the special mint reward
   * @param _recipient address to recieve mints
   */

  function _mint(uint256 _typeId, address _recipient) internal {
    uint256 typeId = _typeId - 1;

    SpecialMints memory _specialMint = specialMints[typeId];

    require(typeId < specialMints.length, "SpecialMint TypeId doesn't exist");
    if (!controllers[_msgSender()]) {
      require(msg.value >= _specialMint.specialMintFee, 'Payment is not enough');
    }
    require(_specialMint.maxSupply > _specialMint.minted, 'Max supply exceed');
    for (uint8 i = 0; i < _specialMint.eggShopTypeIds.length; i++) {
      IEggShop.TypeInfo memory eggShopInfo = eggShop.getInfoForType(_specialMint.eggShopTypeIds[i]);
      if ((eggShopInfo.mints + eggShopInfo.burns) < eggShopInfo.maxSupply) {
        eggShop.mint(_specialMint.eggShopTypeIds[i], _specialMint.eggShopTypeQtys[i], _recipient, uint256(0));
      }
    }
    uint256 minted = farmAnimalsNFT.minted();

    for (uint8 j = 0; j < _specialMint.farmAnimalTypeIds.length; j++) {
      uint256 seed = randomizer.randomToken(minted);

      if (_specialMint.farmAnimalTypeIds[j] == 4) {
        // mint twin hens
        farmAnimalsNFT.mintTwins(seed, _recipient, _recipient);
        // farmAnimalsNFT.specialMint(recipient, seed, 0, true, _specialMint.farmAnimalTypeQtys[j]);

        if (_specialMint.bonusEGGDuration > 0 && _specialMint.bonusEGGPercentage > 0) {
          henHouseAdvantage.addAdvantageBonus(
            minted + 1,
            _specialMint.bonusEGGDuration,
            _specialMint.bonusEGGPercentage
          );
          henHouseAdvantage.addAdvantageBonus(
            minted + 2,
            _specialMint.bonusEGGDuration,
            _specialMint.bonusEGGPercentage
          );
          minted += 2;
        }
      } else if (_specialMint.farmAnimalTypeIds[j] == 5) {
        // special random
        uint256 mintChance = seed % 100;

        // default mint hen
        uint16 mintType = 0;

        if (mintChance < 30) {
          // mint rooster
          mintType = 2;
        } else if (mintChance < 70) {
          // mint coyote
          mintType = 1;
        }
        minted++;
        farmAnimalsNFT.specialMint(_recipient, seed, mintType, false, _specialMint.farmAnimalTypeQtys[j]);
        if (_specialMint.bonusEGGDuration > 0 && _specialMint.bonusEGGPercentage > 0 && mintType == 0) {
          uint256 tokenId = minted;
          for (uint8 a = 0; a < _specialMint.farmAnimalTypeQtys[j]; a++) {
            henHouseAdvantage.addAdvantageBonus(
              tokenId,
              _specialMint.bonusEGGDuration,
              _specialMint.bonusEGGPercentage
            );
            tokenId++;
          }
        }
      } else {
        minted++;
        farmAnimalsNFT.specialMint(
          _recipient,
          seed,
          _specialMint.farmAnimalTypeIds[j],
          false,
          _specialMint.farmAnimalTypeQtys[j]
        );
        if (
          _specialMint.bonusEGGDuration > 0 &&
          _specialMint.bonusEGGPercentage > 0 &&
          _specialMint.farmAnimalTypeIds[j] == 0
        ) {
          uint256 tokenId = minted;
          for (uint8 a = 0; a < _specialMint.farmAnimalTypeQtys[j]; a++) {
            henHouseAdvantage.addAdvantageBonus(
              tokenId,
              _specialMint.bonusEGGDuration,
              _specialMint.bonusEGGPercentage
            );
            tokenId++;
          }
        }
      }
    }

    if (_specialMint.imperialEggQtys > 0) {
      imperialEggs.mint(_recipient, _specialMint.imperialEggQtys);
    }

    if (_specialMint.bonusEGGAmount > 0) {
      eggToken.mint(_recipient, _specialMint.bonusEGGAmount * 10**18);
    }

    specialMints[typeId] = SpecialMints(
      _specialMint.typeId,
      _specialMint.eggShopTypeIds,
      _specialMint.eggShopTypeQtys,
      _specialMint.farmAnimalTypeIds,
      _specialMint.farmAnimalTypeQtys,
      _specialMint.imperialEggQtys,
      _specialMint.bonusEGGDuration,
      _specialMint.bonusEGGPercentage,
      _specialMint.bonusEGGAmount,
      _specialMint.specialMintFee,
      _specialMint.maxSupply,
      ++_specialMint.minted
    );
    emit MintedSpecial(_recipient, _typeId);
  }

  /**
   * @notice mint function for the special mint
   * @dev only Owner can mint this
   * @param _typeId typeId for the special mint reward
   * @param _recipient address to recieve mints
   */

  function mintFree(uint256 _typeId, address _recipient) external onlyOwner {
    _mint(_typeId, _recipient);
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
   * @notice Get the Special Mint Info Data regarding typeId
   * @param _typeId The type id to get the Special Mint Info Data
   */

  function getSpecialMintInfo(uint256 _typeId) public view returns (SpecialMints memory) {
    uint256 typeId = _typeId - 1;
    return specialMints[typeId];
  }

  /**
   * @notice Get the count of number Special Mint types
   */

  function getSpecialMintCount() external view returns (uint256) {
    return specialMints.length;
  }

  /**
   * @notice get the speical mint nft count to reserve
   */

  function getSpecialMintReserve() public view override returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < specialMints.length; i++) {
      SpecialMints memory _specialMint = specialMints[i];
      uint256 mintQty = 0;
      if (_specialMint.minted < _specialMint.minted) {
        for (uint256 j = 0; j < _specialMint.farmAnimalTypeQtys.length; j++) {
          if (_specialMint.farmAnimalTypeIds[j] == 4) {
            // twin hens
            mintQty += _specialMint.farmAnimalTypeQtys[j] + 1;
          } else {
            mintQty += _specialMint.farmAnimalTypeQtys[j];
          }
        }
      }
      total += (_specialMint.maxSupply - _specialMint.minted) * mintQty;
    }
    return total;
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
   * @notice Allows owner to withdraw ETH funds to an address
   * @dev wraps _user in payable to fix address -> address payable
   * @param to Address for ETH to be send to
   */
  function withdraw(address payable to) public onlyOwner {
    uint256 amount = address(this).balance;
    require(_safeTransferETH(to, amount));
  }

  /**
   * @notice Allows owner to withdraw any accident tokens transferred to contract
   * @param _tokenContract Address for the token
   * @param to Address for token to be send to
   * @param amount Amount of token to send
   */
  function withdrawToken(
    address _tokenContract,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);
    tokenContract.transfer(to, amount);
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Set multiple contract addresses
   * @dev Only callable by an existing controller
   * @param _eggShop Address of eggShop contract
   * @param _eggToken Address of eggToken contract
   * @param _farmAnimalsNFT Address of farmAnimals contract
   * @param _imperialEggs Address of imperialEggs contract
   * @param _theFarmGameMint Address of theFarmGameMint contract
   * @param _randomizer Address of randomizer contract
   */

  function setExtContracts(
    address _eggShop,
    address _eggToken,
    address _farmAnimalsNFT,
    address _imperialEggs,
    address _theFarmGameMint,
    address _randomizer
  ) external onlyController {
    eggShop = IEggShop(_eggShop);
    eggToken = IEGGToken(_eggToken);
    farmAnimalsNFT = IFarmAnimals(_farmAnimalsNFT);
    imperialEggs = IImperialEggs(_imperialEggs);
    theFarmGameMint = ITheFarmGameMint(_theFarmGameMint);
    randomizer = IRandomizer(_randomizer);
  }

  /**
   * @notice Set the FarmGameMint contract address
   * @dev Only callable by the owner
   * @param _address Address of FarmGameMint contract
   */
  function setFarmGameMint(address _address) external onlyController {
    theFarmGameMint = ITheFarmGameMint(_address);
  }

  /**
   * @notice Enables owner to pause / unpause contract
   * @dev Only callable by an existing controller
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
   * @dev Only callable by an existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by an existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice add the special reward info regarding the special mint typeId
   * @dev Only callable by an existing controller
   * @param _typeId typeId of specialMint info
   * @param _eggShopTypeIds the array of eggShop typeIds to mint eggShop eggs
   * @param _eggShopTypeQtys the array of quantity to mint eggShop eggs
   * @param _farmAnimalTypeIds the array of farmAnimals special mint typeIds (0 => hen, 1 => coyote, 2 => rooster, 3 => random, 4 => twin hens, 5 special random)
   * @param _farmAnimalTypeQtys the array of farmAnimals special mint quantities
   * @param _imperialEggsQtys the count to mint Imperial Eggs
   * @param _bonusEGGDuration the duration of EGG bonus production in mins
   * @param _bonusEGGPercentage the percentage of EGG bonus production
   * @param _bonusEGGAmount the amount to mint EGG token directly
   * @param _specialMintFee the price of special mint reward
   * @param _maxSupply the max supply of special mint reward by specialTokenId
   */

  function addSpecialMint(
    uint256 _typeId,
    uint256[] memory _eggShopTypeIds,
    uint16[] memory _eggShopTypeQtys,
    uint16[] memory _farmAnimalTypeIds,
    uint16[] memory _farmAnimalTypeQtys,
    uint256 _imperialEggsQtys,
    uint256 _bonusEGGDuration,
    uint16 _bonusEGGPercentage,
    uint256 _bonusEGGAmount,
    uint256 _specialMintFee,
    uint256 _maxSupply
  ) external onlyController {
    require(_eggShopTypeIds.length == _eggShopTypeQtys.length, 'SpecialInfo length is not equal');
    require(_farmAnimalTypeIds.length == _farmAnimalTypeQtys.length, 'SpecialInfo length is not equal');
    require(_maxSupply > 0, 'Max Supply should be greater than zero');
    require(_specialMintFee > 0, 'Special Mint Reward price should be greater than zero');
    specialMints.push(
      SpecialMints(
        _typeId,
        _eggShopTypeIds,
        _eggShopTypeQtys,
        _farmAnimalTypeIds,
        _farmAnimalTypeQtys,
        _imperialEggsQtys,
        _bonusEGGDuration,
        _bonusEGGPercentage,
        _bonusEGGAmount,
        _specialMintFee,
        _maxSupply,
        0
      )
    );
    emit Add(_typeId, _maxSupply, _specialMintFee);
  }

  /**
   * @notice update the special reward info regarding the special mint typeId
   * @dev Only callable by an existing controller
   * @param _typeId typeId of specialMint info
   * @param _eggShopTypeIds the array of eggShop typeIds to mint eggShop eggs
   * @param _eggShopTypeQtys the array of quantity to mint eggShop eggs
   * @param _farmAnimalTypeIds the array of farmAnimals special mint typeIds (0 => hen, 1 => coyote, 2 => rooster, 3 => random, 4 => twin hens, 5 special random)
   * @param _farmAnimalTypeQtys the array of farmAnimals special mint quantities
   * @param _imperialEggsQtys the count to mint Imperial Eggs
   * @param _bonusEGGDuration the duration of EGG bonus production in mins
   * @param _bonusEGGPercentage the percentage of EGG bonus production
   * @param _bonusEGGAmount the amount to mint EGG token directly
   * @param _specialMintFee the price of special mint reward
   * @param _maxSupply the max supply of special mint reward by specialTokenId
   */

  function updateSpecialMint(
    uint256 _typeId,
    uint256[] memory _eggShopTypeIds,
    uint16[] memory _eggShopTypeQtys,
    uint16[] memory _farmAnimalTypeIds,
    uint16[] memory _farmAnimalTypeQtys,
    uint256 _imperialEggsQtys,
    uint256 _bonusEGGDuration,
    uint16 _bonusEGGPercentage,
    uint256 _bonusEGGAmount,
    uint256 _specialMintFee,
    uint256 _maxSupply
  ) external onlyController {
    require(_typeId < specialMints.length, "Special Mint Reward TypeId doesn't exist");
    require(_eggShopTypeIds.length == _eggShopTypeQtys.length, 'SpecialInfo length is not equal');
    require(_farmAnimalTypeIds.length == _farmAnimalTypeQtys.length, 'SpecialInfo length is not equal');
    require(_maxSupply > 0, 'Max Supply should be greater than zero');
    require(_specialMintFee > 0, 'Special Mint Reward price should be greater than zero');

    uint256 typeId = _typeId - 1;

    SpecialMints memory _specialMint = specialMints[typeId];
    specialMints[typeId] = SpecialMints(
      _typeId,
      _eggShopTypeIds,
      _eggShopTypeQtys,
      _farmAnimalTypeIds,
      _farmAnimalTypeQtys,
      _imperialEggsQtys,
      _bonusEGGDuration,
      _bonusEGGPercentage,
      _bonusEGGAmount,
      _specialMintFee,
      _maxSupply,
      _specialMint.minted
    );
    emit Update(_typeId, _maxSupply, _specialMintFee);
  }
}
