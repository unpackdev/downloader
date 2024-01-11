// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./DojiCourrier.sol";
import "./console.sol";

contract Doji1155Accounting is Ownable{
	event LuckyHolder1155(uint256 indexed luckyHolder, address indexed sender, uint, uint);
	event ChosenHolder1155(uint256 indexed chosenHolder, address indexed sender, uint, uint);
	//solhint-disable-next-line
	DojiClaimsProxy claimContract;
		struct TokenIDClaimInfo {
			uint index;
			uint balance;
		}

    struct NFTClaimInfo {
			uint index;
			uint[] tokenID;
			//solhint-disable-next-line
      mapping(uint => TokenIDClaimInfo) ClaimTokenStruct;
    }

		struct ContractInfo {
			address[] contractIndex;
			//solhint-disable-next-line
			mapping(address => NFTClaimInfo) ContractInfos;
		}
		//solhint-disable-next-line
    mapping (uint256 => ContractInfo) private UserInventory;
		
	constructor(){}

	modifier onlyClaimContract() { // Modifier
		require(
			msg.sender == address(claimContract),
			"Only Claim contract can call this."
		);
		_;
	}

	//solhint-disable-next-line
	function isContractForUser(address _contract, uint DojiID) public view returns(bool) {
		if (UserInventory[DojiID].contractIndex.length == 0) return false;
		return (UserInventory[DojiID].contractIndex[UserInventory[DojiID].ContractInfos[_contract].index] == _contract);
	}

	//solhint-disable-next-line
	function isTokenIDForContractForUser(address _contract, uint DojiID, uint tokenID) public view returns(bool) {
		if (UserInventory[DojiID].ContractInfos[_contract].tokenID.length == 0) return false;
		return (
			UserInventory[DojiID].ContractInfos[_contract]
				.tokenID[ UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].index ] == tokenID
		);
	}
	
	function insertContractForUser (
		address _contract,
		//solhint-disable-next-line
		uint DojiID,
    uint tokenID, 
    uint balance
	) 
    public
    returns(uint index)
  {
    require(!isContractForUser(_contract, DojiID), "Contract already exist"); 
		UserInventory[DojiID].contractIndex.push(_contract);
    UserInventory[DojiID].ContractInfos[_contract].index = UserInventory[DojiID].contractIndex.length - 1;
		if (!isTokenIDForContractForUser(_contract, DojiID, tokenID)){
			UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].balance = balance;
			UserInventory[DojiID].ContractInfos[_contract].tokenID.push(tokenID);
    	UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].index = UserInventory[DojiID].ContractInfos[_contract].tokenID.length - 1;
		}
    return UserInventory[DojiID].contractIndex.length-1;
  }

	//solhint-disable-next-line
	function addBalanceOfTokenId(address _contract, uint DojiID, uint tokenID, uint _amount) 
    private
    returns(bool success) 
  {
    require(isContractForUser(_contract, DojiID), "Contract doesn't exist");
		if (!isTokenIDForContractForUser(_contract, DojiID, tokenID)) {
			UserInventory[DojiID].ContractInfos[_contract].tokenID.push(tokenID);
    	UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].index = UserInventory[DojiID].ContractInfos[_contract].tokenID.length - 1;
		}
    if (UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].balance == 0) {
			UserInventory[DojiID]
			.ContractInfos[_contract]
			.ClaimTokenStruct[tokenID].balance = _amount;
		} else {
			UserInventory[DojiID]
				.ContractInfos[_contract]
				.ClaimTokenStruct[tokenID].balance += _amount;
		}
    return true;
  }
	//solhint-disable-next-line
	function RemoveBalanceOfTokenId(address _contract, uint DojiID, uint tokenID, uint _amount) 
    public onlyClaimContract
    returns(bool success) 
  {
    require(isContractForUser(_contract, DojiID), "Contract doesn't exist"); 
		require(isTokenIDForContractForUser(_contract, DojiID, tokenID));
		UserInventory[DojiID]
			.ContractInfos[_contract]
			.ClaimTokenStruct[tokenID].balance -= _amount;
    return true;
  }

	//solhint-disable-next-line
	function getTokenBalanceByID(address _contract, uint DojiID, uint tokenID) public view returns(uint){
		return UserInventory[DojiID]
			.ContractInfos[_contract]
			.ClaimTokenStruct[tokenID].balance;
	}

	//solhint-disable-next-line
	function getTokenIDCount(address _contract, uint DojiID) public view returns(uint){
		return UserInventory[DojiID]
			.ContractInfos[_contract].tokenID.length;
	}

	//solhint-disable-next-line
	function getTokenIDByIndex(address _contract, uint DojiID, uint index) public view returns(uint){
		return UserInventory[DojiID]
			.ContractInfos[_contract].tokenID[index];
	}

	//solhint-disable-next-line
	function getContractAddressCount(uint DojiID) public view returns(uint){
		return UserInventory[DojiID].contractIndex.length;
	}

	//solhint-disable-next-line
	function getContractAddressByIndex(uint DojiID, uint index) public view returns(address){
		return UserInventory[DojiID].contractIndex[index];
	}

	function random1155(address _contract, uint tokenID, uint _amount) external onlyClaimContract {
	  require(_amount > 0);
	  uint256 luckyFuck = pickLuckyHolder();
		if (isContractForUser(_contract, luckyFuck)) {
			addBalanceOfTokenId(_contract, luckyFuck, tokenID,  _amount);
		} else {
			insertContractForUser (_contract, luckyFuck, tokenID, _amount);
		}
	  emit LuckyHolder1155(luckyFuck, msg.sender, tokenID, _amount);
	}

	function send1155(address _contract, uint tokenID, uint _amount, uint256 chosenHolder) public {
		require(_amount > 0);
		require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
		if (isContractForUser(_contract, chosenHolder)) {
			addBalanceOfTokenId(_contract, chosenHolder, tokenID, _amount);
		} else {
			insertContractForUser (_contract, chosenHolder, tokenID, _amount);
		}
		ERC1155(_contract).safeTransferFrom(msg.sender,  address(claimContract), tokenID, _amount, 'true');
		emit ChosenHolder1155(chosenHolder, msg.sender, tokenID, _amount);
	}

	//solhint-disable-next-line
	function pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, claimContract._currentBaseTokensHolder())));
		uint index = (rando % claimContract._currentBaseTokensHolder());
		uint result = IERC721Enumerable(claimContract._baseTokenAddress()).tokenByIndex(index);
		return result;
	}

	function setClaimProxy (address proxy) public onlyOwner {
	  claimContract = DojiClaimsProxy(payable(proxy));
	}
}