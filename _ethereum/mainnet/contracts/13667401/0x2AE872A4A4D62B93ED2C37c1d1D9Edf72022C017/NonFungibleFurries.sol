// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "ERC721.sol";
import "Ownable.sol";
import "SafeMath.sol";


/**
 * @title NFT contract - forked from BAYC
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NonFungibleFurries is ERC721, Ownable{
    using SafeMath for uint256;

    uint256 public constant maxSupply = 6969;
    uint256 public constant price = 5*10**16;
    uint256 public constant purchaseLimit = 10;
    uint256 internal constant reservable = 25;
    uint256 internal constant team = 10;
    string internal constant _name = "Non Fungible Furries";
    string internal constant _symbol = "NFF";
    address payable immutable public payee;
    address payable immutable public deployer;
    address internal immutable reservee = 0xd5F5e8c384dd0d02cbB30d1cf4689A04d69034c5;

    string public contractURI;
    string public provenance;
    bool public saleIsActive = true;
    uint256 public saleStart = 1637622000;

    constructor (
        address payable _payee
        ) public ERC721(_name, _symbol) {
        payee = _payee;
        deployer = msg.sender;
        _setBaseURI("ipfs://QmX1qg9kH9eoMqku85SBdDnyKd1uajFt99ey5LrtBaSw7Z/");
    }

    /** 
     * emergency withdraw function, callable by anyone
     */
    function withdraw() public {
        payee.transfer(address(this).balance);
    }

    /**
     * reserve
     */
    function reserve() public {
        require(totalSupply() < reservable, "reserve would exceed reservable");
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 75; i++) {
            if (totalSupply() < reservable - team) {
                _safeMint(reservee, supply + i);
            } else if (totalSupply() < reservable){
                _safeMint(deployer, supply + i);
            }
        }
    }

    /**
     * set provenance if needed
    */
    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    /*
    * sets baseURI
    */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * set contractURI if needed
    */
    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = (_contractURI);
    }


    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * updates saleStart
    */
    function setSaleStart(uint256 _saleStart) public onlyOwner {
        saleStart = _saleStart;
    }

    /**
    * mint
    */
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(block.timestamp >= saleStart, "Sale has not started yet, timestamp too low");
        require(numberOfTokens <= purchaseLimit, "Purchase would exceed purchase limit");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Purchase would exceed maxSupply");
        require(price.mul(numberOfTokens) <= msg.value, "Ether value sent is too low");
        
        if(totalSupply() < 76){
            deployer.transfer(address(this).balance); 
        } else {
            payee.transfer(address(this).balance);
        }
               
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

}