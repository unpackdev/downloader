// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

// Persistence alone is omnipotent!

// https://protoverse.ai/ 

// ProtoVerse offers secure, no-code Web3 mass-adoption tools.
// Non-custodial; your private keys, your smart contracts!

//  __   __   __  ___  __        ___  __   __   ___      __        __
// |__) |__) /  \  |  /  \ \  / |__  |__) /__` |__      |__) \  / |__)
// |    |  \ \__/  |  \__/  \/  |___ |  \ .__/ |___     |     \/  |  \

// The secure code is audited by the renowned Binance Labs incubated company, Salus Security https://salusec.io/!

// The PVR token is born on-chain without any owner!
// ProtoVerse can not call any functions!
// The supply alloactions are locked and vested before launch!
// Multisig vault with 3 our of 6!
// 0% buy tax. 0% sell tax!
// No proxy!


/*...,ooooooooo......
                      .o8888888888888888888888888o.
                  .o888888888888888888888888888888888o.
                o8888888888A88"V888888888888888888888888o
              o88888887"8"  "   V888  88888888888888888888o
            o88888888            V     888888888888888888888o
           o888888888                   888888888888888888888o
          .88888888888                  88888V"  "V88888888888.
          o88888888888v                 8888"  v8  88888888888o
          88888888888v                  8888v  v88 888888888888
          888888888888                  88888v  "88888888888888
           88888888888V                  V88888v  "88888888888
           88888888888v                            "8888888888
____________8888888888888v.........................v888888888_____________
:::::::::::::::::::::::::'                         :::::::::::::::::::::::
:::::::::::::::::::::::                .:::::::    .::::::::::::::::::::::
::::::::::::::::::::::                 :::::::  .:::::::::::::::::::::::::
:::::::::::::::::::::                  ::::::  ::: :::::::::::::::::::::::
:::::::::::::::::::::.                 ::::::. :: .:::::::::::::::::::::::
::::::::::::::::::::::                 :::::::.  .::::::::::::::::::::::::
:::::::::::::::::::::.           .     :::::::::::::::::::::::::::::::::::
:::::::::::::::::::::          :::.   ::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::.::.:: :::::::.:::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

 */


import "./ERC20.sol";
import "./ERC20Permit.sol";


contract ProtoVerse is ERC20, ERC20Permit {
    uint256 private constant INITIAL_SUPPLY = 1_500_000_000 * (10 ** 18);

    constructor(address _multisig_max_supply)
        ERC20("ProtoVerse", "PVR")
        ERC20Permit("ProtoVerse")
    {
        _mint(_multisig_max_supply, INITIAL_SUPPLY);
    }
}