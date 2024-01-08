// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IAllocatedEditionsLogicEvents {
    event EditionPurchased(
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver
    );

    event EditionCreatorChanged(
        address indexed previousCreator,
        address indexed newCreator
    );
}

interface IAllocatedEditionsLogic {
    function changeBaseURI(string memory baseURI_) external;

    function withdrawFunds() external;

    function burn(uint256 tokenId) external;
}
