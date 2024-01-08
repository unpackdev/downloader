pragma solidity >=0.6.0 <0.7.0;

interface IMerkleValidator {
    function level2UpgradeMerkelRoot() external view returns (bytes32);

    function level3UpgradeMerkelRoot() external view returns (bytes32);

    function level4UpgradeMerkelRoot() external view returns (bytes32);

    function level5UpgradeMerkelRoot() external view returns (bytes32);

    function verify(
        bytes32 merkleRoot,
        uint id,
        bytes32[] calldata merkleProof
    ) external view;
}