// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

/*
    Happy Pandas :: 10,000 Happy Panda NFTs. All unique, all happy.
*/

contract HappyPandas is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    // Constants
    uint256 public MAX_PANDAS = 10000;
    uint256 public MAX_PANDAS_PRESALE = 1000;
    uint256 public MAX_PANDA_PURCHASE = 10;

    uint256 public pandaPrice = 80000000000000000; //0.08 ETH
    bool public presaleActive = false;
    bool public saleActive = false;
    address[] public whitelist; // Pre-sale whitelist
    address[] public sold; // Pre-sale panda sold

    // Private members
    string private _currentBaseURI;

    constructor() ERC721("HappyPandas", "HPY") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    /* 
        Toggle sale state 
    */
    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    /* 
        Toggle pre-sale state 
    */
    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    /* 
        Checks if a user has already bought a panda in pre-sale
    */
    function hasBought(address _addr) public view returns(bool) {
        for (uint i = 0; i < sold.length; i++) {
            if (_addr == sold[i]) {
                return true;
            }
        }
        return false;
    }
    
    /*
        Adds the given addresses to the pre-sale whitelist 
    */
    function whitelistAdd(address[] memory _addr) public onlyOwner {
        for (uint i = 0; i < _addr.length; i++) {
            whitelist.push(_addr[i]);
        }
    }
    
    /*
        Removes the given address from the pre-sale whitelist 
    */
    function whitelistRemove(address _addr) public onlyOwner {
        for (uint i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _addr) {
                delete whitelist[i];
            }
        }
    }

    /*
        Clears the pre-sale whitelist 
    */ 
    function whitelistClear() public onlyOwner {
        delete whitelist;
    }

    /*
        Checks if a given address is whitelisted
    */
    function isWhitelisted(address _addr) public view returns(bool) {
        for (uint i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    /* 
        Set base price of the pandas
    */
    function setPandaPrice(uint256 price) public onlyOwner {
        pandaPrice = price;
    }

    /* 
        Sets the base URI, will be updated on reveal
    */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    /*
        Withdraw Happy Pandas wallet funds
    */
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /*
        Internal mint function for minting pandas
    */
    function mint(uint amount) public onlyOwner {
        // Mint pandas 
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            if (tokenId <= MAX_PANDAS) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    /*
        Mints a given amount of tokens to the contract wallet 
    */
    function mintTo(uint amount, address _addr) public onlyOwner {
        // Mint pandas 
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            if (tokenId <= MAX_PANDAS) {
                _safeMint(_addr, tokenId);
            }
        }
    }

    /*
        Payable mint function for presale
    */
    function mintPresale() external payable {
        require(isWhitelisted(msg.sender), "Must be on the whitelist");
        require(hasBought(msg.sender) == false, "Address has already purchased pre-sale panda");
        require(presaleActive, "Presale is not active now");
        require(totalSupply().add(1) <= MAX_PANDAS_PRESALE + 100, "Cannot mint more than the maximum number of pandas");

        // Mint panda
        uint256 tokenId = totalSupply();
        if (tokenId < MAX_PANDAS_PRESALE + 100) {
            _safeMint(msg.sender, tokenId);
            // Mark address as having bought a panda
            sold.push(msg.sender);
        }
    }

    /*
        Payable mint function for primary sale
    */
    function mintPanda(uint amount) external payable{
        require(saleActive, "Sale is not active now");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= MAX_PANDA_PURCHASE, "Cannot mint more than 10 pandas at a time");
        require(totalSupply().add(amount) <= MAX_PANDAS, "Cannot mint more than the maximum number of pandas");
        require(pandaPrice.mul(amount) <= msg.value, "Ether value sent is not correct");

        // Mint pandas
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            if (tokenId < MAX_PANDAS) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    /*
        Burn function, should not be used
    */
    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }
}
