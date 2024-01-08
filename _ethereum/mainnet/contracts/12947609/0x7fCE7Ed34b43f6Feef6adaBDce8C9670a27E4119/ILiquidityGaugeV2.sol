// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.3;

import "./IERC20.sol";

// Not a complete interface, but should have what we need
interface ILiquidityGaugeV2 is IERC20 {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function withdraw(uint256 _value) external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address, address) external returns (uint256);

    function integrate_fraction(address addr) external view returns (uint256);

    function user_checkpoint(address addr) external returns (bool);

    function reward_integral(address) external view returns (uint256);

    function reward_integral_for(address, address) external view returns (uint256);
}
/* solhint-enable */
