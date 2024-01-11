pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IV3Pool.sol";

contract V4Migration is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  address public oceanAddress;
  address public OPFWallet;

  uint256 internal BASE = 1e18;
  uint256 public lockWindow = 1814400; // used for quick test, will be 1 month, number of blocks

  constructor(
    address _oceanAddress,
    address _OPFWallet,
    uint256 _lockWindow
  ) {
    require(_oceanAddress != address(0), 'Ocean Address cannot be address(0)');
    require(_OPFWallet != address(0), '_OPFWallet cannot be address(0)');
    oceanAddress = _oceanAddress;
    OPFWallet = _OPFWallet;
    lockWindow = _lockWindow;
  }

  enum migrationStatus {
    notStarted,
    allowed,
    completed
  }

  struct PoolShares {
    address owner;
    uint256 shares;
  }
  struct PoolStatus {
    migrationStatus status;
    address poolV3Address;
    address dtV3Address;
    address owner;
    PoolShares[] poolShares;
    uint256 lps;
    uint256 totalSharesLocked;
    uint256 totalOcean;
    uint256 totalDTBurnt;
    uint256 deadline;
  }

  event SharesAdded(
    address poolAddress,
    address user,
    uint256 lockedShares,
    uint256 blockNo
  );
  event Started(address poolAddress, uint256 blockNo, address caller);
  event Completed(address poolAddress, address caller, uint256 blockNo);

  mapping(address => PoolStatus) private pool;

  /**
   * @dev startMigration
   *      Starts migration process for a pool
   * @param _dtAddress datatoken address
   * @param _poolAddress pool address
   */
  function startMigration(address _dtAddress, address _poolAddress)
    external
    nonReentrant
  {
    require(
      uint256(pool[_poolAddress].status) == 0,
      'Migration process has already been started'
    );

    require(
      IV3Pool(_poolAddress).isBound(_dtAddress),
      'Datatoken is not bound'
    );
    require(
      IV3Pool(_poolAddress).isBound(oceanAddress),
      'OCEAN token is not bound'
    );
    // Start the migration process for an asset.
    PoolStatus storage newPool = pool[_poolAddress];
    newPool.status = migrationStatus.allowed;
    newPool.poolV3Address = _poolAddress;
    newPool.dtV3Address = _dtAddress;
    newPool.owner = IV3Pool(_poolAddress).getController();
    newPool.lps = 0;
    newPool.totalSharesLocked = 0;
    newPool.totalOcean = 0;
    newPool.totalDTBurnt = 0;
    newPool.deadline = block.timestamp.add(lockWindow);
    emit Started(_poolAddress, block.number, msg.sender);
  }

  /**
   * @dev addShares
   *      Called by user in order to lock some pool shares.
   * @param _poolAddress pool address
   * @param noOfShares number of shares
   */
  function addShares(address _poolAddress, uint256 noOfShares)
    external
    nonReentrant
  {
    require(noOfShares > 0, 'Adding zero shares is not allowed');
    // Check that the Migration is allowed
    require(
      canAddShares(_poolAddress) == true,
      'Adding shares is not currently allowed'
    );
    uint256 LPBalance = IERC20(_poolAddress).balanceOf(msg.sender);
    require(LPBalance == noOfShares, 'All shares must be locked');
    //loop trough poolShareOwners to see if we already have shares from this user
    uint256 currentShares = 0;
    uint256 i;
    for (i = 0; i < pool[_poolAddress].poolShares.length; i++) {
      if (pool[_poolAddress].poolShares[i].owner == msg.sender) {
        currentShares = pool[_poolAddress].poolShares[i].shares;
        break;
      }
    }
    require(currentShares == 0, 'You already have locked shares');
    // does a transferFrom for LP's shares. requires prior approval.
    require(
      IERC20(_poolAddress).transferFrom(msg.sender, address(this), noOfShares),
      'Failed to transfer shares'
    );

    //add new record, user has not transfered any shares so far
    PoolShares memory newEntry;
    newEntry.owner = msg.sender;
    newEntry.shares = noOfShares;
    pool[_poolAddress].poolShares.push(newEntry);
    pool[_poolAddress].lps++;
    pool[_poolAddress].totalSharesLocked += noOfShares;
    emit SharesAdded(_poolAddress, msg.sender, noOfShares, block.number);
  }

  /**
   * @dev getPoolStatus
   *      Returns pool status
   * @param poolAddress pool Address
   * @return PoolStatus
   */
  function getPoolStatus(address poolAddress)
    external
    view
    returns (PoolStatus memory)
  {
    return (pool[poolAddress]);
  }

  /**
   * @dev getPoolShares
   *      Returns a list of users and coresponding locked shares, using pagination
   *      Use start = 0 , end = 2^256 for default values, but your RPC provider might complain
   * @param _poolAddress pool Address
   * @param start start from index
   * @param end until index
   * @return PoolShares[]
   */
  function getPoolShares(
    address _poolAddress,
    uint256 start,
    uint256 end
  ) external view returns (PoolShares[] memory) {
    uint256 counter = 0;
    uint256 i;
    for (i = start; i < pool[_poolAddress].poolShares.length || i > end; i++) {
      if (pool[_poolAddress].poolShares[i].owner != address(0)) counter++;
    }
    // since it's not possible to return dynamic length array
    // we need to count first, create the array using fixed length and then fill it
    PoolShares[] memory poolShares = new PoolShares[](counter);
    counter = 0;
    for (i = start; i < pool[_poolAddress].poolShares.length || i > end; i++) {
      if (pool[_poolAddress].poolShares[i].owner != address(0)) {
        poolShares[counter].owner = pool[_poolAddress].poolShares[i].owner;
        poolShares[counter].shares = pool[_poolAddress].poolShares[i].shares;
        counter++;
      }
    }
    return (poolShares);
  }

  /**
   * @dev getPoolSharesforUser
   *      Returns amount of pool shares locked by a user for a pool
   * @param _owner user address
   * @param _poolAddress pool Address
   * @return uint256
   */
  function getPoolSharesforUser(address _poolAddress, address _owner)
    external
    view
    returns (uint256)
  {
    uint256 i;
    for (i = 0; i < pool[_poolAddress].poolShares.length; i++) {
      if (pool[_poolAddress].poolShares[i].owner == _owner)
        return (pool[_poolAddress].poolShares[i].shares);
    }
    return (0);
  }

  /**
   * @dev canAddShares
   *      Checks if user can lock poolshares
   * @param _poolAddress pool Address
   * @return boolean
   */
  function canAddShares(address _poolAddress) public view returns (bool) {
    if (pool[_poolAddress].status == migrationStatus.allowed) return true;
    return false;
  }

  /**
   * @dev thresholdMet
   *      Checks if the threshold is met for a pool
   * @param poolAddress pool Address
   * @return boolean
   */
  function thresholdMet(address poolAddress) public view returns (bool) {
    if (pool[poolAddress].status != migrationStatus.allowed) return false;
    uint256 totalLP = IERC20(poolAddress).balanceOf(address(this));
    if (totalLP == 0) {
      return false;
    }
    uint256 totalLPSupply = IERC20(poolAddress).totalSupply();

    if (totalLPSupply.mul(BASE).div(totalLP) <= 1.25 ether) {
      return true;
    } else return false;
  }

  /**
     * @dev liquidate
     *      Liquidates a pool and sends OCEAN to OPF
     * @param poolAddress pool Address
     * @param minAmountsOut array of minimum amount of tokens expected 
          (see https://github.com/oceanprotocol/contracts/blob/main/contracts/balancer/BPool.sol#L519)
     */
  function liquidate(address poolAddress, uint256[] calldata minAmountsOut)
    external
    nonReentrant
  {
    require(
      pool[poolAddress].status == migrationStatus.allowed,
      'Current pool status does not allow to liquidate Pool'
    );
    // uint256 totalLPSupply = IERC20(poolAddress).totalSupply();
    /*require(
      thresholdMet(poolAddress) || pool[poolAddress].deadline < block.timestamp,
      'Threshold or deadline not met'
    ); // 80% of total LP required
    */
    require(
      pool[poolAddress].deadline < block.timestamp,
      'Threshold or deadline not met'
    ); // 80% of total LP required
    require(
      pool[poolAddress].totalSharesLocked > 0,
      'Cannot liquidate 0 shares'
    );
    uint256 oceanBalance = IERC20(oceanAddress).balanceOf(address(this));
    // we update the status
    pool[poolAddress].status = migrationStatus.completed;
    // - Withdraws all pool shares from V3 pool in one call (all shares at once, not per user)
    IV3Pool(poolAddress).exitPool(
      pool[poolAddress].totalSharesLocked,
      minAmountsOut
    );
    require(
      IERC20(poolAddress).balanceOf(address(this)) == 0,
      'Failed to redeem all LPTs'
    );

    // Store values for pool status
    pool[poolAddress].totalDTBurnt = IERC20(pool[poolAddress].dtV3Address)
      .balanceOf(address(this));
    uint256 newOceanBalance = IERC20(oceanAddress).balanceOf(address(this));
    pool[poolAddress].totalOcean = newOceanBalance.sub(oceanBalance);

    // - Burns all DTs
    require(
      IERC20(pool[poolAddress].dtV3Address).transfer(
        address(1),
        pool[poolAddress].totalDTBurnt
      ),
      'Failed to burn v3 DTs'
    );
    // send OCEAN to OPF
    require(
      IERC20(oceanAddress).transfer(OPFWallet, pool[poolAddress].totalOcean),
      'Failed to transfer OCEAN to OPF'
    );

    emit Completed(poolAddress, msg.sender, block.number);
  }
}
