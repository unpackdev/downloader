// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./FixedPointMathLib.sol";
import "./RepoErrors.sol";

import "./IERC20.sol"; // interface

/// @title Banana Repo Project
/// @author Boonana
/// @notice A smart contract that allows one to sell repos of whitelisted tokens. Liquidity (repo buyers) is provided by users. If a repo seller does not repurchase their asset, it defaults to liquidity providers
contract BananaRepoProject is Ownable {

	/////////////////////////////////////////////////////////////////////////////
    //                                  Structs                                //
    /////////////////////////////////////////////////////////////////////////////
	struct repo {
		uint256 expirationTime;
		uint256 repoTokenAmount;
	}

	struct pendingDeposit {
		uint256 activationTime;
		uint256 amount;
	}

	/////////////////////////////////////////////////////////////////////////////
    //                                  Constants                              //
    /////////////////////////////////////////////////////////////////////////////
	
	address public immutable currencyToken;
	address public immutable repoToken;
	uint256 public constant PRECISION = 1e18;
	
	/////////////////////////////////////////////////////////////////////////////
    //                                  Storage                                //
    /////////////////////////////////////////////////////////////////////////////

	mapping (address => uint256) public userCurrencyBalances; // how much each address is owed in Currency Token
	address[] public clearedDepositorsList;
	uint256 public totalClearedBalance; // sum of the balances in userCurrencyBalances
	uint256 public totalEligibleBalance; // sum of the balances in userCurrencyBalances, minus any that are "reserved" in other repos. i.e. the amount that can be used for another repo at the moment
	mapping (address => uint256) public userDefaultBalances;  // how much each address is owed in repoToken
	
	//  Implementation notes:
	// 1. When you deposit, your deposit will go in as a pending deposit with an activation time set pendingTime seconds in the future. In other words, your deposit will only be able to participate after the activation time.
	// 2. If you deposit and you have previous pending deposits whose pending time has not yet passed, your deposited amount will be added to the pending balance and the activation time will reset. 
	// THEY WILL NOT BE CONSIDERED TWO DIFFERENT DEPOSITS WITH TWO DIFFERENT PENDING TIMES.
	// 3. However, every time you deposit, the code will first clear any pending deposits of yours whose activationTime have passed automatically, so rest assured cleared pending deposits will not be reset. 
	// 4. Whenever a repo is initiated, all pending deposits whose activation time have passed will be cleared.
	// 5. You can withdraw before activationTime has passed on a pending deposit; the activation time only applies to if the money can be used in repos.
	// 6. If you have both pending and active balances, and withdraw, the balance will first be taken out of your pending balance - LIFO.

	mapping (address => pendingDeposit) public pendingBalances; // deposits that are not eligible to participate in repo transactions yet. If you deposit again before these activate, your time will restart. 
	address[] public pendingAddressList; // list of addresses currently with pending balances

	mapping (address => repo) public activeRepos; // stores all active repos at the moment
	address[] public reposUsersList;
	uint256 public repoSellPrice;
	uint256 public repoBuybackPrice;
	uint256 public repoTimeLength;
	uint256 public pendingTime; // a pending time can be set to prevent users from only depositing when repos have been bought and not depositing otherwise. Would make sense to be set equal to repoTimeLength
	uint256 public withdrawActivationTime; // after a default, all individuals must wait defaultWithdrawBuffer time to withdraw. Default set to 0.
	uint256 public defaultWithdrawBuffer; // buffer to add after a withdraw to guard against any attacks via the default code. Default is set to 0
	bool public reposPaused; // default set to false;
	
	/////////////////////////////////////////////////////////////////////////////
    //                                  Events                                 //
    /////////////////////////////////////////////////////////////////////////////
    event Deposit(address indexed user, uint256 amount);
	event Withdraw(address indexed user, address indexed token, uint256 amount);
	event repoSold(address indexed seller, uint256 repoTokenAmount, uint256 currencyTokenAmount);
	event repoBoughtBack(address indexed buyer, uint256 repoTokenAmount, uint256 currencyTokenAmount);
	event repoDefault(address indexed defaulter, uint256 repoTokenAmount, uint256 currencyTokenAmount);

	/////////////////////////////////////////////////////////////////////////////
    //                                  CONSTRUCTOR                            //
    /////////////////////////////////////////////////////////////////////////////
	// @notice constructor
	// @param _currencyToken Address of the currency token.
    // @param _repoToken Address of the repo token - the token the contract has open repo bids for.
    // @param _repoSellPrice Sell price for 1e18 units of repoToken. Necessary since you can't store fractions :(.
    // @param _repoBuybackPrice Buyback price for 1e18 shares of repoToken. Necessary to do price fo 1e18 since you can't store fractions :(.
    // @param _repoTimeLength Amount of time in seconds before a buyback option for a repo expires.
	// @param _pendingTime Amount of time in seconds before deposited funds can participate in repo transactions
	constructor(address _currencyToken, address _repoToken,  uint256 _repoSellPrice, uint256 _repoBuybackPrice, uint256 _repoTimeLength, uint256 _pendingTime) Ownable(_msgSender()) {
		currencyToken = _currencyToken;
		repoToken = _repoToken;
		repoSellPrice = _repoSellPrice;
		repoBuybackPrice = _repoBuybackPrice;
		repoTimeLength = _repoTimeLength;
		pendingTime = _pendingTime;
	}

	/////////////////////////////////////////////////////////////////////////////
    //                                   VIEWS                                 //
    /////////////////////////////////////////////////////////////////////////////

	// @notice shows how much _address is owed in both tokens (currencyToken and repoToken). Note this may not be withdrawable at the moment if some funds were used to buy repos.
	// @param _address the address to check owed balance for
	function getOwedBalance(address _address) external view returns (uint256, uint256) {
		return (pendingBalances[_address].amount + userCurrencyBalances[_address], userDefaultBalances[_address]);
	}

	// @notice shows how much _address can currently withdraw in both tokens (currencyToken and repoToken). Note they may be owed more, but some is not withdrawable because it is currently used to buy repos. Both pending and cleared balances are withdrawable.
	// @param _address the address to check withdrawable balance for
	function getWithdrawableBalance(address _address) external view returns (uint256, uint256) {
		uint256 withdrawableCurrencyBalance = (totalEligibleBalance > userCurrencyBalances[_address]) ? (userCurrencyBalances[_address] + pendingBalances[_address].amount) : (totalEligibleBalance + pendingBalances[_address].amount);
		return (withdrawableCurrencyBalance, userDefaultBalances[_address]);
	}

	// @notice returns true if the repo for a given address is expired, returns false if not or if the user does not have an active repo
	// @param the user whose repos to check
	function checkRepoExpiration(address _address) external view returns (bool) {

		uint256 expirationTime = activeRepos[_address].expirationTime;
		if (expirationTime == 0) {
			return false;
		} else if (block.timestamp > expirationTime) {
			return true;
		} else {
			return false;
		}
	}

	// @notice protocol earns money off rounding errors (i.e. if 10 tokens are split 1/3 1/3 1/3, then those are all roudned down and the remainder is protocol profit) or when there are no cleared balances when a repo is bought back (rare)
	// protocol profit as a result should be very small, but is always borrowable as it is included in totalEligibleBalance
	function getProtocolProfits() public view returns (uint256, uint256) {
		
		uint256 contractCurrencyBalance = IERC20(currencyToken).balanceOf(address(this));
		
		uint256 pendingListLength = pendingAddressList.length;
		uint256 pendingBalanceSum;
		for (uint256 i=0; i<pendingListLength; ++i) {
			pendingBalanceSum += pendingBalances[pendingAddressList[i]].amount;
		}

		uint256 currencyTokenProfit = contractCurrencyBalance - totalEligibleBalance - pendingBalanceSum;

		uint256 repoListLength = reposUsersList.length;
		uint256 repoTokenAmountSum;
		for (uint256 i = 0; i<repoListLength; ++i) {
			repoTokenAmountSum += activeRepos[reposUsersList[i]].repoTokenAmount;
		}

		uint256 clearedDepositorLength = clearedDepositorsList.length;
		uint256 defaultBalanceSum;
		for (uint256 i = 0; i<clearedDepositorLength; ++i) {
			defaultBalanceSum += userDefaultBalances[clearedDepositorsList[i]];
		}
		
		return (currencyTokenProfit, IERC20(repoToken).balanceOf(address(this)) - repoTokenAmountSum - defaultBalanceSum);
	}

	// @notice Checks the maximum amount of currencyToken available to buy a repo with at the moment in the protocol
	function getTotalCurrencyAvailableForRepo() external view returns (uint256) {

		uint256 pendingListLength = pendingAddressList.length;
		uint256 pendingBalanceSum;
		uint256 curTimestamp = block.timestamp;
		for (uint256 i=0; i<pendingListLength; ++i) {
			if (curTimestamp > pendingBalances[pendingAddressList[i]].activationTime) {
				pendingBalanceSum += pendingBalances[pendingAddressList[i]].amount;
			}
		}

		return (pendingBalanceSum + totalEligibleBalance);
	}

	/////////////////////////////////////////////////////////////////////////////
    //                                  CORE - DEPOSITORS                      //
    /////////////////////////////////////////////////////////////////////////////

	/// @notice Deposit funds into the user's balance.
	/// @param _amount The amount to deposit.
	function depositFunds(uint256 _amount) external {

		IERC20(currencyToken).transferFrom(msg.sender, address(this), _amount);

		_clearPendingBalanceUser(msg.sender); // if there are any pending balances by this user, first clear them
		uint256 currentTime = block.timestamp;
		if (_amount == 0) return; // nothing to do
		if (pendingBalances[msg.sender].amount == 0) {

			// if it doesn't exist yet, add to pendingAddressList
			pendingAddressList.push(msg.sender);
		} 

		pendingBalances[msg.sender].amount += _amount; // 
		pendingBalances[msg.sender].activationTime = currentTime + pendingTime; // activation time reset
		
		emit Deposit(msg.sender, _amount);
	}

	/// @notice 
	/// @param _token is the token to withdraw
	/// @param _amount is the amount to withdraw
	function withdrawFunds(address _token, uint256 _amount) external {

		if (block.timestamp < withdrawActivationTime) revert RepoErrors.CannotWithdrawUntilWithdrawActivationTime();

		if (_token == currencyToken) {
			
			uint256 currentBalance = userCurrencyBalances[msg.sender];
			uint256 pendingBalance = pendingBalances[msg.sender].amount;
			if (currentBalance + pendingBalance < _amount) revert RepoErrors.InsufficientBalance();

			if (_amount >= pendingBalance) {

				// we subtract from pending balance first to benefit depositor the most; LIFO
				uint256 remainingBalance = (_amount- pendingBalance);
				// see RepoErros.sol for explanation
				if (totalEligibleBalance < remainingBalance) revert RepoErrors.WithdrawingMoreThanEligible();

				userCurrencyBalances[msg.sender] -= remainingBalance;
				if (currentBalance == remainingBalance) {

					_removeClearedDepositorsListUser(msg.sender); // the user has no cleared balance left
				}

				totalClearedBalance -= remainingBalance;
				totalEligibleBalance -= remainingBalance;

				delete pendingBalances[msg.sender];
				_removePendingAddressListUser(msg.sender);
			} else {

				pendingBalances[msg.sender].amount -= _amount; // we subtract from pending balance first to benefit depositor the most; LIFO
			}

			IERC20(currencyToken).transfer(msg.sender, _amount);
			
		} else if (_token == repoToken) {

			// amount of tokens user currently is owed
			if (userDefaultBalances[msg.sender] < _amount) revert RepoErrors.InsufficientBalance();

			userDefaultBalances[msg.sender] -= _amount;
			IERC20(repoToken).transfer(msg.sender, _amount);
		} else {

			revert RepoErrors.InvalidToken();
		}

		emit Withdraw(msg.sender, _token, _amount);
	}

	/// @notice Allows users to withdraw their total owed balance. Note: may fail if some owed balance is currently part of a sold repo
 	/// @dev External function that allows users to withdraw their available balances for currency and repo tokens.
	function withdrawAll() external {

		if (block.timestamp < withdrawActivationTime) revert RepoErrors.CannotWithdrawUntilWithdrawActivationTime();

		uint256 userClearedBalance = userCurrencyBalances[msg.sender];
		uint256 userPendingBalance = pendingBalances[msg.sender].amount;
		uint256 userCurrencyBalance = userClearedBalance + userPendingBalance;
		uint256 userDefaultBalance = userDefaultBalances[msg.sender];

		if (userCurrencyBalance == 0 && userDefaultBalance == 0) revert RepoErrors.NothingToWithdraw();
		if (userClearedBalance > totalEligibleBalance) revert RepoErrors.WithdrawingMoreThanEligible();

		if (userCurrencyBalance > 0) {

			if (userPendingBalance > 0) {
				delete pendingBalances[msg.sender];
				_removePendingAddressListUser(msg.sender);
			}

			totalClearedBalance -= userClearedBalance;
			totalEligibleBalance -= userClearedBalance;
			delete userCurrencyBalances[msg.sender];			

			IERC20(currencyToken).transfer(msg.sender, userCurrencyBalance);
			emit Withdraw(msg.sender, currencyToken, userCurrencyBalance);
		}

		if (userDefaultBalance > 0) {

			delete userDefaultBalances[msg.sender];
			IERC20(repoToken).transfer(msg.sender, userDefaultBalance);
			emit Withdraw(msg.sender, repoToken, userDefaultBalance);
		}

		_removeClearedDepositorsListUser(msg.sender);
	}
	/////////////////////////////////////////////////////////////////////////////
    //                                  CORE - REPO SELLERS                    //
    /////////////////////////////////////////////////////////////////////////////

	/// @notice Allows the selling of repo tokens.
	/// @param _repoTokenAmount The amount of repo tokens to sell.
	function sellRepo(uint256 _repoTokenAmount) external {

		if (reposPaused) revert RepoErrors.RepoPaused();
		if (activeRepos[msg.sender].repoTokenAmount > 0) revert RepoErrors.RepoAlreadyExistsForUser();

		clearPendingBalances(); // any pending balances, clear, to maximize totalEligibleBalance
		uint256 currencyTokenAmount = _repoTokenAmount*repoSellPrice/PRECISION;

		if (currencyTokenAmount > totalEligibleBalance) revert RepoErrors.InsufficientEligibleCurrencyAmount();

		IERC20(repoToken).transferFrom(msg.sender, address(this), _repoTokenAmount);
		IERC20(currencyToken).transfer(msg.sender, currencyTokenAmount);

		uint256 expirationTime = block.timestamp + repoTimeLength;
		activeRepos[msg.sender].expirationTime = expirationTime;
		activeRepos[msg.sender].repoTokenAmount = _repoTokenAmount;
		reposUsersList.push(msg.sender);

		totalEligibleBalance -= currencyTokenAmount;
		emit repoSold(msg.sender, _repoTokenAmount, currencyTokenAmount);
	}

	// @notice Allows the buyback of repo tokens.
	function buybackRepo() external {
		
		repo memory userRepo = activeRepos[msg.sender];
		if (userRepo.expirationTime == 0) revert RepoErrors.NoActiveRepoForUser();
		// if (block.timestamp > userRepo.expirationTime) revert RepoErrors.RepoExpired();

		uint256 currencyTokenAmount = userRepo.repoTokenAmount*repoBuybackPrice/PRECISION;

		IERC20(currencyToken).transferFrom(msg.sender, address(this), currencyTokenAmount);
		IERC20(repoToken).transfer(msg.sender, userRepo.repoTokenAmount);

		clearPendingBalances(); // a bit of a tough design decision. But basically if your balance is cleared before the repo is bought back, then you benefit, even if you weren't cleared at time of deposit
		// the alternative is to only _clearPendingBalances() before the repo is sold. But then deposit also clears pending repos, so say, if pendingTime and repoTimeLength are 24 hours:
		// first deposit is T-23 hours.
		// repo is sold at T+0 hours
		// if repo isn't repaid at T+1 hour, someone could deposit again $1 and cause their balance to clear
		// so the criteria then becomes "to guarantee eligibility without extra work deposit 24 hours before repo is sold, otherwise, with extra work you can guarantee eligibility if you deposit 24 hours before repo is repaid" 
		uint256 newBalanceAdded = currencyTokenAmount - userRepo.repoTokenAmount*repoSellPrice/PRECISION;
		uint256 totalClearedBalanceCopy = totalClearedBalance; // don't call this each time from storage, just save a copy in memory to save gas

		uint256 listLength = clearedDepositorsList.length;
		for (uint256 i=0; i < listLength; ++i) {
			uint256 balanceToAdd = userCurrencyBalances[clearedDepositorsList[i]] * newBalanceAdded / totalClearedBalanceCopy;
			userCurrencyBalances[clearedDepositorsList[i]] += balanceToAdd; // everyone's balance increases yay
			totalClearedBalance += balanceToAdd;
		}

		totalEligibleBalance += (userRepo.repoTokenAmount*repoSellPrice/PRECISION + totalClearedBalance - totalClearedBalanceCopy);

		delete activeRepos[msg.sender];
		_removeReposUsersListUser(msg.sender);

		emit repoBoughtBack(msg.sender, userRepo.repoTokenAmount, currencyTokenAmount);
	}

	function defaultRepo(address _address) external {

		repo memory userRepo = activeRepos[_address];
		if (userRepo.expirationTime == 0) revert RepoErrors.NoActiveRepo(); // nothing to do
		if (block.timestamp <= userRepo.expirationTime) revert RepoErrors.RepoStillActive();
		if (block.timestamp > userRepo.expirationTime) { // repo has indeed expired

			clearPendingBalances();
			uint256 lostCurrencyBalance = userRepo.repoTokenAmount*repoSellPrice/PRECISION;
			uint256 totalClearedBalanceCopy = totalClearedBalance; // don't call this each time from storage, just save a copy in memory to save gas
			
			// see error explanation in RepoErrors.sols. This *shouldn't* be possible at the moment because withdrawals greater than totalEligibleBalance are not permitted, but having this check just in case
			if (totalClearedBalanceCopy < lostCurrencyBalance) revert RepoErrors.InsufficientClearedDeposits(); 

			// high level this is what we want to do:
			// We want to remove lostCurrencyBalance across the cleared balances, and distribute userRepo.repoTokenAmount across those
			// Solidity division rounds towards zero. So we must be careful and err towards removing AT LEAST lostCurrencyBalance, and distributing AT MOST userRepo.repoTokenAmount, with excess going to protocol
			// 1. we can do this for currency balances by adjusting each to be the same percentage as [totalClearedBalance - lostCurrencyBalance] as they are now of totalClearedBalance
			// NOTE: we CANNOT subtract the amount to be subtracted multiplied proportionately across the balances, as rounding in that case may result in removing LESS than lostCurrencyBalance in total
			// 2. we can do this for repo balances by assigning the same current percentage to the repo tokens being distributed
			uint256 tempNewTotalClearedBalance = totalClearedBalance - lostCurrencyBalance; 
			uint256 listLength = clearedDepositorsList.length;
			for (uint256 i=0; i < listLength; ++i) {

				address userAddress = clearedDepositorsList[i];
				userDefaultBalances[userAddress] += userCurrencyBalances[userAddress]*userRepo.repoTokenAmount /totalClearedBalanceCopy; // as noted in 2)
				
				uint256 currencyBalanceOld = userCurrencyBalances[userAddress];
				userCurrencyBalances[userAddress] = currencyBalanceOld * tempNewTotalClearedBalance / totalClearedBalanceCopy; // as noted in 1)
				uint256 currencyBalanceSubtracted = currencyBalanceOld - userCurrencyBalances[userAddress];
				totalClearedBalance -= currencyBalanceSubtracted;

				if ((userCurrencyBalances[userAddress] == 0) && (userDefaultBalances[userAddress] ==0)) _removeClearedDepositorsListUser(userAddress);
			}

			// if removed MORE than lostCurrencyBalance, subtract excess from totalEligibleBalance
			totalEligibleBalance -= (tempNewTotalClearedBalance - totalClearedBalance);

			delete activeRepos[_address];
			_removeReposUsersListUser(_address);

			withdrawActivationTime = block.timestamp + defaultWithdrawBuffer;
			
			emit repoDefault(_address, userRepo.repoTokenAmount, lostCurrencyBalance);
		}


	}

	// @notice Allows the owner to modify the repo sell price.
	function editRepoSellPrice(uint256 _price) external onlyOwner {
		repoSellPrice = _price;
	}

	// @notice Allows the owner to modify the repo buyback price.
	function editRepoBuybackPrice(uint256 _price) external onlyOwner {
		repoBuybackPrice = _price;
	}

	// @notice Allows the owner to modify the repo time length.
	function editRepoTimeLength(uint256 _seconds) external onlyOwner {
		repoTimeLength = _seconds;
	}

	// @notice Allows the owner to modify the pending time.
	function editPendingTime(uint256 _seconds) external onlyOwner {
		pendingTime = _seconds;
	}

	// @notice Allows the owner to pause repos.
	function pauseRepos() external onlyOwner {
		reposPaused = true;
	}

	// @notice Allows the owner to unpause repos.
	function unpauseRepos() external onlyOwner {
		reposPaused = false;
	}

	// @notice Allows the owner edit the withdrawActivationTime
	function editWithdrawActivationTime(uint256 _timestamp) external onlyOwner {
		withdrawActivationTime = _timestamp;
	}

	// @notice Allows the owner to edit the default withdraw buffer.
	function editDefaultWithdrawBuffer(uint256 _seconds) external onlyOwner {
		defaultWithdrawBuffer = _seconds;
	}


	/////////////////////////////////////////////////////////////////////////////
    //                                  CORE - HELPERS                         //
    /////////////////////////////////////////////////////////////////////////////

	/// @notice Clears pending balances by checking their activation time and moving the amounts to the users' currency balances if the activation time has passed.
	function clearPendingBalances() public {

		uint256 i = 0;
		uint256 currentTimestamp = block.timestamp;

		uint256 totalAmountCleared;
		uint256 pendingAddressListLength = pendingAddressList.length; // saves gas to store in memory vs read each time from storage
    	while (i < pendingAddressListLength) {
			
			address userAddress = pendingAddressList[i];
			pendingDeposit memory pendingDepositUser = pendingBalances[userAddress];

			if (currentTimestamp >= pendingDepositUser.activationTime) {
				
				// add to list if first time depositor
				if (userCurrencyBalances[userAddress] == 0) {
					clearedDepositorsList.push(userAddress);
				}

				userCurrencyBalances[userAddress] += pendingDepositUser.amount;
				totalAmountCleared += pendingDepositUser.amount;

				delete pendingBalances[userAddress];
				_removePendingAddressList(i);
				pendingAddressListLength -= 1; //reassign now that length is different
			} else {
				// Increment 'i' only when not removing the element to stay at the same index
				++i;
			}
    	}

		// write to storage just once at the end to save gas
		totalClearedBalance += totalAmountCleared;
		totalEligibleBalance += totalAmountCleared;
	}

	/// @notice Clears pending balances for a specified user address based on the activation time; if current timestamp is past activation time, the user's pending balance is added to their userCurrencyBalance.
	/// @param _address The address for which pending balances need to be cleared.
	function _clearPendingBalanceUser(address _address) internal {

		pendingDeposit memory pendingDepositUser = pendingBalances[_address]; // saves gas to cache in memory
		if (pendingDepositUser.amount == 0) return; // user does not have pending Balance
		
		uint256 currentTimestamp = block.timestamp;
		if (currentTimestamp >= pendingDepositUser.activationTime) {

			// add to list if first time depositor
			if (userCurrencyBalances[_address] == 0) clearedDepositorsList.push(_address);

			userCurrencyBalances[_address] += pendingDepositUser.amount;
			totalClearedBalance += pendingDepositUser.amount;
			totalEligibleBalance += pendingDepositUser.amount;

			delete pendingBalances[_address];
			_removePendingAddressListUser(_address);
		}
	}

	/// @notice Removes a specific user address from pending balance list.
	/// @param _address The address to remove from pending balance list.
	function _removePendingAddressListUser(address _address) internal {

		uint256 listLength = pendingAddressList.length;
		for (uint256 i = 0; i < listLength; ++i) {
			if (pendingAddressList[i] == _address) {
				_removePendingAddressList(i);
				break; // end the function after we find the user, as they should only appear once
			}
		}
	}

	/// @notice Remove a user from the pending balance list at the specified index in the array.
	/// @param _index The index of the address in pendingAddressList to remove
	function _removePendingAddressList(uint256 _index) internal {

		uint256 listLength = pendingAddressList.length;
        if (_index > listLength) revert RepoErrors.InvalidIndex();

		// remove from pending address list
		pendingAddressList[_index] = pendingAddressList[listLength - 1];
		pendingAddressList.pop();

	} 

	/// @notice Removes a specific user address from cleared deposit list.
	/// @param _address The address to remove from cleared deposit list.
	function _removeClearedDepositorsListUser(address _address) internal {

		uint256 listLength = clearedDepositorsList.length;
		for (uint256 i = 0; i < listLength; ++i) {
			if (clearedDepositorsList[i] == _address) {
				_removeClearedDepositorsList(i);
				break; // end the function after we find the user, as they should only appear once
			}
		}
	}

	/// @notice Remove a user from the cleared Deposit list at the specified index in the array.
	/// @param _index The index of the address in clearedDepositList to remove
	function _removeClearedDepositorsList(uint256 _index) internal {
		
		uint256 listLength = clearedDepositorsList.length;
        if (_index > listLength) revert RepoErrors.InvalidIndex();

		// remove from pending address list
		clearedDepositorsList[_index] = clearedDepositorsList[listLength - 1];
		clearedDepositorsList.pop();

	} 

	/// @notice Removes a specific user address from repos users list.
	/// @param _address The address to remove from repos users list.
	function _removeReposUsersListUser(address _address) internal {

		uint256 listLength = reposUsersList.length;
		for (uint256 i = 0; i < listLength; ++i) {
			if (reposUsersList[i] == _address) {
				_removeReposUsersList(i);
				break; // end the function after we find the user, as they should only appear once
			}
		}
	}

	/// @notice Remove a user from the repos users list at the specified index in the array.
	/// @param _index The index of the address in reposUsersList to remove
	function _removeReposUsersList(uint256 _index) internal {
		
		uint256 listLength = reposUsersList.length;
        if (_index > listLength) revert RepoErrors.InvalidIndex();

		// remove from pending address list
		reposUsersList[_index] = reposUsersList[listLength - 1];
		reposUsersList.pop();

	}

	/////////////////////////////////////////////////////////////////////////////
    //                                  CORE - ADMIN                           //
    ///////////////////////////////////////////////////////////////////////////// 

	/// @notice for emergency use if the owner needs to withdraw all tokens. If withdrawing protocol profits, should use protocolProfitWithdraw
	/// @param _tokenAddress the address of the token to withdraw
	/// @param _amount the amount of the token to withdraw
	function adminWithdraw(address _tokenAddress, uint256 _amount) external onlyOwner {

		IERC20(_tokenAddress).transfer(msg.sender, _amount);
		
	}

	/// For withdrawing protocol profits
	function protocolProfitWithdraw() external onlyOwner {

		(uint256 protocolCurrencyProfits, uint256 protocolRepoProfits) = getProtocolProfits();
		IERC20(currencyToken).transfer(msg.sender, protocolCurrencyProfits);
		IERC20(repoToken).transfer(msg.sender, protocolRepoProfits);
	}
}