// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";


/**
 * @title Token2476 contract
 * @dev Extends ERC1155 contract 
 * @author @FrankPoncelet
 * Owner Artchick
 */
contract Token2476 is ERC1155Supply, Ownable, ERC1155Pausable, ERC1155Burnable{
    using SafeMath for uint256;
        
    bool public saleIsActive;
    uint256 public tokenPrice = 1 ether; 
    uint256 private mintedTokens;
    uint constant TOKEN_ID = 2476;
    uint constant MAX_TOKENS = 10000;
    
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant WALLET2476 = 0x0b8F4C4E7626A91460dac057eB43e0de59d5b44F;
    address public attention2476Contract;
    
    event priceChange(address _by, uint256 price);
    event PaymentReleased(address to, uint256 amount);

    constructor() ERC1155("ipfs://QmRuSYR65tcM3vG5Tjyi32vW3CCthX9MNwVaVooZ5KNoeJ") { 
        _mint(FRANK,TOKEN_ID,1, "");
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
        return "Token 2476";
    }

    function symbol() public pure returns (string memory) {
        return "2476";
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
     * Join the 2476 attention contract.
     */
    function join2476() public{
        setApprovalForAll(attention2476Contract,true);
    }
    
    /**
     * Allow to change the Attention crontract in case of updates.
     */
    function setAttentionContract(address contractAddress) public onlyOwner{
        attention2476Contract=contractAddress;
    }
    /**
     * mint the requested numer of tokens.
     * MAX 20!
     * 
     */
    function mint(uint numberOfTokens) external payable{
        require(saleIsActive, "2476: Sale must be active to mint Tokens!");
        require(mintedTokens + numberOfTokens <= MAX_TOKENS, "2476: Purchase would exceed max supply of tokens!");
        require(!paused(), "2476: Minting is paused");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "2476: Ether value sent is not correct");
        require(numberOfTokens<=20,"2476: You can only mint 20 tokens at a time");
        mintedTokens += numberOfTokens;
        _mint(msg.sender,TOKEN_ID,numberOfTokens , "");
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(WALLET2476).send(balance));
        emit PaymentReleased(owner(), balance);
    }

}