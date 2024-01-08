// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";


/**
 * @title FudToken contract
 * @dev Extends ERC1155 contract 
 * @author @FrankPoncelet
 * @dev @FuegoNFT
 */

contract FudToken is ERC1155Supply, Ownable, ERC1155Pausable, ERC1155Burnable{
    using SafeMath for uint256;
        
    bool public saleIsActive;
    uint256 public tokenPrice = 0.025 ether; 
    uint256 private mintedTokens;
    uint constant TOKEN_ID = 7123;
    uint constant MAX_TOKENS = 10000;
    
    address private constant MIKE = 0xf6a39754ab1a18D19d2cF01dd1941c4b0D2bCF15;
    address private constant FUEGO = 0xADDaF99990b665D8553f08653966fa8995Cc1209;
    address private constant CHICK = 0x0b8F4C4E7626A91460dac057eB43e0de59d5b44F;
    address private constant TMAS = 0x756624F2c0816bFb6a09E6d463c695b39a146629;
    address public attentionFudContract;
    
    event priceChange(address _by, uint256 price);
    event PaymentReleased(address to, uint256 amount);

    constructor() ERC1155("ipfs://QmbqE73ZCmMW7eVfrkp8qEgHj6xZRG67Vhm3dsgqVM9cGd") { 
        _mint(FUEGO,TOKEN_ID,1, "");
        mintedTokens = 1;
    }
    
    function pause() external onlyOwner {
        _pause();
        if(saleIsActive){
            saleIsActive = false;
        }
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function name() public pure returns (string memory) {
        return "Fud Token";
    }

    function symbol() public pure returns (string memory) {
        return "FUD";
    }
    
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._burn(account, id, amount);
    }
    
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._mintBatch(to, ids, amounts, data);
    }
    
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._burnBatch(account, ids, amounts);
    } 
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Pausable, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  
    
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }
    
    /**     
    * Set price to new value
    */
    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }
    
    /**
     * Join the Fud attention contract.
     */
    function joinFUD() public{
        setApprovalForAll(attentionFudContract,true);
    }
    
    /**
     * Allow to change the Attention crontract in case of updates.
     */
    function setAttentionContract(address contractAddress) public onlyOwner{
        attentionFudContract=contractAddress;
    }
    /**
     * mint the requested numer of tokens.
     * MAX 20!
     * 
     */
    function mint(uint numberOfTokens) external payable{
        require(saleIsActive, "FUD: Sale must be active to mint Tokens!");
        require(mintedTokens + numberOfTokens <= MAX_TOKENS, "FUD: Purchase would exceed max supply of tokens!");
        require(!paused(), "FUD: Minting is paused");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "FUD: Ether value sent is not correct");
        require(numberOfTokens<=20,"FUD: You can only mint 20 tokens at a time");
        mintedTokens += numberOfTokens;
        _mint(msg.sender,TOKEN_ID,numberOfTokens , "");
    }
    
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(MIKE, ((balance * 10) / 100));
        _withdraw(FUEGO, ((balance * 15) / 100));
        _withdraw(CHICK, ((balance * 35) / 100));
        _withdraw(TMAS, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

}