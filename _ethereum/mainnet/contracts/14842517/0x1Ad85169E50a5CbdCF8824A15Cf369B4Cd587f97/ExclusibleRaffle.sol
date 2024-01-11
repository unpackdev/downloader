pragma solidity >=0.4.22 <0.9.0;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

// EXCLUSIBLE - RAFFLE ENGINE CONTRACT

contract ExclusibleRaffleEngine is VRFConsumerBase, Ownable  {

  bytes32 internal keyHash;
  uint256 internal fee;
  uint256 public randomResult;

  uint256[] public results;
  address[] public walletResults;

  uint256[] public entries;
  address[] public walletEntries;
  bool isWallet = false;
  constructor()
    VRFConsumerBase(
      0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
      0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    )
  {
    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
  }

  function fulfill_random(uint256 randomness) public {
    require(randomness > 0, "Exclusible - randomness not found");
    if(isWallet){
      uint256 index = randomness % walletEntries.length;
      walletResults.push(walletEntries[index]);
      isWallet = !isWallet;
    }else{
      uint256 index = randomness % entries.length;
      results.push(entries[index]);
    }
    
  }

  function setWalletEntries(address[] memory _entries) external onlyOwner {
    require(_entries.length > 0, "Exclusible - empty argument");
    walletEntries = _entries;
  }

  function setEntries(uint256[] memory _entries) external onlyOwner {
    require(_entries.length > 0, "Exclusible - empty argument");
    entries = _entries;
  }

  function addWalletEntry(address _address) external onlyOwner {
      walletEntries.push(_address);
  }

  function addEntry(uint256 _entry) external onlyOwner {
      entries.push(_entry);
  }



  // Request randomness
  function getRandomNumber(bool _iswallet) public returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "Exclusible - Not enough LINK");
    isWallet = _iswallet;
    return requestRandomness(keyHash, fee);
  }


  // Callback function used by VRF Coordinator
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    randomResult = randomness;
    fulfill_random(randomResult);
  }
}