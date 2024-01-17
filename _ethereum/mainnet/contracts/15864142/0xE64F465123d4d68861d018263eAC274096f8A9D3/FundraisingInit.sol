// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io

**************************************/

// OpenZeppelin imports
import "./IERC165.sol";
import "./IERC20.sol";

// Diamond imports
import "./LibDiamond.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";

// Local imports
import "./AccessTypes.sol";
import "./LibAccessControl.sol";
import "./LibAppStorage.sol";
import "./IRaiseFacet.sol";
import "./IMilestoneFacet.sol";
import "./IEquityBadge.sol";

/**************************************

    Fundraising initializer

    ------------------------------

    Diamond deployment looks like this:
    - deploy diamond cutter
    - deploy main diamond
    - deploy initializer
    - deploy all facets
    - perform cut with facets and initializer

 **************************************/

contract FundraisingInit {

    // args
    struct Arguments {
        address usdt;
        address signer;
        address badge;
    }

    // init
    function init(Arguments calldata _args) external {

        // owner
        address _owner = msg.sender;

        // access control
        LibAccessControl.createAdmin(_owner);
        LibAccessControl.grantRole(AccessTypes.SIGNER_ROLE, _args.signer);

        // app storage
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.usdt = IERC20(_args.usdt);
        s.equityBadge = IEquityBadge(_args.badge);

        // interfaces
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IRaiseFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IMilestoneFacet).interfaceId] = true;

    }

}
