//SPDX-License-Identifier: BSD
pragma solidity ^0.8.21;
/*
* Just a helper contract to fetch data for the UI
*/
contract Stats {

    IStogies public stogies = IStogies(0xec6eD05f61E2e8230081eaD6362ebCf2AC505126);
    IBadges public badges = IBadges(0xED9a438bD8E2F0e3F0Feb4DD397cBA4274609DBe);

    struct BadeStats {
        uint256[] ret;           // different stats, including balances, etc
        IBadges.Badge[]  inventory;   // badges
        string[]  uris;       // uris
        uint256[]  ids;       // ids
        IBadges.Badge[]  expInventory;// expired badges
        string[]  expUris;    // uris of expired tokens
        uint256[]  expIds;     // expired ids
    }

    struct Reserve {
        uint112 token0;
        uint112 token1;
        address t0;
    }

    function getStats(
        address _user,
        address[] calldata pools) external view returns (
        uint256[] memory ret,
        uint256[] memory cigdata,
        address theCEO,
        bytes32 graffiti,
        uint112[] memory reserves,
        BadeStats memory bs,       // data from idbadges.sol
        Reserve[] memory r         // reserves info for each pool passed
    ) {
        (ret, cigdata, theCEO, graffiti, reserves) = stogies.getStats(_user);
        (
            bs.ret,
            bs.inventory,
            bs.uris,
            bs.ids,
            bs.expInventory,
            bs.expUris,
            bs.expIds) = badges.getStats(_user);
        r = new Reserve[](pools.length);
        for (uint256 i; i < pools.length; i++) {
            (r[i].token0,r[i].token1,) = ILiquidityPool(pools[i]).getReserves();
            r[i].t0 = ILiquidityPool(pools[i]).token0();
        }
    }
}

interface IStogies {
    function getStats(address _user) external view returns (
        uint256[] memory, // ret
        uint256[] memory, // cigdata
        address,          // theCEO
        bytes32,          // graffiti
        uint112[] memory  // reserves
    );
}

interface IBadges {
    enum State {
        Uninitialized,
        Active,
        PendingExpiry,
        Expired
    }
    struct Badge {
        address identiconSeed;   // address of identicon (the minter)
        address owner;           // address of current owner
        uint256 minStog;         // minimum stogies deposit needed
        address approval;        // address approved for
        uint64 transferAt;       // block id of when was the last transfer
        uint64 index;            // sequential index in the wallet
        State state;             // NFT's state
    }

    function getStats(
        address _holder
    ) view external returns (
        uint256[] memory,           // different stats, including balances, etc
        Badge[] memory inventory,   // badges
        string[] memory uris,       // uris
        uint256[] memory ids,       // ids
        Badge[] memory expInventory,// expired badges
        string[] memory expUris,    // uris of expired tokens
        uint256[] memory expIds     // expired ids
    );
}

interface ILiquidityPool  {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
}