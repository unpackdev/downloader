// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IMintableBurnableERC20.sol";

interface IFeeManager {
    function protocolFee(address, uint) external view returns (uint);
    function redemptionFee(address, uint) external view returns (uint);
    function protocolRedemptionFeeShare() external view returns (uint);
    function protocolFeeTo() external view returns (address);
    function redemptionFeeTo() external view returns (address);

    function beforeRedeem(uint) external;
    function afterRedeem(uint) external;
}
