// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ITopDog.sol";

contract RyoshiSays is Ownable {

  // WELCOME TO RyoshiSays
  //
  // This is a small contract that helps compute voting rights for the RYOSHI DAO
  // For now, it has been decided that voting rights will be distributed as follows:
  //     50% for RYOSHI+ETH ShibaSwap LP holders/stakers
  //     25% for RYOSHI holders (balance-independent)
  //     25% for RYOSHI holders (balance-dependent)
  //
  // To determine thse voting power ratios, balance dependent votes will be based on
  // a maximum holder percentage. For example, upon launch, the maximum holder percentage
  // for RYOSHI will be set to 5%. All wallets holding 5% or more of the circulating supply
  // will have the same balance-dependent voting power. The same is true for Shiba Swap LP
  // token holders. In general, voting power can be computed as follows:
  //       (0.25 * balance / maxBalance) + (0.5 * (lpBalance + lpStaked) / maxLPBalance) + 0.25
  //
  //
  // As the future progresses, this distribution may be changed and this contract may be replaced
  // as decided upon by the DAO voting platform, which can be found here:
  //     https://snapshot.org/#/ryoshis-vision.eth

  event DecirculatedAddressAdded(address indexed wallet);
  event MaxBalanceSet(uint256 amount);
  event MaxLPRatioSet(uint256 amount);

  address public rewardDistributorAddress = 0x7732674B5E5FfeC4785AEFdAEa807EeCA383B5e6;
  address public legendaryBurnAddress = 0xdEAD000000000000000042069420694206942069;
  address public ryoshiRewardAddress = 0xf71741c102e5295813912Cf3b2fc07bc740A0f1c;
  address public shibAddress = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;

  address public shibaSwapLPAddress = 0x5660c518c5610493086A3BA550f7ad6EB7935d1E;
  address public uniswapLPAddress = 0x92FFe72EE8A6a3DF28d18d6CA01a8e17ADF608F0;
  address public ryoshiAddress = 0x777E2ae845272a2F540ebf6a3D03734A5a8f618e;
  address public topDogAddress = 0x94235659cF8b805B2c658f9ea2D6d6DDbb17C8d7;

  address[] public decirculatedAddresses;

  uint256 public maxRyoshiBalance;
  uint256 public maxLPBalanceRatio;
  uint256 public ratioPercision;

  uint256 public trillionRyoshi = 1000000000000 * 10 ** 18;

  uint256 public totalSupply;

  constructor() Ownable() {
    addDecirculatedAddress(rewardDistributorAddress);
    addDecirculatedAddress(legendaryBurnAddress);
    addDecirculatedAddress(ryoshiRewardAddress);
    addDecirculatedAddress(shibaSwapLPAddress);
    addDecirculatedAddress(uniswapLPAddress);
    addDecirculatedAddress(shibAddress);

		setTotalSupply(100000 * 10 ** 18);
    setMaxRyoshiBalance(trillionRyoshi);
    setMaxLPBalanceRatio(500);

    ratioPercision = 10000;
  }

  function symbol() public view virtual returns (string memory) {
      return 'ryoVOTE';
  }

  function name() public view virtual returns (string memory) {
      return 'RYOSHI VOTE';
  }

	// This function will determine the number of votes that any address will get:
  function balanceOf(address account) public view returns (uint256) {
    // Contracts should never be able to vote
    if (Address.isContract(account)) return 0;

    // Each RYOSHI holder will receive votes in the following form:
    //   10^18       votes for each RYOSHI or RYOSHI LP holder/staker (25% balance-independent)
    //   10^18       votes multiplied by amountHeld / maxAmount (25% balance-dependent)
    //   2 * 10^18   votes multiplied by amountLP / maxLPAmount (50% ShibaSwap LP holders/stakers)

    uint256 ownershipVotes = getRyoshiOwnershipVotes(account) + 2 * getLpOwnershipVotes(account);
    if (ownershipVotes == 0) return 0;

    uint256 equalHolderVotes = (10 ** 18);
    return ownershipVotes + equalHolderVotes;
  }

  function getLpOwnershipVotes(address account) public view returns (uint256) {
    uint256 lpBalance = IERC20(shibaSwapLPAddress).balanceOf(account);
    // Add number of RYOSHI+ETH LP tokens staked in ShibaSwap:
    uint256 ryoshiPoolIndex = 23;
    ITopDog.UserInfo memory info = ITopDog(topDogAddress).userInfo(ryoshiPoolIndex, account);
    lpBalance += info.amount;

    uint256 maxLPBalance = maxLPBalanceRatio * circulatingShibaSwapLP() / ratioPercision;

    // Holders with more than the maximum LP balance will all have the same voting power:
    if (lpBalance > maxLPBalance) lpBalance = maxLPBalance;

    // If a user has less than 10 LP tokens, they should not have any voting power.
    if (lpBalance < 10 * 10 ** 18) lpBalance = 0;

    return (10 ** 18) * lpBalance / maxLPBalance;
  }

  function circulatingShibaSwapLP() public view returns (uint256) {
    uint256 totalSupplyLP = IERC20(shibaSwapLPAddress).totalSupply();
    uint256 burnedLP = IERC20(shibaSwapLPAddress).balanceOf(shibAddress);
    return totalSupplyLP - burnedLP;
  }

  function getRyoshiOwnershipVotes(address account) public view returns (uint256) {
    uint256 balance = IERC20(ryoshiAddress).balanceOf(account);

    // Holders with more than the maximum RYOSHI balance will all have the same voting power:
    if (balance > maxRyoshiBalance) balance = maxRyoshiBalance;

    // If a user has less than 10m RYOSHI, they should not have any voting power.
    if (balance < 10000000 * 10 ** 18) balance = 0;

    return (10 ** 18) * balance / maxRyoshiBalance;
  }

  function initialRyoshiSupply() public pure returns (uint256) {
    return 1000000000000000 * 10 ** 18;
  }

  function circulatingRyoshi() public view returns (uint256) {
    uint256 supply = initialRyoshiSupply();
    for (uint256 i=0; i < decirculatedAddresses.length; i++)
      supply -= IERC20(ryoshiAddress).balanceOf(decirculatedAddresses[i]);

    return supply;
  }

  function totalRyoshiBurnt() public view returns (uint256) {
    return IERC20(ryoshiAddress).balanceOf(legendaryBurnAddress) +
      IERC20(ryoshiAddress).balanceOf(shibAddress);
  }

  function totalRyoshiSupply() public view returns (uint256) {
    return initialRyoshiSupply() - totalRyoshiBurnt();
  }

  function addDecirculatedAddress(address addr) public onlyOwner {
    decirculatedAddresses.push(addr);
    emit DecirculatedAddressAdded(addr);
  }

  function setMaxLPBalanceRatio(uint256 ratio) public onlyOwner {
    require(ratio > 50, 'Max LP Ratio must be more than 0.5%');
    require(ratio < 2000, 'Max LP Ratio must be less than 20%');

    maxLPBalanceRatio = ratio;
    emit MaxLPRatioSet(ratio);
  }

	function setTotalSupply(uint256 supply) public onlyOwner {
    totalSupply = supply;
  }

  function setMaxRyoshiBalance(uint256 max) public onlyOwner {
    require(max > trillionRyoshi / 20, 'Max Ryoshi Balance must be more than 50,000,000,000');
    require(max < 2 * trillionRyoshi, 'Max Ryoshi Balance be less than 2 trillion');

    maxRyoshiBalance = max;
    emit MaxBalanceSet(max);
  }

  function decimals() public view virtual returns (uint8) {
      return 18;
  }
}
