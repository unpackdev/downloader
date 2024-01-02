pragma solidity 0.6.7;

import "./BasicTokenAdapters.sol";

contract JoinFactory {
    function deploy(
        address safeEngine,
        bytes32 collateralType,
        address collateralAddress,
        address owner
    ) external returns (address) {
        BasicCollateralJoin join = new BasicCollateralJoin(
            safeEngine,
            collateralType,
            collateralAddress
        );
        join.addAuthorization(owner);
        join.removeAuthorization(address(this));
        return address(join);
    }
}
