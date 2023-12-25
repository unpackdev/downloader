// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
import "./Ownable.sol";

/**
 * @title
 * @author
 * @notice
 */
contract AuctionMintContract is Ownable {
    struct AuctionData {
        uint256 initialSupply;
        uint256 minted;
        uint256 startTimestamp;
        uint256 finishTimestamp;
        uint256 initialPrice;
        uint256 maxBuy;
    }

    uint256[] public auctionStepList;
    uint256[] public auctionPriceList;
    uint256[] public auctionSupplyList;
    bool public auctionSoldout = false;

    event AuctionNewStep(address user, uint256 minted, uint256 newPrice, uint256 newSupply);
    event AuctionMint(address user, uint256 amount, uint256 timestamp, uint256 price);

    AuctionData public auctionData;

    mapping(address => uint256) public auctionMinted;
    uint256 public finalAuctionPrice = 0.0169 ether;

    function initAuction(
        uint256 initialSupply,
        uint256 startTimestamp,
        uint256 finishTimestamp,
        uint256 initialPrice,
        uint256 maxBuy
    ) public onlyOwner {
        auctionData.initialSupply = initialSupply;
        auctionData.startTimestamp = startTimestamp;
        auctionData.finishTimestamp = finishTimestamp;
        auctionData.initialPrice = initialPrice;
        auctionData.maxBuy = maxBuy;
    }

    function initAuctionPrice(
        uint256[] calldata _auctionStepList,
        uint256[] calldata _auctionPriceList,
        uint256[] calldata _auctionSupplyList
    ) public onlyOwner {
        uint len = _auctionStepList.length;
        require(len == _auctionPriceList.length, "auction price list not equal");
        require(len == _auctionSupplyList.length, "auction supply list not equal");
        for (uint256 i = 0; i < len; i++) {
            if (auctionStepList.length < i + 1) {
                auctionStepList.push(_auctionStepList[i]);
            } else {
                auctionStepList[i] = _auctionStepList[i];
            }

            if (auctionPriceList.length < i + 1) {
                auctionPriceList.push(_auctionPriceList[i]);
            } else {
                auctionPriceList[i] = _auctionPriceList[i];
            }

            if (auctionSupplyList.length < i + 1) {
                auctionSupplyList.push(_auctionSupplyList[i]);
            } else {
                auctionSupplyList[i] = _auctionSupplyList[i];
            }
        }
    }

    function currentPriceAndSupply(uint256 currentTime) public view returns (uint256 price, uint256 supply) {
        uint256 len = auctionStepList.length;
        if (len == 0) {
            return (uint256(0), uint256(0));
        }
        if (currentTime < auctionStepList[0]) {
            return (auctionPriceList[0], auctionSupplyList[0]);
        }
        for (uint256 i = 0; i < len; i++) {
            if (currentTime < auctionStepList[i]) {
                return (auctionPriceList[i - 1], auctionSupplyList[i - 1]);
            }
        }

        return (auctionPriceList[len - 1], auctionSupplyList[len - 1]);
    }

    function auctionRunning() public view returns (bool) {
        return block.timestamp >= auctionData.startTimestamp && block.timestamp <= auctionData.finishTimestamp;
    }

    function auctionBeforeMint(
        address user,
        uint256 amount,
        uint256 userPayed
    ) internal {
        require(auctionRunning(), "auction is not running");
        // user cap
        require(auctionMinted[user] + amount <= auctionData.maxBuy, "u can only buy 5");
        (uint256 newPrice, uint256 newSupply) = currentPriceAndSupply(block.timestamp);
        require(userPayed >= newPrice * amount, "user pay not enough");
        require(
            auctionData.minted + amount <= newSupply,
            "there is no enough auction sofa maker for u! auction sell finished!"
        );
        emit AuctionMint(user, amount, block.timestamp, newPrice);
        auctionMinted[user] += amount;
        auctionData.minted += amount;
        if (finalAuctionPrice != newPrice) {
            finalAuctionPrice = newPrice;
        }
        if (auctionData.minted >= newSupply) {
            auctionSoldout = true;
        }
    }

    function getAuctionPriceConfig()
        public
        view
        returns (
            uint256[] memory priceList,
            uint256[] memory timeList,
            uint256[] memory supplyList
        )
    {
        priceList = new uint256[](auctionStepList.length);
        timeList = new uint256[](auctionStepList.length);
        supplyList = new uint256[](auctionStepList.length);
        for (uint i = 0; i < auctionStepList.length; i++) {
            priceList[i] = auctionPriceList[i];
            timeList[i] = auctionStepList[i];
            supplyList[i] = auctionSupplyList[i];
        }
    }
}
