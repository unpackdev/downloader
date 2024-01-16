// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IMagneticFieldGenerator.sol";
import "./IPlanet.sol";

// MagneticFieldGenerator is the master of Fermion. He can make Fermion and he is a fair machine.
contract MagneticFieldGenerator is IMagneticFieldGenerator, Ownable
{
	using SafeERC20 for IERC20;
	
	// Accumulated Fermion Precision
	uint256 private constant _ACC_FERMION_PRECISSION = 1e12;
	// The block number when FMN mining starts.
	uint256 private immutable _startBlock;
	// FMN tokens created per block.
	uint256 private _fermionPerBlock;
	// Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 private _totalAllocPoint; // Initializes with 0
	// The FMN TOKEN!
	IFermion private immutable _fermion;
	// The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMigratorDevice private _migrator;
	// The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMagneticFieldGenerator private _successor;
	IMagneticFieldGeneratorStore private _store;
	IPlanet private immutable _planet;

	constructor(IFermion fermion, IPlanet planet, uint256 fermionPerBlock, uint256 startBlock)
	{
		_fermion = fermion;
		_fermionPerBlock = fermionPerBlock;
		_startBlock = startBlock;
		_planet = planet;
		require(_fermion == _planet.token(), "MFG: Wrong Planet");
	}

	function setStore(IMagneticFieldGeneratorStore storeContract) override external onlyOwner
	{
		_store = storeContract;
	}

	/// @inheritdoc IMagneticFieldGenerator
	function add(uint256 allocPoint, IERC20 lpToken, uint256 lockPeriod) override public onlyOwner
	{
		// Do every time.
		// If a pool prevents massUpdatePools because of accFermionPerShare overflow disable the responsible pool with disablePool.
		massUpdatePools();
		uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
		_totalAllocPoint = _totalAllocPoint + allocPoint;
		if(lpToken == _fermion)
		{
			lpToken = _planet;
			// Approve Planet to transfer fermion tokens.
			_fermion.approve(address(_planet), type(uint256).max);
		}
		_store.newPoolInfo(
			PoolInfo({
				lpToken: lpToken,
				allocPoint: allocPoint,
				lastRewardBlock: lastRewardBlock,
				accFermionPerShare: 0,
				initialLock: lockPeriod > 0 ? lastRewardBlock + lockPeriod : 0
			})
		);
		
		emit LogPoolAddition(_unsafeSub(_store.getPoolLength(), 1), allocPoint, lpToken); // Overflow not possible.
	}

	// Deposit LP tokens to MagneticFieldGenerator for FMN allocation.
	function deposit(uint256 pid, uint256 amount, address to) override public
	{
		PoolInfo memory pool = updatePool(pid);
		UserInfo memory user = _store.getUserInfo(pid, to);

		user.amount = user.amount + amount;
		user.rewardDebt += int256(((amount * pool.accFermionPerShare) / _ACC_FERMION_PRECISSION));
		_store.updateUserInfo(pid, to, user); // Save changes

		
		// If the deposit token is Fermion exchange the correct amount with PlanetFermion Tokens.
		if(pool.lpToken == _planet)
		{
			// Grab the Fermions
			SafeERC20.safeTransferFrom(_fermion, address(_msgSender()), address(this), amount);
			// Exchange the Fermions and send PlanetTokens to MFG.
			_planet.enter(amount, address(this));
		}
		else
		{
			SafeERC20.safeTransferFrom(pool.lpToken, address(_msgSender()), address(this), amount);
		}
		emit Deposit(_msgSender(), pid, amount, to);
	}

	// Update the given pool's FMN allocation point to 0. Can only be called by the owner.
	// This is necessary if a pool reaches a accFermionPerShare overflow.
	function disablePool(uint256 pid) public override onlyOwner
	{
		// Underflow is impossible since _totalAllocPoint can not be lower that _poolInfo[pid].allocPoint.
		PoolInfo memory pi = _store.getPoolInfo(pid);
		_totalAllocPoint = _unsafeSub(_totalAllocPoint, pi.allocPoint);
		pi.allocPoint = 0;
		_store.updatePoolInfo(pid, pi);
	}

	// Withdraw without careing about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 pid, address to) public override
	{
		PoolInfo memory pool = _store.getPoolInfo(pid);
		require(pool.initialLock < block.number, "MFG: pool locked");
		UserInfo memory user = _store.getUserInfo(pid,_msgSender());

		uint256 userAmount = user.amount;

		if(pool.lpToken == _planet)
		{
			//Special Handling Fermion Pool
			_planet.leave(userAmount, address(this));
			SafeERC20.safeTransfer(_fermion, to, userAmount);
		}
		else
		{
			pool.lpToken.safeTransfer(to, userAmount);
		}
		emit EmergencyWithdraw(_msgSender(), pid, userAmount, to);
		user.amount = 0;
		user.rewardDebt = 0;
		_store.updateUserInfo(pid, _msgSender(), user);
	}

	function handOverToSuccessor(IMagneticFieldGenerator suc) override public onlyOwner
	{
		//TODO: DO ALL participants
		require(address(_successor) == address(0), "MFG: Successor already set");
		require(suc.owner() == address(this), "MFG: Successor not owned by this");
		_successor = suc;
		_fermion.transferOwnership(address(suc));
		_fermion.transfer(address(suc), _fermion.balanceOf(address(this)));
		// Hand over all pools no need for user interaction
		massUpdatePools();
		_store.transferOwnership(address(suc));
		_successor.setStore(_store);
		// Hand over Planet
		_planet.transferOwnership(address(suc));

		suc.transferOwnership(owner());
	}

	// Update reward variables for all pools. Be careful of gas spending!
	function massUpdatePools() public override
	{
		// Overflow of pid not possible and need not to be checked.
		unchecked
		{
			uint256 length = _store.getPoolLength();
			for (uint256 pid = 0; pid < length; ++pid)
			{
				updatePool(pid);
			}
		}
	}

	// Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
	function migrate(uint256 pid) override public onlyOwner
	{
		require(address(_migrator) != address(0), "migrate: no migrator");
		PoolInfo memory pool = _store.getPoolInfo(pid);
		IERC20 lpToken = pool.lpToken;
		uint256 bal = lpToken.balanceOf(address(this));
		lpToken.safeApprove(address(_migrator), bal);
		IERC20 newLpToken = IERC20(_migrator.migrate(lpToken));
		require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
		pool.lpToken = newLpToken;
		_store.updatePoolInfo(pid, pool);
		emit Migrate(pid, bal, lpToken, newLpToken);
	}

	/// @notice Leaves the contract without owner. Can only be called by the current owner.
	function renounceOwnership() public override(Ownable, IMagneticFieldGenerator)
	{
		Ownable.renounceOwnership();
	}

	// Update the given pool's FMN allocation point. Can only be called by the owner.
	function set(uint256 pid, uint256 allocPoint) override public onlyOwner
	{
		// Do every time.
		// If a pool prevents massUpdatePools because of accFermionPerShare overflow disable the responsible pool with disablePool.
		massUpdatePools();
		PoolInfo memory pi = _store.getPoolInfo(pid);
		// Underflow is impossible since _totalAllocPoint can not be lower that _poolInfo[pid].allocPoint.
		_totalAllocPoint = _unsafeSub(_totalAllocPoint, pi.allocPoint) + allocPoint;
		pi.allocPoint = allocPoint;
		_store.updatePoolInfo(pid, pi);
		emit LogSetPool(pid, allocPoint);
	}

	function setFermionPerBlock(uint256 fermionPerBlock) override public onlyOwner
	{
		massUpdatePools();
		_fermionPerBlock = fermionPerBlock;
	}

	// Set the migrator contract. Can only be called by the owner.
	function setMigrator(IMigratorDevice migratorContract) override public onlyOwner
	{
		_migrator = migratorContract;
	}

	/// @notice Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.
	function transferOwnership(address newOwner) public override(Ownable, IMagneticFieldGenerator)
	{
		Ownable.transferOwnership(newOwner);
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 pid) override public returns(PoolInfo memory)
	{
		PoolInfo memory pool = _store.getPoolInfo(pid);

		if (block.number <= pool.lastRewardBlock)
		{
			return pool;
		}

		uint256 lpSupply = pool.lpToken.balanceOf(address(this));

		if (lpSupply == 0)
		{
			pool.lastRewardBlock = block.number;
			_store.updatePoolInfo(pid, pool);
			return pool;
		}

		uint256 fermionReward = _getFermionReward(_getMultiplier(pool.lastRewardBlock, block.number), pool.allocPoint);
		pool.accFermionPerShare = _getAccFermionPerShare(pool.accFermionPerShare, fermionReward, lpSupply);
		_fermion.mint(address(this), fermionReward);
		pool.lastRewardBlock = block.number;
		_store.updatePoolInfo(pid, pool);
		emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accFermionPerShare);
		return pool;
	}

	// Harvests only Fermion tokens.
	function harvest(uint256 pid, address to) override public
	{
		// HINT: pool.accFermionPerShare can only grow till it overflows, at that point every withdraw will fail.
		// HINT: The owner can set pool allocPoint to 0 without pool reward update. After that all lp tokens can be withdrawn
		// HINT: including the rewards up to the the last sucessful pool reward update.
		PoolInfo memory pool = updatePool(pid);
		UserInfo memory user = _store.getUserInfo(pid, _msgSender());
		
		// Division of uint can not overflow.
		uint256 fermionShare = _unsafeDiv((user.amount *  pool.accFermionPerShare), _ACC_FERMION_PRECISSION);
		uint256 pending = uint256(int256(fermionShare) - user.rewardDebt);
		user.rewardDebt = int256(fermionShare);

		_store.updateUserInfo(pid, _msgSender(), user);
		// THOUGHTS on a previous Fermion balance check at this point
		// The intend was that if there was a rounding error and MFG does therefore not hold enouth Fermion 
		// the available amount of Fermion will be used.
		// BUT since all variables are used in divisions are uint especially accFermionPerShare.
		// Rounding errors can only appear in the form of cut of decimals.
		// A calculated fermionShare can therefor only be equal or smaller than the real value (with unlimited precision)
		// Therefore there should always be enough Fermion.
		_fermion.transfer(to, pending);
		emit Harvest(_msgSender(), pid, pending, to);
	}

	// Withdraw LP tokens from MagneticFieldGenerator.
	function withdraw(uint256 pid, uint256 amount, address to) override public
	{
		// HINT: pool.accFermionPerShare can only grow till it overflows, at that point every withdraw will fail.
		// HINT: The owner can set pool allocPoint to 0 without pool reward update. After that all lp tokens can be withdrawn
		// HINT: including the rewards up to the the last sucessful pool reward update.
		PoolInfo memory pool = updatePool(pid);
		require(pool.initialLock < block.number, "MFG: pool locked");
		UserInfo memory user =  _store.getUserInfo(pid, _msgSender());
		
		uint256 userAmount = user.amount;
		require(userAmount >= amount, "MFG: amount exeeds stored amount");

		uint256 accFermionPerShare = pool.accFermionPerShare;
		// Since we only withdraw rewardDept will be negative.
		user.rewardDebt = user.rewardDebt - int256(_unsafeDiv(amount * accFermionPerShare, _ACC_FERMION_PRECISSION));
		
		// Can not overflow. Checked with require.
		userAmount = _unsafeSub(userAmount, amount);
		user.amount = userAmount;
		_store.updateUserInfo(pid, _msgSender(), user);
		if(pool.lpToken == _planet)
		{
			//Special Handling Fermion Pool
			_planet.leave(amount, address(this));
			SafeERC20.safeTransfer(_fermion, to, amount);
		}
		else
		{
			pool.lpToken.safeTransfer(to, amount);
		}
		emit Withdraw(_msgSender(), pid, amount, to);
	}

	// Withdraw LP tokens from MagneticFieldGenerator.
	function withdrawAndHarvest(uint256 pid, uint256 amount, address to) override public
	{
		// HINT: pool.accFermionPerShare can only grow till it overflows, at that point every withdraw will fail.
		// HINT: The owner can set pool allocPoint to 0 without pool reward update. After that all lp tokens can be withdrawn
		// HINT: including the rewards up to the the last sucessful pool reward update.
		PoolInfo memory pool = updatePool(pid);
		require(pool.initialLock < block.number, "MFG: pool locked");
		UserInfo memory user = _store.getUserInfo(pid, _msgSender());
		
		uint256 userAmount = user.amount;
		require(userAmount >= amount, "MFG: amount exeeds stored amount");
		
		uint256 accFermionPerShare = pool.accFermionPerShare;

		// Division of uint can not overflow.
		uint256 pending = uint256(int256(_unsafeDiv((user.amount * accFermionPerShare), _ACC_FERMION_PRECISSION)) - user.rewardDebt);
		// THOUGHTS on a previous Fermion balance check at this point
		// The intend was that if there was a rounding error and MFG does therefore not hold enouth Fermion 
		// the available amount of Fermion will be used.
		// BUT since all variables are used in divisions are uint especially accFermionPerShare.
		// Rounding errors can only appear in the form of cut of decimals.
		// A calculated fermionShare can therefor only be equal or smaller than the real value (with unlimited precision)
		// Therefore there should always be enough Fermion.
		_fermion.transfer(to, pending);

		// Can not overflow. Checked with require.
		userAmount = _unsafeSub(userAmount, amount);
		user.amount = userAmount;
		// Division of uint can not overflow.
		user.rewardDebt = int256(_unsafeDiv(userAmount * accFermionPerShare, _ACC_FERMION_PRECISSION));
		_store.updateUserInfo(pid, _msgSender(), user);
		if(pool.lpToken == _planet)
		{
			//Special Handling Fermion Pool
			_planet.leave(amount, address(this));
			SafeERC20.safeTransfer(_fermion, to, amount);
		}
		else
		{
			pool.lpToken.safeTransfer(to, amount);
		}
		emit Withdraw(_msgSender(), pid, amount, to);
		emit Harvest(_msgSender(), pid, pending, to);
	}

	function getFermionContract() public override view returns (IFermion)
	{
		return _fermion;
	}

	function getFermionPerBlock() public override view returns (uint256)
	{
		return _fermionPerBlock;
	}

	function getStartBlock() public override view returns (uint256)
	{
		return _startBlock;
	}

	/// @notice Returns the current migrator.
	function migrator() override public view returns(IMigratorDevice)
	{
		return _migrator;
	}

	/// @notice Returns the address of the current owner.
	function owner() public view override(Ownable, IMagneticFieldGenerator) returns (address)
	{
		return Ownable.owner();
	}

	// View function to see pending FMNs on frontend.
	function pendingFermion(uint256 pid, address user) public view override returns (uint256)
	{
		PoolInfo memory pool = _store.getPoolInfo(pid);
		UserInfo memory singleUserInfo = _store.getUserInfo(pid, user);
		uint256 accFermionPerShare = pool.accFermionPerShare;
		uint256 lpSupply = pool.lpToken.balanceOf(address(this));
		if (block.number > pool.lastRewardBlock && lpSupply != 0)
		{
			accFermionPerShare = _getAccFermionPerShare(
				accFermionPerShare,
				_getFermionReward(_getMultiplier(pool.lastRewardBlock, block.number), pool.allocPoint)
				, lpSupply);
		}
		return uint256(int256(_unsafeDiv((singleUserInfo.amount * accFermionPerShare), _ACC_FERMION_PRECISSION)) - singleUserInfo.rewardDebt);
	}

	function poolInfo(uint256 pid) override public view returns (PoolInfo memory)
	{
		return _store.getPoolInfo(pid);
	}

	function poolLength() override public view returns (uint256)
	{
		return _store.getPoolLength();
	}

	/// @notice Returns the address of the sucessor.
	function successor() override public view returns (IMagneticFieldGenerator)
	{
		return _successor;
	}

	function totalAllocPoint() override public view returns (uint256)
	{
		return _totalAllocPoint;
	}

	function userInfo(uint256 pid, address user) override public view returns (UserInfo memory)
	{
		return _store.getUserInfo(pid, user);
	}

	function _getFermionReward(uint256 multiplier, uint256 allocPoint) private view returns (uint256)
	{
		// As long as the owner chooses sane values for _fermionPerBlock and pool.allocPoint it is unlikely that an overflow ever happens
		// Since _fermionPerBlock and pool.allocPoint are choosen by  the owner, it is the responsibility of the owner to ensure
		// that there is now overflow in multiplying these to values.
		// Divions can not generate an overflow if used with uint values. Div by 0 will always panic, wrapped or not.
		// The only place an overflow can happen (even very unlikeley) is if the multiplier gets big enouth to force an overflow.
		return _unsafeDiv(multiplier * _unsafeMul(_fermionPerBlock, allocPoint), _totalAllocPoint);
	}

	function _getAccFermionPerShare(uint256 currentAccFermionShare, uint256 fermionReward, uint256 lpSupply) private pure returns (uint256)
	{
		// Divions can not generate an overflow if used with uint values. Div by 0 will always panic, wrapped or not.

		// Check for overflow for automatic pool deactivation.
		return currentAccFermionShare + _unsafeDiv(fermionReward * _ACC_FERMION_PRECISSION, lpSupply); 
	}

	// Return reward multiplier over the given _from to _to block.
	function _getMultiplier(uint256 from, uint256 to) private pure returns (uint256)
	{
		unchecked
		{
			return to - from;
		}
	}

	function _unsafeDiv(uint256 a, uint256 b) private pure returns (uint256)
	{
		unchecked
		{
			return a / b;
		}
	}

	function _unsafeMul(uint256 a, uint256 b) private pure returns (uint256)
	{
		unchecked
		{
			return a * b;
		}
	}

	function _unsafeSub(uint256 a, uint256 b) private pure returns (uint256)
	{
		unchecked
		{
			return a - b;
		}
	}
}
