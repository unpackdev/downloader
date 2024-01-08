// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract IPhoenix {
	function getTotalLevels(address _user) external view returns(uint256){}
}
/**
 ______     __         ______     ______     ______    
/\  == \   /\ \       /\  __ \   /\___  \   /\  ___\   
\ \  __<   \ \ \____  \ \  __ \  \/_/  /__  \ \  __\   
 \ \_____\  \ \_____\  \ \_\ \_\   /\_____\  \ \_____\ 
  \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/ 

*/


contract Blaze is ERC20, Ownable {

	using SafeMath for uint256;
	
	mapping(address => uint) lastUpdate;

	mapping(address => bool) burnAddresses;

	mapping(address => uint) tokensOwed;

	IPhoenix[] public phoenixContracts;

	uint[] ratePerLevel;

	constructor() ERC20("Blaze", "BLAZE") {

	}

	/**
	 __     __   __     ______   ______     ______     ______     ______     ______   __     ______     __   __    
	/\ \   /\ "-.\ \   /\__  _\ /\  ___\   /\  == \   /\  __ \   /\  ___\   /\__  _\ /\ \   /\  __ \   /\ "-.\ \   
	\ \ \  \ \ \-.  \  \/_/\ \/ \ \  __\   \ \  __<   \ \  __ \  \ \ \____  \/_/\ \/ \ \ \  \ \ \/\ \  \ \ \-.  \  
	 \ \_\  \ \_\\"\_\    \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_____\    \ \_\  \ \_\  \ \_____\  \ \_\\"\_\ 
	  \/_/   \/_/ \/_/     \/_/   \/_____/   \/_/ /_/   \/_/\/_/   \/_____/     \/_/   \/_/   \/_____/   \/_/ \/_/ 

	*/
	                                                                                                               
	/*
	* @dev updates the tokens owed and the last time the user updated, called when leveling up a phoenix or minting
	* @dev _userAddress is the address of the user to update
	*/
	function updateTokens(address _userAddress) external {

		if (_userAddress != address(0)) {

			uint lastTime = lastUpdate[_userAddress];
			
			uint currentTime = block.timestamp;

			lastUpdate[_userAddress] = currentTime;
 
			IPhoenix[] memory phoenix_contracts = phoenixContracts;

			uint[] memory ratePerLev = ratePerLevel; 

			if(lastTime > 0) {

				uint claimable;

				for(uint i = 0; i < phoenix_contracts.length; i++) {

					claimable += phoenix_contracts[i].getTotalLevels(_userAddress).mul(ratePerLev[i]);

				}
 
				tokensOwed[_userAddress] += claimable.mul(currentTime - lastTime).div(86400);
			}
			
		}

	}

	/**
	* @dev called on token transfer, and updates the tokens owed and last update for each user involved in the transaction
	* @param _fromAddress is the address the token is being sent from
	* @param _toAddress is the address the token is being sent to
	*/
	function updateTransfer(address _fromAddress, address _toAddress) external {

		uint currentTime = block.timestamp;

		uint claimable;

		uint timeDifference;

		uint lastTime;

		IPhoenix[] memory phoenix_contracts = phoenixContracts;

		uint[] memory ratePerLev = ratePerLevel;

		if(_fromAddress != address(0)) {

			lastTime = lastUpdate[_fromAddress];
			lastUpdate[_fromAddress] = currentTime;

			if(lastTime > 0) {

				claimable = 0;

				timeDifference = currentTime - lastTime;

				for(uint i = 0; i < phoenix_contracts.length; i++) {

					claimable += phoenix_contracts[i].getTotalLevels(_fromAddress).mul(ratePerLev[i]);

				}
 
				tokensOwed[_fromAddress] += claimable.mul(timeDifference).div(86400);
			}

		}

		if(_toAddress != address(0)) {

			lastTime = lastUpdate[_toAddress];
			lastUpdate[_toAddress] = currentTime;

			if(lastTime > 0) {

				claimable = 0;

				timeDifference = currentTime - lastTime;

				for(uint i = 0; i < phoenix_contracts.length; i++) {

					claimable += phoenix_contracts[i].getTotalLevels(_toAddress).mul(ratePerLev[i]);

				}
 
				tokensOwed[_toAddress] += claimable.mul(timeDifference).div(86400);
			}

		}

	}

	/**
	* @dev claims tokens generated and mints into the senders wallet
	*/
	function claim() external {

    	address sender = _msgSender();

    	uint lastUpdated = lastUpdate[sender];
    	uint time = block.timestamp;

    	require(lastUpdated > 0, "No tokens to claim");

    	lastUpdate[sender] = time;

    	uint unclaimed = getPendingTokens(sender, time - lastUpdated);

    	if(tokensOwed[sender] > 0) {

    		unclaimed += tokensOwed[sender];
    		tokensOwed[sender] = 0;

    	}

    	require(unclaimed > 0, "No tokens to claim");

    	_mint(sender, unclaimed);

    }

    /**
    * @dev burns the desired amount of tokens from the wallet, this can only be called by accepted addresses, prefers burning owed tokens over minted
    * @param _from is the address to burn the tokens from
    * @param _amount is the number of tokens attempting to be burned
    */
	function burn(address _from, uint256 _amount) external {

		require(burnAddresses[_msgSender()] == true, "Don't have permission to call this function");

		uint owed = tokensOwed[_from];	

		if(owed >= _amount) {
			tokensOwed[_from] -= _amount;
			return;
		}

		uint balance = balanceOf(_from);

		if(balance >= _amount) {
			_burn(_from, _amount);
			return;

		}

		if(balance + owed >= _amount) {

			tokensOwed[_from] = 0;

			_burn(_from, _amount - owed);

			return;

		}

		uint lastUpdated = lastUpdate[_from];

		require(lastUpdated > 0, "User doesn't have enough blaze to complete this action");

		uint time = block.timestamp;

		uint claimable = getPendingTokens(_from,  time - lastUpdated);

		lastUpdate[_from] = time;

		if(claimable >= _amount) {

			tokensOwed[_from] += claimable - _amount;
			return;

		} 

		if(claimable + owed >= _amount) {

			tokensOwed[_from] -= _amount - claimable;
			return;

		}

		if(balance + owed + claimable >= _amount) {

			tokensOwed[_from] = 0;

			_burn(_from, _amount - (owed + claimable));

			return;

		}

		revert("User doesn't have enough blaze available to complete this action");

			
	}


	/**
	 ______     ______     ______     _____    
	/\  == \   /\  ___\   /\  __ \   /\  __-.  
	\ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ 
	 \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____- 
	  \/_/ /_/   \/_____/   \/_/\/_/   \/____/ 
                                          
    */

    /**
    * @dev returns the last time an address has updated with the contract
    * @param _userAddress is the user address that wants the know the time
    */
	function lastUpdateTime(address _userAddress) public view returns(uint) {
		return lastUpdate[_userAddress];
	}

	/**
	* @dev Gets the total tokens that are available to be claimed and minted for a given address
	* @param _userAddress is the address that the claimable tokens are calculated for
	*/
	function getClaimableTokens(address _userAddress) public view returns(uint) {
		return tokensOwed[_userAddress] + getPendingTokens(_userAddress);
	}

	/**
	* @dev returns the tokens accounted for but not minted for a given address
	* @param _userAddress is the address that wants to know whats owed
	*/
	function getTokensOwed(address _userAddress) public view returns(uint) {
		return tokensOwed[_userAddress];
	}

	
	/**
	* @dev recieves the pending tokens yet to be accounted for
	* @param _userAddress is the address which the pending tokens are being calculated for
	* @param _timeDifference is the current time minus the last time the _userAddress was updated
	*/
	function getPendingTokens(address _userAddress, uint _timeDifference) public view returns(uint) {

		uint claimable;

		for(uint i = 0; i < phoenixContracts.length; i++) {

			claimable += phoenixContracts[i].getTotalLevels(_userAddress).mul(ratePerLevel[i]);

		}

		//multiply by the time in seconds, then divide by the number seconds in the day;
		return claimable.mul(_timeDifference).div(86400);
	}


	/**
	* @dev recieves the pending tokens yet to be accounted for, this function is called if the time difference since last update is unknown for the address
	* @param _userAddress is the address which the pending tokens are being calculated for
	*/
	function getPendingTokens(address _userAddress) public view returns(uint) {
		
		uint lastUpdated = lastUpdate[_userAddress];

		if(lastUpdated == 0) {
			return 0;
		}

		return getPendingTokens(_userAddress, block.timestamp - lastUpdated);

	}

   
   /**
     ______     __     __     __   __     ______     ______    
	/\  __ \   /\ \  _ \ \   /\ "-.\ \   /\  ___\   /\  == \   
	\ \ \/\ \  \ \ \/ ".\ \  \ \ \-.  \  \ \  __\   \ \  __<   
	 \ \_____\  \ \__/".~\_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\ 
	  \/_____/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/ /_/ 

	*/
        
    /**
    * @dev Sets a phoenix contract where the phoenixs are capable of burning and generating tokens
    * @param _phoenixAddress is the address of the phoenix contract
    * @param _index is the index of where to set this information, either to add a new collection, or update an existing one
    * @param _ratePerLevel is the rate of token generation per phoenix level for this contract
    */                                                   
    function setPhoenixContract(address _phoenixAddress, uint _index, uint _ratePerLevel) external onlyOwner {
		require(_index <= phoenixContracts.length, "index outside range");

		if(phoenixContracts.length == _index) {
			phoenixContracts.push(IPhoenix(_phoenixAddress));
			ratePerLevel.push(_ratePerLevel);
		} 
		else {

			if(burnAddresses[address(phoenixContracts[_index])] == true) {
				burnAddresses[address(phoenixContracts[_index])] = false;
			}

			phoenixContracts[_index] = IPhoenix(_phoenixAddress);
			ratePerLevel[_index] = _ratePerLevel;


		}

		burnAddresses[_phoenixAddress] = true;
	}

	/**
	* @dev sets the addresss that are allowed to call the burn function
	* @param _burnAddress is the address being set
	* @param _value is to allow or remove burning permission
	*/
	function setBurnAddress(address _burnAddress, bool _value) external onlyOwner {
		burnAddresses[_burnAddress] = _value;
	}

}