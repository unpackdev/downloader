// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// 8888888b.  888                        888              .d8888b.                                     
// 888   Y88b 888                        888             d88P  Y88b                                    
// 888    888 888                        888             Y88b.                                         
// 888   d88P 88888b.   8888b.  88888b.  888888  8888b.   "Y888b.   88888b.   8888b.   .d8888b .d88b.  
// 8888888P"  888 "88b     "88b 888 "88b 888        "88b     "Y88b. 888 "88b     "88b d88P"   d8P  Y8b 
// 888        888  888 .d888888 888  888 888    .d888888       "888 888  888 .d888888 888     88888888 
// 888        888  888 888  888 888  888 Y88b.  888  888 Y88b  d88P 888 d88P 888  888 Y88b.   Y8b.     
// 888        888  888 "Y888888 888  888  "Y888 "Y888888  "Y8888P"  88888P"  "Y888888  "Y8888P "Y8888  
//                                                                  888                                
//                                                                  888                                
//                                                                  888                  


import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";


contract PhantaSpace is Initializable, ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC721RoyaltyUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    string public baseURI;
    string public contractURI;

    uint public vendingPrice;
    uint public auctionFloor;
    uint public auctionDuration;
    uint public royaltyFeesInBips;
    uint public unWithdrawnFunds;

    mapping (uint256 => uint) public auctionEndTime;
    mapping (uint256 => uint) public highestBid;
    mapping (uint256 => address) public highestBidder;
    mapping (uint256 => bool) public subspaceAvailableForAuction;
    mapping (uint256 => mapping (address => uint)) public pendingReturns; // also serve as history of user highest's bid


    event SpaceMinted(address to, uint256 geocode);
    event AuctionStarted(uint256 geocode, uint256 auctionEndTime, uint256 highestBid, address highestBidder);
    event AuctionExtended(uint256 geocode, uint256 newAuctionEndTime);
    event AuctionEnded(uint256 geocode, address highestBidder, uint256 highestBid);
    event HighestBidIncreased(uint256 geocode, address highestBidder, uint256 highestBid);
    event SubSpaceAuctionAllowed(uint256 geocode);
    event withDrawalRequested(uint256 geocode, address bidder, uint256 amount);

    function initialize( string memory _metadataURL, string memory _contractURI, uint _vendingPrice, uint _auctionFloor, uint _auctionDuration, uint96 _royaltyFeesInBips) initializer public {
        __ERC721_init("PhantaSpace", unicode"🌐");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC721Royalty_init();

        baseURI = _metadataURL;
        vendingPrice = _vendingPrice;
        auctionFloor = _auctionFloor;
        auctionDuration = _auctionDuration;
        royaltyFeesInBips = _royaltyFeesInBips;
        _setDefaultRoyalty(owner(), _royaltyFeesInBips);
        contractURI = _contractURI;
        unWithdrawnFunds = 0;

    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _metadataURL) public onlyOwner{
        baseURI = _metadataURL;
    }

    function setContractURI (string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setVendingPrice (uint _vendingPrice) public onlyOwner {
        vendingPrice = _vendingPrice;
    }

    function setAuctionFloor (uint _auctionFloor) public onlyOwner {
        auctionFloor = _auctionFloor;
    }


    function setAuctionDuration(uint _auctionDuration) public onlyOwner {
        auctionDuration = _auctionDuration;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function exists(uint256 geocode) public view returns (bool) {
        return _exists(geocode);
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 geocode)
        public
        onlyOwner
    {
        _checkGeocode(geocode);
        _safeMint(to, geocode);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // PhantaSpace functions

    function _checkGeocode(uint256 geocode)
        internal
        pure
    {
        // verify if the geocode is acceptable
        uint p = geocode % 10;
        require(p > 0, "Precision must be greater than 0");

        uint longitude = geocode / 10**(p+1) % 1000;
        require(longitude <= 360, "Longitude show be less than 360");

        uint latitude = geocode / 10**(2*p+4) % 1000;
        require(latitude <= 180, "Latitude show be less than 180");

        uint levelSign = geocode / 10**(2*p+7) % 10;
        require(levelSign == 1 || levelSign == 3, "Level sign should be 1 or 3");

        uint level = geocode / 10**(2*p+8);
        if(levelSign == 1) {
            require(level <= 10**p, "Level should be less than 10**precision if it's negative");
        }

    }


    // function to mint subspaces
    function mintSubspace(uint256 geocode, uint x, uint y, uint z) public {
        require(_exists(geocode), "Space is not minted yet");
        require(msg.sender == ownerOf(geocode), "Only space owner can mint subspace");
        require(x>=0 && x<=9, "x should be between 0 and 9");
        require(y>=0 && y<=9, "y should be between 0 and 9");
        require(z>=0 && z<=9, "z should be between 0 and 9");
        uint p = geocode % 10;
        uint longitude = (geocode / 10**(1) % 10**(p + 3) * 10 + x) * 10;
        uint latitude = (geocode / 10**(p + 4) % 10**(p + 3) * 10 + y) * 10**(p + 5);
        uint levelSign = (geocode / 10**(2*p + 7) % 10) * 10**(2*(p+1) + 7);
        uint level = (geocode / 10**(2*p+8) * 10 + z) * 10**(2*(p+1) + 8);
        uint newGeocode = level + levelSign + latitude + longitude + p + 1;
        _safeMint(ownerOf(geocode), newGeocode);
        emit SpaceMinted(ownerOf(geocode), newGeocode);
    }

    // random function
    function _randomMint(uint vendingLevel, uint n) internal  {
        for (uint i = 0; i < n; i++) {
            uint256 random = uint(keccak256(abi.encodePacked(block.number, block.timestamp, block.difficulty, msg.sender, vendingLevel, i)));
            uint longitude = random % 3600;
            uint latitude = random / 3600 % 1700 + 50;  // limit the venting range withing 50 to 1750 for better user experience.
            uint geocode = vendingLevel * 10**9 + latitude * 10**5 + longitude * 10**1 + 1;
            if (_exists(geocode) || ! (auctionEndTime[geocode]==0)) {
                n = n + 1;
            } else {
                _safeMint(msg.sender, geocode);
                emit SpaceMinted(msg.sender, geocode);
            }
        }
    }

    // vending function
    function vending(uint vendingLevel) public payable {
        require(msg.value >= vendingPrice, "Value should be greater than vendingPrice");
        require(vendingLevel % 10 == 1 || vendingLevel % 10 == 3, "Vending level sign should be 1 or 3");
        uint n = msg.value / vendingPrice;
        _randomMint(vendingLevel, n); // vending on level 0 and 3 is for positive space
    }

    function genesisAuction(uint256 geocode) public payable {
        _checkGeocode(geocode);
        require(msg.value >= auctionFloor, "Value should be greater than auctionFloor");
        require(!_exists(geocode), "Space is already minted");
        require(auctionEndTime[geocode]==0, "Space is already in auction");

        if(geocode % 10 == 1){
            require(msg.value >= vendingPrice, "Auction starting bid should be greater than vending Price");
            
        } else {
            require(subspaceAvailableForAuction[parent(geocode)] == true, "Space is not available for auction");
        }

        auctionEndTime[geocode] = block.timestamp + auctionDuration;
        highestBid[geocode] = msg.value;
        unWithdrawnFunds += msg.value;
        highestBidder[geocode] = msg.sender;
        emit AuctionStarted(geocode, auctionEndTime[geocode], highestBid[geocode], highestBidder[geocode]);
    }

    function putSubspaceToAuciton(uint256 geocode) public {
        _checkGeocode(geocode);
        require(ownerOf(geocode) == msg.sender, "Only space owner can put subspace to auction");
        subspaceAvailableForAuction[geocode] = true;
        emit SubSpaceAuctionAllowed(geocode);
    }



    function parent(uint256 geocode) public pure returns (uint256 parentGeocode) {
        uint p = geocode % 10;
        require(p>1, "You are naughty. Top spaces don't have parents");
        uint longitude = geocode / 10**(p) % (10**(p+2));
        uint latitude = geocode / 10**(p+5) % (10**(p+2));
        uint levelSign = geocode / 10**(2*p + 7) % 10;
        uint level = geocode / 10**(2*p+9);
        parentGeocode = level*10**(2*p+6) + levelSign*10**(2*p+5) + latitude * 10**(p+3) + longitude * 10 + p-1;
    }

    function bid(uint256 geocode) public payable {
        require(msg.value > 0, "Value should be greater than 0");
        _checkGeocode(geocode);
        require(!_exists(geocode), "Space is already minted");
        require(!(auctionEndTime[geocode]==0), "Space is not on auction");
        require(block.timestamp < auctionEndTime[geocode], "Space auction is over");
        
        uint newBid;
        // increase the bid 
        if(msg.sender == highestBidder[geocode]) {
        newBid = highestBid[geocode] + msg.value;
        } else {
        newBid = pendingReturns[geocode][msg.sender] + msg.value;
        }

        require(newBid > highestBid[geocode], "Bid should be greater than highestBid");
        
        pendingReturns[geocode][msg.sender] = 0;
        pendingReturns[geocode][highestBidder[geocode]] = highestBid[geocode];
        highestBid[geocode] = newBid;
        highestBidder[geocode] = msg.sender;
        unWithdrawnFunds += msg.value;
        emit HighestBidIncreased(geocode, msg.sender, newBid);

        if(block.timestamp > (auctionEndTime[geocode] - 10 * 60) ){
            auctionEndTime[geocode] += 10 * 60;  //  Any bids made in the last 10 minutes of an auction will extend each auction by 10 more minutes.
            emit AuctionExtended(geocode, auctionEndTime[geocode]);
        }


    }

    function withdraw(uint256 geocode) public returns (bool) {
        require(block.timestamp > auctionEndTime[geocode], "Please wait for space auction to end to withdraw");
        _checkGeocode(geocode);
        uint amount = pendingReturns[geocode][msg.sender];
        require(amount > 0, "You have no pending returns");
        pendingReturns[geocode][msg.sender] = 0;
        unWithdrawnFunds -= amount;
        if(!payable(msg.sender).send(amount)){
            pendingReturns[geocode][msg.sender] = amount;
            return false;
        }
        emit withDrawalRequested( geocode, msg.sender, amount);
        return true;
    }

    function genesisAuctionEnd(uint256 geocode) public {
        _checkGeocode(geocode);
        require(block.timestamp > auctionEndTime[geocode], "Space auction is not over");
        require(!_exists(geocode), "Space is already minted");

        if(geocode % 10 == 1){

        _safeMint(highestBidder[geocode], geocode);
       
        } else {
        
        _safeMint(highestBidder[geocode], geocode);
        
        uint256 parentGeocode = parent(geocode);
        uint amount = highestBid[geocode] / 10000 * (10000 - royaltyFeesInBips);  //  royaltyFeesInBips / 10000 % of the bid is the royalty fees
        payable(ownerOf(parentGeocode)).transfer(amount);

        }

        unWithdrawnFunds -= highestBid[geocode];

        emit AuctionEnded(geocode, highestBidder[geocode], highestBid[geocode]);

    }



    function ownerWithdraw(uint amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }
}