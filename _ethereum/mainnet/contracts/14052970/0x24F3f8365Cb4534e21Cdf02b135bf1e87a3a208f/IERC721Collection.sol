// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC165.sol";

import "./ICollectionBase.sol";

/**
 * @dev ERC721 Collection Interface
 */
interface IERC721Collection is ICollectionBase, IERC165 {

    event Unveil(uint256 collectibleId, address tokenAddress, uint256 tokenId);

    struct CollectionState {
        uint16 tokenMax;
        uint16 tokenRemaining;
        uint256 tokenPrice;
        uint16 transactionLimit;
        uint16 purchaseLimit;
        uint256 presaleTokenPrice;
        uint16 presalePurchaseLimit;
        uint16 purchaseCount;
        bool active;
        uint256 startTime;
        uint256 endTime;
        uint256 presaleInterval;
    }

    /**
     * @dev Pre-mint
     */
    function premint(uint16 amount) external;

    function premint(address[] calldata addresses) external;

    /**
     *  @dev set the tokenURI prefix
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev Withdraw funds
     */
    function withdraw(address payable recipient, uint256 amount) external;

    /**
     * @dev Activate the contract
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_) external;

    /**
     * @dev Deactivate the contract
     */
    function deactivate() external;

    /**
     * @dev purchase
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external payable;

    /**
     * @dev returns the collection state
     */
    function state() external view returns(CollectionState memory);

    /**
     * @dev Get number of tokens left
     */
    function tokenRemaining() external view returns(uint16);

}
