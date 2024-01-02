// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./SafeProxyFactoryI.sol";
import "./MNFTFactoryV3I.sol";
import "./IMembershipNftV3.sol";

/// @notice Create a safe and lore crowdfund in one transaction
contract SafeCrowdfundFactoryV3 {
    function create(
        address safeFactory,
        bytes calldata safeFactoryCalldata,
        address mnftFactory,
        address owner, string memory name, string memory symbol, string memory baseUrlIn
    )
    external
    returns (MembershipNftV3I){
        address safeProxy = callAndGetAddress(safeFactory, safeFactoryCalldata);
        //create the crowdfund with the new safe address passed in

        MNFTFactoryV3I crowdfundFactory = MNFTFactoryV3I(mnftFactory);

        bytes memory encodedCall = abi.encodeWithSignature("initialize(address,address,string,string,string)", owner, safeProxy, name, symbol, baseUrlIn);
        return MembershipNftV3I(crowdfundFactory.createWithInitializer(encodedCall));
    }

    function createWithEditions(
        address safeFactory,
        bytes calldata safeFactoryCalldata,
        address mnftFactory,
        address owner, string memory name, string memory symbol, string memory baseUrlIn,
        MembershipNftV3I.EditionTier[] memory tiers,
        address _minter
    )
    external
    returns (MembershipNftV3I){
        address safeProxy = callAndGetAddress(safeFactory, safeFactoryCalldata);
        //create the crowdfund with the new safe address passed in
        MNFTFactoryV3I crowdfundFactory = MNFTFactoryV3I(mnftFactory);
        // map uint->uint256 and struct->tuple[]
        bytes memory encodedCall = abi.encodeWithSignature("initializeEditions(address,address,string,string,string,(uint256,uint256,uint256,uint256,uint256,bytes32,uint256)[],address)", owner, safeProxy, name, symbol, baseUrlIn, tiers, _minter);
        return MembershipNftV3I(crowdfundFactory.createWithInitializer(encodedCall));
    }

    function callAndGetAddress(
        address contractAddress,
        bytes calldata callData
    ) internal returns (address){
        (bool success, bytes memory data) = contractAddress.call{value: 0}(callData);
        require(success, "call failed");
        (address addr) = abi.decode(data, (address));
        return addr;
    }
}

