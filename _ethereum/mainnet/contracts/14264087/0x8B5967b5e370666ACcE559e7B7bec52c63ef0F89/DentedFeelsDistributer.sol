// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;


import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./SafeMath.sol";

/**
 * @title Dented Feels helper contract
 * @author @FrankPoncelet
 * 
 */

contract DentedFeelsHelper is IERC721Receiver, ERC165, Ownable   {
    using SafeMath for uint256;
        
    mapping(address => bool) private whitelist;
    mapping(address => uint256) private ammount;
    bool public saleIsActive;
    bool public preSaleIsActive;
    IERC721 public dentedContract;
    uint256 public tokenPrice = 0.11 ether; 

    address private constant ONE = 0xE3cE6966c6dCdfB49055d8d0c6D46C09CDbd13f7;
    address private constant TWO = 0x12d7F4C942C8264BD1f0D3c3B2313EF794030222;
    address private constant TREE = 0xd7d9B479106EF63DF5e46C1D9cAA5db4078E2Ac3;
    address private constant FOUR = 0x7356646D4bAC2Ee3c92700f213851fd7Ae9b3533;
    address private constant FIVE = 0x74F3647c2b76BD5257D7c1dF25b1759e8fAc7442;
    address private constant SIX = 0x7297E66567526781Ca42B818bff80bb747876955;
    address private constant SEVEN = 0xB57dF54d276B3555b2F99ab5C1266cBe4e931b1e;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant SIMON = 0x743CA37E0b8bAFb4Ca2D49382f820410d6e6E431;
    uint256[] private ids;


    event priceChange(address _by, uint256 price);

    constructor() {
        dentedContract=IERC721(0xc5e55e4Bd5Fef12831b5a666fc9e391538ACdc45);
    }
    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            preSaleIsActive=false;
        }
    }

    /**
     * Mint Tokens to a wallet.
     */
    function mint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply.sub(numberOfTokens) >= 0, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < 26, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 id= ids[ids.length-1];
            ids.pop();
            dentedContract.safeTransferFrom(address(this),to,id,'');
        }
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }

    /**
    * add an address to the WL
    */
    function addWL(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    /**
    * add an array of address to the WL
    */
    function addAdresses(address[] memory _address) external onlyOwner {
         for (uint i=0; i<_address.length; i++) {
            addWL(_address[i]);
         }
    }

    /**
    * remove an address off the WL
    */
    function removeWL(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    /**
    * returns true if the wallet is Whitelisted.
    */
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    function mint(uint256 numberOfTokens) external payable{
        require(msg.sender == tx.origin);
        if(preSaleIsActive){
            require(isWhitelisted(msg.sender),"sender is NOT Whitelisted ");
        }else{
            require(saleIsActive,"Sale NOT active yet");
        }
        require(ammount[msg.sender]+numberOfTokens<3,"Purchase would exceed max mint for walet");
        uint256 supply = totalSupply();
        require(supply.sub(numberOfTokens) >= 0, "Purchase would exceed max supply of Tokens");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");  
        ammount[msg.sender] = ammount[msg.sender]+numberOfTokens;
        for(uint256 i; i < numberOfTokens; i++){
            uint256 id= ids[ids.length-1];
            ids.pop();
            dentedContract.safeTransferFrom(address(this),msg.sender,id,'');
        }
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return ids.length;
    }

    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes memory
    ) public virtual override returns (bytes4) {
        ids.push(id);
        return this.onERC721Received.selector;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(ONE, (balance*30)/100);
        _withdraw(TWO, (balance*25)/100);
        _withdraw(TREE, (balance*20)/100);
        _withdraw(FOUR, (balance*9)/100);
        _withdraw(FIVE, (balance)/100);
        _withdraw(SIX, (balance*5)/100);
        _withdraw(SEVEN, (balance*5)/100);
        _withdraw(FRANK, (balance)/100);
        _withdraw(SIMON, (balance*4)/100);
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }
}