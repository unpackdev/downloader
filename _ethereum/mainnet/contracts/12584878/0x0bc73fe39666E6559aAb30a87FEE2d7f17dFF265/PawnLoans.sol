pragma solidity ^0.8.2;

import "./IPawnLoans.sol";
import "./ERC721.sol";

import "./console.sol";

contract PawnLoans is ERC721, IPawnLoans {
    address public pawnShop;

    constructor(address _pawnShop) ERC721("Pawn Loans", "PWNL") {
        pawnShop = _pawnShop;
    }

    modifier pawnShopOnly(){ 
        require(msg.sender == pawnShop, "PawnLoans: Forbidden");
        _; 
    }

    function mintLoan(address to, uint256 tokenId) pawnShopOnly override external {
        _mint(to, tokenId);
    }
    function transferLoan(address from, address to, uint256 loanId) pawnShopOnly override external{
        _transfer(from, to, loanId);
    }
}