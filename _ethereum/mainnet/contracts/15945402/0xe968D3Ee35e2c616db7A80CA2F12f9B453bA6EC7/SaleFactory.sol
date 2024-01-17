
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./SaleContract.sol";
import "./BlackHolePrevention.sol";
import "./Ownable.sol";


contract SaleFactoryV1 is Ownable, BlackHolePrevention {

    function deploy(
        SaleConfiguration memory saleConfig,
        address _actualOwner
    ) external returns (address) {
        // Launch new sale contract
        SaleContract sale = new SaleContract();
        sale.setup(saleConfig);
        
        // transfer ownership of the new contract to owner
        sale.transferOwnership(_actualOwner);
        return address(sale);
    }

}