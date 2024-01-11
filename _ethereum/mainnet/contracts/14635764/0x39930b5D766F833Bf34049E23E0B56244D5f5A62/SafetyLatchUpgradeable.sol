// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import "./ERC721.sol";
import "./ERC1155.sol";
import "./ERC20.sol";
import "./OwnableUpgradeable.sol";

contract SafetyLatchUpgradeable is OwnableUpgradeable {
    function __SafetyLatchUpgradeable_init() public initializer {
        __Ownable_init();
    }

    function withdrawERC721(address contractAddress, uint256 tokenId)
        public
        onlyOwner
    {
        ERC721(contractAddress).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function withdrawERC1155(address contractAddress, uint256 tokenId)
        public
        onlyOwner
    {
        uint256 balance = ERC1155(contractAddress).balanceOf(
            address(this),
            tokenId
        );
        ERC1155(contractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            balance,
            ""
        );
    }

    function withdrawERC20(address contractAddress) public onlyOwner {
        uint256 balance = ERC20(contractAddress).balanceOf(address(this));
        ERC20(contractAddress).transfer(msg.sender, balance);
    }
}
