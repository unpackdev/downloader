// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./DID.sol";
import "./DIDRegistrarController.sol";
import "./IDIDRegistrarController.sol";
import "./Resolver.sol";
import "./IBulkRenewal.sol";
import "./IPriceOracle.sol";

import "./IERC165.sol";

contract BulkRenewal is IBulkRenewal {
    bytes32 private constant DID_NAMEHASH =
        0x8a74fc6994ef0554dd9cc95c3391f9cd66152031a0c1feacb835e3890805af5f;

    DID public immutable did;

    constructor(DID _did) {
        did = _did;
    }

    function getController() internal view returns (DIDRegistrarController) {
        Resolver r = Resolver(did.resolver(DID_NAMEHASH));
        return
            DIDRegistrarController(
                r.interfaceImplementer(
                    DID_NAMEHASH,
                    type(IDIDRegistrarController).interfaceId
                )
            );
    }

    function rentPrice(string[] calldata names, uint256 duration)
        external
        view
        override
        returns (uint256 total)
    {
        DIDRegistrarController controller = getController();
        for (uint256 i = 0; i < names.length; i++) {
            IPriceOracle.Price memory price = controller.rentPrice(
                names[i],
                duration
            );
            total += (price.base + price.premium);
        }
    }

    function renewAll(string[] calldata names, uint256 duration)
        external
        payable
        override
    {
        DIDRegistrarController controller = getController();
        for (uint256 i = 0; i < names.length; i++) {
            IPriceOracle.Price memory price = controller.rentPrice(
                names[i],
                duration
            );
            controller.renew{value: price.base + price.premium}(
                names[i],
                duration
            );
        }
        // Send any excess funds back
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IBulkRenewal).interfaceId;
    }
}
