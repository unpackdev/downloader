// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC721Upgradeable.sol";

interface ITNFT is IERC721Upgradeable {

    function burnFromWithdrawal(uint256 _validatorId) external;
    function initialize() external;
    function initializeOnUpgrade(address _etherFiNodesManagerAddress) external;
    function mint(address _receiver, uint256 _validatorId) external;
    function burnFromCancelBNftFlow(uint256 _validatorId) external;
    function upgradeTo(address _newImplementation) external;
}
