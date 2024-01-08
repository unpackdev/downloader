pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Math.sol";

library TimeManagment{
    function minutesToTimestamp(uint256 timestamp )internal pure returns (uint256){
        return timestamp/60;    
    }
}
abstract contract Whitelist is Ownable{
    
    
    mapping(address => bool) internal _whitelist;
    constructor() {
        _whitelist[msg.sender] = true;
    }
    function addToWhitelist(address[] memory addressesToAdd) public onlyOwner {
        for(uint i = 0;i< addressesToAdd.length;i++){
            _whitelist[addressesToAdd[i]]=true;
        }
    }
    function removeFromWhitelist(address addressToRemove) public onlyOwner{
        _whitelist[addressToRemove]=false;
    }
    function isWhitelisted(address addressToCheck)public view returns(bool){
        return _whitelist[addressToCheck];
    }
}

abstract contract Pausable is Ownable{
    bool public paused;
    function pause(bool val) public onlyOwner{
        paused=val;
    }
    modifier notPaused{
        require(!paused,"Pause!");
        _;
    }
}

abstract contract OpenSeaCompatible is Ownable,ERC721Enumerable{
    string private _contractURI;
    function contractURI() public view returns (string memory){
        return _contractURI;
    }
    function setContractURI(string memory _contractUri) public onlyOwner{
        _contractURI = _contractUri;
    }
    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}

abstract contract SafeWithdrawals is Ownable{
    function withdrawTokens(address tokenAddress,address receiver) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(receiver, token.balanceOf(address(this)));
    }
    function _withdrawETH(address receiver) internal{
        (bool sent,) = receiver.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    function withdrawETH(address receiver) public onlyOwner{
        _withdrawETH(receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract ChariverseKids is 
    OpenSeaCompatible,
    Pausable,
    SafeWithdrawals,
    Whitelist 
    {
	uint256 public constant MAX_SUPPLY = 8888;
	uint256 public constant MAX_SUPPLY_FOR_GIVEAWAY = 50;
	string private _baseTokenURI;

	uint256 public presalePrice = 0.15 ether;
	uint256 public presaleDate = 1668707949; //November 22
	uint256 public saleDate = 1671299949; //December 22
	uint256 public maxItemPerMint = 10;
	uint256 public maxSuplyDuringPresale = 500;
	address public mintValueReceiver;
	
    uint256 public minutesToDropSalePrice = 10;
	uint256[] public priceRanges = [
	    0.5 ether,
        0.4 ether,
	    0.3 ether,
	    0.2 ether,
	    0.1 ether
	  ];
	
    function _baseURI() internal view override returns (string memory){
        return _baseTokenURI;
    }
    function setBaseUri(string memory baseURI) public onlyOwner{
        _baseTokenURI = baseURI;
    }
	function setSaleTime(uint256 saleDate_) public onlyOwner{
	    saleDate = saleDate_;
	}
	function setPreSaleTime(uint256 presaleDate_) public onlyOwner{
	    presaleDate = presaleDate_;
	}
	function setPreSalePrice(uint256 presalePrice_) public onlyOwner{
	    presalePrice = presalePrice_;
	}
    function setTokenSaleAuctionPriceRanges(uint256[] calldata priceRanges_) public onlyOwner {
        priceRanges = priceRanges_;
    }
    function setMaxItemPerSingleMint(uint256 maxItemPerMint_) public onlyOwner{
	    maxItemPerMint = maxItemPerMint_;
	}
    function setMaxSuplyDuringPresale(uint256 maxSuplyDuringPresale_) public onlyOwner{
	    maxSuplyDuringPresale = maxSuplyDuringPresale_;
	}
    function setMintValueReceiver(address mintValueReceiver_) public onlyOwner{
	    mintValueReceiver = mintValueReceiver_;
	}
    function setMinutesToDropSalePrice(uint256 minutesToDropSalePrice_) public onlyOwner{
	    minutesToDropSalePrice = minutesToDropSalePrice_;
	}
	    
    constructor(string memory baseTokenURI_)
        ERC721("ChariverseKids", "KID") {
        _baseTokenURI = baseTokenURI_;
        mintValueReceiver = msg.sender;

        pause(true);
    }


    modifier timed {
        require(
            block.timestamp >= saleDate || (isPreSale() && _whitelist[msg.sender]),

            "timelock"
        );
        _;
        
    }
    function mintChariverseItem(address to, uint count) public payable notPaused timed {
        require(count <= maxItemPerMint, "To much minting");
        //Require to mint limited supply during presale
        if(isPreSale()){
            require(totalSupply() < maxSuplyDuringPresale, "Hit Max Presale Supply");
            require(totalSupply() + count <= maxSuplyDuringPresale, "Max limit");
        }else{
            require(totalSupply() < MAX_SUPPLY, "Sale end");
            require(totalSupply() + count <= MAX_SUPPLY, "Max limit");
        }
        require(msg.value >= price(count), "Value below price");
        for(uint i = 0; i < count; i++){
            _safeMint(to, totalSupply());
        }
        _withdrawETH(mintValueReceiver);
    }

     function mintGiveAwayItems(address to, uint count) public onlyOwner{
        require(totalSupply()+count < MAX_SUPPLY_FOR_GIVEAWAY, "Max GiveAway Limit");
	    for(uint i = 0; i < count; i++){
            _safeMint(to, totalSupply());
        }
	}
    
    function isPreSale() public view returns (bool){
        return block.timestamp >= presaleDate && block.timestamp < saleDate;
    }
    
    function _minutesToPrice(uint256 minute) private view returns (uint256){
        return priceRanges[Math.min(minute/minutesToDropSalePrice, priceRanges.length - 1)];
    }
    
    function price(uint count) public view returns (uint256) {
        if(isPreSale()) return presalePrice*count;
        uint256 minutesSinceSale = TimeManagment.minutesToTimestamp(block.timestamp-saleDate);
        return _minutesToPrice(minutesSinceSale)*count;
    }
}