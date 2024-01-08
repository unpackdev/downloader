// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Pausable.sol";

contract KikiTunaPass is ERC1155Supply, Ownable , ERC1155Pausable  {
    bool public saleIsActive;
    uint constant TOKEN_ID = 420;
    uint constant NUM_RESERVED_TOKENS = 10;
    uint constant MAX_TOKENS = 1000;

    constructor() ERC1155("ipfs://QmSBht6NnsWhNQUukmffMAqjmKuAD8auZYcgkq8mGRwnZa") {
        reserve();
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

    function reserve() public onlyOwner {
        require(!paused(), "minting is paused");
       _mint(msg.sender, TOKEN_ID, NUM_RESERVED_TOKENS, "");
    }
    
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }
    
    function mint() external {
        require(saleIsActive, "Sale must be active to mint Tokens!");
        require(totalSupply(TOKEN_ID) + 1 <= MAX_TOKENS, "Purchase would exceed max supply of tokens!");
        require(balanceOf(msg.sender,TOKEN_ID)==0,"you can only mint ONE pass per wallet!");
        require(!paused(), "minting is paused");
        _mint(msg.sender,TOKEN_ID,1 , "");
    }

}