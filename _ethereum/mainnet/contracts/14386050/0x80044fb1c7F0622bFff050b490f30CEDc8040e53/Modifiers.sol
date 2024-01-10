// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";
import "./LibGetters.sol";

contract Modifiers {
    modifier lockInner(uint256 _metaNftId) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        require(!pairInfo.innerLock);
        pairInfo.innerLock = true;
        _;
        pairInfo.innerLock = false;
    }

    modifier lockOuter(uint256 _metaNftId) {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        require(!pairInfo.outerLock);
        pairInfo.outerLock = true;
        _;
        pairInfo.outerLock = false;
    }

    modifier ensure(uint64 _deadline) {
        require(_deadline >= block.timestamp);
        _;
    }

    modifier listed(uint256 _metaNftId) {
        AppStorage storage ds = LibAppStorage._diamondStorage();
        PairInfo storage pairInfo = ds.pairs[_metaNftId];

        /// Check it is the latest version.
        require(pairInfo.version == ds.metaNftIds[pairInfo.nftAddress][pairInfo.tokenId].length - 1);

        /// Check the latest version is activated.
        require(pairInfo.activated);
        _;
    }

    modifier delisted(uint256 _metaNftId) {
        PairInfo storage pairInfo = LibAppStorage._diamondStorage().pairs[_metaNftId];

        /// Check the latest version is activated.
        require(!pairInfo.activated);
        _;
    }

    modifier onlyOneBlock() {
        mapping(uint256 => mapping(address => bool)) storage transactionHistory = LibAppStorage._diamondStorage().transactionHistory;
        require(
            !transactionHistory[block.number][tx.origin],
            "Pilgrim: one block, one function"
        );
        require(
            !transactionHistory[block.number][msg.sender],
            "Pilgrim: one block, one function"
        );

        _;

        transactionHistory[block.number][tx.origin] = true;
        transactionHistory[block.number][msg.sender] = true;
    }
}
