//SPDX-License-Identifier: BSD 
pragma solidity ^0.8.0;

import "./console.sol";

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract PointlessPebbles is ERC721A, Ownable, ReentrancyGuard {
    uint16 public constant MAX_TOTAL_TOKENS = 727;
    uint256 public constant MINT_PRICE = 10000000000000000; // 0.01 ETH 

    bool private _halt_mint = true;
    bool private _is_revealed;
    string private _URI;

    constructor() public ERC721A("PointlessPebbles", "PBLS") {}

    function mint(uint256 quantity) external payable nonReentrant {
        require(_halt_mint == false, "Halted");
        require(quantity > 0, "quantity>0");
        require(quantity < 10, "quantity<10");
        require(totalSupply() < MAX_TOTAL_TOKENS, "fin.");
        require(totalSupply()+quantity < MAX_TOTAL_TOKENS, ">maxTokens");
        require(MINT_PRICE * quantity == msg.value, "$ETH!=rx");

        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'tokenId?');

        // include the token index if revealed
        if (_is_revealed) {
            return string(abi.encodePacked(_URI, toString(tokenId)));
        } 

        // otherwise return the URI
        return string(_URI);
    }

    /**
     * @dev Halt minting 
    */
    function setHaltMint(bool v) public onlyOwner() {
        _halt_mint = v;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    **/
    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Set URI 
    */
    function setURI(string memory v) public onlyOwner() {
        _URI = v;
    }

    /**
     * @dev Set reveal 
    */
    function setIsReveal(bool v) public onlyOwner() {
        _is_revealed = v;
    }

	/////////////////////////////////////////////
	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}
