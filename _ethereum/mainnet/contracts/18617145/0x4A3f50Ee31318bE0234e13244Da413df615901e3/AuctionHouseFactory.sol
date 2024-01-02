pragma solidity 0.6.7;

import "./CollateralAuctionHouse.sol";

contract AuctionHouseFactory {
    function deploy(
        address safeEngine,
        address liquidationEngine,
        bytes32 collateralType,
        address owner
    ) external returns (address) {
        IncreasingDiscountCollateralAuctionHouse auctionHouse = new IncreasingDiscountCollateralAuctionHouse(
                safeEngine,
                liquidationEngine,
                collateralType
            );
        auctionHouse.addAuthorization(owner);
        auctionHouse.removeAuthorization(address(this));
        return address(auctionHouse);
    }
}
