// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "./Clones.sol";
import "./IEnglishAuctionReservePrice.sol";

contract EnglishAuctionReservePriceCloneFactory {

    event EnglishAuctionReservePriceCloneDeployed(address indexed cloneAddress);

    address public referenceEnglishAuctionReservePrice;
    address public cloner;

    constructor(address _referenceEnglishAuctionReservePrice) public {
        referenceEnglishAuctionReservePrice = _referenceEnglishAuctionReservePrice;
        cloner = msg.sender;
    }

    modifier onlyCloner {
        require(msg.sender == cloner);
        _;
    }

    function changeCloner(address _newCloner) external onlyCloner {
        cloner = _newCloner;
    }

    function newEnglishAuctionReservePriceClone(
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _reservePriceWei,
        uint256 _minimumStartTime,
        uint256 _stakingRewardPercentageBasisPoints,
        uint8 _percentageIncreasePerBid,
        address _hausAddress,
        address _stakingSwapContract
    ) external onlyCloner returns (address) {
        // Create new EnglishAuctionReservePriceClone
        address newEnglishAuctionReservePriceCloneAddress = Clones.clone(referenceEnglishAuctionReservePrice);
        IEnglishAuctionReservePrice reservePriceAuction = IEnglishAuctionReservePrice(newEnglishAuctionReservePriceCloneAddress);
        reservePriceAuction.initialize(
            _tokenId,
            _tokenAddress,
            _reservePriceWei,
            _minimumStartTime,
            _stakingRewardPercentageBasisPoints,
            _percentageIncreasePerBid,
            _hausAddress,
            _stakingSwapContract,
            msg.sender
        );
        emit EnglishAuctionReservePriceCloneDeployed(newEnglishAuctionReservePriceCloneAddress);
        return newEnglishAuctionReservePriceCloneAddress;
    }

}