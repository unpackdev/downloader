//PDX-License-Identifier: <SPDX-License>
pragma solidity ^0.6.2;

interface IExchange {
    function calculatePrice(address _token, uint256 _amount) external returns (uint256);

    function buy(
        address _token,
        uint256 _amount,
        address _addressToSendTokens
    ) external payable;

    function sell(
        address _token,
        uint256 _amount,
        address payable _addressToSendEther
    ) external returns (uint256);
}
