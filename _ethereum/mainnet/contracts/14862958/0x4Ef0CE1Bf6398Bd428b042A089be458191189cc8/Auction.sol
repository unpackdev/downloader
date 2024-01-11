// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";

contract Auction is Ownable, ReentrancyGuard {
    struct Bid {
        uint256 amount;
        bool isRefund;
    }

    struct Winner {
        uint256 amount;
        address winner;
        bool isWithdrawn;
    }

    ERC1155 public nft;
    address public hati;
    address public deployer = 0xf0Bc35eFCc611eb89181cC73EB712650FCdC9087;
    uint256 public count;
    uint256[] public tokenIds;
    uint256[] amounts;

    uint256[] public owner_tokenIds;
    uint256[] owner_amounts;

    uint256 public auctionStartTime;
    uint256 public minBidAmount = 66666666666 ether;

    mapping(uint256 => Winner) public winners;
    mapping(uint256 => mapping(address => Bid)) public bidders;

    constructor(address _hati, string memory _uri) {
        hati = _hati;
        nft = new ERC1155(_uri);
        for (uint256 i = 1; i <= 30; i++) {
            tokenIds.push(i);
            amounts.push(1);
        }
        for (uint256 i = 31; i <= 40; i++) {
            owner_tokenIds.push(i);
            owner_amounts.push(1);
        }
        nft.mintBatch(address(this), tokenIds, amounts, "0x00");
        nft.mintBatch(deployer, owner_tokenIds, owner_amounts, "0x00");
        //auctionStartTime = block.timestamp;
    }

    function startAuction() external onlyOwner {
        auctionStartTime = block.timestamp;
    }

    function setBidder(uint256 _tokenId, uint256 _amount) external {
        require(_amount >= minBidAmount, "Not Enought Amount");
        uint256 currentId = (block.timestamp - auctionStartTime) / 1 hours + 1;
        require(
            _tokenId == currentId && _tokenId <= tokenIds.length,
            "Invalid NFT"
        );

        bool winFlag;
        for (uint256 i = 1; i < currentId; i++)
            if (winners[i].winner == msg.sender) {
                winFlag = true;
                break;
            }

        require(!winFlag, "Winner Cannot Bid");

        uint256 beforeBalance = IERC20(hati).balanceOf(address(this));
        IERC20(hati).transferFrom(msg.sender, address(this), _amount);
        uint256 afterBalance = IERC20(hati).balanceOf(address(this));

        Bid storage _bid = bidders[_tokenId][msg.sender];

        if (_bid.amount > 0) IERC20(hati).transfer(msg.sender, _bid.amount);

        _bid.amount = afterBalance - beforeBalance;

        if (winners[_tokenId].amount < _bid.amount) {
            winners[_tokenId].amount = _bid.amount;
            winners[_tokenId].winner = msg.sender;
        }
    }

    function withdrawWinner(uint256 _tokenId) external {
        require(winners[_tokenId].winner == msg.sender, "You are not Winner");
        require(
            winners[_tokenId].isWithdrawn == false,
            "You have already withdrawn"
        );
        nft.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "0x0");
        IERC20(hati).transfer(deployer, winners[_tokenId].amount);
        winners[_tokenId].isWithdrawn = true;
    }

    function claimRefund(uint256 _tokenId) external {
        require(!bidders[_tokenId][msg.sender].isRefund, "Already Refunded");
        require(
            bidders[_tokenId][msg.sender].amount > 0,
            "Bidders can refund tokens"
        );
        uint256 currentId = (block.timestamp - auctionStartTime) / 1 hours + 1;
        require(
            _tokenId < currentId && winners[_tokenId].winner != msg.sender,
            "Winner cannot refund"
        );
        IERC20(hati).transfer(msg.sender, bidders[_tokenId][msg.sender].amount);
        bidders[_tokenId][msg.sender].isRefund = true;
    }
}