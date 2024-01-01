// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721LazyMint.sol";
import "./ERC721AVirtualApprove.sol";

contract Ambatu is ERC721LazyMint {

    struct RedeemInfo {
        bool redeemSoulOpen;
        address soulAddress;
    }
    RedeemInfo public redeemInfo;

    event SoulRedeemed(
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 indexed soulId
    );

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
        ERC721LazyMint(
            _defaultAdmin,
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {}

    function redeemSouls(address _receiver, uint256[] calldata soulIds) public {
        require(redeemInfo.redeemSoulOpen == true, "Redeem is not opened.");

        uint256 amount = soulIds.length;
        require(amount > 0, "No token IDs provided");

        for (uint256 i = 0; i < amount; i++) {
            uint256 soulTokenId = soulIds[i];

            // Ensure that the caller owns the NFT to burn
            checkSoulOwnerOf(soulTokenId);

            // Burn the NFT by transferring it to address(0)
            burnSoul(soulTokenId);

            uint256 tokenIdToClaim = nextTokenIdToClaim();

            // Mint the revealed NFT to the caller
            super.claim(_receiver, 1);

            emit SoulRedeemed(_receiver, tokenIdToClaim, soulTokenId);
        }
    }

    function burnSoul(uint256 tokenId) private {
        ERC721LazyMint soulNFT = ERC721LazyMint(redeemInfo.soulAddress);
        soulNFT.burn(tokenId);
    }

    // Ensure that the caller owns the NFT to burn
    function checkSoulOwnerOf(uint256 tokenId) private view returns (bool) {
        ERC721A soulNFT = ERC721A(redeemInfo.soulAddress);
        require(
            soulNFT.ownerOf(tokenId) == msg.sender,
            "You don't own this Soul NFT"
        );
        return true;
    }

    // Function for the admin to set the NFT contract address
    function setSoulAddress(address newAddress) public onlyOwner {
        redeemInfo = RedeemInfo(redeemInfo.redeemSoulOpen, newAddress);
    }

    function setRedeemSoulState(bool _redeemBeanOpen) external onlyOwner {
        address soulAddress = redeemInfo.soulAddress;
        require(soulAddress != address(0), "Soul Address not set.");
        redeemInfo = RedeemInfo(_redeemBeanOpen, soulAddress);
    }
}
