// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "Ownable.sol";
import {IResolverV2} from "IResolverV2.sol";
import {IVaultMK2} from "IVaultMK2.sol";
import {IStrategyAPI} from "IStrategyAPI.sol";
import {IVaultAPI} from "IVaultAPI.sol";
import {GGelatoResolver} from "GGelatoResolver.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs

contract GGuardedExecutor is Ownable {
    /*///////////////////////////////////////////////////////////////
                    Storage Variables/Types/Modifier(s)
    //////////////////////////////////////////////////////////////*/
    // @notice address for resolver
    GGelatoResolver public resolver;
    /// @notice keeper address
    address public keeper;

    modifier onlyKeeper() {
        require(msg.sender == keeper, "!Keeper");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/

    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
    }

    function setResolver(GGelatoResolver _resolver) external onlyOwner {
        resolver = _resolver;
    }

    /*///////////////////////////////////////////////////////////////
                        Core Logic
    //////////////////////////////////////////////////////////////*/

    function executeHarvest(address _vault, uint256 _index)
        external
        onlyKeeper
    {
        (bool canExecute, ) = resolver.harvestChecker(_vault, _index);
        require(canExecute, "!Execute");

        IVaultMK2(_vault).strategyHarvest(_index);
    }

    function executeInvest(address _vault) external onlyKeeper {
        (bool canExecute, ) = resolver.investChecker(_vault);
        require(canExecute, "!Execute");
        IVaultMK2(_vault).invest();
    }
}
