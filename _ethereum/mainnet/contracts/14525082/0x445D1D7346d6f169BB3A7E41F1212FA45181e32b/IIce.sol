// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/entropy/IIce.sol)
// https://omnuslab.com/icering

// IIce (In Chain Entropy - Interface)

pragma solidity ^0.8.13;

/**
* @dev ICE - In-Chain Entropy
*
* This protocol generates in-chain entropy (OK, ON-chain not in-chain, but that didn't make a cool acronym...).
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
*                   please DYOR on what option is best for you. There are no guarantees the entropy seeds here will be maintained
*                   (I mean, no one might ever use this). No liability is accepted etc.
*/

/**
*
* @dev Implementation of the Ice interface.
*
*/

interface IIce {
  event EntropyAdded (address _entropyAddress);
  event EntropyUpdated (uint256 _index, address _newAddress, address _oldAddress); 
  event EntropyCleared (); 
  event EntropyServed(address seedAddress, uint256 seedValue, uint256 timeStamp, uint256 modulo, uint256 entropy);
  event FeeUpdated(uint256 oldFee, uint256 newFee);
  event TreasurySet(address treasury);
  event TokenWithdrawal(uint256 indexed withdrawal, address indexed tokenAddress);

  function viewEntropyAddress(uint256 _index) external view returns (address entropyAddress);
  function addEntropy(address _entropyAddress) external;
  function updateEntropy(uint256 _index, address _newAddress) external;
  function deleteAllEntropy() external;
  function updateFee(uint256 _fee) external;
  function getConfig() external view returns(uint256 seedIndex_, uint256 counter_, uint256 modulo_, address seedAddress_, uint256 fee_);
  function validateProof(uint256 _seedValue, uint256 _modulo, uint256 _timeStamp, uint256 _entropy) external pure returns(bool valid);
}