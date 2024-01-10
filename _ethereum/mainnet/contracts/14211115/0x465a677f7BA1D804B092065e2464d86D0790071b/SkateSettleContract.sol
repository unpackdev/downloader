// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ISkateContract.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";

contract SkateSettleContract is Ownable, IERC721Receiver {
    ISkateContract private _skateAddress;

    constructor(ISkateContract skateAddress_) {
        _skateAddress = skateAddress_;
    }

    function startAuction() external {
        require(
            _skateAddress.owner() == address(this),
            "Skate: Please transfer ownership to this contract"
        );
        _skateAddress.auctionStart();
    }

    function settleAuction() external virtual {
        _skateAddress.settleCurrentAndCreateNewAuction();
    }

    function transferOwnershipOfSettleContract(address newOwner)
        external
        virtual
        onlyOwner
    {
        _skateAddress.transferOwnership(newOwner);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
