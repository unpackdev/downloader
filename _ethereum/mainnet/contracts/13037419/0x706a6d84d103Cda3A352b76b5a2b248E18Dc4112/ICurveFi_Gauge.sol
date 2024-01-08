// SPDX-License-Identifier: None
pragma solidity 0.6.12;

/**
 * @dev Interface for Curve.Fi CRV staking Gauge contract.
 * @dev See original implementation in official repository:
 * https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/LiquidityGauge.vy
 */
interface ICurveFi_Gauge {
    function lp_token() external view returns(address);
    function crv_token() external view returns(address);

    function balanceOf(address addr) external view returns (uint256);
    function deposit(uint256 _value) external;
    function withdraw(uint256 _value) external;

    function claimable_tokens(address addr) external returns (uint256);
    function minter() external view returns(address); //use minter().mint(gauge_addr) to claim CRV

    function integrate_fraction(address _for) external view returns(uint256);
    function user_checkpoint(address _for) external returns(bool);
}

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
    function user_checkpoint(address) external;
}

interface VotingEscrow {
    function create_lock(uint256 v, uint256 time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
}

interface Mintr {
    function mint(address) external;
}