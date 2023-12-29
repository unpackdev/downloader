// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";

interface IDuel {
  function getRainValue() external view returns (uint256);
}

contract PrivateSwap is Ownable {
  IERC20 rainToken;
  IDuel duelToken;
  address public captureWallet;

  struct SwapRecord{
    uint amount;
    uint stakePeriodDays;
    uint swapTime;
    uint rainUsdtValue;
  }

  mapping (address => uint) public swapLimits; 
  mapping (address => SwapRecord) public swapRecords; 

  event SwapAndStake(
    address indexed staker,
    uint amount,
    uint stakePeriodDays,
    uint rainUsdtValue
  );

  constructor(address rainAddress, address duelAddress, address captureAddress) Ownable(msg.sender) {
      rainToken = IERC20(rainAddress);
      duelToken = IDuel(duelAddress);
      captureWallet = captureAddress;
  }

  function swapAndStake(uint amount, uint stakePeriodDays) external {
    require(amount > 0, "Swap amount cant be 0");
    require(amount <= swapLimits[msg.sender], "Swap too large");

    uint limit = swapLimits[msg.sender];
    swapLimits[msg.sender] = limit - amount;

    rainToken.transferFrom(
        msg.sender,
        captureWallet,
        amount
    );

    uint rainUsdtValue = duelToken.getRainValue();

    uint prevAmount = swapRecords[msg.sender].amount;
    
    swapRecords[msg.sender] = SwapRecord(amount + prevAmount, stakePeriodDays, block.timestamp, rainUsdtValue);
    emit SwapAndStake(msg.sender, amount, stakePeriodDays, rainUsdtValue);
  }

  function viewSwapRecord(address swapper) external view returns(SwapRecord memory){
    return swapRecords[swapper];
  }

  // ADMIN FUNCTIONS

  // Unbounded loop. Ok since we have very few VIPs. Be careful of gas. 
  function addWhitelistedAccounts(address[] memory whitelistedAccounts, uint[] memory limits) external onlyOwner {
    require(whitelistedAccounts.length == limits.length, "accounts don't match limits");

    for(uint i =0; i< whitelistedAccounts.length; i++){
      swapLimits[whitelistedAccounts[i]] = limits[i];
    }
  }

  function setCaptureWallet(address captureAddress) external onlyOwner {
    captureWallet = captureAddress;
  }

}
