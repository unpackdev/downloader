// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./NFTYBot.sol";
import "./NFTYPass.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";

contract NFTYMigration is Ownable, IERC721Receiver {
    NFTYPass public legacyToken =
        NFTYPass(0x46C1d006e1f6611825cD448E1D49Cf660a2b79a1);
    NFTYBot public token = NFTYBot(0x96516C18a3Be6e036b364a916CEFD89e8f3Fa079);

    constructor() {
        legacyToken.setApprovalForAll(address(token), true);
    }

    function migrate() external {
        uint256 balance = legacyToken.balanceOf(msg.sender);

        while (balance > 0) {
            uint256 tokenId = legacyToken.tokenOfOwnerByIndex(
                msg.sender,
                balance - 1
            );

            uint256 expiry = legacyToken.tokenExpiry(tokenId) + 1 weeks;

            legacyToken.setExpiryTime(
                tokenId,
                legacyToken.tokenExpiry(tokenId) + 2 weeks
            );
            legacyToken.transferFrom(msg.sender, address(this), tokenId);
            legacyToken.transferOwnership(address(token));

            token.migrate();
            token.transferFrom(address(this), msg.sender, tokenId);
            token.setExpiryTime(tokenId, expiry);
            token.transferLegacyOwnership(address(this));

            balance--;
        }
    }

    function transferNFTYPassOwnership(address newOwner) external onlyOwner {
        legacyToken.transferOwnership(newOwner);
    }

    function transferNFTYBotOwnership(address newOwner) external onlyOwner {
        token.transferOwnership(newOwner);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
