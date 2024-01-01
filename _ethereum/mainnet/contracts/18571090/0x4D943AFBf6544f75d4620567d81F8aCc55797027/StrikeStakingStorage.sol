pragma solidity ^0.5.16;

contract StrikeStakingProxyAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of StrikeStakingProxy
    */
    address public strikeStakingImplementation;

    /**
    * @notice Pending brains of StrikeStakingProxy
    */
    address public pendingStrikeStakingImplementation;
}

contract StrikeStakingG1Storage is StrikeStakingProxyAdminStorage {
}
