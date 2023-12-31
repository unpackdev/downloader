pragma solidity ^0.6.10;

interface IGMXRouter {
    function approvePlugin(address _plugin) external ;

    function approvedPlugins(address arg1, address arg2) external view returns (bool);

    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function swapETHToTokens(address[] memory _path, uint256 _minOut, address _receiver) external payable;

}
