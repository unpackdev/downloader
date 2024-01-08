// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";

contract AddressBook is Ownable {
    enum Name {
        CHICK,
        GOVERN_TOKEN,
        VAULT_TOKEN,
        ETH_PRICE_FEED,
        CHICK_PRICE_FEED,
        REWARD_MGR,
        INTEREST_MGR,
        LIQUIDATION_MGR,
        ROUTER,
        LP
    }

    event SetAddressEvent( Name name, address addr );

    mapping(Name => address) private mBook;

    function setAddress(Name name, address addr) public onlyOwner {
        mBook[name] = addr;
        emit SetAddressEvent( name, addr );
    }

    function getAddress(Name name) public view returns (address) {
        return mBook[name];
    }
}

