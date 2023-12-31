// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeCollectionToken.sol";

/**
 * @author MetaPlayerOne DAO
 * @title GenerativeCollectionFactory
 */
contract GenerativeCollectionFactory {
    address private _owner_of;
    address private _randomizer_address;
    address private _whitelist_storage_address;
    address private _goldlist_storage_address;
    address private _airdrop_storage_address;
    address private _profit_split_storage_address;

    constructor(
        address owner_of_,
        address randomizer_address_,
        address whitelist_storage_address_,
        address goldlist_storage_address_,
        address airdrop_storage_address,
        address profit_split_storage_address_
    ) {
        _owner_of = owner_of_;
        _randomizer_address = randomizer_address_;
        _whitelist_storage_address = whitelist_storage_address_;
        _goldlist_storage_address = goldlist_storage_address_;
        _airdrop_storage_address = airdrop_storage_address;
        _profit_split_storage_address = profit_split_storage_address_;
    }

    event collectionCreated(
        address token_address,
        address owner_of,
        string[3] metadata,
        uint96 royalty,
        bool is_randomness,
        uint256[4] main_data
    );

    function createCollection(
        string[3] memory metadata_,
        uint256[4] memory main_data_,
        bool is_randomness_,
        uint96 royalty_
    ) public {
        address[7] memory main_addresses = [
            msg.sender,
            _owner_of,
            _randomizer_address,
            _whitelist_storage_address,
            _goldlist_storage_address,
            _airdrop_storage_address,
            _profit_split_storage_address
        ];
        GenerativeCollectionToken token = new GenerativeCollectionToken(
            main_addresses,
            main_data_,
            metadata_,
            royalty_,
            is_randomness_
        );
        emit collectionCreated(
            address(token),
            msg.sender,
            metadata_,
            royalty_,
            is_randomness_,
            main_data_
        );
    }
}
