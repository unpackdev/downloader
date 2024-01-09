// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract CumRocketCuties is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public TOTAL_SUPPLY = 100; 
    uint256 public MINT_PRICE = 0.069 ether; 
    uint256 public MAX_PER_ADDRESS = 2;
    uint256 public MAX_PER_TX = 2;

    uint256 public supplyMinted;

    string public baseTokenURI;

    bool public saleStarted;
    bool public whitelistOn = true;

    mapping(address => bool) private whitelist;

    mapping(address => uint256) public totalClaimed;

    event BaseURIChanged(string baseURI);
    event NftMinted(address minter, uint256 amount);
    event WhitelistToggled(bool toggled);
    event SaleToggled(bool toggled);

    modifier whenSaleStarted() {
        require(saleStarted, "Sale has not started");
        _;
    }

    constructor(string memory baseURI) ERC721("CumRocket Cuties", "Cuties") {
        baseTokenURI = baseURI;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            whitelist[addresses[i]] = true;
        }
    }

    function checkWhitelistEligibility(address addr) external view returns (bool) {
        return whitelist[addr];
    }

    function mint(uint256 amount) external payable whenSaleStarted {
        if(whitelistOn) {
            require(whitelist[msg.sender], "You're not in the whitelist");
        }
        require(totalSupply() + amount <= TOTAL_SUPPLY, "Minting would exceed max supply");
        require(totalClaimed[msg.sender] + amount <= MAX_PER_ADDRESS, "Purchase exceeds max allowed per address");
        require(amount > 0, "Must mint at least one");
        require(amount <= MAX_PER_TX, "Amount over max per transaction. ");
        require(MINT_PRICE * amount <= msg.value, "Amount is incorrect");
        
        for (uint256 i = 0; i < amount; i++) {
            supplyMinted += 1;
            totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, supplyMinted);
        }

        emit NftMinted(msg.sender, amount);
    }

    function startSale() external onlyOwner {
        saleStarted = !saleStarted;
        emit SaleToggled(saleStarted);
    }

    function toggleWhitelist() external onlyOwner {
        whitelistOn = !whitelistOn;
        emit WhitelistToggled(whitelistOn);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(recipient, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}