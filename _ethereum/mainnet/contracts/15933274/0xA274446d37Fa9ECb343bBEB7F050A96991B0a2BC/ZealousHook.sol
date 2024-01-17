//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./IPublicLockV12.sol";

interface ERC721 {
    function balanceOf(address account) external view returns (uint256);
}

interface ERC1155 {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}


error NOT_AUTHORIZED();

contract ZealousHook {
    uint256 MAX_INT = 2**256 - 1;

    mapping(address => mapping(address => uint)) public partners;

    constructor() {
    }

    function addPartner(address lock, address partner, uint price) public {
        if (!IPublicLock(lock).isLockManager(msg.sender)) {
            revert NOT_AUTHORIZED();
        }
        partners[lock][partner] = price;
    }

    /**
     * Price is the same for everyone... except if the user has a NFT from the `data` field.
     * `data` is [contract, tokenId]
     * if `tokenId` is MAXUINT, assume 721
     * if `tokenId` is <MAXUINT, assume 1155
     * we then make `balanceOf` 
     */
    function keyPurchasePrice(
        address, /* buyer */
        address recipient,
        address, /* referrer */
        bytes memory data
    ) external view returns (uint256 minKeyPrice) {
        if (data.length == 0) {
            return IPublicLock(msg.sender).keyPrice();
        }
        (address nftContract, uint tokenId) = abi.decode(data, (address, uint));
        uint price  = partners[msg.sender][nftContract];
        if (tokenId == MAX_INT) {
            uint balance721 = ERC721(nftContract).balanceOf(recipient);
            if (balance721 > 0) {
                return price;
            } 
            return IPublicLock(msg.sender).keyPrice();
        }
        uint balance1155 = ERC1155(nftContract).balanceOf(recipient, tokenId);
        if (balance1155 > 0) {
            return price;
        }
        return IPublicLock(msg.sender).keyPrice();
    }

    /**
     * No-op but required for the hook to work
     */
    function onKeyPurchase(
        uint256, /* tokenID */
        address, /* from */
        address, /* recipient */
        address, /* referrer */
        bytes calldata, /* data */
        uint256, /* minKeyPrice */
        uint256 /* pricePaid */
    ) external {
    }

    // TODO implement onValidKey hook so that all NFT are considered expired after 31/12/2023
    //
}