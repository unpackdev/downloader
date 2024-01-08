// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IRewardKeeper {

    function owner() external view returns (address);

    function isActionAddress(address actionAddress_) external view returns (bool);

    function sendReward(address erc20TokenAddress_, address recipient_, uint256 amount_) external returns (bool);
}
