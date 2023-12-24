// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./OperatorFilterer.sol";
import "./Ownable2Step.sol";
import "./ERC2981.sol";

contract Test is ERC721A, Pausable, OperatorFilterer, Ownable2Step {
    uint256 public MAX_SUPPLY = 888;
    uint256 public MINT_PRICE;
    
    
    constructor(
        address operatorFilterer
    ) ERC721A("TestKF", "TKF") OperatorFilterer(operatorFilterer, true) {}

    function mint(address to, uint256 amount) external {
            _mint(to, amount);
    }
    
    // Opensea overiding functions
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
}
