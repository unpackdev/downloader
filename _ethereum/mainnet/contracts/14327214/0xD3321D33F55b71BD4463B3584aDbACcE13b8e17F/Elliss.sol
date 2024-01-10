//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";


/*

███████╗██╗     ██╗     ██╗███████╗███████╗
██╔════╝██║     ██║     ██║██╔════╝██╔════╝
█████╗  ██║     ██║     ██║███████╗███████╗
██╔══╝  ██║     ██║     ██║╚════██║╚════██║
███████╗███████╗███████╗██║███████║███████║
╚══════╝╚══════╝╚══════╝╚═╝╚══════╝╚══════╝
                                           
🧿  ΞLLISS is a collection of generative abstract geometric art.
🌱  100% of minting fees go to fund Ethereum public goods on Gitcoin Grants.

*/

contract Elliss is ERC721Enumerable, Ownable {

	address payable public constant gitcoin = payable(0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6);
	uint256 public price = 0.01 ether;
	string baseURI = "";


	constructor() ERC721("ELLISS", "ELLISS") {
		setBaseURI("https://elliss.xyz/metadata?tokenId=");
	}
	function setBaseURI(string memory uri) public onlyOwner {
		baseURI = uri;
	}
	function _baseURI() override internal view virtual returns (string memory) {
		return baseURI;
	}

	function mint(uint256 id) public payable {
		require(msg.value >= price, "not enough ether");
		price = (price * 101) / 100; // increase price by 1%

		(bool success, ) = gitcoin.call{ value: msg.value }("");
		require(success, "could not send to gitcoin");

		_mint(msg.sender, id);
	}
}
