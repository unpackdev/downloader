// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./SquadOwnable.sol";

error DataError(string msg);

contract Satoshigoat is ERC721A, SquadOwnable, ReentrancyGuard {
	
	bytes16 private constant HEX_DIGITS = "0123456789abcdef";

	//@dev Sale Data
	uint256 public constant MAX_NUM_TOKENS = 2;
	uint256 constant public royaltyFeeBps = 1000;//10%

	//@dev Properties
	string internal _contractURI;//*set in parent
	string internal _baseTokenURI;//*passed thru parent constructor
	address public payoutAddress;//*set in parent
	address public _owner;//*set in parent
	uint256 public purchasePrice;//*set in parent

	// -----------
	// RESTRICTORS
	// -----------

	modifier onlyValidTokenID(uint256 tid) {
		if (tid != 0 && tid != 1)
			revert DataError("tid OOB");
		_;
	}

	modifier notEqual(string memory str1, string memory str2) {
		if(_stringsEqual(str1, str2))
			revert DataError("strings must be different");
		_;
	}

	modifier enoughSupply(uint256 qty) {
		if (totalSupply() >= MAX_NUM_TOKENS)
			revert DataError("not enough left");
		_;
	}

	modifier purchaseArgsOK(address to, uint256 amount) {
		if (amount < purchasePrice)
            revert DataError("insufficient funds");
		if (_isContract(to))
			revert DataError("silly rabbit :P");
		_;
	}

	// ----
	// CORE
	// ----
	
    constructor(
    	string memory name_,
    	string memory symbol_,
    	string memory baseTokenURI
    ) 
    	ERC721A(name_, symbol_)
    {
    	_baseTokenURI = baseTokenURI;
    	_contractURI = "";
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

	//@dev Ability to change the purchase/mint price
	function setPurchasePrice(uint256 newPriceInWei) external isSquad 
	{ 
		if (purchasePrice == newPriceInWei)
			revert DataError("prices can't be the same");
		purchasePrice = newPriceInWei;
	}

	// -------
	// HELPERS
	// -------

	/**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

	//@dev Determine if two strings are equal using the length + hash method
	function _stringsEqual(string memory a, string memory b) 
		internal pure returns (bool)
	{
		bytes memory A = bytes(a);
		bytes memory B = bytes(b);

		if (A.length != B.length)
			return false;
		else
			return keccak256(A) == keccak256(B);
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

	/**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }
}
