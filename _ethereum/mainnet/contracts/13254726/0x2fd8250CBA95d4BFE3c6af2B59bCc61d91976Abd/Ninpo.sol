// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Ninpo is ERC721Enumerable, Ownable {

    using Strings for uint256;

    // base URI
    string _baseTokenURI;
    // Price of each Ninpo
    uint256 private _price = 0.08 ether;
    // Maximum amount of Ninpo in existance 
    uint256 public _total_ninpo = 8888;
    uint256 public _max_giveaway = 88;
    // Max presale 
    uint256 public presaleListMax = 3;
    // Presale list
    mapping(address => bool) private _presaleList;
    // Presale claimed
    mapping(address => uint256) private _presaleListClaimed;
    // Pause sales
    bool public _paused = true;
    // Pause Presale
    bool public _presale_paused = true;
    // ninpo addresses
    address ninpo = 0x4135A02896740AD0b64A0BA1BEb0E73db3d5bb81;
    

    constructor(string memory tokenURI) ERC721("Ninpo Gakko", "NINPO") {
        setBaseURI(tokenURI);
        // ninpo team mint the first one
        _safeMint( ninpo, 0);
    }

    /**
    * @dev Mint Ninpo
    */
    function mint(uint256 ninpoNumber) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( msg.value >= _price * ninpoNumber,             "Ether sent is not correct" );
        require( supply + ninpoNumber < _total_ninpo - _max_giveaway ,      "Exceeds maximum Ninpo supply" );
        require(ninpoNumber > 0, "You cannot mint 0 Ninpo");
        require(ninpoNumber <= 20, "You are not allowed to buy this many Ninpo at once");

        for(uint256 i; i < ninpoNumber; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    /**
    * @dev Presale Ninpo
    */
    function presale(uint256 ninpoNumber) public payable {
        uint256 supply = totalSupply();
        require( !_presale_paused,                              "Presale paused" );
        require(_presaleList[msg.sender], 'You are not on the Allow List');
        require(supply + ninpoNumber < _total_ninpo - _max_giveaway, 'Exceeds maximum Ninpo supply');
        require(ninpoNumber <= presaleListMax, 'Cannot purchase this many Ninpo');
        require(_presaleListClaimed[msg.sender] + ninpoNumber <= presaleListMax, 'Purchase exceeds max allowed');
        require( msg.value >= _price * ninpoNumber,             "Ether sent is not correct" );

        for (uint256 i = 0; i < ninpoNumber; i++) {
            _presaleListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
    * @dev Add people to Presale List
    */
    function addToPresaleList(address[] calldata presaleList) public onlyOwner {
        for (uint256 i = 0; i < presaleList.length; i++) {
            _presaleList[presaleList[i]] = true;
            _presaleListClaimed[presaleList[i]] > 0 ? _presaleListClaimed[presaleList[i]] : 0;
        }
    }

    /**
    * @dev Check if you are in Presale List
    */
    function onPresaleList(address presaleCheck) public view returns (bool) {
        return _presaleList[presaleCheck];
    }

    /**
    * @dev Remove people from Presale List
    */
    function removeFromAllowList(address[] calldata removeList) public onlyOwner {
        for (uint256 i = 0; i < removeList.length; i++) {
            _presaleList[removeList[i]] = false;
        }
    }

    /**
    * @dev Check how many is claimed already
    */
    function allowListClaimedBy(address owner) public view returns (uint256){
        return _presaleListClaimed[owner];
    }

    /**
    * @dev Give away (Callable by owner only)
    */
    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        require( _amount < _max_giveaway,      "Exceeds maximum ninpo giveaway" );

        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _max_giveaway -= _amount;
    }

    /**
    * @dev Owner Mint Ninpo
    */
    function ownerMint(address _to,uint256 ninpoNumber) external onlyOwner() {
        uint256 supply = totalSupply();
        require( supply + ninpoNumber < _total_ninpo - _max_giveaway,      "Exceeds maximum Ninpo supply" );

        for(uint256 i; i < ninpoNumber; i++){
            _safeMint( _to, supply + i );
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    * @dev Change the base URI 
    */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    /**
    * @dev Change the total Ninpo
    */
    function setTotalNinpo(uint256 totalNinpo) public onlyOwner {
        _total_ninpo = totalNinpo;
    }

    /**
    * @dev Change the max giveaway
    */
    function setGiveaway(uint256 maxGiveaway) public onlyOwner {
        _max_giveaway = maxGiveaway;
    }

    /**
    * @dev Change the presale list max number
    */
    function setpresaleListMax(uint256 maxPresaleListMax) public onlyOwner {
        presaleListMax = maxPresaleListMax;
    }


    /**
    * @dev Get all tokens of a owner provided
    */
    function getTokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
    * @dev Set Price 
    */
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    /**
    * @dev Get Price 
    */
    function getPrice() public view returns (uint256){
        return _price;
    }

    /**
    * @dev Pause the sale
    */
    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    /**
    * @dev Pause the presale
    */
    function presalePause(bool val) public onlyOwner {
        _presale_paused = val;
    }

    /**
    * @dev Withdraw 
    */
    function withdraw() onlyOwner public {
        uint256 _balance = address(this).balance;
        require(payable(ninpo).send(_balance));
    }
}
