// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMasterFundAdmin {
    function subscribe(address _from, address _token, uint256 _amount, address _client, address _destination) external;

    function redeem(address _from, address _token, uint256 _amount, address _client, address _destination) external;
}
