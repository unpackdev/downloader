// SPDX-License-Identifier: MIT
// Author: Warren Cheng - twtr: @warrenycheng
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
                                                                                 
// 88b           d88              88888888ba                             88         
// 888b         d888              88      "8b                            88         
// 88`8b       d8'88              88      ,8P                            88         
// 88 `8b     d8' 88   ,adPPYba,  88aaaaaa8P'  88       88  8b,dPPYba,   88   ,d8   
// 88  `8b   d8'  88  a8P_____88  88""""""'    88       88  88P'   `"8a  88 ,a8"    
// 88   `8b d8'   88  8PP"""""""  88           88       88  88       88  8888[      
// 88    `888'    88  "8b,   ,aa  88           "8a,   ,a88  88       88  88`"Yba,   
// 88     `8'     88   `"Ybbd8"'  88            `"YbbdP'Y8  88       88  88   `Y8a  

                                                                                 
interface Punk {
    function mint(address receiver) external returns (uint256 mintedTokenId);
}

contract MePunkAuction is Ownable, ReentrancyGuard, Pausable {
    address public mePunk;

    uint256 public remainingMintCount;
    uint256 public maxNFTPurchase;

    uint256 public auctionStartTime;
    uint256 public auctionEndTime;
    uint256 public auctionTimeStep = 60;
    uint256 public totalAuctionTimeSteps;

    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;

    uint256 public auctionPriceStep = 0.1 ether;
    

    constructor(address _mePunk) {
        mePunk = _mePunk;
        maxNFTPurchase = 3;
        remainingMintCount = 10;
    }

    /**********
     * EVENTS *
     **********/
    event AuctionConfigured(
        uint256 remainingMintCount,
        uint256 maxNFTPurchase,
        uint256 auctionStartTime,
        uint256 auctionEndTime,
        uint256 totalAuctionTimeSteps,
        uint256 auctionStartPrice,
        uint256 auctionEndPrice,
        uint256 auctionPriceStep,
        uint256 auctionTimeStep
    );

    event Minted(address receiver, uint256 numberOfMePunks);

    /******************
     * ADMIN FUNCTION *
     ******************/
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pause() external onlyOwner{
            _pause();
    }

    function unpause() external onlyOwner{
            _unpause();
    }

    function setAuction(
        uint256 _remainingMintCount,
        uint256 _maxNFTPurchase,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        uint256 _totalAuctionTimeSteps,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionPriceStep,
        uint256 _auctionTimeStep
    ) external onlyOwner {
        remainingMintCount = _remainingMintCount;
        maxNFTPurchase = _maxNFTPurchase;

        auctionStartTime = _auctionStartTime;
        auctionEndTime = _auctionEndTime;

        totalAuctionTimeSteps =_totalAuctionTimeSteps;

        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;

        auctionPriceStep = _auctionPriceStep;
        auctionTimeStep = _auctionTimeStep;

        emit AuctionConfigured(
            remainingMintCount,
            maxNFTPurchase,
            auctionStartTime,
            auctionEndTime,
            totalAuctionTimeSteps,
            auctionStartPrice,
            auctionEndPrice,
            auctionPriceStep,
            auctionTimeStep
        );
    }

    /*****************
     * USER FUNCTION *
     *****************/

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

    function auctionBuyMePunk(uint256 numberOfMePunks) public payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "smart contract not allowed to mint");
        require(auctionStartTime != 0, "auctionStartTime not set");
        require(auctionEndTime != 0, "auctionEndTime not set");
        require(block.timestamp >= auctionStartTime, "not yet started");
        require(block.timestamp <= auctionEndTime, "has finished");
        require(
            numberOfMePunks > 0,
            "numberoOfTokens can not be less than or equal to 0"
        );
        require(
            numberOfMePunks <= maxNFTPurchase,
            "numberOfMePunks exceeds purchase limit per tx"
        );
        require(
            numberOfMePunks <= remainingMintCount,
            "numberOfMePunks would exceed remaining mint count for this batch"
        );
        uint256 price = getAuctionPrice();
        require(
            price * numberOfMePunks <= msg.value,
            "Sent ether value is incorrect"
        );
        remainingMintCount -= numberOfMePunks;
        for (uint256 i = 0; i < numberOfMePunks; i++) {
            Punk(mePunk).mint(msg.sender);
        }
        emit Minted(msg.sender, numberOfMePunks);
    }
}
