// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721Enumerable.sol";

contract KingTokenDistributeNFT is Ownable {
    using SafeMath for uint;

    // the king (ERC20) token
    IERC20 public king;

    // NFT (IERC721Enumerable) tokens
    address public kw;
    address public qz;
    address public km;

    address public knight;
    address public queen;
    address public kingNFTs;

    address public royalDecks;

    address public batchSender;

    //Default Constructor
    constructor(IERC20 _king, address _kw, address _qz, address _km, address _kingNFTs, address _queen, address _knight, address _royalDecks, address _batchSender)
    public
    {
        king = _king;

        kw = _kw;
        qz = _qz;
        km = _km;

        kingNFTs = _kingNFTs;
        queen = _queen;
        knight = _knight;


        royalDecks = _royalDecks;
        batchSender = _batchSender;

    }

    // @dev Only the owner may call
    function withdraw() public onlyOwner{
        uint kingBalance = king.balanceOf(address(this));
        require(kingBalance >= 5, "nothing to withdraw"); // i.e. `knightAllocation >= 1`

        uint kingAllocation = kingBalance.mul(3).div(5);
        uint queenAllocation = kingAllocation.div(2);
        uint knightAllocation = kingBalance.sub(kingAllocation).sub(queenAllocation);

        withdrawKing(kingAllocation);
        withdrawQueen(queenAllocation);
        withdrawKnight(knightAllocation);
    }

    function withdrawQueen(uint kingAmount) internal {
        withdrawForNftPair(IERC721Enumerable(queen), IERC721Enumerable(qz), kingAmount);
    }

    function withdrawKing(uint kingAmount) internal {
        withdrawForNftPair(IERC721Enumerable(kingNFTs), IERC721Enumerable(kw), kingAmount);
    }

    function withdrawKnight(uint kingAmount) internal {
        withdrawForNftPair(IERC721Enumerable(knight), IERC721Enumerable(km), kingAmount);
    }

    function withdrawForNftPair(IERC721Enumerable nft1, IERC721Enumerable nft2, uint kingTotal) private {
        uint nft1Qty = nft1.totalSupply();
        uint nft2Qty = nft2.totalSupply();
        uint totalQty = nft1Qty.add(nft2Qty);
        if (totalQty == 0) return;

        uint share = kingTotal.div(totalQty);
        if (share == 0) return;

        uint remaining = kingTotal;
        if (nft1Qty != 0) remaining = distributeKingForNftHolders(nft1, nft1Qty, remaining, share);
        if (nft2Qty != 0) remaining = distributeKingForNftHolders(nft2, nft2Qty, remaining, share);
    }

    function distributeKingForNftHolders(IERC721Enumerable nft, uint nftQty, uint kingTotal, uint kingAmount)
    private returns (uint remaining) {
        remaining = kingTotal;
        for (uint i = 1; i <= nftQty; i++) {
            address holder = nft.ownerOf(i);
            if (holder == address(0)) continue;
            

            uint amount = remaining > kingAmount ? kingAmount : remaining;
            remaining = remaining.sub(amount);

            if(holder == royalDecks){
                king.transfer(batchSender, amount);
            }else{
                king.transfer(holder, amount);
            }
        }
    }

    function setRoyalDecks(address _royalDecks) public onlyOwner{
        royalDecks = _royalDecks;
    }

    function setBatchSender(address _batchSender) public onlyOwner{
        batchSender = _batchSender;
    }


}
