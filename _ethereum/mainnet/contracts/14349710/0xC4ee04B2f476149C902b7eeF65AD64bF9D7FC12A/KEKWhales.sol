// SPDX-License-Identifier: MIT

/* 
██╗  ██╗███████╗██╗  ██╗██╗    ██╗██╗  ██╗ █████╗ ██╗     ███████╗███████╗
██║ ██╔╝██╔════╝██║ ██╔╝██║    ██║██║  ██║██╔══██╗██║     ██╔════╝██╔════╝
█████╔╝ █████╗  █████╔╝ ██║ █╗ ██║███████║███████║██║     █████╗  ███████╗
██╔═██╗ ██╔══╝  ██╔═██╗ ██║███╗██║██╔══██║██╔══██║██║     ██╔══╝  ╚════██║
██║  ██╗███████╗██║  ██╗╚███╔███╔╝██║  ██║██║  ██║███████╗███████╗███████║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
                        https://www.kekwhales.com
*/

pragma solidity ^0.8.0;


import "./ERC721A.sol";
import "./Ownable.sol";

contract KEKWhales is ERC721A, Ownable {
    uint public price = 0.03 ether;
    uint public max = 969;
    uint public txnLimit = 5;
    uint public presaleTxnLimit = 3;
    bool public saleIsActive = false;
    bool public presaleIsActive = false;
    string public baseURI = "";
    string public constant baseExtension = ".json";
    string public contractURI = "";
    mapping(address => bool) private presaleList;

    constructor() 
        ERC721A("KEKWhales", "KEKWhale") {
        
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function mintWhale(uint total) public payable {

        address _caller = _msgSender();
        require(total > 0, "Number to mint must be greater than 0");
        require(tx.origin == _caller, "No contracts plz");

        if(presaleIsActive) {
            require(presaleList[msg.sender], "You are not on the presale list.  Please wait for public mint.");
            require(total <= presaleTxnLimit, "Over presale transaction limit");
            require(price * (total - 1) <= msg.value, "Ether value sent is not correct.  You only get one free mint.");
            presaleList[msg.sender] = false;
        } else {
            require(saleIsActive, "The sale is not active");
            require(price * total <= msg.value, "Ether value sent is not correct");
            require(total <= txnLimit, "Over transaction limit");
        }
        
        require(max >= totalSupply() + total, "Amount requested exceeds max supply");
        
        _safeMint(msg.sender, total);
    }

    function addUserToPresale(address userAddress) public onlyOwner {
        presaleList[userAddress] = true;
    }

    function addUsersToPresale(address[] calldata userAddresses) public onlyOwner {
        for(uint i=0; i < userAddresses.length; i++) {
            presaleList[userAddresses[i]] = true;
        }
    }

    function isUserInPresale(address userAddress) public view returns(bool) {
        bool userIsInPresale = presaleList[userAddress];
        return userIsInPresale;
    }

    function giftWhale(address addr, uint total) public payable onlyOwner {
        require(total > 0, "Number to mint must be greater than 0");
        require(max >= totalSupply() + total, "Amount requested exceeds max supply");
        _safeMint(addr, total);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setPrice(uint price_) external onlyOwner {
        price = price_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
