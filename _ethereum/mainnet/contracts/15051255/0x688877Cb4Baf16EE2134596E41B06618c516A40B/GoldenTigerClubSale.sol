// SPDX-License-Identifier: MIT
//Azzzzzzzz.eth
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract GoldenTigerClubSale is Ownable, ReentrancyGuard {

    uint256 public publicSaleTime = 1656684000; // 7/1 10:00pm
    uint256 public publicSaleEndTime = 1657152000; //11/1 10:00pm
    uint256 public publicSalePrice = 0.5 ether;
    uint256 public remainingCount = 1970;
    uint256 public maxPurchasedQuantity = 10;

    address public goldenTigerClub;

    constructor(address _goldenTigerClub) {
        goldenTigerClub = _goldenTigerClub;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */
    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(tx.origin == msg.sender, "contract not allowed");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        _mint(numberOfTokens);
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _mint(uint256 numberOfTokens) internal {
        require(
            block.timestamp >= publicSaleTime, 
            "PublicSale hasn't started"    
        );
        require(
            block.timestamp < publicSaleEndTime,
            "PublicSale has been over"
        );
        require(
            msg.value >= publicSalePrice * numberOfTokens, 
            "sent ether value incorrect"
        );
        require(
            numberOfTokens <= remainingCount, 
            "tokens sold out"
        );
        require(
            numberOfTokens <= maxPurchasedQuantity,
            "Maximum token number reached"
        );

        remainingCount -= numberOfTokens;
        NFT(goldenTigerClub).mint(msg.sender, numberOfTokens);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setSaleData(
        uint256 _publicSaleTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSalePrice,
        uint256 _remainingCoung,
        uint256 _maxPurchasedQuantity
    ) external onlyOwner {
        publicSaleTime = _publicSaleTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSalePrice = _publicSalePrice;
        remainingCount = _remainingCoung;
        maxPurchasedQuantity = _maxPurchasedQuantity;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "sent value failed");
    }
}