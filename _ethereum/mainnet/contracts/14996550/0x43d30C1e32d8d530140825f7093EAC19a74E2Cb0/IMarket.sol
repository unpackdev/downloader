// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUtils.sol";


interface IMarket {
    // For Fee dividend
    struct Collaborators {
        address[] _collaborators;
        uint8[] _percentages;
        bool _receiveCollabShare;
    }

    // All EVENTS Related To Market
    event OrderCreated(uint256 indexed orderId, IUtils.Order order);
    event OrderCompleted(uint256 indexed orderId, IUtils.Order order);
    event OrderRemoved(uint256 indexed orderId, IUtils.Order order);

    event BidAdded(uint256 indexed bidId, IUtils.Bid bid);
    event BidAccepted(uint256 indexed bidId, IUtils.Bid bid);
    event BidRemoved(uint256 indexed bidId, IUtils.Bid bid);

    event CommissionUpdated(uint8 commissionPercentage);
    event UpdateAdminWallet(address indexed _oldWallet, address indexed _newAdminWallet);

    /**
     * @notice This Method is used to set Admin's Address
     *
     * @param _newAdminAddress Admin's Address To set
     *
     * @return bool Transaction status
     */
    function setAdminAddress(address _newAdminAddress) external returns (bool);

    /**
     * @notice This Method is used to set Commission percentage of The Admin
     *
     * @param _commissionPercentage New Commission Percentage To set
     *
     * @return bool Transaction status
     */
    function setCommissionPercentage(uint8 _commissionPercentage)
        external
        returns (bool);
    /**
     * @notice This method is used to get Admin's Commission Percentage
     *
     * @return uint8 Commission Percentage
     */
    function getCommissionPercentage() external view returns (uint8);

    function updateCurrency(address _tokenAddress, bool _status) external returns (bool);


    function updateNFTContract(address _tokenAddress, bool _status) external returns (bool);


    /**
     * @notice Sets the order on a particular NFT.
     */
    function setOrder(address _nftContract, uint256 _tokenId, address _currency, uint256 _askAmount, uint256 expiryTime) external;
    function getOrder(uint256 _orderId)
        external
        view
        returns (IUtils.Order memory);

    function cancelOrder(uint256 _orderId)
        external
        returns (bool);

    function completeOrder(uint256 _orderId)
        external
        returns (bool);

    /**
     * @notice Sets the Bid on a particular NFT.
     */
    function addBid(address _nftContract, uint256 _tokenId, address _currency, uint256 _bidAmount, uint256 expiryTime) external;
    function getBid(uint256 _bidId)
        external
        view
        returns (IUtils.Bid memory);

    function cancelBid(uint256 _bidId)
        external
        returns (bool);

    function acceptBid(uint256 _bidId)
        external
        returns (bool);

} //end of interface  marketplace