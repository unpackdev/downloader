// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract BBW is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // Sale
    uint256 public constant TOTAL_SUPPLY = 10000;
    uint256 public constant PUBLIC_SUPPLY = 9691;
    uint public constant MAX_PURCHASABLE = 100;
    uint public constant PRESALE_MAX_PURCHASABLE = 3;
    uint256 public constant MINT_PRICE = 100000000000000000; // 0.1 ETH

    // Dates
    uint256 public presaleStartTime = 1634648400; // Tue Oct 19 2021 13:00:00 GMT+0000
    uint256 public presaleEndTime = 1634814000;    // 46 hrs from Tue Oct 19 2021 13:00:00 GMT+0000 
    uint256 public saleStartTime = 1634824800; // Thu Oct 21 2021 14:00:00 GMT+0000

    // Team can emergency start/pause sale
    bool public saleStarted = false;

    // Base URI
    string private _baseURIextended = "https://api.bullsandbears.world/metadata/";
    string private _contractURI = "ipfs://QmTN5dTLz67qwQGcojWuDwku4MmuoQ9GH1MTegtb12Atrc";

    // Reveal variables
    bool public metadataRevealed = false;

    bool public locked = false;

    mapping(address => bool) public whitelistedAddresses;

    constructor() ERC721("BullsandBears.World", "BBW") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        require(!locked, "locked functions");
        _baseURIextended = baseURI_;
    }

	function setContractURI(string memory newuri) public onlyOwner {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();

        if (!metadataRevealed) {
            return baseURI;
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }
    }

    function mint(uint256 amountToMint) public payable {
        require(saleStarted == true, "Sale is not active.");

        uint256 mintLimit = MAX_PURCHASABLE;
        uint256 time = block.timestamp;
        
        if (time < saleStartTime) {
            if (whitelistedAddresses[msg.sender]) {
                require(time >= presaleStartTime, "Presale has not started yet.");
                require(time <= presaleEndTime, "Presale has ended.");
            } else {
                revert("Sale has not started yet.");
            }

            mintLimit = PRESALE_MAX_PURCHASABLE;
        }

        require(totalSupply() < PUBLIC_SUPPLY, "All BullsandBears have been minted.");
        require(amountToMint > 0, "Minimum mint is 1 BullsandBears.");
        require(amountToMint <= mintLimit, string(abi.encodePacked("Maximum mint is ", mintLimit.toString(), " BullsandBears.")));
        require(balanceOf(msg.sender).add(amountToMint) <= mintLimit, string(abi.encodePacked("You have already minted ", mintLimit.toString(), " BullsandBears.")));

        require(totalSupply() + amountToMint <= PUBLIC_SUPPLY, "The amount of BullsandBears you are trying to mint exceeds the max supply.");
        require(MINT_PRICE.mul(amountToMint) == msg.value, "Incorrect Ether value.");

        _mint(amountToMint);
    }

    function _mint(uint256 amountToMint) private {
        for (uint256 i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function ownerMint(uint256 amountToMint) public onlyOwner {
        require(totalSupply() < TOTAL_SUPPLY, "All BullsandBears have been minted.");
        require(totalSupply() + amountToMint <= TOTAL_SUPPLY, "The amount of BullsandBears you are trying to mint exceeds the max supply.");

        _mint(amountToMint);
    }

    function reveal() public onlyOwner {
        metadataRevealed = true;
    }

    function unreveal() public onlyOwner {
        metadataRevealed = false;
    }

    function batchWhitelist(address[] memory _users) public onlyOwner {
        uint size = _users.length;
        
        for(uint256 i = 0; i < size; i++){
            address user = _users[i];
            whitelistedAddresses[user] = true;
        }
    }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function pauseSale() public onlyOwner {
        saleStarted = false;
    }

    function setPresaleStartTime(uint256 time) public onlyOwner {
        require(time < saleStartTime, "Presale start time should be less than sale start time.");
        
        presaleStartTime = time;
    }

    function setPresaleEndTime(uint256 time) public onlyOwner {
        require(presaleStartTime < time, "Presale end time should be greater than presale time.");
        require(time < saleStartTime, "Presale end time should be less than sale start time.");
        
        presaleEndTime = time;
    }

    function setSaleStartTime(uint256 time) public onlyOwner {
        require(presaleStartTime < time, "Sale start time should be greater than presale start time.");
        saleStartTime = time;
    }

	// and for the eternity....
	function lockMetadata() external onlyOwner {
		locked = true;
	}

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}