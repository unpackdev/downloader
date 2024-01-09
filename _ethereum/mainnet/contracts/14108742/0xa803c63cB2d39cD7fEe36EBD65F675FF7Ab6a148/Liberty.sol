// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";

contract Liberty is ERC20 {

	uint256 private constant MAX_SUPPLY = 66000000000000 * (10**18);
	uint256 private constant AMOUNT_COMMUNITY_POPULARITY_PROMOTION = (MAX_SUPPLY * 3) / 100;
	uint256 private constant AMOUNT_LP = (MAX_SUPPLY * 10) / 100;
	uint256 private constant AMOUNT_OPENDAO = (MAX_SUPPLY * 17) / 100;
	uint256 private constant AMOUNT_STAKE = (MAX_SUPPLY * 20) / 100;
	uint256 private constant AMOUNT_CLAIM = (MAX_SUPPLY * 50) / 100;

	mapping(address => bool) private minted;
	uint256 private claimedAmount;
	
	uint256 private immutable startTime;
	address private immutable gSigner;
	address private immutable holderOpenDAO;

	bool private isRetrieved;

	constructor(string memory _name,
		    string memory _symbol,
		    address _holderLP,
		    address _holderOpenDAO,
		    address _holderStake,
		    address _signer) ERC20(_name, _symbol) {
			    
		gSigner = _signer;
		startTime = block.timestamp;
		holderOpenDAO = _holderOpenDAO;

		_mint(_holderLP, AMOUNT_LP);
		_mint(_holderOpenDAO, AMOUNT_OPENDAO);
		_mint(_holderStake, AMOUNT_STAKE);
		_mint(msg.sender, AMOUNT_COMMUNITY_POPULARITY_PROMOTION);
	}

	function claim(uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
		require(block.timestamp < startTime + 60 days, "Liberty: claim time is over");
		require(!minted[msg.sender], "Liberty: claimed");
		require(claimedAmount + amount < AMOUNT_CLAIM, "Liberty: exceed max claim amount");
		require(amount > 0, "Liberty: nothing to claim");

		bytes32 payloadHash = keccak256(abi.encode(msg.sender, amount));
		bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));

		address signer = ecrecover(digest, v, r, s);

		require(signer == gSigner, "Liberty: wrong signer");

		minted[msg.sender] = true;
		claimedAmount += amount;
		_mint(msg.sender, amount);
	}

	function retrieveUnclaimedToken() external {
		require(block.timestamp > startTime + 60 days, "Liberty: not the time to retrieve token");
		require(!isRetrieved, "Liberty: the rest token has been retrieved");

		uint256 unclaimedTokenAmount = AMOUNT_CLAIM - claimedAmount;
		isRetrieved = true;

		_mint(holderOpenDAO, unclaimedTokenAmount);
	}
}
