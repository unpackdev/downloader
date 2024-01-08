pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./TempleERC20Token.sol";
import "./ITreasuryAllocation.sol";
import "./MintAllowance.sol";
import "./SafeERC20.sol";

// import "./console.sol";

contract TempleTreasury is Ownable {
    // Underlying TEMPLE token
    TempleERC20Token private TEMPLE;

    // DAI contract
    IERC20 private DAI;

    // Minted temple allocated to various investment contracts
    MintAllowance public MINT_ALLOWANCE;

    // Ratio of mark to market DAI to minted TEMPLE at a particular harvest point
    // eg. temple for DAI would be amountPaidInDai / (intrinsicValueRatio.dai/intrinsicValueRatio.temple * ivMultiple);
    struct IntrinsicValueRatio {
      uint256 dai;
      uint256 temple;
    } 
    IntrinsicValueRatio public intrinsicValueRatio;

    // Temple rewards harvested, and (yet) to be allocated to a pool
    uint256 public harvestedRewards;

    // Has treasury been seeded with DAI yet (essentially, has seedMint been called)
    // this will bootstrap IV
    bool public seeded = false;

    // all active pools. A pool is anything
    // that gets allocated some portion of harvest
    address[] public pools;
    mapping(address => uint96) public poolHarvestShare;
    uint96 public totalHarvestShares;

    // Current treasury DAI allocations
    mapping(ITreasuryAllocation => uint256) public treasuryAllocations;
    uint256 public totalAllocationDai;

    event RewardsHarvested(uint256 _amount);
    event HarvestDistributed(address _contract, uint256 _amount);

    constructor(TempleERC20Token _TEMPLE, IERC20 _DAI) {
      TEMPLE = _TEMPLE;
      DAI = _DAI;
      MINT_ALLOWANCE = new MintAllowance(_TEMPLE);
    }

    function numPools() public view returns (uint256) {
      return pools.length;
    }

    /**
     * Seed treasury with DAI and Temple to bootstrap
     */
    function seedMint(uint256 daiAmount, uint256 templeAmount) external onlyOwner {
      require(!seeded, "Owner has already seeded treasury");
      seeded = true;

      // can this go in the constructor?
      intrinsicValueRatio.dai = daiAmount;
      intrinsicValueRatio.temple = templeAmount;

      SafeERC20.safeTransferFrom(DAI, msg.sender, address(this), daiAmount);
      TEMPLE.mint(msg.sender, templeAmount);
    }

    /**
     * Harvest rewards.
     *
     * For auditing, we harvest and allocate in two steps
     */
    function harvest(uint256 scalingFactor) external onlyOwner {
      require(scalingFactor <= 100, "Scaling factor interpreted as a %, needs to be between 0 (no harvest) and 100 (max harvest)");

      uint256 reserveAsDai = DAI.balanceOf(address(this)) + totalAllocationDai;

      // // Burn any excess temple, that is Any temple over and beyond harvestedRewards.
      // // NOTE: If we don't do this, IV could drop...
      if (TEMPLE.balanceOf(address(this)) > harvestedRewards) {
        // NOTE: there isn't a Reentrancy issue as we control the TEMPLE ERC20 contract, and configure
        //       treasury with an address on contract creation
        TEMPLE.burn(TEMPLE.balanceOf(address(this)) - harvestedRewards);
      }

      uint256 totalTempleSupply = TEMPLE.totalSupply() - TEMPLE.balanceOf(address(MINT_ALLOWANCE));
      uint256 totalSupplyForNoIVIncreaseTemple = reserveAsDai * intrinsicValueRatio.temple / intrinsicValueRatio.dai;

      require(totalSupplyForNoIVIncreaseTemple >= totalTempleSupply, "Cannot run harvest when IV drops");

      uint256 newHarvest = (totalSupplyForNoIVIncreaseTemple - totalTempleSupply) * scalingFactor / 100;
      harvestedRewards += newHarvest;

      intrinsicValueRatio.dai = reserveAsDai;
      intrinsicValueRatio.temple = totalTempleSupply + newHarvest;

      TEMPLE.mint(address(this), newHarvest);
      emit RewardsHarvested(newHarvest);
    }

    function resetIV() external onlyOwner {
      uint256 reserveAsDai = DAI.balanceOf(address(this)) + totalAllocationDai;
      uint256 totalTempleSupply = TEMPLE.totalSupply() - TEMPLE.balanceOf(address(MINT_ALLOWANCE));
      intrinsicValueRatio.dai = reserveAsDai;
      intrinsicValueRatio.temple = totalTempleSupply;
    }

    /**
     * Allocate rewards to each investment contract.
     */
    function distributeHarvest() external onlyOwner {
      // transfer rewards as per defined allocation
      uint256 totalAllocated = 0;
      for (uint256 i = 0; i < pools.length; i++) {
        uint256 allocatedRewards = harvestedRewards * poolHarvestShare[pools[i]] / totalHarvestShares;

        // integer rounding may cause the last allocation to exceed harvested
        // rewards. Handle gracefully
        if ((totalAllocated + allocatedRewards) > harvestedRewards) {
          allocatedRewards = harvestedRewards - totalAllocated;
        }
        totalAllocated += allocatedRewards;
        SafeERC20.safeTransfer(TEMPLE, pools[i], allocatedRewards);
        emit HarvestDistributed(pools[i], allocatedRewards);
      }
      harvestedRewards -= totalAllocated;
    }

    /**
     * Mint and Allocate treasury TEMPLE.
     */
    function mintAndAllocateTemple(address _contract, uint256 amountTemple) external onlyOwner {
      require(amountTemple > 0, "TEMPLE to mint and allocate must be > 0");

      // Mint and Allocate TEMPLE via MINT_ALLOWANCE helper
      TEMPLE.mint(address(this), amountTemple);
      SafeERC20.safeIncreaseAllowance(TEMPLE, address(MINT_ALLOWANCE), amountTemple);
      MINT_ALLOWANCE.increaseMintAllowance(_contract, amountTemple);
    }

    /**
     * Burn minted temple associated with a specific contract
     */
    function unallocateAndBurnUnusedMintedTemple(address _contract) external onlyOwner {
      MINT_ALLOWANCE.burnUnusedMintAllowance(_contract);
    }

    /**
     * Allocate treasury DAI.
     */
    function allocateTreasuryDai(ITreasuryAllocation _contract, uint256 amountDai) external onlyOwner {
      require(amountDai > 0, "DAI to allocate must be > 0");

      treasuryAllocations[_contract] += amountDai;
      totalAllocationDai += amountDai;
      SafeERC20.safeTransfer(DAI, address(_contract), amountDai);
    }

    /**
     * Update treasury with latest mark to market for a given treasury allocation
     */
    function updateMarkToMarket(ITreasuryAllocation _contract) external onlyOwner {
      uint256 oldReval = treasuryAllocations[_contract];
      uint256 newReval = _contract.reval();
      totalAllocationDai = totalAllocationDai + newReval - oldReval;
      treasuryAllocations[_contract] = newReval;
    }

    /**
     * Withdraw from a contract. 
     *
     * Expects that pre-withdrawal reval() includes the unwithdrawn allowance, and post withdrawal reval()
     * drops by exactly this amount.
     */
    function withdraw(ITreasuryAllocation _contract) external onlyOwner {
      uint256 preWithdrawlReval = _contract.reval();
      uint256 pendingWithdrawal = DAI.allowance(address(_contract), address(this));
      SafeERC20.safeTransferFrom(DAI, address(_contract), address(this), pendingWithdrawal);
      uint256 postWithdrawlReval = _contract.reval();

      totalAllocationDai = totalAllocationDai - pendingWithdrawal;
      treasuryAllocations[_contract] -= pendingWithdrawal;

      require(postWithdrawlReval + pendingWithdrawal == preWithdrawlReval);
    }

    /**
     * Withdraw from a contract which has some treasury allocation 
     *
     * Provided as a backstop so we can get back to a consistent state if there are any issues
     * with the pre-condition checks of withdraw
     *
     * Resets both this contract's allocation and removes it from all treasuryAllocations. The intention
     * being we'd use resetIV or similar to re-cover.
     */
    function unsafeWithdraw(ITreasuryAllocation _contract, uint256 _newTotalAllocationDai) external onlyOwner {
      uint256 pendingWithdrawal = DAI.allowance(address(_contract), address(this));
      totalAllocationDai = _newTotalAllocationDai;
      treasuryAllocations[_contract] = 0;
      SafeERC20.safeTransferFrom(DAI, address(_contract), address(this), pendingWithdrawal);
    }

    /**
     * Add a new pool, and transfer in treasury assets
     */
    function setPoolHarvestShare(address _contract, uint96 _poolHarvestShare) external onlyOwner {
      require(_poolHarvestShare > 0, "Harvest share must be > 0");

      totalHarvestShares = totalHarvestShares + _poolHarvestShare - poolHarvestShare[_contract];

      // first time, add contract to array as well
      if (poolHarvestShare[_contract] == 0) { 
        pools.push(_contract);
      }

      poolHarvestShare[_contract] = _poolHarvestShare;
    }

    /**
     * Remove a given investment pool.
     */
    function removePool(uint256 idx, address _contract) external onlyOwner {
      require(idx < pools.length, "No pool at the specified index");
      require(pools[idx] == _contract, "Pool at index and passed in address don't match");

      pools[idx] = pools[pools.length-1];
      pools.pop();
      totalHarvestShares -= poolHarvestShare[_contract];
      delete poolHarvestShare[_contract];
    }
}