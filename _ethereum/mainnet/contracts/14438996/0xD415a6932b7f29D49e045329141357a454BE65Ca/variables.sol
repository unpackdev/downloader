//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";
import "./ERC20Upgradeable.sol";

contract ConstantVariables is ERC20Upgradeable {
    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IInstaIndex internal constant instaIndex =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    IAaveProtocolDataProvider internal constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
}

contract Variables is ConstantVariables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    IDSA public vaultDsa;

    // last revenue exchange price (helps in calculating revenue)
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 public lastRevenueExchangePrice;

    uint256 public safeDistancePercentage; // 10000 = 100%, used in withdraw & rebalance with leverage

    uint256 public withdrawalTime; // in seconds.

    uint256 public revenueFee; // 1000 = 10% (10% of user's profit)

    uint256 public revenue;

    uint256 public totalWithdrawAwaiting;

    struct Withdraw {
        uint128 amount;
        uint128 time; // time at which amount will be available to withdraw
    }

    mapping (address => Withdraw[]) public userWithdrawAwaiting;

}

