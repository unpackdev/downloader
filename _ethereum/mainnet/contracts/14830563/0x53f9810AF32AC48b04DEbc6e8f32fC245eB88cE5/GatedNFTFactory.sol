// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "./GatedNFT.sol";
// solhint-disable-next-line max-line-length
import "./Factory.sol";
// solhint-disable-next-line max-line-length
import "./ITier.sol";
import "./Clones.sol";

contract GatedNFTFactory is Factory {
    address private immutable implementation;

    constructor() {
        address implementation_ = address(new GatedNFT());
        emit Implementation(msg.sender, implementation_);
        implementation = implementation_;
    }

    function createChildTyped(
        GatedNFT.Config memory config_,
        ITier tier_,
        uint256 minimumStatus_,
        uint256 maxPerAddress_,
        GatedNFT.Transferrable transferrable_,
        uint256 maxMintable_,
        address royaltyRecipient_,
        uint256 royaltyBPS
    ) external returns (GatedNFT) {
        return GatedNFT(
            this.createChild(
                abi.encode(
                    msg.sender,
                    config_,
                    tier_,
                    minimumStatus_,
                    maxPerAddress_,
                    transferrable_,
                    maxMintable_,
                    royaltyRecipient_,
                    royaltyBPS
                )
            )
        );
    }

    function _createChild(bytes calldata data_)
        internal
        virtual
        override
        returns (address)
    {
        (
            address owner_,
            GatedNFT.Config memory config_,
            ITier tier_,
            uint256 minimumStatus_,
            uint256 maxPerAddress_,
            GatedNFT.Transferrable transferrable_,
            uint256 maxMintable_,
            address royaltyRecipient_,
            uint256 royaltyBPS_
        ) = abi.decode(
            data_,
            (
                address,
                GatedNFT.Config,
                ITier,
                uint256,
                uint256,
                GatedNFT.Transferrable,
                uint256,
                address,
                uint256
            )
        );

        address clone_ = Clones.clone(implementation);

        GatedNFT(clone_).initialize(
            owner_,
            config_,
            tier_,
            minimumStatus_,
            maxPerAddress_,
            transferrable_,
            maxMintable_,
            royaltyRecipient_,
            royaltyBPS_
        );

        return clone_;
    }
}
