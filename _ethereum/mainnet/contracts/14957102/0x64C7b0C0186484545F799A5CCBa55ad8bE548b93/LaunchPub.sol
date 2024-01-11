// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol"; 
import "./ERC721A.sol";

contract LaunchPub is ERC721A, Ownable {
	string private _collectionURI;
	string private baseURI = "ipfs://bafkreie4przma2mtaz56pyhymkc5f4be3ehjelpj2ynpwbml6px2zk6hvm";
	bool public _paused = false;
	uint public price = 1 ether;
	uint public maxSupply = 1000;
	uint public maxMintPerAddress = 3;
	uint public maxCrossmintTransactionAmount = 1;
    uint public constant WENMOON_TOTAL_PAYOUT = 41.15 ether;
    uint public wenMoonPaid = 0;

	address private _crossmintAddress =
		0xdAb1a1854214684acE522439684a145E62505233;

	address payable private WENMOON = // wenmoon
		payable(0xf313b537bA711116D7c49A660E90B7bc2F4FCF5B);
    address payable private launchPub = // launchpub
        payable(0xeE6a61Db00e3539369C58fc5F5046a6C55Fe690f);

	mapping(address => uint) public addressMintedBalance;
	mapping(address => bool) private canWithdraw;

	constructor(
		string memory _name,
		string memory _symbol
	) ERC721A(_name, _symbol) {
		canWithdraw[WENMOON] = true;
		canWithdraw[launchPub] = true;
	}

	modifier onlyAdmins(){
		if(canWithdraw[msg.sender]){
			_;
		}
		else{
			revert("This action is reserved for Admins");
		}
	}

	receive() external payable {}

	fallback() external payable {}

	// public
	function tokenURI(uint tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		return
			bytes(baseURI).length != 0
				? string(abi.encodePacked(baseURI))
				: "";
	}

	function mint(uint _mintAmount) external payable {
		require(!_paused, "the contract is paused");
		require(_mintAmount > 0, "need to mint at least 1 NFT");

		uint supply = totalSupply();
		require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

		if (msg.sender != launchPub) {
				require(addressMintedBalance[msg.sender]+_mintAmount <= maxMintPerAddress, "limit per address exceeded");
				require(msg.value >= price * _mintAmount, "insufficient funds");
				addressMintedBalance[msg.sender] += _mintAmount;
				_safeMint(msg.sender, _mintAmount);
				_handleMint();
				return;
		}

		addressMintedBalance[msg.sender] += _mintAmount;
		_safeMint(msg.sender, _mintAmount);
		_handleMint();
	}

	function crossmint(address to, uint _count) external payable {
		require(
			msg.sender == _crossmintAddress,
			"Crossmint only."
		);
		require(to != address(0x0), "Invadlid address");
		require(
			_count <= maxCrossmintTransactionAmount,
			"Max tokens exceeded."
		);
		require(!_paused, "Sale is currently paused.");

		uint supply = totalSupply();
		require(supply + _count <= maxSupply, "Exceeds max supply.");
		require(msg.value >= price * _count, "Ether sent is not correct.");
		_safeMint(to, _count);
		_handleMint();
	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function _handleMint() internal{
		uint supply = totalSupply();
		if (supply >= 800) {
			price = 1.5 ether;
		} else if (supply >= 550) {
			price = 1.2 ether;
		} else if (supply >= 300) {
			price = 1.1 ether;
		}
	}

	function setPrice(uint _newPrice) public onlyOwner{
		price = _newPrice;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setMaxMintPerAddress(uint _newMaxMintPerAddress) public onlyOwner {
		maxMintPerAddress = _newMaxMintPerAddress;
	}

	function setCrossmintMaxAmountPerTransaction(uint _newMaxCrossmintAmount)
		public
		onlyOwner
	{
		maxCrossmintTransactionAmount = _newMaxCrossmintAmount;
	}

	function pause(bool _state) public onlyOwner {
		_paused = _state;
	}

	/**
	 * @dev set collection URI for marketplace display
	 */
	function setCollectionURI(string memory collectionURI)
		internal
		virtual
		onlyOwner
	{
		_collectionURI = collectionURI;
	}


	function withdraw() public payable onlyAdmins {
        uint256 total = address(this).balance; 
		if(WENMOON_TOTAL_PAYOUT>wenMoonPaid){ // To prevent any possibility of underflows
			uint wenmoonMissingBal = WENMOON_TOTAL_PAYOUT - wenMoonPaid;
			if (wenmoonMissingBal > 0) { 
				if (total > wenmoonMissingBal){ 
					(bool sentWM, ) = WENMOON.call{value: wenmoonMissingBal}(""); 
					require(sentWM, "Failed to send WENMOON");
					wenMoonPaid = wenMoonPaid+wenmoonMissingBal; 
					(bool sentLP, ) = launchPub.call{value: total-wenmoonMissingBal}(""); 
					require(sentLP, "Failed to send LaunchPub");
				}
				else{ 
					(bool sentWM, ) = WENMOON.call{value: total}("");
					require(sentWM, "Failed to send WENMOON");
					wenMoonPaid+= total;
				}
			}
			else{
				(bool sentLP, ) = launchPub.call{value: address(this).balance}("");
				require(sentLP, "Failed to send LaunchPub");
			}
		}
		else{
			(bool sentLP, ) = launchPub.call{value: address(this).balance}("");
			require(sentLP, "Failed to send LaunchPub");
		}
	}
}