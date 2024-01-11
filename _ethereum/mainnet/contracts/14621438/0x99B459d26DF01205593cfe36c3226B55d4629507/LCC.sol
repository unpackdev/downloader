// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract LCC is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant TOTAL_SUPPLY = 1000;
    
    // Variables
    uint256 public MINT_PRICE = 0.000000000000001 ether;
    mapping(address => bool) whitelistedAddressesOG;
    uint256 public timestampPublicSale = 1672527599; // init to 2022-12-31 23:59:59 CET, to be set by owner
    uint public percentageForTrading = 80;
    uint public phase = 1;

    Counters.Counter public currentTokenId;
    
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721("LCC_old", "LCC_old") {
        baseTokenURI = "https://bafybeid5e2cutdvjrj766vnbpll36dc3msunpc2wycccp52d6pqjxzn5pa.ipfs.dweb.link/metadata/";
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

    /// Sets the mint phase. 1 to 10
    function setPhase(uint _phase) public onlyOwner {
        require(_phase <=10, "phase should be < 10");
        phase = _phase;
    }



    // Internal mint
    function _mint() private returns (uint256) {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(msg.sender, newItemId);
        return(newItemId);
    }
 
    // Mint token if conditions are fulfilled.  
    function mint(uint number) public payable {
        uint256 tokenId = currentTokenId.current();

        require( ((tokenId + number) / phase) <= 100, "Max supply reached");
        require(msg.value >= MINT_PRICE * number, "Transaction value is less than the min mint price");

        if( timestampPublicSale > block.timestamp ) {
            for(uint i=0; i<number; i++) {
                require( 
                        verifyUserOG(msg.sender) ,
                        "You need to be whitelisted to mint token or you have wait for the public sale"
                    );

                _mint();
            }
        }
        else {
            for(uint i=0; i<number; i++) {
                _mint();
            }
        }
    }

    // Smart contract owner can mint as many as he wants
    function mintFromOwner(uint number) public onlyOwner {
        uint256 tokenId = currentTokenId.current();
        require(tokenId + number <= TOTAL_SUPPLY, "Max supply reached");
        for (uint i=0; i<number; i++) {
            _mint();
        }
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