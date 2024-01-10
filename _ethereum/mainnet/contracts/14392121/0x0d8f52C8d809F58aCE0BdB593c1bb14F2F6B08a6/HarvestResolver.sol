// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.12;

import "Ownable.sol";
import { IResolver } from "IResolver.sol";
import { IVaultMK2 } from "IVaultMK2.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|
// Harvest Resolver
// To work with Gelato Ops to automate strategy harvests

// gro protocol: https://github.com/groLabs

// Primary Author(s)
// Farhaan Ali: https://github.com/farhaan-ali

// Reviewer(s) / Contributor(s)
// Kristian Domanski: https://github.com/kristian-gro

contract HarvestResolver is IResolver, Ownable {
    // address for DAI Vault
    address public immutable DAIVAULT;
    // mapping of (strategy index => gas cost) to harvest each strategy
    mapping(uint256 => uint256) public daiStrategyCosts;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _daiVault) {
        DAIVAULT = _daiVault;
    }

    /** set gas cost for dai strategy */
    function setDaiStrategyCost(uint256 index, uint256 gascost) external onlyOwner {
        daiStrategyCosts[index] = gascost;
    }

    /** check for gelato keeper */
    function checker()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload) {
            //check strategy length
            uint256 daiStrategyLength = IVaultMK2(DAIVAULT).getStrategiesLength();

            for (uint256 i = 0; i < daiStrategyLength; i++) {
                uint256 callCost = block.basefee * daiStrategyCosts[i];

                if (IVaultMK2(DAIVAULT).strategyHarvestTrigger(i, callCost)) {
                    canExec = true;
                    execPayload = abi.encodeWithSelector(
                        IVaultMK2.strategyHarvest.selector,
                        uint256(i)
                    );
                }

                if (canExec) break;
            }

        }
}
