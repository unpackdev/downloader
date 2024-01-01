//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ISolve3Master {
    function initialize(address _signer) external;

    // ============ Views ============

    function getNonce(address _account) external view returns (uint256);

    // ============ Owner Functions ============

    function setSigner(address _account, bool _flag) external;

    function transferOwnership(address _newOwner) external;

    function recoverERC20(address _token) external;

    // ============ EIP 712 Functions ============

    function verifyProof(bytes calldata _proof)
        external
        returns (
            address account,
            uint256 timestamp,
            bool verified
        );
}
