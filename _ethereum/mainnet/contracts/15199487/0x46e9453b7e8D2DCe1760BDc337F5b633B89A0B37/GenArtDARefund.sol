// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./GenArtDutchAuctionHouse.sol";

contract GenArtDARefund is GenArtAccess {
    GenArtDutchAuctionHouse public _genartDA;
    mapping(address => uint256) public _refundsEth;
    address[] public _fundedCollections;
    // collection => user => bool
    mapping(address => mapping(address => bool)) public _claimedCollections;

    constructor(address genartDA_) {
        _genartDA = GenArtDutchAuctionHouse(payable(genartDA_));
    }

    /**
     * @dev modifier to only allow DA contract to call functions
     */
    modifier onlyDAContract() {
        require(
            address(_genartDA) == msg.sender,
            "GenArtDARefund: only DA contract allowed"
        );
        _;
    }

    function claim(address collection) public {
        uint256 amount = _getClaimableAmount(collection, msg.sender);
        payable(msg.sender).transfer(amount);
    }

    function claimCollections(address[] memory collections) public {
        uint256 amount;
        for (uint256 i; i < collections.length; i++) {
            amount += _getClaimableAmount(collections[i], msg.sender);
        }
        payable(msg.sender).transfer(amount);
    }

    function claimAll() public {
        _claim(msg.sender);
    }

    function _claim(address user) internal {
        uint256 amount;

        // claim all funden collections for user
        for (uint256 i; i < _fundedCollections.length; i++) {
            amount += _getClaimableAmount(_fundedCollections[i], user);
        }
        payable(user).transfer(amount);
    }

    function _getClaimableAmount(address collection, address user)
        internal
        returns (uint256)
    {
        if (_claimedCollections[collection][user]) return 0;
        uint256 refunds = calcDARefunds(collection, user);
        _claimedCollections[collection][user] = true;
        return refunds;
    }

    function calcDARefunds(address collection, address user)
        public
        view
        returns (uint256)
    {
        uint256 totalRefund;
        uint256 refundPhase = _genartDA.calcRefundPhase(collection);
        uint256 avgPrice = _genartDA.calcAvgPrice(collection);

        for (uint256 i = 1; i <= refundPhase; i++) {
            uint256 mints = _genartDA._mints(collection, user, refundPhase);
            uint256 price = _genartDA.getAuctionPriceByPhase(
                collection,
                refundPhase
            );
            totalRefund += (price - avgPrice) * mints;
        }

        return totalRefund;
    }

    function receiveFunds(address collection) external payable onlyDAContract {
        _refundsEth[collection] += msg.value;
        _fundedCollections.push(collection);
    }
}
