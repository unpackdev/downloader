//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface I1inchSupport {
    function modifyOneinchAmount(bytes memory _data, uint256 _amount) external pure returns (bytes memory);

    function inchSwapNoHandle(
        address _from,
        uint256 _amount,
        bytes memory _inData
    ) external payable returns (uint256);

    function inchSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minReturn,
        bytes memory _inData
    ) external payable returns (uint256 _returns);
}
