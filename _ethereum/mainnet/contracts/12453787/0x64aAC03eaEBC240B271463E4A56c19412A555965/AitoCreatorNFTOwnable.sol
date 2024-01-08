// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./AitoCreatorNFT.sol";

contract AitoCreatorNFTOwnable is AitoCreatorNFT, Ownable {
    constructor(string memory name, string memory symbol) AitoCreatorNFT(name, symbol) {}

    function mint(
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string calldata uri
    ) public override onlyOwner {
        super.mint(creator, to, feeRecipient, feeBps, uri);
    }

    function batchMint(
        uint256 amount,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string[] calldata uris
    ) public override onlyOwner {
        super.batchMint(amount, creator, to, feeRecipient, feeBps, uris);
    }

    function batchMintCopies(
        uint256 amount,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string calldata uri
    ) public override onlyOwner {
        super.batchMintCopies(amount, creator, to, feeRecipient, feeBps, uri);
    }
}
