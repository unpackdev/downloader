// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;
interface IKeep3r {
    event Keep3rSet(address _keep3r);
    event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA);
    
    function setKeep3r(address _keep3r) external;
    function setKeep3rRequirements(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA) external;
}
