// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/RandomlyAllocated/RandomlyAllocated.sol)
// https://omnuslab.com/randomallocation

// RandomlyAllocated (Allocate the items in a fixed length collection, calling IceRing to randomly assign each ID.

pragma solidity ^0.8.13;

/**
*
* @dev RandomlyAllocated
*
* This contract extension allows the selection of items from a finite collection, each selection using the IceRing
* entropy source and removing the assigned item from selection. Intended for use with random token mints etc.
*
*/

import "./Context.sol";  
import "./IceRing.sol";

/**
*
* @dev Contract module which allows children to randomly allocated items from a decaying array.
* You must pass in:
* 1) The length of the collection you wish to select from (e.g. 1,000)
* 2) The IceRing contract address for this chain.
* 3) The ERC20Payable contract acting as relay.
* 
* The contract will pass back the item from the array that has been selected and remove that item from the array,
* hence you have a decaying list of items to select from.
*
*/

abstract contract RandomlyAllocated is Context, IceRing {

  // The parent array holds an index addressing each of the underlying 32 entry uint8 children arrays. The number of each
  // entry in the parentArray denotes how many times 32 we elevate the number in the child array when it is selected, with 
  // each child array running from 0 to 32 (one slot). For example, if we have parentArray 4 then every number in childArray
  // 4 is elevated by 4*32, position 0 in childArray 4 therefore representing number 128 (4 * 32 + 0)
  uint16[] public parentArray; 
  // Mapping of parentArray to childArray:
  mapping (uint16 => uint8[]) childArray;

  uint256 public continueLoadFromArray;
  
  uint256 public immutable entropyMode;
  
  // In theory this approach could handle a collection of 2,097,120 items. But as that would required 65,535 parentArray entries
  // we would need to load these items in batches. Set a notional parent array max size of 1,600 items, which gives a collection
  // max size of 51,200 (1,600 * 32):
  uint256 private constant COLLECTION_LIMIT = 51200; 
  // Each child array holds 32 items (1 slot wide):
  uint256 private constant CHILD_ARRAY_WIDTH = 32;
  // Max number of child arrays that can be loaded in one block
  uint16 private constant LOAD_LIMIT = 125;
  // Save a small amount of gas by holding these values as constants:
  uint256 private constant EXPONENT_18 = 10 ** 18;
  uint256 private constant EXPONENT_36 = 10 ** 36;

  /**
  *
  * @dev must be passed supply details, ERC20 payable contract and ice contract addresses, as well as entropy mode and fee (if any)
  *
  */
  constructor(uint16 supply_, address ERC20SpendableContract_, address iceContract_, uint256 entropyMode_, uint256 ethFee_, uint256 oatFee_)
    IceRing(ERC20SpendableContract_, iceContract_, ethFee_, oatFee_) {
    
    require(supply_ < (COLLECTION_LIMIT + 1),"Max supply of 51,200");

    entropyMode = entropyMode_;

    uint256 numberOfParentEntries = supply_ / CHILD_ARRAY_WIDTH;

    uint256 finalChildWidth = supply_ % CHILD_ARRAY_WIDTH;

    // If the supply didn't divide perfectly by the child width we have a remainder child at the end. We will load this now
    // so that all subsequent child loads can safely assume a full width load:
    if (finalChildWidth != 0) {

      // Set the final child array now:
      // Exclude 98 (yellow bird) as that is available for free at yellowbird.ethertree.org:
      childArray[uint16(numberOfParentEntries)] = [0,1,3];

      // Add one to the numberOfParentEntries to include the finalChild (as this will have been truncated off the calc above):
      numberOfParentEntries += 1;

    }

    // Now load the parent array:
    for(uint256 i = 0; i < numberOfParentEntries;) {
      parentArray.push(uint16(i));
      unchecked{ i++; }
    }

    // Load complete, all set up and ready to go.
  }

  /**
  *
  * @dev View total remaining items left in the array
  *
  */
  function remainingParentItems() external view returns(uint256) {
    return(parentArray.length);
  }

  /**
  *
  * @dev View parent array
  *
  */
  function parentItemsArray() external view returns(uint16[] memory) {
    return(parentArray);
  }

  /**
  *
  * @dev View items array
  *
  */
  function childItemsArray(uint16 index_) external view returns(uint8[] memory) {
    return(childArray[index_]);
  }

  /**
  *
  * @dev View total remaining IDs
  *
  */
  function countOfRemainingIds() external view returns(uint256 totalRemainingIds) {
        
    for (uint16 i = 0; i < parentArray.length; i++) {
      // A child array with a length of 0 means that this entry in the parent array has yet to 
      // have the child array created. If the child array was fully depleted to 0 Ids the parent
      // array will have been deleted. Therefore a parent array with no corresponding child array
      // needs to increase the total count by the full 32 items that will be loaded into the child
      // array when it is instantiate.
      if (childArray[i].length == 0) {
        totalRemainingIds += 32;
      }
      else {
        totalRemainingIds += uint256(childArray[i].length);
      }
    }
          
    return(totalRemainingIds);
  }

  /**
  *
  * @dev Allocate item from array:
  *
  */
  function _getItem(uint256 accessMode_) internal returns(uint256 allocatedItem_) { //mode: 0 = light, 1 = standard, 2 = heavy
    
    require(parentArray.length != 0, "ID allocation exhausted");

    // Retrieve a uint256 of entropy from IceRing. We will use separate parts of this entropy uint for number in range
    // calcs for array selection:
    uint256 entropy = _getEntropy(accessMode_);

    // First select the entry from the parent array, using the left most 18 entropy digits:
    uint16 parentIndex = uint16(((entropy % EXPONENT_18) * parentArray.length) / EXPONENT_18);

    uint16 parent = parentArray[parentIndex];

    // Check if we need to load the child (we will the first time it is accessed):
    if (childArray[parent].length == 0) {
      // Exclude blueberrybird5:
      if (parent == 0) {
        childArray[parent] = [0,1,2,3,4,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];  
      }
      else {
        childArray[parent] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];
      }  
    }

    // Select the item from the child array, using the a different 18 entropy digits, and add on the elevation factor from the parent:
    uint256 childIndex = (((entropy % EXPONENT_36) / EXPONENT_18) * childArray[parent].length) / EXPONENT_18;
    
    allocatedItem_ = uint256(childArray[parent][childIndex]) + (parent * CHILD_ARRAY_WIDTH);

    // Pop this item from the child array. First set the last item index:
    uint256 lastChildIndex = childArray[parent].length - 1;

    // When the item to remove from the array is the last item, the swap operation is unnecessary
    if (childIndex != lastChildIndex) {
      childArray[parent][childIndex] = childArray[parent][lastChildIndex];
    }

    // Remove the last position of the array:
    childArray[parent].pop();

    // Check if the childArray is no more:
    if (childArray[parent].length == 0) {
      // Remove the parent as the child allocation is exhausted. First set the last index:
      uint256 lastParentIndex = parentArray.length - 1;

      // When the item to remove from the array is the last item, the swap operation is unnecessary
      if (parentIndex != lastParentIndex) {
        parentArray[parentIndex] = parentArray[lastParentIndex];
      }

      parentArray.pop();

    }

    return(allocatedItem_);
  }

  /**
  *
  * @dev Retrieve Entropy
  *
  */
  function _getEntropy(uint256 accessMode_) internal returns(uint256 entropy_) { 
    
    // Access mode of 0 is direct access, ETH payment may be required:
    if (accessMode_ == 0) { 
      if (entropyMode == 0) entropy_ = (_getEntropyETH(ENTROPY_LIGHT));
      else if (entropyMode == 1) entropy_ = (_getEntropyETH(ENTROPY_STANDARD));
      else if (entropyMode == 2) entropy_ = (_getEntropyETH(ENTROPY_HEAVY));
      else revert("Unrecognised entropy mode");
    }
    // Access mode of 0 is token relayed access, OAT payment may be required:
    else {
      if (entropyMode == 0) entropy_ = (_getEntropyOAT(ENTROPY_LIGHT));
      else if (entropyMode == 1) entropy_ = (_getEntropyOAT(ENTROPY_STANDARD));
      else if (entropyMode == 2) entropy_ = (_getEntropyOAT(ENTROPY_HEAVY));
      else revert("Unrecognised entropy mode");
    }

    return(entropy_);

  }

  /**
  *
  * @dev _loadChildren: Optional function that can be used to pre-load child arrays. This can be used to shift gas costs out of
  * execution by pre-loading some or all of the child arrays.
  *
  */
  function _loadChildren() internal {

    require(continueLoadFromArray < parentArray.length, "Load Children: load already complete");
        
    // Determine how many arrays we will be checking and loading on this call:
    uint256 loadUntil;

    // Example: Parent array length is 300 (index 0 to 299). On the first call to this function
    // the storage var continueLoadFromArray will be 0. Therefore the statement below will be
    // if (300 - 0) > 125, which it is. We therefore set loadUntil to 0 + 125 (the load limit)
    // which is 125.
    // On the second call to this function continueLoadFromArray will be 125 (we set it to the loadUntil
    // value at the end of this function). (300 - 125) is 175, so still greater than the load limit of 125.
    // We therefore set loadUntil to 125 + 125 = 250.
    // On the third call to this function continueLoadFromArray will be 250. (300 - 250) = 50, which is less 
    // that our load limit. We therefore set loadUntil to the length of the parent array, which is 300. Note
    // that when processing the parent array items we terminate the look when i < loadUntil, meaning that in 
    // are example we will load index 0 all the way to 299, which is as it should be.
    if ((parentArray.length - continueLoadFromArray) > LOAD_LIMIT) {
      loadUntil = continueLoadFromArray + LOAD_LIMIT;
    }
    else {
      loadUntil = parentArray.length;
    }

    for(uint256 i = continueLoadFromArray; i < loadUntil;) {
      if (childArray[uint16(i)].length == 0) {
        childArray[uint16(i)] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];
      }
      unchecked{ i++; }
    }

    continueLoadFromArray = loadUntil;

  }

}