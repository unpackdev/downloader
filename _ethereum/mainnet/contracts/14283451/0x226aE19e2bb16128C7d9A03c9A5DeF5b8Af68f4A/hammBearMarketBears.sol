//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//    ___ ___    _____      _____      _____    .___ _______   ____  __. _________            
//   /   |   \  /  _  \    /     \    /     \   |   |\      \ |    |/ _| \_   ___ \  ____     
//  /    ~    \/  /_\  \  /  \ /  \  /  \ /  \  |   |/   |   \|      <   /    \  \/ /  _ \    
//  \    Y    /    |    \/    Y    \/    Y    \ |   /    |    \    |  \  \     \___(  <_> )   
//   \___|_  /\____|__  /\____|__  /\____|__  / |___\____|__  /____|__ \  \______  /\____/ /\ 
//         \/         \/         \/         \/              \/        \/         \/        \/ 

import "./hammbones.sol";

contract hammBearMarketBears is hammbones {
    constructor(
        address targetAddress,
        address rewardAddress,
        uint256 baseRate,
        uint256 rewardFrequency,
        uint256 initialReward,
        uint256 stakeRate
    )
        hammbones(
            targetAddress,
            rewardAddress,
            baseRate,
            rewardFrequency,
            initialReward,
            stakeRate
        )
    {}
}