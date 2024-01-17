// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Marketplace.sol";

contract MarketplaceFactory is Ownable {
    // events
    event NewMarketplace(address indexed marketplace, address indexed owner, uint indexed deployIndex);

    // deployed marketplaces
    mapping (uint => address) public marketplaces;

    // deployed marketplaces counter
    uint public marketplacesCounter;

    /**
     * @notice Constructor
     */
    constructor () {}

    /**
     * @notice Deploy new Marketplace
     */
    function deployMarketplace(address owner, address _nft, address _recoverAddress, uint _minBidPriceIncrease,
        bool _shouldExtendEnd, bool _shouldStopBidding) external onlyOwner {

        Marketplace marketplace = new Marketplace(_nft, _recoverAddress, _minBidPriceIncrease, _shouldExtendEnd,
            _shouldStopBidding);
        marketplace.addAddressToWithdrawList(owner);
        marketplace.transferOwnership(owner);

        marketplaces[marketplacesCounter] = address(marketplace);
        marketplacesCounter += 1;

        emit NewMarketplace(address(marketplace), owner, marketplacesCounter - 1);
    }
}
