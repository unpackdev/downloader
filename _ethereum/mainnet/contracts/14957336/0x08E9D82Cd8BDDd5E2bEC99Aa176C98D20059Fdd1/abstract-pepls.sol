// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";

contract AbstractPepl is ERC721A, Ownable {
    uint256 public MAX_MINTS = 3;
    uint256 public MAX_SUPPLY = 8350;
    uint256 public MINT_PRICE = 0.0025 ether;
    uint256 public NUM_FREE = 1;
    bool public isPaused = true;

    string public baseURI = "https://nftstorage.link/ipfs/bafybeih7kd5m6dxk7nbahm7gognkooj5znpzqcifp4mx22wf5y5bhxk4ui/";

    constructor() ERC721A("Abstract Pepls", "ABSTRACTPEPL") {}

    function mint(uint256 quantity) external payable {
        require(!isPaused, "Sales are off");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the wallet limit");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        uint payForCount = quantity;
        if (_numberMinted(msg.sender) < NUM_FREE) {
			payForCount = payForCount - NUM_FREE;
        }

		require(
			msg.value >= payForCount * MINT_PRICE,
			"Ether value sent is not sufficient"
		);

        _safeMint(msg.sender, quantity);
    }

    function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

    function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Nothing to Withdraw');
        payable(owner()).transfer(balance);
    }

    function withdrawTo(address to) external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Nothing to Withdraw');
        payable(to).transfer(balance);
    }

	function makePeplsFly(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= MAX_SUPPLY,
			'Exceeded the limit'
		);
		_safeMint(to, count);
	}

    function airdropToMulti(address[] memory airdrops, uint[] memory count) external onlyOwner {
        for(uint i=0; i<airdrops.length; i++){
            require(
                _totalMinted() + count[i] <= MAX_SUPPLY,
                'Exceeded the limit'
            );
            _safeMint(airdrops[i], count[i]);
        }
    }

    function setBaseURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setMaxMint(uint256 _mint) public onlyOwner {
        MAX_MINTS = _mint;
    }
}