pragma solidity =0.8.0;

interface ITransfers {
    function swap(
        address _fromToken,
        address _destToken,
        uint256 _amount
    ) external returns (uint256 returnAmount);

    function uniSwap(address[] calldata path, uint256 _amount) external returns (uint256 returnAmount);

    function getExpectedAmount(
        address _fromToken,
        address _destToken,
        uint256 _amount
    ) external view returns (uint256);
}
