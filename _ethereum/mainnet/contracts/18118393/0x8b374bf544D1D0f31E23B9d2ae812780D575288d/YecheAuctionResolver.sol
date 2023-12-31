pragma solidity ^0.8.11;  

import "./IYecheAuction.sol";

contract YecheAuctionResolver {
    IYecheAuctionHouseV2 public immutable auctionHouse;

    constructor(IYecheAuctionHouseV2 _auctionHouse) {
        auctionHouse = _auctionHouse;
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = auctionHouse.areThereExpiredAuctions();

        execPayload = abi.encodeCall(IYecheAuctionHouseV2.endExpiredAuctions, ());
    }
}