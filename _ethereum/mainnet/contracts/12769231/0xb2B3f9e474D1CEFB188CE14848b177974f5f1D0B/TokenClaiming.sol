// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./IERC721Upgradeable.sol";
import "./MintableCollection.sol";

contract TokenClaiming is Initializable, OwnableUpgradeable  {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  MintableCollection private nftCollection;

  // Info of each partnership pool.
  struct TokenPoolInfo {
    uint256 claimStartDate; // timestamp of when users are allowed to claim
    bool isLocked;  // boolean to lock a pool
    bool exists; 
    IERC20Upgradeable tokenContract; // address of the rewards-token
    mapping(uint256 => PmonNft) whiteListedNftIds; // mapping with the whitelisted NFT ids
    uint256[] whiteListedNftIdsAsArray; // array with the whitelisted NFT ids
    uint256 qualifyingNftAmount; // counter for how many NFT ids have been whitelisted - the ones who claimed
    uint256 depositedAmount;  // cumulative sum of added rewards for a pool
    uint256 claimedRewards; // cumulative sum of claimed rewards for a pool
    string pmonType; //the type of the Polychain Monsters that are eligible for this pool
  }

  struct PmonNft {
    bool whitelisted;
    bool hasClaimed;
  }

  string[] public pmonTypesWithPools;

  event PoolCreated(string indexed pmonType, address indexed tokenContract);
  event TokensDeposited(string indexed pmonType, address indexed tokenContract, uint256 amount);
  event TokensClaimed(string indexed pmonType, address indexed tokenContract, address indexed receiver, uint256 amount, uint256 nftId);

  // factor to use to limit rounding errors
  uint256 private constant ROUNDING_PRECISION = 1e12;

  //a mapping from the typeId of the Polychain Monster to the TokenPoolInfo
  mapping(string => TokenPoolInfo) public pools;

  modifier poolExists(string memory pmonType) {
    require(pools[pmonType].exists, "TokenClaiming: Pool does not exist");
    _;
  }

  modifier poolNotExists(string memory pmonType) {
    require(!pools[pmonType].exists, "TokenClaiming: Pool already exists");
    _;
  }

  modifier poolNotLocked(string memory pmonType) {
    require(!pools[pmonType].isLocked, "TokenClaiming: Pool is locked");
    _;
  }

  modifier poolClaimStarted(string memory pmonType) {
    require(pools[pmonType].claimStartDate <= block.timestamp, "TokenClaiming: Claim not allowed yet");
    _;
  }

  function initialize(MintableCollection _nftCollection) public initializer {
    nftCollection = _nftCollection;
    OwnableUpgradeable.__Ownable_init();
  }

  function addPool(
    string memory pmonType, // //the type of the Polychain Monsters that are eligible for this pool
    IERC20Upgradeable tokenContract, // address of the rewards-token
    uint256 claimStartDate // start date timestamp in seconds
  ) external onlyOwner poolNotExists(pmonType) {
    TokenPoolInfo storage pool = pools[pmonType];
    pool.claimStartDate = claimStartDate;
    pool.isLocked = false;
    pool.exists = true;
    pool.tokenContract = tokenContract;
    pool.pmonType = pmonType;

    pmonTypesWithPools.push(pmonType);

    emit PoolCreated(pmonType, address(tokenContract));
  }

  function deposit(
    string memory pmonType,
    uint256 amount // the token amount that should be added to the pool
  ) public onlyOwner poolExists(pmonType) poolNotLocked(pmonType) {
    TokenPoolInfo storage pool = pools[pmonType];

    pool.tokenContract.transferFrom(msg.sender, address(this), amount);
    pool.depositedAmount = pool.depositedAmount + amount;

    emit TokensDeposited(pmonType, address(pool.tokenContract), amount);
  }

  function claim(string memory pmonType, uint256 nftId)
    external
    poolExists(pmonType)
    poolNotLocked(pmonType)
    poolClaimStarted(pmonType)
  {
    TokenPoolInfo storage pool = pools[pmonType];
    require(pool.whiteListedNftIds[nftId].whitelisted, "TokenClaiming: NFT not whitelisted");
    require(!pool.whiteListedNftIds[nftId].hasClaimed, "TokenClaiming: Already claimed");
    
    require(nftCollection.ownerOf(nftId) == msg.sender, "TokenClaiming: Sender is not the owner");

    nftCollection.burn(nftId);
    pool.whiteListedNftIds[nftId].hasClaimed = true;

    uint256 claimAmount = pool.depositedAmount / pool.qualifyingNftAmount;
    safeClaimTransfer(pmonType, msg.sender, claimAmount);
    pool.qualifyingNftAmount = pool.qualifyingNftAmount - 1;

    emit TokensClaimed(pmonType, address(pool.tokenContract), msg.sender, claimAmount, nftId);
  }

  function availableForClaim(string memory pmonType, uint256 nftId)
    external
    view
    poolExists(pmonType)
    poolNotLocked(pmonType)
    poolClaimStarted(pmonType)
    returns (uint256)
  {
    TokenPoolInfo storage pool = pools[pmonType];
    require(pool.whiteListedNftIds[nftId].whitelisted, "TokenClaiming: NFT not whitelisted");
    require(!pool.whiteListedNftIds[nftId].hasClaimed, "TokenClaiming: Already claimed");
    require(_getOwnerOfNft(nftId) != address(0), "TokenClaiming: NFT was burned");

    return pool.depositedAmount / pool.qualifyingNftAmount;
  }

  function whitelistNftIds(string memory pmonType, uint256[] memory nftIds)
    external
    onlyOwner
    poolExists(pmonType)
  {
    TokenPoolInfo storage pool = pools[pmonType];
    for (uint256 i = 0; i < nftIds.length; i++) {
      pool.whiteListedNftIds[nftIds[i]] = PmonNft({
        whitelisted: true,
        hasClaimed: false
      });
      pool.whiteListedNftIdsAsArray.push(nftIds[i]);
    }
    pool.qualifyingNftAmount = pool.qualifyingNftAmount + nftIds.length;
  }

  function getAddressesWithWhitelistedNfts(string memory pmonType) external
    view
    poolExists(pmonType)
    poolNotLocked(pmonType)
    poolClaimStarted(pmonType) returns (address[] memory, uint256[] memory )
    {
      TokenPoolInfo storage pool = pools[pmonType];
      address[] memory addresses = new address[](pool.whiteListedNftIdsAsArray.length); 
      for (uint256 i = 0; i < pool.whiteListedNftIdsAsArray.length; i++) {
        addresses[i] = _getOwnerOfNft(pool.whiteListedNftIdsAsArray[i]);
      }
      return (addresses, pool.whiteListedNftIdsAsArray);
    }

  function _getOwnerOfNft(uint256 nftId) internal view returns (address) {
      try nftCollection.ownerOf(nftId) returns (address owner) {
            return owner;
        } catch Error(string memory) {
            return address(0);
        } catch (bytes memory) {
            return address(0);
        }
  }

  function safeClaimTransfer(string memory pmonType, address to, uint256 amount) internal {
    TokenPoolInfo storage pool = pools[pmonType];
    if (amount > pool.depositedAmount) {
      pool.tokenContract.transfer(to, pool.depositedAmount);
      pool.depositedAmount = 0;
    } else {
      pool.tokenContract.transfer(to, amount);
      pool.depositedAmount = pool.depositedAmount - amount;
    }
  }

  function getPoolNumber() external view returns (uint256) {
    return pmonTypesWithPools.length;
  }
}
