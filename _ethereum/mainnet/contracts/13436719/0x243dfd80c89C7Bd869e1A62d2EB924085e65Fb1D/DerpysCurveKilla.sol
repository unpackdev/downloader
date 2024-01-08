//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Derpys.sol";


/*************************************************
 __        __        ___                          
/  ` |  | |__) \  / |__     |__/ | |    |     /\  
\__, \__/ |  \  \/  |___    |  \ | |___ |___ /~~\ 

	I AM THE
	CURVE KILLER.

	AND I HAVE ARRIVED.

**************************************************/

//	I mint Derpys.
//	And I care not for bonding curves.	


/// @title The CurveKilla contract
/// @author @CoinFuPanda
/** 
 * @notice CurveKilla negates bonding curves associated with minting 
 * and allows minters to pay a flat price
 */
contract DerpysCurveKilla is IERC721Receiver, Ownable, ReentrancyGuard {
	address payable public immutable targetAddress;
	uint256 public MINT_PRICE = 0.045 ether;
	uint256 public MIN_BUFFER = 50 ether; //max cost to mint 50 derpys

	/**
	 * @param _targetAddress is the contract that 
	 * needs its bonding curve destroyed
	 */
	constructor(address _targetAddress) {
		targetAddress = payable(_targetAddress);
	}

	/** @dev allow deposits to this contract,
	 * used to overcome higher prices in the 
	 * target contract
	 */
	receive() external payable {
	}

	/**
	 * @dev set the price per mint required from msg.sender
	 */
	function setMintPrice(uint256 newWeiPrice) public onlyOwner {
		MINT_PRICE = newWeiPrice;
	}

	/**
	 * @dev minimum amount of ETH to keep in this contract during sale
	 */
	function setMinBuffer(uint256 newWeiBuffer) public onlyOwner {
		MIN_BUFFER = newWeiBuffer;
	}

	/**
	 * @notice mint Derpys!
	 */
	function mintDerpys(uint256 numToMint) 
	public 
	payable 
	nonReentrant 
	{
		require(
			numToMint > 0 && numToMint <= 50,
			"you can mint between 1 and 50 tokens"
		);
		require(
			msg.value >= numToMint * MINT_PRICE, //CHECK SOLIDITY MATH OPERATIONS
			"sent value is not enough"
		);

		Derpys targetContract = Derpys(payable(targetAddress)); //trusted contract
		uint256 targetSupply = targetContract.currentSupply();
		require(
			targetSupply + numToMint <= 10000,
			"not enough tokens remaining in the target"
		);

		//if this contract does not have enough ether
		//top up from target
		uint256 targetMintCost = numToMint * targetContract.getCatchCost();
		if (
			address(this).balance < targetMintCost &&
			targetContract.owner() == address(this)
		) 
		{
			targetContract.withdrawMissionBounty();
		}
		require(
			address(this).balance >= targetMintCost,
			"target mint price too high: top up this contract"
		);

		//INTERACTIONS
		//mint requested tokens to this contract
		//this reverts by default if the minting fails
		//because CK is ERC721Receiver
		targetContract.catchDerpy{value: targetMintCost}(numToMint);

		//forward tokens to msg.sender
		for (uint256 ii = 0; ii < numToMint; ii++) {
			uint256 itoken = targetSupply + ii;
			targetContract.safeTransferFrom(
				address(this), 
				msg.sender, 
				itoken
			);
		}
	}

	/**
	 * @dev allows owner to partially withdraw from this
	 * contract, leaving enough eth to continue killin curvez
	 */
	function skim() public payable onlyOwner {
		require(
			address(this).balance > MIN_BUFFER,
			"this ether needs to remain in CurveKilla"
		);
		uint256 amount = address(this).balance - MIN_BUFFER;
		payable(msg.sender).transfer(amount);
	}

	function withdraw() public payable onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	/**
	 * @dev This contract must become owner of targetContract.
	 * This function returns control of targetContract to owner
	 */
	function reclaimOwnershipOfTarget() public onlyOwner {
		Derpys targetContract = Derpys(payable(targetAddress));

		require(
			targetContract.owner() == address(this),
			"CurveKilla does not own targetContract"
		);
		targetContract.transferOwnership(this.owner());
	}
	
	/**
	 * @dev manually prompt this contract to top itself up by 
	 * withdrawing from the targetContract
	 */
	function manualWithdrawFromTarget() public onlyOwner {
		Derpys targetContract = Derpys(payable(targetAddress));
		require(
			targetContract.owner() == address(this), 
			"CurveKilla does not own targetContract"
		);
		targetContract.withdrawMissionBounty();
	}

	function onERC721Received(
		address operator, 
		address from, 
		uint256 tokenId, 
		bytes calldata data
	)
		public 
		virtual 
		override 
		returns (bytes4) 
	{
		return this.onERC721Received.selector;
	}
}
