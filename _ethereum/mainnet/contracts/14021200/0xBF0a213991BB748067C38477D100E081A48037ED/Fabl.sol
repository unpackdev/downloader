pragma solidity ^0.8.0;
/**
 * @title FABL contract
 * @dev ERC20
 */

 /**
 *  SPDX-License-Identifier: UNLICENSED
 */

/*
	$FABL
 */

import "./ERC20PresetMinterPauserUpgradeable.sol";

interface IFabergegg {
	function balanceOf(address owner) external view returns(uint256);
    
    function ownerOf(uint256 id) external view returns(address);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);
}

contract FABL is ERC20PresetMinterPauserUpgradeable () {
	uint256 public FERTILITY_RATE;
	uint256 public START;

	mapping(uint256 => uint256) public rewards;
	mapping(uint256 => uint256) public lastUpdate;

	IFabergegg public Fabergegg;
	bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

	function claimReward() external {
        uint256 accumulatedUserValue;
        uint256 totalTokensByOwner;
        totalTokensByOwner = Fabergegg.balanceOf(msg.sender);
        for (uint i = 0; i < totalTokensByOwner; i++) {
            uint256 tokenFromLoop; 
            tokenFromLoop = Fabergegg.tokenOfOwnerByIndex(msg.sender, i);
            rewards[tokenFromLoop] += getPendingReward(tokenFromLoop);
            accumulatedUserValue += rewards[tokenFromLoop];
            rewards[tokenFromLoop] = 0;
            lastUpdate[tokenFromLoop] = block.timestamp;
        }
		_mint(msg.sender, accumulatedUserValue);
	}

	function spend(address user, uint256 amount) external {
		require(hasRole(SPENDER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have spender role to spend tokens");
		_burn(user, amount);
	}

	function getTotalClaimable(uint256 tokenID) external view returns(uint256) {
		return rewards[tokenID] + getPendingReward(tokenID);
	}

	function getPendingReward(uint256 tokenID) internal view returns(uint256) {
        require(msg.sender == Fabergegg.ownerOf(tokenID));
		return FERTILITY_RATE * (block.timestamp - (lastUpdate[tokenID] >= START ? lastUpdate[tokenID] : START));
	}

	function setFabergegg(address fabergeggAddress) external {
		require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to set Faabergegg addy");
		Fabergegg = IFabergegg(fabergeggAddress);
	}

	function fertilize(uint256 fertility) external {
		require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to fertilize");
		FERTILITY_RATE = fertility;
	}

	function initialize() initializer public {
		__ERC20PresetMinterPauser_init("FABLE", "FABL");
		_setupRole(SPENDER_ROLE, _msgSender());

		// ~10 tokens per day 
		FERTILITY_RATE = 115740740740740;
		START = block.timestamp - (2 days);
    }
}