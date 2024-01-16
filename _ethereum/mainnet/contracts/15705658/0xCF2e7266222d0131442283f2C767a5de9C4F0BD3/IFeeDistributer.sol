pragma solidity ^0.8.17;
import "./IAsset.sol";

interface IFeeDistributer {
    function ownerAsset() external returns (IAsset);

    function outputAsset() external returns (IAsset);
}
