// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ____    ______   __       ____    ____       
// /\  _`\ /\__  _\ /\ \     /\  _`\ /\  _`\     
// \ \ \L\ \/_/\ \/ \ \ \    \ \ \/\ \ \ \L\ \   
//  \ \  _ <' \ \ \  \ \ \  __\ \ \ \ \ \ ,  /   
//   \ \ \L\ \ \_\ \__\ \ \L\ \\ \ \_\ \ \ \\ \  
//    \ \____/ /\_____\\ \____/ \ \____/\ \_\ \_\
//     \/___/  \/_____/ \/___/   \/___/  \/_/\/ /                                            

// @jonathansnow x @tom_hirst

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract BildrCollectionPass is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 25;
    uint256 public constant PRICE_WAVE_ONE = 2 ether;
    uint256 public constant PRICE_WAVE_TWO = 4 ether;

    bool public saleIsActive;

    address r1 = 0xb6ba815DC649b7Db1Ed4dA400da9D76688ea8A54;
    address r2 = 0x3E7898c5851635D5212B07F0124a15a2d3C547EB;
    address r3 = 0x2C6B8C19dd7174F6e0cc56424210F19EeFe62f94;

    constructor() ERC721("BildrCollectionPass", "BCNP") {
        _nextTokenId.increment();   // Start Token Ids at 1
        saleIsActive = false;       // Set sale to inactive
    }

    // Function to handle minting passes
    function mint() public payable {
        require(saleIsActive, "Sale is not active yet.");
        require(_nextTokenId.current() <= MAX_SUPPLY, "Exceeds max available.");
        require(msg.value >= currentPrice(), "Wrong ETH value sent.");

        _safeMint(msg.sender, _nextTokenId.current());
        _nextTokenId.increment();
    }

    // Function to determine the current price of a pass
    function currentPrice() public view returns (uint256) {
        if (totalSupply() < 5) {
            return PRICE_WAVE_ONE;
        } else {
            return PRICE_WAVE_TWO;
        }
    }

    // Function to return the number of passes remaining to mint
    function passesRemaining() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    // Function to return how many passes have been minted
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // Function to override the baseURI function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Function to set or update the baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Function to flip the sale on or off
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Function to withdraw ETH balance with splits
    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(r1).transfer((balance * 950) / 1000);  // 95%   - Bildr
        payable(r2).transfer((balance * 25) / 1000);   // 2.5%  - Dev
        payable(r3).transfer((balance * 25) / 1000);   // 2.5%  - Dev
        payable(r1).transfer(address(this).balance);   // Transfer remaining balance to Bildr
    }

}