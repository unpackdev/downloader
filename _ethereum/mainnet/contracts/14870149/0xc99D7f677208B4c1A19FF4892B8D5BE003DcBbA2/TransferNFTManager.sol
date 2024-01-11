// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

import "./IERC721.sol";
import "./Ownable.sol";

/**
 * @title TransferManagerERC721
 * @notice It allows the transfer of ERC721 tokens.
 */
contract TransferNFTManager is Ownable {
    address public OK_EXCHANGE;

    /**
     * @notice Constructor
     * @param _exchange address of the LooksRare exchange
     */
    constructor(address _exchange) {
        OK_EXCHANGE = _exchange;
    }


    function setExchangeAddr(
        address _exchange
    ) public onlyOwner {
        OK_EXCHANGE = _exchange;
    }

    function proxy(
        address dest,
        uint256 howToCall,
        bytes calldataValue
    ) public returns (bool result) {
        require(msg.sender == OK_EXCHANGE, "Transfer: Only OK Exchange");
        if (howToCall == 0) {
            result = dest.call(calldataValue);
        } else if (howToCall == 1) {
            result = dest.delegatecall(calldataValue);
        }
        return result;
    }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @dev For ERC721, amount is not used
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external {
        require(msg.sender == OK_EXCHANGE, "Transfer: Only OK Exchange");
        // https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721-safeTransferFrom
        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }
}
