// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./StrategyFeiFarmBase.sol";

contract StrategyFeiTribeLp is StrategyFeiFarmBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token addresses
    address public constant fei_rewards = 0x18305DaAe09Ea2F4D51fAa33318be5978D251aBd;
    address public constant uni_fei_tribe_lp =
        0x9928e4046d7c6513326cCeA028cD3e7a91c7590A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyFeiFarmBase(
            fei_rewards,
            uni_fei_tribe_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFeiTribeLp";
    }
}
