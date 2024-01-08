// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "./IERC721.sol";
import "./console.sol";

/// @title OwnableERC721
/// @notice Use ERC721 ownership for access control
contract OwnableERC721 {
    address private _nftAddress;

    modifier onlyOwner() {
        console.log('owner %s', owner());
        require(owner() == msg.sender, "OwnableERC721: caller is not the owner");
        _;
    }

    function _setNFT(address nftAddress) internal {
        console.log('setNFT %s', nftAddress);
        _nftAddress = nftAddress;
    }

    function nft() public view virtual returns (address nftAddress) {
        return _nftAddress;
    }

    function owner() public view virtual returns (address ownerAddress) {
        console.log('this %s', address(this));
        console.log('nft addr', _nftAddress);
        return IERC721(_nftAddress).ownerOf(uint256(address(this)));

    }
}
