// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract GStakingRoles is AccessControl {
    // keccak256("BIG_GUARDIAN_ROLE")
    bytes32 public constant BIG_GUARDIAN_ROLE = 0x05c653944982f4fec5b037dad255d4ecd85c5b85ea2ec7654def404ae5f686ec;
    // keccak256("GUARDIAN_ROLE")
    bytes32 public constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;
    // keccak256("PAUSER_ROLE")
    bytes32 public constant PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    // keccak256("CLAIM_ROLE")
    bytes32 public constant CLAIM_ROLE = 0xf7db13299c8a9e501861f04c20f69a2444829a36a363cfad4b58864709c75560;

    function grantPauser(address _pauser) external onlyRole(getRoleAdmin(PAUSER_ROLE)) {
        require(_pauser != address(0), "Pauser address is invalid!");
        grantRole(PAUSER_ROLE, _pauser);
    }

    function grantGuardian(address _guardian) external onlyRole(getRoleAdmin(GUARDIAN_ROLE)) {
        require(_guardian != address(0), "Guardian address is invalid!");
        grantRole(GUARDIAN_ROLE, _guardian);
    }

    function grantClaimer(address _claimer) external onlyRole(getRoleAdmin(CLAIM_ROLE)) {
        require(_claimer != address(0), "Claimer address is invalid!");
        grantRole(CLAIM_ROLE, _claimer);
    }

    function isGuardian(address _guardian) public view returns(bool) {
        return hasRole(GUARDIAN_ROLE, _guardian);
    }

    function isBigGuardian(address _guardian) public view returns(bool) {
        return hasRole(BIG_GUARDIAN_ROLE, _guardian);
    }

    function isPauser(address _pauser) public view returns(bool) {
        return hasRole(PAUSER_ROLE, _pauser);
    }

    function isClaimer(address _claimer) public view returns(bool) {
        return hasRole(CLAIM_ROLE, _claimer);
    }
}
