// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


/**
 * @dev Interface for interacting with the Nafter contract that holds Nafter beta tokens.
 */
interface INafter {

    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function creatorOfToken(uint256 _tokenId)
    external
    view
    returns (address payable);

    /**
     * @dev Gets the Service Fee
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function getServiceFee(uint256 _tokenId)
    external
    view
    returns (uint8);

    /**
     * @dev Gets the price type
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     * @return get the price type
     */
    function getPriceType(uint256 _tokenId, address _owner)
    external
    view
    returns (uint8);

    /**
     * @dev update price only from auction.
     * @param _price price of the token
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the token owner
     */
    function setPrice(uint256 _price, uint256 _tokenId, address _owner) external;

    /**
     * @dev update bids only from auction.
     * @param _bid bid Amount
     * @param _bidder bidder address
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the token owner
     */
    function setBid(uint256 _bid, address _bidder, uint256 _tokenId, address _owner) external;

    /**
     * @dev remove token from sale
     * @param _tokenId uint256 id of the token.
     * @param _owner owner of the token
     */
    function removeFromSale(uint256 _tokenId, address _owner) external;

    /**
     * @dev get tokenIds length
     */
    function getTokenIdsLength() external view returns (uint256);

    /**
     * @dev get token Id
     * @param _index uint256 index
     */
    function getTokenId(uint256 _index) external view returns (uint256);

    /**
     * @dev Gets the owners
     * @param _tokenId uint256 ID of the token
     */
    function getOwners(uint256 _tokenId)
    external
    view
    returns (address[] memory owners);

    /**
     * @dev Gets the is for sale
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getIsForSale(uint256 _tokenId, address _owner) external view returns (bool);
}
