//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "./IPartyBid.sol";
import "./IMarketWrapper.sol";
import "./IWETH.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./FlashLoanReceiverBase.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./Math.sol";
import "./console.sol";
//partyScooper contract can be used to trigger a maxbid from partybid
contract PartyScooper is Ownable, FlashLoanReceiverBase {

    uint8 internal constant FEE_PERCENT = 25;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(ILendingPoolAddressesProvider _addressProvider) 
                FlashLoanReceiverBase(_addressProvider) public {}

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {

        (address partyBid) = abi.decode(params, (address));
        //bid amount that should be equal to amount loaned
        uint256 flashLoanBidAmount = amounts[0];
        console.log("flashloan bid amount", flashLoanBidAmount);
        console.log("min auction bid", getMinAuctionBid(partyBid));
        console.log(msg.sender);
        require(flashLoanBidAmount > getMinAuctionBid(partyBid), "bid below required min!");

        uint256 auctionId = IPartyBid(partyBid).auctionId();
        console.log("balance before flashloan", address(this).balance);
        //unwrap weth
        IWETH(WETH).withdraw(flashLoanBidAmount);
        console.log("balance after flashloan", address(this).balance);
        //contribute 1 wei so we are allowed to submit bids on behalf of party
        IPartyBid(partyBid).contribute{value: 1}();
        //submit bid
        (bool success, bytes memory returnData) = IPartyBid(partyBid).marketWrapper().delegatecall(
                abi.encodeWithSignature("bid(uint256,uint256)", auctionId, flashLoanBidAmount));
        
        require(success, string(abi.encodePacked("PartyBid::bid: place bid failed: ", returnData)));
        console.log("balance before bid", address(this).balance);
        console.log("min auction bid", getMinAuctionBid(partyBid));

        // trigger partybid bid which should be above last bid
        IPartyBid(partyBid).bid();
        console.log("balance after bid", address(this).balance);
        console.log("min auction bid", getMinAuctionBid(partyBid));

        //return loan plus premium
        uint amountOwing = amounts[0].add(premiums[0]);
        IWETH(WETH).deposit{value:amountOwing}();
        IERC20(assets[0]).approve(address(LENDING_POOL), amountOwing);
        
        return true;
    }

    function triggerFlashLoanAndExecuteBids(uint256 flashLoanBidAmount, address partyBid) internal {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = WETH;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = flashLoanBidAmount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);

        // encode partybid address
        bytes memory params = abi.encode(partyBid);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function raisePartyBid(address partyBid) external payable onlyOwner {
        uint256 flashLoanBidAmount = getFlashLoadBidAmount(partyBid);
        //trigger bidding
        triggerFlashLoanAndExecuteBids(flashLoanBidAmount, partyBid);
        //return any leftover funds to owner
        payable(owner()).transfer(address(this).balance);
    }

    // a temporary hack to calculate the amount that needs to be borrowed from 
    // flash loan to bid on auction. We want this amount to be large enough that 
    //the subsequent bid from partybid is close to partybid's max bid. But not so large 
    //that the subsequent auction's minBid is larger than partybid's max bid. Because min bid logic 
    //is both platform dependent and auction dependent, deriving the optimal value
    //will require some effort. 
    function getFlashLoadBidAmount(address partyBid) internal view returns (uint256) {
        uint256 totalContributedToParty = IPartyBid(partyBid).totalContributedToParty();
        uint256 maximumPossiblePartyBid = getMaximumBid(totalContributedToParty);
        console.log("max bid", maximumPossiblePartyBid);
        //for now, we make it 90% of partybid's max possible bid
        return Math.max((maximumPossiblePartyBid * 90) / 100, getMinAuctionBid(partyBid)+1);
    }

    //replicate max bid logic from partybid contract
    //this is the maximum bid that partybid is able to submit
    function getMaximumBid(uint256 totalContributedToParty) internal pure returns (uint256) {
        //partyDAO takes a 2.5% fee
        uint256 fee = (totalContributedToParty * FEE_PERCENT) / 1000;
        return totalContributedToParty - fee;
    }

    //minimum bid accepted by auction
    function getMinAuctionBid(address partyBid) internal view returns (uint256) {
        address marketWrapper = IPartyBid(partyBid).marketWrapper();
        uint256 auctionId = IPartyBid(partyBid).auctionId();
        return IMarketWrapper(marketWrapper).getMinimumBid(auctionId);
    }

    receive() external payable {}
}