// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Initializable.sol";

import "./ICRVDepositor.sol";
import "./IClaimRewards.sol";
import "./ICRVFactory.sol";
import "./ICRVGauge.sol";
import "./IDelegation.sol";
import "./IPool.sol";
import "./IRegistry.sol";
import "./IERC20.sol";
import "./sdCRV3.sol";
import "./ReentrancyGuard.sol";
import "./Errors.sol";


contract Swap is Initializable, ReentrancyGuardUpgradeable {
address public registry;
     function initialize(
address _registry
    ) external initializer {
        registry = _registry;
    }


    function grandSwap(
        address[9] memory _route,
        uint256[3][4] calldata i,
        uint256 _amountA,
        address[4] memory pools
    ) public {
        IERC20 Token = IERC20(_route[0]);
        Token.approve(registry, _amountA);
        Iregistry(registry).exchange_multiple(_route, i, _amountA, 0, pools);
    }

function _swap(address[9] memory _route1,
        uint256[3][4] calldata i1,
        uint256 amount1,
        address[4] memory pools,
        address[9] memory _route2,
        uint256[3][4] calldata i2,
        uint256 amount2,
        address[9] memory _route3,
        uint256[3][4] calldata i3,
        uint256 amount3) public {
                        grandSwap(_route1, i1, amount1, pools);
                                    grandSwap(_route2, i2, amount2, pools);
                                                grandSwap(_route3, i3, amount3, pools);
            

        }
}