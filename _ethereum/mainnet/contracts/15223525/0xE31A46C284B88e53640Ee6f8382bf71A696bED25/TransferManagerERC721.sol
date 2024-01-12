/**
                                                ....                      ....                              ....       
                                                 #@@@?                    ^@@@@                             :@@@@       
                                                 P&&&!                    :@@@@                             :@@@@       
     ....  ....  ....     .....................  ....   ............   ...!@@@@:...   ............  ........!@@@@       
    !@@@&  @@@@: G@@@Y   .@@@@@@@@@@@@@@@@@@@@@. #@@@? !@@@@@@@@@@@@~ J@@@@@@@@@@@@^ P@@@@@@@@@@@@. B@@@@@@@@@@@@       
    !@@@&  @@@@: G@@@5   .@@@@&&&&@@@@@&&&&@@@@. #@@@? !@@@@&&&&@@@@~ 7&&&&@@@@&&&&: P@@@@#&&&@@@@. B@@@@&&&&@@@@       
    ~&&&G  #&&&. G@@@5   .@@@@.   G@@@5   .@@@@. #@@@? !@@@&    &@@@~     ^@@@@      P@@@G...~@@@@. B@@@Y   ^@@@@       
                 G@@@5   .@@@@.   G@@@5   .@@@@. #@@@? !@@@&    &@@@~     ^@@@@      P@@@@@@@@@@@@. B@@@J   :@@@@       
                 G@@@5   .@@@@.   G@@@5   .@@@@. #@@@? !@@@&    &@@@~     ^@@@@      P@@@@#&&&##&#. B@@@J   :@@@@       
     ............B@@@5   .@@@@.   G@@@5   .@@@@. #@@@? !@@@&    &@@@~     ^@@@@      P@@@G........  B@@@5...!@@@@       
    !@@@@@@@@@@@@@@@@5   .@@@@.   G@@@5   .@@@@. #@@@? 7@@@&    &@@@~     ^@@@@      P@@@@@@@@@@@@. B@@@@@@@@@@@@       
    ~&&&&&&&&&&&&&&&&?   .&&&#    Y&&&?   .&&&#. P&&&! ~&&&G    B&&&^     :&&&#      J&&&&&&&&&&&&. 5&&&&&&&&&&&#   
                                                                                                                                                                                            
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

import "./ITransferManagerNFT.sol";

/**
 * @title TransferManagerERC721
 * @notice It allows the transfer of ERC721 tokens.
 */
contract TransferManagerERC721 is ITransferManagerNFT {
    address public immutable MINTED_EXCHANGE;

    /**
     * @notice Constructor
     * @param _mintedExchange address of the Minted exchange
     */
    constructor(address _mintedExchange) {
        MINTED_EXCHANGE = _mintedExchange;
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
    ) external override {
        require(msg.sender == MINTED_EXCHANGE, "Transfer: Only Minted Exchange");
        // https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721-safeTransferFrom
        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }
}
