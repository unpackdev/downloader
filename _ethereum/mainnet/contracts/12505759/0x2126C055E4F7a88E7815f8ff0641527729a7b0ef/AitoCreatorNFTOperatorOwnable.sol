// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./AitoCreatorNFTOperator.sol";

contract AitoCreatorNFTOperatorOwnable is AitoCreatorNFTOperator, Ownable {
    constructor(string memory name, string memory symbol)
        AitoCreatorNFTOperator(name, symbol, msg.sender)
    {}

    function mint(
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string calldata uri,
        bool approveGlobal
    ) public override onlyOwner {
        super.mint(creator, to, feeRecipient, feeBps, uri, approveGlobal);
    }

    function batchMint(
        uint256 amount,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string[] calldata uris,
        bool approveGlobal
    ) public override onlyOwner {
        super.batchMint(amount, creator, to, feeRecipient, feeBps, uris, approveGlobal);
    }

    function batchMintCopies(
        uint256 amount,
        address creator,
        address to,
        address feeRecipient,
        uint16 feeBps,
        string calldata uri,
        bool approveGlobal
    ) public override onlyOwner {
        super.batchMintCopies(amount, creator, to, feeRecipient, feeBps, uri, approveGlobal);
    }
}
