// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./LibPart.sol";

error RefundPeriodOver();
error DataError(string msg);

contract Satoshigoat is ERC721A, Pausable, ReentrancyGuard {
	
	//@dev Sale Data
	uint256 public constant MAX_NUM_TOKENS = 4;

	//@dev Properties
	string internal _contractURI;
	string internal _baseTokenURI;
	address public payoutAddress;
	address public _owner;//for some site i can't recall rn
	uint256 constant public royaltyFeeBps = 1000;//10%

	// -----------
	// RESTRICTORS
	// -----------

	modifier onlyValidTokenId(uint256 tid) {
		if (tid < 0 || tid >= MAX_NUM_TOKENS)
			revert DataError("tid OOB");
		_;
	}

	modifier notEqual(string memory str1, string memory str2) {
		if(_stringsEqual(str1, str2))
			revert DataError("strings must be different");
		_;
	}

	modifier enoughSupply(uint256 qty) {
		if (totalSupply() + qty > MAX_NUM_TOKENS)
			revert DataError("not enough left");
		_;
	}

	// ----
	// CORE
	// ----
	
	//@dev Mostly an extension but with merkle root & start countdown
    constructor(
    	string memory name_,
    	string memory symbol_,
    	string memory baseTokenURI
    ) 
    	ERC721A(name_, symbol_)
    {
    	_baseTokenURI = baseTokenURI;
    	_contractURI = "ipfs://Qmey3S1pFsXXDz6c3qQS8yUVGmC1HewLgbuk4zUSpj59uZ";
    	_owner = address(0x6b8C6E15818C74895c31A1C91390b3d42B336799);
    }

    //@dev See {ERC721A-_baseURI}
	function _baseURI() internal view virtual override returns (string memory)
	{
		return _baseTokenURI;
	}

	//@dev Controls the contract-level metadata
	function contractURI() external view returns (string memory)
	{
		return _contractURI;
	}

    //@dev Allows us to withdraw funds collected
    function withdraw(address payable wallet, uint256 amount) 
        external isSquad nonReentrant
    {
        if (amount > address(this).balance)
            revert DataError("insufficient funds to withdraw");
        wallet.transfer(amount);
    }

    //@dev Ability to change _baseTokenURI
	function setBaseTokenURI(string calldata newBaseURI) 
		external isSquad notEqual(_baseTokenURI, newBaseURI) { _baseTokenURI = newBaseURI; }

	//@dev Ability to change the contract URI
	function setContractURI(string calldata newContractURI) 
		external isSquad notEqual(_contractURI, newContractURI) { _contractURI = newContractURI; }

	// -------
	// HELPERS
	// -------

	//@dev Gives us access to the otw internal function `_numberMinted`
	function numberMinted(address owner) public view returns (uint256) 
	{
		return _numberMinted(owner);
	}

	//@dev Determine if two strings are equal using the length + hash method
	function _stringsEqual(string memory a, string memory b) 
		internal pure returns (bool)
	{
		bytes memory A = bytes(a);
		bytes memory B = bytes(b);

		if (A.length != B.length) {
			return false;
		} else {
			return keccak256(A) == keccak256(B);
		}
	}

	//@dev Determine if an address is a smart contract 
	function _isContract(address a) internal view returns (bool)
	{
		// This method relies on `extcodesize`, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
		uint32 size;
		assembly {
			size := extcodesize(a)
		}
		return size > 0;
	}

	// ---------
	// ROYALTIES
	// ---------

	//@dev Rarible Royalties V2
	function getRaribleV2Royalties(uint256 tid) 
		external view onlyValidTokenId(tid) 
		returns (LibPart.Part[] memory) 
	{
		LibPart.Part[] memory royalties = new LibPart.Part[](1);
		royalties[0] = LibPart.Part({
			account: payable(payoutAddress),
			value: uint96(royaltyFeeBps)
		});

		return royalties;
	}

	//@dev See {EIP-2981}
	function royaltyInfo(uint256 tid, uint256 salePrice) 
		external view onlyValidTokenId(tid) 
		returns (address, uint256) 
	{
		uint256 ourCut = (salePrice * royaltyFeeBps) / 10000;
		return (payoutAddress, ourCut);
	}
}
