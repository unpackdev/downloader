// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/entropy/Ice.sol)
// https://omnuslab.com/icering

// ICE (In Chain Entropy)

pragma solidity ^0.8.13;

/**
* @dev ICE - In-Chain Entropy
*
* This protocol generates in-chain entropy (OK, ON-chain not IN-chain, but that didn't make a cool acronym...).
* Solidity and blockchains are deterministic, so standard warnings apply, this produces pseudorandomness. For very strict levels of 
* randomness the answer remains to go off-chain, but that carries a cost and also introduces an off-chain dependency that could fail or,
* worse, some day be tampered with or become vulnerable. 
* 
* The core premise of this protocol is that we aren't chasing true random (does that even exist? Philosophers?). What we are chasing 
* is a source or sources of entropy that are unpredictable in that they can't practically be controlled or predicted by a single entity.
*
* A key source of entropy in this protocol is contract balances, namely the balances of contracts that change with every block. Think large 
* value wallets, like exchange wallets. We store a list of these contract addresses and every request combine the eth value of these addresses
* with the current block time and a modulo and hash it. 
* 
* Block.timestamp has been used as entropy before, but it has a significant drawback in that it can be controlled by miners. If the incentive is
* high enough a miner could look to control the outcome by controlling the timestamp. 
* 
* When we add into this a variable contract balance we require a single entity be able to control both the block.timestamp and, for example, the 
* eth balance of a binance hot wallet. In the same block. To make it even harder, we loop through our available entropy sources, so the one that
* a transaction uses depends on where in the order we are, which depends on any other txns using this protocol before it. So to be sure of the 
* outcome an entity needs to control the block.timestamp, either control other txns using this in the block or make sure it's the first txn in 
* the block, control the balance of another parties wallet than changes with every block, then be able to hash those known variables to see if the
* outcome is a positive one for them. Whether any entity could achieve that is debatable, but you would imagine that if it is possible it 
* would come at significant cost.
*
* The protocol can be used in two ways: to return a full uin256 of entropy or a number within a given range. Each of these can be called in light,
* standard or heavy mode:
*   Light    - uses the balance of the last contract loaded into the entropy list for every generation. This reduces storage reads
*              at the disadvantage of reducing the variability of the seed.
*   Standard - increments through our list of sources using a different one as the seed each time, returning to the first item at the end of the 
*              loop and so on.
*   Heavy    - creates a hash of hashes using ALL of the entropy seed sources. In principle this would require a single entity to control both
*              the block timestamp and the precise balances of a range of addresses within that block. 
*
*                                                             D I S C L A I M E R
*                                                             ===================    
*                   Use at your own risk, obvs. I've tried hard to make this good quality entropy, but whether random exists is
*                   a question for philosophers not solidity devs. If there is a lot at stake on whatever it is you are doing 
*                   please DYOR on what option is best for you. No liability is accepted etc.
*/

import "./Ownable.sol";  
import "./SafeERC20.sol";
import "./IIce.sol";  
import "./OmStorage.sol"; 
import "./ERC20SpendableReceiver.sol"; 

contract Ice is Ownable, OmStorage, ERC20SpendableReceiver, IIce {
  using SafeERC20 for IERC20;
  
  uint256 constant NUMBER_IN_RANGE_LIGHT = 0;
  uint256 constant NUMBER_IN_RANGE_STANDARD = 1;
  uint256 constant NUMBER_IN_RANGE_HEAVY = 2;
  uint256 constant ENTROPY_LIGHT = 3;
  uint256 constant ENTROPY_STANDARD = 4;
  uint256 constant ENTROPY_HEAVY = 5;

  address public treasury;
  /**
  *
  * @dev entropyItem mapping holds the list of addresses for the contract balances we use as entropy seeds:
  *
  */
  mapping (uint256 => address) entropyItem;

  /**
  *
  * @dev Constructor must be passed the address for the ERC20 that is the designated spendable item for this protocol. Access
  * to the protocol is relayed via the spendable ERC20 even if there is no fee for use:
  * 
  * This contract makes use of OmStorage to greatly reduce storage costs, both read and write. A single uint256 is used as a
  * 'bitmap' for underlying config values, meaning a single read and write is required in all cases. For more details see
  * contracts/storage/OmStorage.sol.
  *
  */
  constructor(address _ERC20Spendable)
    ERC20SpendableReceiver(_ERC20Spendable)
    OmStorage(2, 2, 8, 49, 10, 2, 2, 0, 0, 0, 0, 0) {
    encodeNus(0, 0, 10000000, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  }

  /**
  *
  * @dev Standard entry point for all calls relayed via the payable ERC20. 
  *
  */
  function receiveSpendableERC20(address, uint256 _tokenPaid, uint256[] memory _arguments) override external onlyERC20Spendable(msg.sender) returns(bool, uint256[] memory) { 
    
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    uint256 oatFee = feeBase * (10 ** oatExponent);

    if (oatFee != 0) {
      require(_tokenPaid == oatFee, "Incorrect ERC20 payment");
    }

    uint256[] memory returnResults = new uint256[](1);

    /**
    *
    * @dev Number in range request, send with light / normal / heavy designation:
    *
    */
    if (_arguments[0] == NUMBER_IN_RANGE_LIGHT) {
      returnResults[0] = getNumberInRangeLight(_arguments[1], seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }
    if (_arguments[0] == NUMBER_IN_RANGE_STANDARD) {
      returnResults[0] = getNumberInRange(_arguments[1], seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }

    if (_arguments[0] == NUMBER_IN_RANGE_HEAVY) {
      returnResults[0] = getNumberInRangeHeavy(_arguments[1], seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }

    /**
    *
    * @dev Standard entropy request, send with light / normal / heavy designation:
    *
    */
    if (_arguments[0] == ENTROPY_LIGHT) {
      returnResults[0] = getEntropyLight(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }
    if (_arguments[0] == ENTROPY_STANDARD) {
      returnResults[0] = getEntropy(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }

    if (_arguments[0] == ENTROPY_HEAVY) {
      returnResults[0] = getEntropyHeavy(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent); 
      return(true, returnResults);
    }  

    return(false, returnResults);
  }

  /**
  *
  * @dev Standard entry point for direct call, number in range
  *
  */
  function iceRingNumberInRange(uint256 _mode, uint256 _upperBound) external payable returns(bool, uint256 numberInRange_) {  

    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    uint256 ethFee = feeBase * (10 ** ethExponent);

    if (ethFee != 0) {
      require(msg.value == ethFee, "Incorrect ETH payment");
    }

    /**
    *
    * @dev Number in range request, send with light / normal / heavy designation:
    *
    */
    if (_mode == NUMBER_IN_RANGE_LIGHT) {

      return(true, getNumberInRangeLight(_upperBound, seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));
    
    }
    if (_mode == NUMBER_IN_RANGE_STANDARD) {

      return(true, getNumberInRange(_upperBound, seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));

    }

    if (_mode == NUMBER_IN_RANGE_HEAVY) {

      return(true, getNumberInRangeHeavy(_upperBound, seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent)); 

    }

    return(false, 0);
  }

  /**
  *
  * @dev Standard entry point for direct call, entropy
  *
  */
  function iceRingEntropy(uint256 _mode) external payable returns(bool, uint256 entropy_) { 

    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    uint256 ethFee = feeBase * (10 ** ethExponent);

    if (ethFee != 0) {
      require(msg.value == ethFee, "Incorrect ETH payment");
    }

    /**
    *
    * @dev Standard entropy request, send with light / normal / heavy designation:
    *
    */
    if (_mode == ENTROPY_LIGHT) {

      return(true, getEntropyLight(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));

    }

    if (_mode == ENTROPY_STANDARD) {

      return(true, getEntropy(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));

    }

    if (_mode == ENTROPY_HEAVY) {

      return(true, getEntropyHeavy(seedIndex, counter, modulo, seedAddress, feeBase, ethExponent, oatExponent));

    }  

    return(false, 0);

  }


  /**
  *
  * @dev View details of a given entropy seed address:
  *
  */
  function viewEntropyAddress(uint256 _index) external view returns (address entropyAddress) {
    return (entropyItem[_index]) ;
  }

  /**
  *
  * @dev get ETH fee
  *
  */
  function getEthFee() external view returns (uint256 ethFee) {
    return (getOm05() * (10 ** getOm06())) ;
  }

  /**
  *
  * @dev get OAT fee
  *
  */
  function getOatFee() external view returns (uint256 oatFee) {
    return (getOm05() * (10 ** getOm07())) ;
  }
  
  /**
  *
  * @dev Owner can add entropy seed address:
  *
  */
  function addEntropy(address _entropyAddress) external onlyOwner {

    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    counter += 1;
    entropyItem[counter] = _entropyAddress;
    seedAddress = _entropyAddress;
    emit EntropyAdded(_entropyAddress);
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, ethExponent, oatExponent, 0, 0, 0, 0, 0);
  }

  /**
  *
  * @dev Owner can update entropy seed address:
  *
  */
  function updateEntropy(uint256 _index, address _newAddress) external onlyOwner {
    address oldEntropyAddress = entropyItem[_index];
    entropyItem[_index] = _newAddress;
    emit EntropyUpdated(_index, _newAddress, oldEntropyAddress); 
  }

  /**
  *
  * @dev Owner can clear the list to start again:
  *
  */
  function deleteAllEntropy() external onlyOwner {
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oatExponent) = getConfig();

    require(counter > 0, "No entropy defined");
    for (uint i = 1; i <= counter; i++){
      delete entropyItem[i];
    }
    counter = 0;
    seedAddress = address(0);
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, ethExponent, oatExponent, 0, 0, 0, 0, 0);
    emit EntropyCleared();
  }

  /**
  *
  * @dev Owner can update the base fee
  *
  */
  function updateBaseFee(uint256 _newBaseFee) external onlyOwner {
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 oldFeeBase, uint256 ethExponent, uint256 oatExponent) = getConfig(); 
    
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), _newBaseFee, ethExponent, oatExponent, 0, 0, 0, 0, 0);
    
    emit BaseFeeUpdated(oldFeeBase, _newBaseFee);
  }

  /**
  *
  * @dev Owner can update the ETH fee exponent
  *
  */
  function updateETHFeeExponent(uint256 _newEthExponent) external onlyOwner {
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 oldEthExponent, uint256 oatExponent) = getConfig(); 
    
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, _newEthExponent, oatExponent, 0, 0, 0, 0, 0);
    
    emit ETHExponentUpdated(oldEthExponent, _newEthExponent);
  }

  /**
  *
  * @dev Owner can update the OAT fee exponent
  *
  */
  function updateOATFeeExponent(uint256 _newOatExponent) external onlyOwner {
    (uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256 feeBase, uint256 ethExponent, uint256 oldOatExponent) = getConfig(); 
    
    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, ethExponent, _newOatExponent, 0, 0, 0, 0, 0);
    
    emit OATExponentUpdated(oldOatExponent, _newOatExponent);
  }

  /** 
  *
  * @dev owner can update treasury address:
  *
  */ 
  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit TreasurySet(_treasury);
  }

  /**
  *
  * @dev Create hash of entropy seeds:
  *
  */
  function _hashEntropy(bool lightMode, uint256 seedIndex, uint256 counter, uint256 modulo, address seedAddress, uint256  feeBase, uint256 ethExponent, uint256 oatExponent) internal returns(uint256 hashedEntropy_){

    if (modulo >= 99999999) {
      modulo = 10000000;
    }  
    else {
      modulo = modulo + 1; 
    } 

    if (lightMode) {
      hashedEntropy_ = (uint256(keccak256(abi.encode(seedAddress.balance + (block.timestamp % modulo)))));
    }
    else {
      if (seedIndex >= counter) {
      seedIndex = 1;
      }  
      else {
        seedIndex += 1; 
      } 
      address rotatingSeedAddress = entropyItem[seedIndex];
      uint256 seedAddressBalance = rotatingSeedAddress.balance;
      hashedEntropy_ = (uint256(keccak256(abi.encode(seedAddressBalance, (block.timestamp % modulo)))));
      emit EntropyServed(rotatingSeedAddress, seedAddressBalance, block.timestamp, modulo, hashedEntropy_); 
    }         

    encodeNus(seedIndex, counter, modulo, uint256(uint160(seedAddress)), feeBase, ethExponent, oatExponent, 0, 0, 0, 0, 0);
      
    return(hashedEntropy_);
  }

  /**
  *
  * @dev Find a number within a range:
  *
  */
  function _numberInRange(uint256 _upperBound, bool _lightMode, uint256 _seed, uint256 _counter, uint256 _modulo, address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 numberWithinRange){
    return((((_hashEntropy(_lightMode, _seed, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent) % 10 ** 18) * _upperBound) / (10 ** 18)) + 1);
  }

  /**
  *
  * @dev Get OM values from the NUS
  *
  */
  function getConfig() public view returns(uint256 seedIndex_, uint256 counter_, uint256 modulo_, address seedAddress_, uint256 feeBase_, uint256 ethExponent_, uint256 oatExponent_){
    
    uint256 nusInMemory = nus;

    return(om1Value(nusInMemory), om2Value(nusInMemory), om3Value(nusInMemory), address(uint160(om4Value(nusInMemory))), om5Value(nusInMemory), om6Value(nusInMemory), om7Value(nusInMemory));
  }

  /**
  *
  * @dev Return a full uint256 of entropy:
  *
  */
  function getEntropy(uint256 _seed, uint256 _counter, uint256 _modulo, address _seedAddress, uint256  _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 entropy_){
    entropy_ = _hashEntropy(false, _seed, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent); 
    return(entropy_);
  }

  /**
  *
  * @dev Return a full uint256 of entropy - light mode. Light mode uses the most recent added seed address which is stored
  * in the control NUS. This avoids another read from storage at the cost of not cycling through multiple entropy
  * sources. The normal (non-light) version increments through the seed mapping.
  *
  */
  function getEntropyLight(uint256 _seedIndex,uint256 _counter, uint256 _modulo, address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 entropy_){
    entropy_ = _hashEntropy(true, _seedIndex, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent); 
    return(entropy_);
  }

  /**
  *
  * @dev Return a full uint256 of entropy - heavy mode. Heavy mode looks to maximise the number of sources of entropy that an
  * entity would need to control in order to predict an outome. It creates a hash of all our entropy sources, 1 to n, hashed with
  * the block.timestamp altered by an increasing modulo.
  *
  */
  function getEntropyHeavy(uint256, uint256 _counter, uint256 _modulo, address _seedAddress, uint256  _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 entropy_){
    
    uint256 loopEntropy;

    for (uint i = 0; i < _counter; i++){
      loopEntropy = _hashEntropy(false, i, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent); 
      entropy_ = (uint256(keccak256(abi.encode(entropy_, loopEntropy))));
    }
    return(entropy_);

  }

  /**
  *
  * @dev Return a number within a range (1 to upperBound):
  *
  */
  function getNumberInRange(uint256 _upperBound, uint256 _seedIndex, uint256 _counter, uint256 _modulo, 
      address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 numberInRange_){
    numberInRange_ = _numberInRange(_upperBound, false, _seedIndex, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent);
    return(numberInRange_);
  }

  /**
  *
  * @dev Return a number within a range (1 to upperBound) - light mode. Light mode uses the most recent added seed address which is stored
  * in Om Storage. This avoids another read from storage at the cost of not cycling through multiple entropy
  * sources. The normal (non-light) version increments through the seed mapping.
  *
  */
  function getNumberInRangeLight(uint256 _upperBound, uint256 _seedIndex, uint256 _counter, uint256 _modulo, 
      address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 numberInRange_){
    numberInRange_ = _numberInRange(_upperBound, true, _seedIndex, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent);
    return(numberInRange_);
  }

  /**
  *
  * @dev Return a number within a range (1 to upperBound) - heavy mode.
  *
  */
  function getNumberInRangeHeavy(uint256 _upperBound, uint256 _seedIndex, uint256 _counter, uint256 _modulo, 
      address _seedAddress, uint256 _feeBase, uint256 _ethExponent, uint256 _oatExponent) internal returns(uint256 numberInRange_){
    numberInRange_ = ((((getEntropyHeavy(_seedIndex, _counter, _modulo, _seedAddress, _feeBase, _ethExponent, _oatExponent) % 10 ** 18) * _upperBound) / (10 ** 18)) + 1);
    return(numberInRange_);
  }

  /**
  *
  * @dev Validate proof:
  *
  */
  function validateProof(uint256 _seedValue, uint256 _modulo, uint256 _timeStamp, uint256 _entropy) external pure returns(bool valid){
    if (uint256(keccak256(abi.encode(_seedValue, (_timeStamp % _modulo)))) == _entropy) return true;
    else return false;
  }

  /**
  *
  * @dev Allow any token payments to be withdrawn:
  *
  */
  function withdrawERC20(IERC20 _token, uint256 _amountToWithdraw) external onlyOwner {
    _token.safeTransfer(treasury, _amountToWithdraw); 
    emit TokenWithdrawal(_amountToWithdraw, address(_token));
  }

  /** 
  * @dev Owner can withdraw eth to treasury:
  */ 
  function withdrawETH(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = treasury.call{value: _amount}("");
    require(success, "Transfer failed.");
    emit EthWithdrawal(_amount); 
    return true;
  }

  /**
  *
  * @dev Revert all eth payments not from the owner or unknown function calls
  *
  */
  receive() external payable {
    require(msg.sender == owner(), "Only owner can fund contract");
  }

  fallback() external payable {
    revert();
  }

}