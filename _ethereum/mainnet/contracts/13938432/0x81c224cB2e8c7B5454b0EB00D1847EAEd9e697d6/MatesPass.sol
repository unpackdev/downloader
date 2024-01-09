// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract AussieMatesMatesPass is ERC1155, Ownable {
    constructor() ERC1155("uri") {}


    uint256 public maxSupply = 5000;
    uint256 public PRICE = 40000000000000000; //0.04

    bool public saleIsActive = false;

    uint public supply  = 0;
    string private _baseTokenURI;
    uint public maxPerTransaction = 3;
    uint public maxPerWallet = 3;
    string public contractURIstr = "";
    string public name = "AussieMates Official MatesPass";

    //dev wallet address
    address payable private devguy = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);

    //minting function
    function mint(uint256 amount)
        public
        payable
    {
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= maxPerTransaction, "Max 3 NFTs");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(supply+amount <= maxSupply, "Not enough passes left");
        require(balanceOf(msg.sender, 1) + amount <= maxPerWallet, "Max 3 NFTs per wallet");
        
        _mint(msg.sender, 1, amount, "");
        supply += amount;
    }

    //withdraw function
    function withdraw() external
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");
        require(address(this).balance > 0, "Balance is 0");

        uint devPart = address(this).balance / 100 * 6;
        devguy.transfer(devPart);
        payable(owner()).transfer(address(this).balance);
    }   

    //
    function flipSaleState()external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    //change sales details
    function changeSaleDetails(uint _maxPerTransaction, uint _maxPerWallet, uint _maxSupply, uint _price) external onlyOwner 
    {
        maxPerTransaction = _maxPerTransaction;
        maxPerWallet = _maxPerWallet;
        maxSupply = _maxSupply;
        PRICE = _price;
        saleIsActive = false;
    }

   function supportsInterface(bytes4 interfaceId)public view
    override(ERC1155)returns(bool) {
        return super.supportsInterface(interfaceId);
    }

    ////
    //URI management part
    ////

    //set contract name
    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function getName() public view returns (string memory) {
       return name;
    }

    function contractURI() public view returns (string memory){
       return contractURIstr;
    }
    
    function setContractURI(string memory newuri) external onlyOwner {
       contractURIstr = newuri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    
    function _setBaseURI(string memory baseURI)internal virtual {
        _baseTokenURI = baseURI;
    }

    function setBaseURI(string memory baseURI)external onlyOwner {
        _setBaseURI(baseURI);
    }

}
