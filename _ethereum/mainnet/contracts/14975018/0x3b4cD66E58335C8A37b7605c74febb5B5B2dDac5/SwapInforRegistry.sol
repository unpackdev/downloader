// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./Ownable.sol";

/**
    Kovan instances:
    - Aave V2 LendingPoolAddressesProvider:     0x88757f2f99175387aB4C6a4b3067c77A695b0349
    - Uniswap V3 Router:                        0xE592427A0AEce92De3Edee1F18E0157C05861564
    - Sushiswap V2 Router:                      0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    - DAI:                                      0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
    - ETH:                                      0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    
    
    Mainnet instances:
    - Aave V2 LendingPoolAddressesProvider:     0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
    - Uniswap V3 Router:                        0xE592427A0AEce92De3Edee1F18E0157C05861564
    - Sushiswap V2 Router:                      0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
    - DAI:                                      0x6B175474E89094C44Da98b954EedeAC495271d0F
    - ETH:                                      0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
   
    Kovan Token addresses:
   
        WETH:   ["0xd0A1E359811322d97991E03f863a0C30C2cF029C"]
        // AAVE:   0xB597cd8D3217ea6477232F9217fa70837ff667Af
        // LINK:   0xAD5ce863aE3E4E9394Ab43d4ba0D80f419F61789
        DAI:    ["0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa"]
        // BAT:    0x2d12186Fbb9f9a8C28B3FfdD4c42920f8539D738
        // UNI:    0x075A36BA8846C6B6F53644fDd3bf17E5151789DC
        // YFI:    0xb7c325266ec274fEb1354021D27FA3E3379D840d
        // SNX:    0x7FDb81B0b8a010dd4FFc57C3fecbf145BA8Bd947
    Ropsten Token address:
        WETH:   0xc778417E063141139Fce010982780140Aa0cD5Ab
        // LINF:   0x60aee66253dd486cf24eeca0f9b0cf03ce18559a
        DAI:    0x6A9865aDE2B6207dAAC49f8bCba9705dEB0B0e6D
        // SNX:    0x23d254a9dca012d4dfd54ab020ac0c4c6be6473c
        // BAT:    0x5e06d959339f24fa05f5fc1d0c0c2c1d6ba2a4d5
    1Eth = 1000000000000000000 wei
*/
contract SwapInforRegistry is Ownable {
    struct SwapRouterInfo {
        address router;
        address factory;
        uint24 poolFee;    //  3000
        uint64 deadline;    //  300 ~ 600
    }
  
    // swap router id constants
    uint16 public constant UNISWAP_V3_ROUTER_ID = 1;
    uint16 public constant UNISWAP_V2_ROUTER_ID = 2;
    uint16 public constant SUSHISWAP_ROUTER_ID = 3;
    uint16 public constant SIBASWAP_ROUTER_ID = 4;
    uint16 public constant ONEINCHISWAP_ROUTER_ID = 5;
    uint16 public constant APESWAP_ROUTER_ID = 6;
    uint16 public constant KYBER_ROUTER_ID = 7;
    uint16 public constant PANCAKE_ROUTER_ID = 8;

    mapping(uint16 => SwapRouterInfo) public swapRouterInfos;
    event RouterInfoSeted(
        uint16 _index,
        address indexed _router,
        address indexed _factory,
        uint24 _poolFee
    );
    function setSwapRouterInfo(
        uint16 routerID,
        SwapRouterInfo memory routerInfo
    ) external onlyOwner() {
        swapRouterInfos[routerID] = routerInfo;
        emit RouterInfoSeted(
            routerID,
            routerInfo.router,
            routerInfo.factory,
            routerInfo.poolFee
        );
    }
}