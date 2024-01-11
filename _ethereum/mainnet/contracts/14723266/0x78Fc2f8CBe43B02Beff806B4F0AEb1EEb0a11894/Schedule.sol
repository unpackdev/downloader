// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";

error PublicSaleOpen();
error PublicSaleNotOpen();
error TokenMintedOut();
error TokenNotMintedOut();

/** @dev This contract can be used to manage some basic scheduling of a token sale.
 *       To have the isMintedOut() function work, it is required to either update the mintedOutTimestamp
 *       or to override the function (using totalSupply() for instance).
 */
contract Schedule is Ownable {
    uint256 public publicSaleStartTimestamp;
    uint256 public mintedOutTimestamp;

    function openPublicSale() external onlyOwner whenPublicSaleClosed {
        publicSaleStartTimestamp = block.timestamp;
    }

    function isPublicSaleOpen() public view virtual returns (bool) {
        return
            publicSaleStartTimestamp != 0 &&
            block.timestamp > publicSaleStartTimestamp;
    }

    modifier whenPublicSaleOpen() {
        if (!isPublicSaleOpen()) revert PublicSaleNotOpen();
        _;
    }

    modifier whenPublicSaleClosed() {
        if (isPublicSaleOpen()) revert PublicSaleOpen();
        _;
    }

    function isMintedOut() public view virtual returns (bool) {
        return mintedOutTimestamp > 0;
    }

    modifier whenMintedOut() {
        if (!isMintedOut()) revert TokenNotMintedOut();
        _;
    }

    modifier whenNotMintedOut() {
        if (isMintedOut()) revert TokenMintedOut();
        _;
    }
}
