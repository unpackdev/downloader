// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;


interface IJustWin {
    
    struct Mintable {
        uint friends;
        uint family;
        uint whitelist;
        uint viplist;
    }

    struct MaxSupplies {
        uint friends;
        uint whitelist;
        uint viplist;
        uint sale;
    }

    struct Prices {
        uint friends;
        uint whitelist;
        uint viplist;
        uint sale;
    }

    struct Roots {
        bytes32 whitelist;
        bytes32 viplist;
    }

    struct Claimed {
        uint friends;
        uint whitelist;
        uint viplist;
    }
    struct Supplies {
        uint friends;
        uint whitelist;
        uint viplist;
        uint sale;
    }

    struct Params {
        uint version;
        uint supply;
        uint maxSupply;
        Supplies supplies;
        MaxSupplies maxSupplies;
        Mintable mintable;
        Prices prices;
        Roots roots;
    }

    enum List {
        friends,
        whitelist,
        viplist,
        sale
    }
}