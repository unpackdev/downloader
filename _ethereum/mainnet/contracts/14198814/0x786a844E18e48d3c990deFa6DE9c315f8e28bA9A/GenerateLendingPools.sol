// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SupplyTreasuryFundForCompound.sol";
import "./IConvexBooster.sol";
import "./ISupplyBooster.sol";

/* 
This contract will be executed after the lending contracts is created and will become invalid in the future.
 */

interface ILendingMarket {
    function addMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) external;
}

interface ISupplyRewardFactoryExtra is ISupplyRewardFactory {
    function addOwner(address _newOwner) external;
}

contract GenerateLendingPools {
    address public convexBooster;
    address public lendingMarket;

    address public supplyBooster;
    address public supplyRewardFactory;

    bool public completed;
    address public deployer;

    struct ConvexPool {
        address target;
        uint256 pid;
    }

    struct LendingMarketMapping {
        uint256 convexBoosterPid;
        uint256[] supplyBoosterPids;
        int128[] curveCoinIds;
    }

    address[] public supplyPools;
    address[] public compoundPools;
    ConvexPool[] public convexPools;
    LendingMarketMapping[] public lendingMarketMappings;

    constructor(address _deployer) public {
        deployer = _deployer;
    }

    function setLendingContract(
        address _supplyBooster,
        address _convexBooster,
        address _lendingMarket,
        address _supplyRewardFactory
    ) public {
        require(
            deployer == msg.sender,
            "GenerateLendingPools: !authorized auth"
        );

        supplyBooster = _supplyBooster;
        convexBooster = _convexBooster;
        lendingMarket = _lendingMarket;
        supplyRewardFactory = _supplyRewardFactory;
    }

    function createMapping(
        uint256 _convexBoosterPid,
        uint256 _param1,
        uint256 _param2,
        int128 _param3,
        int128 _param4
    ) internal pure returns (LendingMarketMapping memory lendingMarketMapping) {
        uint256[] memory supplyBoosterPids = new uint256[](2);
        int128[] memory curveCoinIds = new int128[](2);

        supplyBoosterPids[0] = _param1;
        supplyBoosterPids[1] = _param2;

        curveCoinIds[0] = _param3;
        curveCoinIds[1] = _param4;

        lendingMarketMapping.convexBoosterPid = _convexBoosterPid;
        lendingMarketMapping.supplyBoosterPids = supplyBoosterPids;
        lendingMarketMapping.curveCoinIds = curveCoinIds;
    }

    function createMapping(
        uint256 _convexBoosterPid,
        uint256 _param1,
        int128 _param2
    ) internal pure returns (LendingMarketMapping memory lendingMarketMapping) {
        uint256[] memory supplyBoosterPids = new uint256[](1);
        int128[] memory curveCoinIds = new int128[](1);

        supplyBoosterPids[0] = _param1;
        curveCoinIds[0] = _param2;

        lendingMarketMapping.convexBoosterPid = _convexBoosterPid;
        lendingMarketMapping.supplyBoosterPids = supplyBoosterPids;
        lendingMarketMapping.curveCoinIds = curveCoinIds;
    }

    // function generateSupplyPools() internal {
    //     address compoundComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    //     // (address USDC,address cUSDC) = (0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x39AA39c021dfbaE8faC545936693aC917d5E7563); // index 0
    //     // (address DAI,address cDAI) = (0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643); // index 1
    //     // (address TUSD,address cTUSD) = (0x0000000000085d4780B73119b644AE5ecd22b376, 0x12392F67bdf24faE0AF363c24aC620a2f67DAd86); // index -
    //     // (address WBTC,address cWBTC) = (0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4); // index 2
    //     // (address Ether,address cEther) = (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5); // index 3


    //     // supplyPools.push(USDC);
    //     // supplyPools.push(DAI);
    //     // supplyPools.push(TUSD);
    //     // supplyPools.push(WBTC);
    //     // supplyPools.push(Ether);

    //     // compoundPools.push(cUSDC);
    //     // compoundPools.push(cDAI);
    //     // compoundPools.push(cTUSD);
    //     // compoundPools.push(cWBTC);
    //     // compoundPools.push(cEther);

    //     for (uint256 i = 0; i < supplyPools.length; i++) {
    //         SupplyTreasuryFundForCompound supplyTreasuryFund = new SupplyTreasuryFundForCompound(
    //                 supplyBooster,
    //                 compoundPools[i],
    //                 compoundComptroller,
    //                 supplyRewardFactory
    //             );

    //         ISupplyRewardFactoryExtra(supplyRewardFactory).addOwner(address(supplyTreasuryFund));

    //         ISupplyBooster(supplyBooster).addSupplyPool(
    //             supplyPools[i],
    //             address(supplyTreasuryFund)
    //         );
    //     }
    // }

    function generateConvexPools() internal {
        // USDC,DAI , supplyBoosterPids, curveCoinIds  =  [cUSDC, cDAI], [USDC, DAI]
        // convexPools.push( ConvexPool(0xC25a3A3b969415c80451098fa907EC722572917F, 4) ); // DAI USDC USDT sUSD               [1, 0] [0, 1] sUSD
        // convexPools.push( ConvexPool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B, 40) ); // MIM DAI USDC USDT               [1, 0] [1, 2] mim
        // convexPools.push( ConvexPool(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490, 9) ); // DAI USDC USDT                    [1, 0] [0, 1] 3Pool
        // convexPools.push( ConvexPool(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B, 32) ); // FRAX DAI USDC USDT              [1, 0] [1, 2] frax
        // convexPools.push( ConvexPool(0x1AEf73d49Dedc4b1778d0706583995958Dc862e6, 14) ); // mUSD + 3Crv                     [1, 0] [1, 2] musd
        // convexPools.push( ConvexPool(0x94e131324b6054c0D789b190b2dAC504e4361b53, 21) ); // UST + 3Crv                      [1, 0] [1, 2] ust
        // convexPools.push( ConvexPool(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA, 33) ); // LUSD + 3Crv                     [1, 0] [1, 2] lusd
        // convexPools.push( ConvexPool(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c, 36) ); // alUSD + 3Crv                    [1, 0] [1, 2] alusd
        // convexPools.push( ConvexPool(0xD2967f45c4f384DEEa880F807Be904762a3DeA07, 10) ); // GUSD + 3Crv                     [1, 0] [1, 2] gusd
        // convexPools.push( ConvexPool(0x4f3E8F405CF5aFC05D68142F3783bDfE13811522, 13) ); // USDN + 3Crv                     [1, 0] [1, 2] usdn
        // convexPools.push( ConvexPool(0x97E2768e8E73511cA874545DC5Ff8067eB19B787, 12) ); // USDK + 3Crv                     [1, 0] [1, 2] usdk
        // convexPools.push( ConvexPool(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a, 34) ); // BUSD + 3Crv                     [1, 0] [1, 2] busdv2
        // convexPools.push( ConvexPool(0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858, 11) ); // HUSD + 3Crv                     [1, 0] [1, 2] husd
        // convexPools.push( ConvexPool(0xC2Ee6b0334C261ED60C72f6054450b61B8f18E35, 15) ); // RSV + 3Crv                      [1, 0] [1, 2] rsv
        // convexPools.push( ConvexPool(0x3a664Ab939FD8482048609f652f9a0B0677337B9, 17) ); // DUSD + 3Crv                     [1, 0] [1, 2] dusd
        // convexPools.push( ConvexPool(0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6, 28) ); // USDP + 3Crv                     [1, 0] [1, 2] usdp

        // // TUSD
        // convexPools.push( ConvexPool(0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1, 31) ); // TUSD + 3Crv                     [2] [0] tusd

        // // WBTC
        // convexPools.push( ConvexPool(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3, 7) ); // renBTC + wBTC + sBTC            [3] [1] sbtc
        // convexPools.push( ConvexPool(0x2fE94ea3d5d4a175184081439753DE15AeF9d614, 20) ); // oBTC + renBTC + wBTC + sBTC     [3] [2] obtc
        // convexPools.push( ConvexPool(0x49849C98ae39Fff122806C06791Fa73784FB3675, 6) ); // renBTC + wBTC                   [3] [1] ren
        convexPools.push( ConvexPool(0xb19059ebb43466C323583928285a49f558E572Fd, 8) ); // HBTC + wBTC                     [3] [1] hbtc
        // convexPools.push( ConvexPool(0x410e3E86ef427e30B9235497143881f717d93c2A, 19) ); // BBTC + renBTC + wBTC + sBTC     [3] [2] bbtc
        // convexPools.push( ConvexPool(0x64eda51d3Ad40D56b9dFc5554E06F94e1Dd786Fd, 16) ); // tBTC + renBTC + wBTC + sBTC     [3] [2] tbtc
        // convexPools.push( ConvexPool(0xDE5331AC4B3630f94853Ff322B66407e0D6331E8, 18) ); // pBTC + renBTC + wBTC + sBTC     [3] [2] pbtc

        // // ETH
        // convexPools.push( ConvexPool(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c, 23) ); // ETH + sETH                      [4] [0] seth
        // convexPools.push( ConvexPool(0x06325440D014e39736583c165C2963BA99fAf14E, 25) ); // ETH + stETH                     [4] [0] steth
        // convexPools.push( ConvexPool(0xaA17A236F2bAdc98DDc0Cf999AbB47D47Fc0A6Cf, 27) ); // ETH + ankrETH                   [4] [0] ankreth
        // convexPools.push( ConvexPool(0x53a901d48795C58f485cBB38df08FA96a24669D5, 35) ); // ETH + rETH                      [4] [0] reth

        for (uint256 i = 0; i < convexPools.length; i++) {
            IConvexBooster(convexBooster).addConvexPool(convexPools[i].pid);
        }
    }

    function generateMappingPools() internal {
        // lendingMarketMappings.push(createMapping(0, 1, 0, 0, 1)); // [1, 0] [0, 1]
        // lendingMarketMappings.push(createMapping(1, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(2, 1, 0, 0, 1)); // [1, 0] [0, 1]
        // lendingMarketMappings.push(createMapping(3, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(4, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(5, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(6, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(7, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(8, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(9, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(10, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(11, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(12, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(13, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(14, 1, 0, 1, 2)); // [1, 0] [1, 2]
        // lendingMarketMappings.push(createMapping(15, 1, 0, 1, 2)); // [1, 0] [1, 2]

        // lendingMarketMappings.push(createMapping(16, 2, 0)); // [2] [0]

        // lendingMarketMappings.push(createMapping(2, 2, 1)); // [3] [1]
        // lendingMarketMappings.push(createMapping(18, 3, 2)); // [3] [2]
        // lendingMarketMappings.push(createMapping(3, 2, 1)); // [3] [1]
        lendingMarketMappings.push(createMapping(4, 2, 1)); // [3] [1]
        // lendingMarketMappings.push(createMapping(21, 3, 2)); // [3] [2]
        // lendingMarketMappings.push(createMapping(22, 3, 2)); // [3] [2]
        // lendingMarketMappings.push(createMapping(23, 3, 2)); // [3] [2]

        // lendingMarketMappings.push(createMapping(24, 4, 0)); // [4] [0]
        // lendingMarketMappings.push(createMapping(25, 4, 0)); // [4] [0]
        // lendingMarketMappings.push(createMapping(26, 4, 0)); // [4] [0]
        // lendingMarketMappings.push(createMapping(27, 4, 0)); // [4] [0]

        for (uint256 i = 0; i < lendingMarketMappings.length; i++) {
            ILendingMarket(lendingMarket).addMarketPool(
                lendingMarketMappings[i].convexBoosterPid,
                lendingMarketMappings[i].supplyBoosterPids,
                lendingMarketMappings[i].curveCoinIds,
                100,
                50
            );
        }
    }

    function run() public {
        require(deployer == msg.sender, "GenerateLendingPools: !authorized auth");
        require(!completed, "GenerateLendingPools: !completed");

        require(supplyBooster != address(0),"!supplyBooster");
        require(convexBooster != address(0),"!convexBooster");
        require(lendingMarket != address(0),"!lendingMarket");
        require(supplyRewardFactory != address(0),"!supplyRewardFactory");

        // generateSupplyPools();
        generateConvexPools();
        generateMappingPools();

        completed = true;
    }
}
