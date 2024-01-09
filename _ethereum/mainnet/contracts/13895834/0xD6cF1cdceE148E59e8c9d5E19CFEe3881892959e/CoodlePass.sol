// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Pausable.sol";

contract CoodlePass is ERC1155Supply, Ownable , ERC1155Pausable  {
    bool public saleIsActive;
    uint constant TOKEN_ID = 1;
    uint constant NUM_RESERVED_TOKENS = 10;
    uint constant MAX_TOKENS = 101; // one too high to get cheaper gas comparison!
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;

    constructor() ERC1155("ipfs://QmRge8iwNBUnAkfCdCDDf7sd4pVkNiXbeTRx1TUoRf3wxr") {
        _mint(FRANK,TOKEN_ID,1, "");
        reserve();
    }
    
    function pause() external onlyOwner {
        _pause();
        saleIsActive = false;
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  

    function reserve() public onlyOwner whenNotPaused{
       _mint(msg.sender, TOKEN_ID, NUM_RESERVED_TOKENS, "");
    }
    
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }
    
    function mint() external whenNotPaused{
        require(saleIsActive, "Sale must be active to mint Tokens!");
        require(totalSupply(TOKEN_ID) + 1 < MAX_TOKENS, "Purchase would exceed max supply of tokens!");
        require(balanceOf(msg.sender,TOKEN_ID)==0,"you can only mint ONE pass per wallet!");
        _mint(msg.sender,TOKEN_ID,1 , "");
    }

    ///////////// Add name and symbol for etherscan /////////////////
    function name() public pure returns (string memory) {
        return "Coodles Mint Pass";
    }

    function symbol() public pure returns (string memory) {
        return "CMP";
    }
}