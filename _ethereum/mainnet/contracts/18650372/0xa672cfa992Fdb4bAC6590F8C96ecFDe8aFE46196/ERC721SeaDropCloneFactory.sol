// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721SeaDropCloneable.sol";
import "./IWavemintV1Info.sol";

import "./Clones.sol";

contract ERC721SeaDropCloneFactory {
    address public immutable seaDropCloneableUpgradeableImplementation;
    address public constant DEFAULT_SEADROP =
        0x015904187e7a5B1c0f2C77B5568225E5A8DCaD98;

    constructor() {
        ERC721SeaDropCloneable impl = new ERC721SeaDropCloneable();
        impl.initialize("", "", new address[](0), address(this), address(this), 10,"");
        seaDropCloneableUpgradeableImplementation = address(impl);
    }

    function createClone(
        string memory name,
        string memory symbol,
        address royaltyAddress,
        uint96 royaltyBps,
        string memory contractURI,
        bytes32 salt
    ) external returns (address) {
        // Derive a pseudo-random salt, so clone addresses don't collide
        // across chains.
        bytes32 cloneSalt = keccak256(
            abi.encodePacked(salt, blockhash(block.number))
        );

        address instance = Clones.cloneDeterministic(
            seaDropCloneableUpgradeableImplementation,
            cloneSalt
        );
        require(address(instance) != address(0), "Contract ERC721SeaDropCloneable address not set");
        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = DEFAULT_SEADROP;
        ERC721SeaDropCloneable(instance).initialize(
            name,
            symbol,
            allowedSeaDrop,
            msg.sender,
            royaltyAddress,
            royaltyBps,
            contractURI
        );
        return instance;
    }
}
