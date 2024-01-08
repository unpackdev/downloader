pragma solidity ^0.8.0;

interface IxAsset {
    function withdrawFees() external;

    function transferOwnership(address newOwner) external;
}

interface IxINCH is IxAsset {
    function withdrawableOneInchFees() external view returns (uint256);
}

interface IxAAVE is IxAsset {
    function withdrawableAaveFees() external view returns (uint256);
}
