//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
// Registry managed contracts
import "./IHub.sol";
import "./IRoyalties.sol";
import "./INft.sol";

contract Registry is Ownable, ReentrancyGuard {
    // -----------------------------------------------------------------------
    // STATE
    // -----------------------------------------------------------------------

    // Storage of current hub instance
    IHub internal hubInstance_;
    // Storage of current royalties instance
    IRoyalties internal royaltiesInstance_;
    // Storage of NFT contract (cannot be changed)
    INft internal nftInstance_;

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _nft) Ownable() {
        require(INft(_nft).isActive(), "REG: Address invalid NFT");
        nftInstance_ = INft(_nft);
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getHub() external view returns (address) {
        return address(hubInstance_);
    }

    function getRoyalties() external view returns (address) {
        return address(royaltiesInstance_);
    }

    function getNft() external view returns (address) {
        return address(nftInstance_);
    }

    function isActive() external view returns (bool) {
        return true;
    }

    // -----------------------------------------------------------------------
    //  ONLY OWNER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function updateHub(address _newHub) external onlyOwner nonReentrant {
        IHub newHub = IHub(_newHub);
        require(_newHub != address(0), "REG: cannot set HUB to 0x");
        require(
            address(hubInstance_) != _newHub,
            "REG: Cannot set HUB to existing"
        );
        require(
            newHub.isAuctionHubImplementation(),
            "REG: HUB implementation error"
        );
        require(IHub(_newHub).init(), "REG: HUB could not be init");
        hubInstance_ = IHub(_newHub);
    }

    function updateRoyalties(address _newRoyalties)
        external
        onlyOwner
        nonReentrant
    {
        require(_newRoyalties != address(0), "REG: cannot set ROY to 0x");
        require(
            address(royaltiesInstance_) != _newRoyalties,
            "REG: Cannot set ROY to existing"
        );
        require(IRoyalties(_newRoyalties).init(), "REG: ROY could not be init");
        royaltiesInstance_ = IRoyalties(_newRoyalties);
    }
}
