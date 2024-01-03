// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./IERC20.sol";

interface IDRF is IERC20 {

    function reserveSupply() external returns (uint256);

    function bonusSupply() external returns (uint256);

    function lockedSupply() external returns (uint256);

    function setFee(uint256 _reflectFeeDenominator, uint256 _buyTxFeeDenominator, uint256 _sellTxFeeDenominator, uint256 _buyBonusDenominator, uint256 _sellFeeDenominator) external;

    function setReserveSupply(uint256 amount) external;

    function depositPrincipalSupply(uint256 amount) external;

    function withdrawPrincipalSupply() external returns(uint256);

    function distributePrincipalRewards(address _pairAddress) external;

}
