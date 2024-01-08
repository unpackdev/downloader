/* SPDX-License-Identifier: MIT
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠛⢉⢉⠉⠉⠻⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⠟⠠⡰⣕⣗⣷⣧⣀⣅⠘⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠃⣠⣳⣟⣿⣿⣷⣿⡿⣜⠄⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⠁⠄⣳⢷⣿⣿⣿⣿⡿⣝⠖⠄⣿⣿⣿⣿⣿
⣿⣿⣿⣿⠃⠄⢢⡹⣿⢷⣯⢿⢷⡫⣗⠍⢰⣿⣿⣿⣿⣿
⣿⣿⣿⡏⢀⢄⠤⣁⠋⠿⣗⣟⡯⡏⢎⠁⢸⣿⣿⣿⣿⣿
⣿⣿⣿⠄⢔⢕⣯⣿⣿⡲⡤⡄⡤⠄⡀⢠⣿⣿⣿⣿⣿⣿
⣿⣿⠇⠠⡳⣯⣿⣿⣾⢵⣫⢎⢎⠆⢀⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠄⢨⣫⣿⣿⡿⣿⣻⢎⡗⡕⡅⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠄⢜⢾⣾⣿⣿⣟⣗⢯⡪⡳⡀⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠄⢸⢽⣿⣷⣿⣻⡮⡧⡳⡱⡁⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡄⢨⣻⣽⣿⣟⣿⣞⣗⡽⡸⡐⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡇⢀⢗⣿⣿⣿⣿⡿⣞⡵⡣⣊⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⡀⡣⣗⣿⣿⣿⣿⣯⡯⡺⣼⠎⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣧⠐⡵⣻⣟⣯⣿⣷⣟⣝⢞⡿⢹⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡆⢘⡺⣽⢿⣻⣿⣗⡷⣹⢩⢃⢿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣷⠄⠪⣯⣟⣿⢯⣿⣻⣜⢎⢆⠜⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⡆⠄⢣⣻⣽⣿⣿⣟⣾⡮⡺⡸⠸⣿⣿⣿⣿
⣿⣿⡿⠛⠉⠁⠄⢕⡳⣽⡾⣿⢽⣯⡿⣮⢚⣅⠹⣿⣿⣿
⡿⠋⠄⠄⠄⠄⢀⠒⠝⣞⢿⡿⣿⣽⢿⡽⣧⣳⡅⠌⠻⣿
⠁⠄⠄⠄⠄⠄⠐⡐⠱⡱⣻⡻⣝⣮⣟⣿⣻⣟⣻⡺⣊

༼ つ ◕_◕ ༽つ WERE IZ DILDO !? ༼ つ ◕_◕ ༽つ
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract WereIzDildo is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
	using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

	string public dildoUri = "https://ipfs.io/ipfs/QmQc5sammAicbc4P6UjxK33vPQC9rUZRbAUK6T5WMhMedz/";

    uint256 public constant hardCap = 10001; // Save the gweis, save them! (no + 1)
    uint256 public constant maxPleasure = 6; // Can't have too much pleasure at once! (no + 1)
    uint256 private dildoPrice = 30000000000000000; // 0.03 Ether - Defined on deployment but modifiable
	uint256 public goldenDildo = 0;

	bool public mintOver = false;
	
    mapping (uint => address) private previousOwner;

    constructor() ERC721("Were Iz Dildo", "WID") {}

    // Mint the token
    function mintDildo(uint256 _pleasureAmount) public payable {
		require(mintOver == false, "Seems like the reveal was done!");
        require(_tokenIdCounter.current() < hardCap, "No mas! No mas! Enough dildos");
        require(msg.value == dildoPrice.mul(_pleasureAmount), "That is not the right price, no no!");
        require(_pleasureAmount < maxPleasure, "Can't have too much pleasure at once!");

		for(uint256 i = 0; i < _pleasureAmount; i++){
			_tokenIdCounter.increment();
			uint256 _newItemId = _tokenIdCounter.current();
			_safeMint(msg.sender, _newItemId);
			_setTokenURI(_newItemId, "dildo.json");
		}
	}

	/** Store  */

	// Change the baseURI to redirect to the correct IPFS CID
	function revealDildo(string memory _revealUri) public onlyOwner {
		require(mintOver == false, "The reveal has already taken place.");
		dildoUri = _revealUri;
		mintOver = true;
	}

    // Randomly set one of the minted token to the golden dildo
	function setGolden() public onlyOwner {
		require(goldenDildo == 0, "The golden dildo has already been chosen!"); // Can only be done once
		uint256 _goldenId = _generateNumber(); // Generate a number randomly
		_setTokenURI(_goldenId, "golden.json");
	    goldenDildo = _goldenId;
	}
	
	// Burn the token and register the former owner
	function redeemToken(uint256 _tokenId) public {
	    require(ownerOf(_tokenId) == msg.sender, "You don't own this pleasure giver");
	    previousOwner[_tokenId] = msg.sender;
	    _transfer(msg.sender, 0x000000000000000000000000000000000000dEaD, _tokenId);
	}

    // We all know that is this about
	function withdrawOrgasms() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    // To adapt the price based on ETH fluctuations
	function changeOrgasms(uint256 _newPleasure) public onlyOwner {
		dildoPrice = _newPleasure;
	}

	/** VIEW FUNCTIONS */
	
	// Generate the number randomly on chain
	function _generateNumber() internal view returns(uint256) {
		uint256 _ceilingNumber = _tokenIdCounter.current();
		uint256 seed = uint256(keccak256(abi.encodePacked(
			block.timestamp + block.difficulty +
			((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
			block.gaslimit + 
			((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
			block.number
		)));

		return (seed - ((seed / _ceilingNumber) * _ceilingNumber)) % _ceilingNumber + 1;
	}

    // Get the price of the dildo
	function getOrgasms() public view returns(uint256) {
		return dildoPrice;
	}

    // Show which token has been chosen as golden (only visible when revealed)
	function getGoldenDildo() public view returns (uint256) {
		return goldenDildo;
	}
	
	// Show previous owner of the redeemed token
	function getPreviousOwner(uint256 _tokenId) public view returns (address) { 
	    return previousOwner[_tokenId];
	}
	
	
	/** OVERRIDES */
	function _baseURI() internal view override returns (string memory) {
		return dildoUri;
	}
	
	function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(_tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
		return super.tokenURI(_tokenId);
	}
}