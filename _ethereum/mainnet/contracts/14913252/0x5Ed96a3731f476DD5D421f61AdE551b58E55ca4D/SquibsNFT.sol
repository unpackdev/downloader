// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;                                                                          

import "./ERC721A.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./IERC2981.sol";

pragma solidity 0.8.9;
pragma abicoder v2;

contract Squibs is ERC721A, Ownable {

    uint256 public squibsPrice = 30000000000000000; // 0.03 ETH

    uint public constant maxSquibsPurchase = 5;

    uint256 public availableSquibs = 5267;

    bool public saleIsActive = false;

    // Withdraw addresses
    address t1 = 0x9159b574895936F22b661aE4Cbc0040ee4628a44; // SQUIBBY WALLET
    address t2 = 0x1BfA80C141D17bf98809Ce70aDE9E298ba1b2Bcd; // COMMUNITY WALLET

    string private _baseTokenURI;

    constructor() ERC721A("SQUIBS", "SQUIBS") { }

    modifier squibsCapture() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
    function withdraw() public onlyOwner {
        uint256 _total = address(this).balance;
        require(payable(t1).send(((_total)/100)*85)); 
        require(payable(t2).send(((_total)/100)*15)); 
    }

    function setTheSquibsPrice(uint256 newPrice) public onlyOwner {
        squibsPrice = newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


    // Utility 

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mint(uint squibsAmount) public payable squibsCapture {
        require(saleIsActive, "Public Sale is not active");
        require(squibsAmount > 0 && squibsAmount <= maxSquibsPurchase, "This is not possible");
        require(totalSupply() + squibsAmount <= availableSquibs, "Supply would be exceeded");
        require(msg.value >= squibsPrice * squibsAmount, "Ether value sent is incorrect");

            _safeMint(msg.sender, squibsAmount);
    } 

}