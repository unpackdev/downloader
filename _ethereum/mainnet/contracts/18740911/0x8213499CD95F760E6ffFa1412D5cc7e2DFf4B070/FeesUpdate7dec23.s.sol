// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./Script.sol";
import "./console.sol";

import "./IDiamondCut.sol";
import "./IKairos.sol";

import "./BorrowFacet.sol";
import "./ProtocolFacet.sol";
import "./AdminFacet.sol";
import "./ContractsCreator.sol";
import "./FuncSelectors.h.sol";
import "./Rollover.sol";

contract FeesUpdate7dec23 is Script, ContractsCreator {
    function run() public {
        // IKairos kairos = IKairos(0xa7fc58e0594C2e8ecEfFADCE2B3d606Baf782520); // mainnet
        // IKairos kairos = IKairos(0x5FbDB2315678afecb367f032d93F642f64180aa3); // polygon
        // IKairos kairos = IKairos(0xD5Ea0dDc7E062917DA32fe7C6D2D53A0bF882395); // cronos
        IKairos kairos = IKairos(0xDE75133b77762b056903584a509D722aC7aE352e); // goerli
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](3);
        bytes4[] memory setFeeRateForAssetSelector = new bytes4[](1);
        setFeeRateForAssetSelector[0] = AdminFacet.setFeeRateForAsset.selector;
        bytes4[] memory getFeeRateForAssetSelector = new bytes4[](1);
        getFeeRateForAssetSelector[0] = ProtocolFacet.getFeeRateForAsset.selector;

        vm.startBroadcast();

        // borrow = new BorrowFacet();
        // protocol = new ProtocolFacet();
        // admin = new AdminFacet();
        Rollover rollover = new Rollover(kairos);

        vm.stopBroadcast();

        facetCuts[0] = getUpgradeFacetCut(address(borrow), borrowFS());
        facetCuts[1] = getAddFacetCut(address(admin), setFeeRateForAssetSelector);
        facetCuts[2] = getAddFacetCut(address(protocol), getFeeRateForAssetSelector);

        // for polygon and cronos (no safe)
        // vm.startBroadcast();
        // kairos.diamondCut(facetCuts, address(0), new bytes(0));
        // vm.stopBroadcast();

        // for mainnet and goerli (safe)
        // console.logBytes(abi.encodeWithSelector(IDiamondCut.diamondCut.selector, facetCuts, address(0), new bytes(0)));

        console.log("rollover ", address(rollover));
    }
}
