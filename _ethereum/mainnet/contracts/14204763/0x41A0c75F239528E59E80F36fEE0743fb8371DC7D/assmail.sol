/* This is a 69-line contract between the good folks at ass.com and you.
assmail: an ERC721 token that entitles you to an "@ass.com" email address of your choosing.
Mint in good humor and fun; hate and violence have no place at ass.com */
pragma solidity ^0.8.0; // SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721URIStorage.sol";
import "./IERC721Metadata.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
contract assonline is ERC721URIStorage, Ownable {
	using SafeMath for uint256;	using Strings for string; using Counters for Counters.Counter; 
	Counters.Counter private _tokenIds; Counters.Counter private _tokenIds_special;

/***** 10,000 assmail NFTs available, each assigned a unique phrase. After sale, we'll move data to IPFS *****/
	uint256 public tokenSupply = 10000;
	uint256 public betaSupply = 100; // For beta testers and early birds.
	string public BaseURI = "https://mail.ass.com/assmail_metadata/";
	bool public saleOpen = false;
	mapping (string => uint256) private tokenMap; mapping (uint256 => string) private phraseMap;
	modifier openSale() {require(saleOpen,'Sale is closed, baby!');_;}

/***** Our team's addresses ;) *****/
	constructor() ERC721("Assmail","ADC") {tokenMap["tom"]=11237; tokenMap["mrhouse"]=10013; 
	tokenMap["phattest"]=10458; tokenMap["help"]=11379;} 

/***** mint_assmail(phrase) is the "phrase@ass.com" accessible on ass.com *****/ 
	function mint_assmail(string memory phrase) public payable openSale returns (uint256) {
		require(msg.value >= 0.03 ether, 'Not enough Ethereum (0.03 ETH Required) to mint.');
		require(_validatePhrase(phrase), 'Invalid phrase. Lowercase a-z only.');
		require(bytes(phrase).length < 11, 'Phrase is too long.');
		require(tokenMap[phrase] == 0, 'How unoriginal; already claimed.');
		require(_tokenIds.current() < tokenSupply && _tokenIds.current() < betaSupply, 'Sorry folks: assmail sold out!');
		_tokenIds.increment(); uint256 tokenID = _tokenIds.current();
		_safeMint(msg.sender, tokenID);
		tokenMap[phrase] = tokenID;	phraseMap[tokenID] = phrase;
		return tokenID;}

/***** DirtyThirty: the strange people who believed in us. Capped at 30, counting backwards *****/
	function mint_dirtythirty(string memory phrase, address receiver) public onlyOwner returns (uint256) {
		require(_validatePhrase(phrase), 'Validity.');require(bytes(phrase).length < 11, 'Length.');
		require(tokenMap[phrase] == 0, 'Taken.'); require(_tokenIds_special.current() < 30, 'DirtyThirty claimed.');
		uint256 tokenID = tokenSupply - _tokenIds_special.current();
		_tokenIds_special.increment(); _mint(receiver, tokenID);
		tokenMap[phrase] = tokenID; phraseMap[tokenID] = phrase; return tokenID;}

/***** System only validates lowercase a-z *****/
	function _validatePhrase(string memory phrase) internal pure returns (bool) {
		bytes memory s = bytes(phrase);
			for(uint i; i<s.length; i++){bytes1 char = s[i];
				if(!(char >= 0x61 && char <= 0x7A)) return false;}
		return true;}

/***** 'view' methods for administration *****/
	function totalSupply() public view returns (uint256) {return _tokenIds.current() + _tokenIds_special.current();}
	function _baseURI() internal view override returns (string memory) {return BaseURI;}

/***** 'onlyOwner' methods for administration *****/
	function updateURI(string memory dropURI) external onlyOwner {BaseURI = dropURI;}
	function get_ID(string memory phrase) public view onlyOwner returns (uint256) {
		require(tokenMap[phrase] != 0, "Error: phrase wasn't minted."); return tokenMap[phrase];}
	function get_phrase(uint256 tokenID) public view onlyOwner returns (string memory) {return phraseMap[tokenID];}
	function toggle_sale() public onlyOwner{saleOpen = !saleOpen;}
	function raiseSoftLimit(uint256 newLimit) public onlyOwner{betaSupply = newLimit;}
	function withdraw() public onlyOwner {uint256 balance = address(this).balance; payable(msg.sender).transfer(balance);}
}