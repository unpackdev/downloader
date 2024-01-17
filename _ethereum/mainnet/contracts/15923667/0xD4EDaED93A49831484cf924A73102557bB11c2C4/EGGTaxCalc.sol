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
import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IRandomizer.sol";
import "./IEGGTaxCalc.sol";

contract EGGTaxCalc is IEGGTaxCalc, Ownable {
  event InitializedContract(address thisContract);

  struct ExtNFTBenefits {
    address contractAddress; // Contract that holds an NFT
    bool isERC1155; // If true use typeId NFT in msg.sender wallet lookup, then apply below tax variables
    // If false assume ERC721 and if >= 1 NFT in msg.sender wallet lookup, then apply below tax variables
    uint256 typeId; // TypeId of token in ERC1155
    uint256 taxChance; // The percentage that a tax rate will be applied 0-100%. 10000 = 100%, 500 = 5%
    uint256 splitTaxRateFrom; // If taxChance is > 0 then this is the split from, this will override the default _splitTaxRateFrom
    uint256 splitTaxRateTo; // If taxChance is > 0 then this is the split to, this will override the default _splitTaxRateTo
  }

  ExtNFTBenefits[] private extNFTBenefits;

  IRandomizer public randomizer; // Reference to Randomizer

  uint256 private _splitTaxRateFrom = 500; // Default Start tax rate to split the tax amount. 500 = 5%
  uint256 private _splitTaxRateTo = 1000; // Default End tax rate to split the tax amount. 1000 = 10%
  uint256 private TAX_CHANCE = 5000; // Default tax chance rate. 5000 = 50%

  mapping(address => bool) private controllers;

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

  constructor(IRandomizer _randomizer) {
    randomizer = _randomizer;
    controllers[_msgSender()] = true;
    emit InitializedContract(address(this));
  }

  /**
   * @notice Return taxRate and taxChance values regarding ExtNFTBenefits logic
   * @param sender Sender address when the tokens transfer
   * returns (taxRate, taxChance)
   */

  function getTaxRate(address sender) external view override returns (uint256, uint256) {
    uint256 taxChance = 1;
    uint256 splitTaxRateFrom = 1;
    uint256 splitTaxRateTo = 1;
    for (uint8 i = 0; i < extNFTBenefits.length; i++) {
      uint256 balance = 0;
      ExtNFTBenefits memory _extNFTBenefit = extNFTBenefits[i];

      if (_extNFTBenefit.isERC1155) {
        balance = IERC1155(_extNFTBenefit.contractAddress).balanceOf(sender, _extNFTBenefit.typeId);
      } else {
        balance = IERC721(_extNFTBenefit.contractAddress).balanceOf(sender);
      }

      if (balance > 0) {
        if ((taxChance == 0 && _extNFTBenefit.taxChance > 0) || taxChance > _extNFTBenefit.taxChance) {
          taxChance = _extNFTBenefit.taxChance;
        }

        if (
          (splitTaxRateFrom == 0 && _extNFTBenefit.splitTaxRateFrom > 0) ||
          splitTaxRateFrom > _extNFTBenefit.splitTaxRateFrom
        ) {
          splitTaxRateFrom = _extNFTBenefit.splitTaxRateFrom;
        }

        if (
          (splitTaxRateTo == 0 && _extNFTBenefit.splitTaxRateTo > 0) || splitTaxRateTo > _extNFTBenefit.splitTaxRateTo
        ) {
          splitTaxRateTo = _extNFTBenefit.splitTaxRateTo;
        }
      }
    }

    if (taxChance == 0) {
      taxChance = TAX_CHANCE;
    }

    if (splitTaxRateFrom == 0) {
      splitTaxRateFrom = _splitTaxRateFrom;
    }

    if (splitTaxRateTo == 0) {
      splitTaxRateTo = _splitTaxRateTo;
    }

    uint256 randomTaxRate = (randomizer.random() % (splitTaxRateTo - (splitTaxRateFrom + 1))) + splitTaxRateFrom;

    return (randomTaxRate, taxChance);
  }

  /**
   * @notice Set the default from percentage number to apply tax amount
   * @dev Only callable by an existing controller
   * @param splitTaxRateFrom Number of the start percentage to split tax
   */

  function setSplitTaxRateFrom(uint256 splitTaxRateFrom) external onlyController {
    _splitTaxRateFrom = splitTaxRateFrom;
  }

  /**
   * @notice Set the default to percentage number to apply tax amount
   * @dev Only callable by an existing controller
   * @param splitTaxRateTo Number of the end percentage to split tax
   */

  function setSplitTaxRateTo(uint256 splitTaxRateTo) external onlyController {
    _splitTaxRateTo = splitTaxRateTo;
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
   * @notice Add new ExtNFTBenefit data for calculating taxChance and taxRate of EGGToken contract
   * @param _contractAddress Contract that holds an NFT
   * @param _isERC1155  If true use typeId NFT in msg.sender wallet lookup, then apply below tax variables
   *                    If false assume ERC721 and if >= 1 NFT in msg.sender wallet lookup, then apply below tax variables
   * @param _taxChance The percentage that a tax rate will be applied 0-100% (10000 = 100%, 100 = 1%)
   * @param splitTaxRateFrom If taxChance is > 0 then this is the split from, this will override the default _splitTaxRateFrom
   * @param splitTaxRateTo If taxChance is > 0 then this is the split to, this will override the default _splitTaxRateTo
   */

  function addExtNFTBenefits(
    address _contractAddress,
    bool _isERC1155,
    uint256 _typeId,
    uint256 _taxChance,
    uint256 splitTaxRateFrom,
    uint256 splitTaxRateTo
  ) external onlyController {
    require(_contractAddress != address(0), "Contract address can't be zero.");
    extNFTBenefits.push(
      ExtNFTBenefits(_contractAddress, _isERC1155, _typeId, _taxChance, splitTaxRateFrom, splitTaxRateTo)
    );
  }

  /**
   * @notice Get ExtNFTBenefits data regarding id
   */

  function getExtNFTBenefits(uint8 id) external view returns (ExtNFTBenefits memory) {
    require(id < extNFTBenefits.length, "ExtNFTBenefits data doesn't exist.");
    return extNFTBenefits[id];
  }

  /**
   * @notice Update new ExtNFTBenefit data for calculating taxChance and taxRate of EGGToken contract regarding id
   * @param _contractAddress Contract that holds an NFT
   * @param _isERC1155  If true use typeId NFT in msg.sender wallet lookup, then apply below tax variables
   *                    If false assume ERC721 and if >= 1 NFT in msg.sender wallet lookup, then apply below tax variables
   * @param _taxChance The percentage that a tax rate will be applied 0-100%
   * @param splitTaxRateFrom If taxChance is > 0 then this is the split from, this will override the default _splitTaxRateFrom
   * @param splitTaxRateTo If taxChance is > 0 then this is the split to, this will override the default _splitTaxRateTo
   */

  function updateExtNFTBenefits(
    uint8 id,
    address _contractAddress,
    bool _isERC1155,
    uint256 _typeId,
    uint256 _taxChance,
    uint256 splitTaxRateFrom,
    uint256 splitTaxRateTo
  ) external onlyController {
    require(id < extNFTBenefits.length, "ExtNFTBenefits data doesn't exist.");
    require(_contractAddress != address(0), "Contract address can't be zero.");

    extNFTBenefits[id] = ExtNFTBenefits(
      _contractAddress,
      _isERC1155,
      _typeId,
      _taxChance,
      splitTaxRateFrom,
      splitTaxRateTo
    );
  }

  /**
   * @notice Set contract address
   * @dev Only callable by an existing controller
   * @param _address Address of randomizer contract
   */

  function setRandomizer(address _address) external onlyController {
    randomizer = IRandomizer(_address);
  }

  /**
   * @notice Remove ExtNFTBenefits data regarding id
   */

  function removeExtNFTBenefits(uint8 id) external onlyController {
    require(id < extNFTBenefits.length, "ExtNFTBenefits data doesn't exist.");
    ExtNFTBenefits memory lastExtNFTBenefits = extNFTBenefits[extNFTBenefits.length - 1];
    extNFTBenefits[id] = lastExtNFTBenefits; //  Shuffle last ExtNFTBenefits to current position
    extNFTBenefits.pop();
  }
}
