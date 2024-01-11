// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721A.sol";
import "./Ownable.sol";

contract LCC is ERC721A, Ownable {

    // Constants
    uint256 public constant MAX_SUPPLY = 10_000;

    
    // Variables
    uint256 public MINT_PRICE = 0.07 ether;
    mapping(address => bool) whitelistedAddressesOG;
    uint256 public timestampPublicSale = 1672527599; // init to 2022-12-31 23:59:59 CET, to be set by owner
    uint public percentageForTrading = 80;
    uint public TRANCHE = 1;

    
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721A("Legendary Cobra Club", "LCC", 1000, MAX_SUPPLY) {
        baseTokenURI = "https://bafybeiad2xylgb47iw2ukcvhhfmtonuarf5e7k6xh3wvk5hyddxhan2imy.ipfs.dweb.link/metadata/";
    }



    /// @dev Returns an URI for a given token ID.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// Sets the minimum mint token price.
    function setMintPrice(uint _mint_price) public onlyOwner {
        MINT_PRICE = _mint_price;
    }

    /// Sets the timestamp date when everyone can mint new token.
    function setTimestampPublicSale(uint256 _timestampPublicSale) public onlyOwner {
        timestampPublicSale = _timestampPublicSale;
    }

    /// Sets the percentage for trading.
    function setPercentageForTrading(uint _newPercentage) public onlyOwner {
        percentageForTrading = _newPercentage;
    }

    /// Sets the mint trannche. 1 to 10
    function setTranche(uint _tranche) public onlyOwner {
        require(_tranche <=10, "tranche should be < 10");
        TRANCHE = _tranche;
    }


    // Mint token if conditions are fulfilled.  
    function mint(uint number) public payable {

        require( ((totalSupply() + number) / TRANCHE) <= 1000, "Max supply reached");
        require(msg.value >= MINT_PRICE * number, "Transaction value is less than the min mint price");

        if( timestampPublicSale > block.timestamp ) {
            require( 
                        verifyUserOG(msg.sender) ,
                        "You need to be whitelisted to mint token or you have wait for the public sale"
                    );
            _safeMint(msg.sender, number);
        }
        else {
            _safeMint(msg.sender, number);
        }
    }

    // Owner can mint without paying smart contract
    function mintFromOwner(uint number) public onlyOwner {
        require( ((totalSupply() + number) / TRANCHE) <= 1000, "Max supply reached");
        _safeMint(msg.sender, number);
    }


    /// Add a new address to the OG whitelist mapping.
    function addWhitelistUserOG(address[] memory newWhitelistedUserOG) public onlyOwner {
        for (uint i=0; i<newWhitelistedUserOG.length; i++) {
            require( !verifyUserOG( newWhitelistedUserOG[i] ) , "already OG" );
            whitelistedAddressesOG[ newWhitelistedUserOG[i] ] = true;
        }
    }
    /// Verify is an address is whitelisted OG. 
    function verifyUserOG(address _whitelistedAddressOG) public view returns(bool) {
        return whitelistedAddressesOG[_whitelistedAddressOG];
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoneyTo(address payable _to) public onlyOwner {
        _to.transfer(getBalance() * (100 - percentageForTrading) / 100);
    }

    function withdrawMoneyForTrading() public onlyOwner {
        payable(msg.sender).transfer(getBalance() * percentageForTrading / 100);
    }
}