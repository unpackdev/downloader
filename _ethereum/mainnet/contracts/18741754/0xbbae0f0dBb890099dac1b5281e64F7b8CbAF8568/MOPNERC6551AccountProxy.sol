// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./console.sol";

import "./IERC721.sol";
import "./ERC1967Upgrade.sol";
import "./Proxy.sol";
import "./ERC6551AccountLib.sol";

interface ICryptoPunks {
    function punkIndexToAddress(
        uint index
    ) external view returns (address owner);
}

contract MOPNERC6551AccountProxy is Proxy, ERC1967Upgrade {
    address public immutable defaultImplementation;

    constructor(address defaultImplementation_) {
        defaultImplementation = defaultImplementation_;
    }

    function upgradeTo(address implementation_) public {
        (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        ) = ERC6551AccountLib.token();

        require(chainId == block.chainid, "chainId mismatch");
        if (tokenContract == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
            require(
                msg.sender ==
                    ICryptoPunks(tokenContract).punkIndexToAddress(tokenId),
                "only owner can upgrade"
            );
        } else {
            require(
                msg.sender == IERC721(tokenContract).ownerOf(tokenId),
                "only owner can upgrade"
            );
        }

        require(implementation_ != _implementation(), "same Implementation");
        ERC1967Upgrade._upgradeTo(implementation_);
    }

    function _implementation()
        internal
        view
        override
        returns (address implementation_)
    {
        implementation_ = ERC1967Upgrade._getImplementation();
        if (implementation_ == address(0))
            implementation_ = defaultImplementation;
    }

    function implementation() public view returns (address) {
        return _implementation();
    }
}
