//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./Pausable.sol";

interface ICacheGold {
    function totalCirculation() external view returns (uint256);
}

interface IChainLink {
  function latestAnswer() external view returns (int256 answer);
}

/**
* @title LockedGoldOraclePausable
* @dev Read from an external contract - Chainlink Proof Of Reserves and return the information to the CACHE Token Contract
* @dev The read checks if the contract is not paused and 
* @dev the oracle value is always greater than the present circulation. In case either condition fails a ZERO value is returned
* @dev The owner is a multisig deployed by CACHE
*/
contract LockedGoldOraclePausable is Ownable, Pausable {
  
  uint8 public constant DECIMALS = 8;
  // 10^8 shortcut
  uint256 private constant TOKEN = 10 ** uint256(DECIMALS);
  // Cap on total number of tokens that can ever be produced
  uint256 public constant SUPPLY_CAP = 8133525786 * TOKEN;

  address private _cacheContract;
  address private _chainLinkContract;
  event ContractSet(address indexed, string);

  /**
  * @dev Set the CACHE token contract address
  */
  function setCacheContract(address __cacheContract) external onlyOwner {
    _cacheContract = __cacheContract;
    emit ContractSet(__cacheContract, "CACHE");
  }

  /**
  * @dev Set the Chainlink Proof Of Reserves contract address
  */
  function setChainlinkContract(address __chainLinkContract) external onlyOwner {
    _chainLinkContract = __chainLinkContract;
    emit ContractSet(__chainLinkContract, "CHAINLINK");
  }

  /**
  @dev Add pause role for owner, this is implemented as an emergency measure to pause Mint of new tokens.
  */
  function pause() external onlyOwner {
      _pause();
  }

  function unpause() external onlyOwner {
      _unpause();
  }

  /**
  * @dev Requires the Proof of Reserves amount emitted to be lower than token circulation amount emitted by CACHE Token Contract. 
  * @dev Requires that the locked Gold is less than or equal to the total supply cap of the CACHE GOLD Contract. 
  * @dev Requires that the contract is not paused. 
  * @dev CACHE Token Contract Mint return 0/revert message when this function fails above requirements.   
  */
  function lockedGold() external view whenNotPaused() returns(uint256) {
    uint _lockedGold = uint(IChainLink(_chainLinkContract).latestAnswer());
    require(_lockedGold >= ICacheGold(_cacheContract).totalCirculation(), "Insufficent grams locked");
    require(_lockedGold <= SUPPLY_CAP, "Exceeds Supply Cap");
    return _lockedGold;
  }

  function cacheContract() external view returns(address) {
    return _cacheContract;
  }
  
  function chainlinkContract() external view returns(address) {
    return _chainLinkContract;
  }
}