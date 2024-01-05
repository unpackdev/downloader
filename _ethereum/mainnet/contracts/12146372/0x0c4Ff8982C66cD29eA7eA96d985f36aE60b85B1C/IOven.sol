// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface IOven {
    function bake(
        address[] calldata _receivers,
        uint256 _outputAmount,
        uint256 _maxPrice
    ) external;

    function deposit() external payable;

    function withdrawAll(address payable _receiver) external;

    function withdrawAllETH(address payable _receiver) external;

    function withdrawETH(uint256 _amount, address payable _receiver) external;

    function withdrawOutput(address _receiver) external;

    function setCap(uint256 _cap) external;

    function setController(address _controller) external;

    function setPie(address _pie) external;

    function getCap() external view returns (uint256);

    function saveToken(address _token) external;
}
