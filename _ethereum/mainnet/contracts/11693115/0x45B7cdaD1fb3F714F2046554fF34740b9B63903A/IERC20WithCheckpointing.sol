pragma solidity 0.6.8;

// From https://github.com/aragonone/voting-connectors
interface IERC20WithCheckpointing {
    function balanceOf(address _owner) external view returns (uint256);
    function balanceOfAt(address _owner, uint256 _blockNumber) external view returns (uint256);

    function totalSupply() external view returns (uint256);
    function totalSupplyAt(uint256 _blockNumber) external view returns (uint256);
}