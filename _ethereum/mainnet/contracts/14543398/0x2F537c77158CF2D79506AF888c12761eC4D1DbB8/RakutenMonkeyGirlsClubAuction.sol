// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC721Enumerable.sol";

contract RakutenMonkeyGirlsClubAuction is Ownable, ReentrancyGuard {
    uint256 public auctionStartTime = 1649476800; // 4/9 12pm
    uint256 public auctionEndTime = auctionStartTime + 6 hours;
    uint256 public auctionTimeStep = 60 minutes;
    uint256 public totalAuctionTimeSteps = 5;
    uint256 public auctionStartPrice = 0.25 ether;
    uint256 public auctionEndPrice = 0.15 ether;
    uint256 public auctionPriceStep = 0.02 ether;
    address public rmgc = 0xD55d4fEe2d1E93173896FDe1688d71f02b8da698;

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */
    constructor() {}

    function remainingCount() public view returns (uint256) {
        return IERC721Enumerable(rmgc).balanceOf(address(this));
    }

    function getAuctionPrice() public view returns (uint256) {
        require(auctionStartTime != 0, "auctionStartTime not set");
        require(auctionEndTime != 0, "auctionEndTime not set");
        if (block.timestamp < auctionStartTime) {
            return auctionStartPrice;
        }
        uint256 timeSteps = (block.timestamp - auctionStartTime) /
            auctionTimeStep;
        if (timeSteps > totalAuctionTimeSteps) {
            timeSteps = totalAuctionTimeSteps;
        }
        uint256 discount = timeSteps * auctionPriceStep;
        return
            auctionStartPrice > discount
                ? auctionStartPrice - discount
                : auctionEndPrice;
    }

    function buy() external payable nonReentrant {
        require(tx.origin == msg.sender, "contract not allowed");
        require(block.timestamp > auctionStartTime, "not started");
        require(block.timestamp < auctionEndTime, "finished");
        require(remainingCount() > 0, "not enogugh left for this purchase");
        uint256 price = getAuctionPrice();
        require(msg.value >= price, "sent ether value incorrect");
        uint256 tokenId = IERC721Enumerable(rmgc).tokenOfOwnerByIndex(
            address(this),
            0
        );
        IERC721Enumerable(rmgc).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setAuctionTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        auctionStartTime = _startTime;
        auctionEndTime = _endTime;
    }

    function setRMGC(address _rmgc) external onlyOwner {
        rmgc = _rmgc;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "sent value failed");
    }

    function withdrawNFT() external onlyOwner {
        uint256 balance = IERC721Enumerable(rmgc).balanceOf(address(this));
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = IERC721Enumerable(rmgc).tokenOfOwnerByIndex(
                address(this),
                0
            );
            IERC721Enumerable(rmgc).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
