//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";
import "./SafeERC20.sol";
import "./ERC20Upgradeable.sol";

contract ConstantVariables is ERC20Upgradeable {
    using SafeERC20 for IERC20;

    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IInstaIndex internal constant instaIndex =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    IAaveProtocolDataProvider internal constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    IERC20 internal constant awethVariableDebtToken = IERC20(0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf);
    IERC20 internal constant astethToken = IERC20(0x1982b2F5814301d4e9a8b0201555376e62F82428);
    TokenInterface internal constant wethCoreContract = TokenInterface(wethAddr); // contains deposit & withdraw for weth
    IERC20 internal constant wethContract = IERC20(wethAddr);
    IERC20 internal constant stEthContract = IERC20(stEthAddr);
    uint internal constant liquidationThreshold = 7500;
}

contract Variables is ConstantVariables {

    uint internal _status = 1;

    address public auth;

    // only authorized addresses can rebalance
    mapping (address => bool) public isRebalancer;

    IDSA public vaultDsa;

    // TODO: make sure all the values will <= 1e14
    // Initially could be: [7400, 7000, 6900, 300 * 1e23] = [74%, 70%, 69%, 3%]
    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    Ratios public ratios;

    // last revenue exchange price (helps in calculating revenue)
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 public lastRevenueExchangePrice;

    uint256 public revenueFee; // 1000 = 10% (10% of user's profit)

    uint256 public revenue;

    uint256 public withdrawalFee; // 10000 = 100%

}

