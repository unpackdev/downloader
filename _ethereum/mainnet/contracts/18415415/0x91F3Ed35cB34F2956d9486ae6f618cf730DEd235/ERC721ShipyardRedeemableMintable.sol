// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC165.sol";
import "./ERC721ConduitPreapproved_Solady.sol";
import "./ConsiderationStructs.sol";
import "./Ownable.sol";
import "./ERC7498NFTRedeemables.sol";
import "./RedeemablesStructs.sol";
import "./IRedemptionMintable.sol";
import "./ERC721ShipyardRedeemable.sol";
import "./IRedemptionMintable.sol";
import "./RedeemablesStructs.sol";

contract ERC721ShipyardRedeemableMintable is ERC721ShipyardRedeemable, IRedemptionMintable {
    /// @dev Revert if the sender of mintRedemption is not this contract.
    error InvalidSender();

    /// @dev The next token id to mint.
    uint256 _nextTokenId = 1;

    constructor(string memory name_, string memory symbol_) ERC721ShipyardRedeemable(name_, symbol_) {}

    function mintRedemption(
        uint256, /* campaignId */
        address recipient,
        ConsiderationItem[] calldata, /* consideration */
        TraitRedemption[] calldata /* traitRedemptions */
    ) external {
        if (msg.sender != address(this)) {
            revert InvalidSender();
        }
        // Increment nextTokenId first so more of the same token id cannot be minted through reentrancy.
        ++_nextTokenId;

        _mint(recipient, _nextTokenId - 1);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ShipyardRedeemable)
        returns (bool)
    {
        return interfaceId == type(IRedemptionMintable).interfaceId
            || ERC721ShipyardRedeemable.supportsInterface(interfaceId);
    }
}
