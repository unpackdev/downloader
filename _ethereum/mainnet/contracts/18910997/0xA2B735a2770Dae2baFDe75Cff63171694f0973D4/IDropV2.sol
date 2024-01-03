pragma solidity >=0.6.6;
import "./IDropBase.sol";

interface IDropV2 is IDropBase {
    function initialize(
        uint256 _startBlock,
        uint256 _whiteListTimeOutBlock,
        uint256 _endBlock,
        uint256 _maxTotalDropUSDAmount,
        uint256 _maxDropUSDAmountEachUser,
        address _finAddr,
        address _ownerAddress
    ) external;

    function whiteList() external view returns (address[] memory addresses);
}
