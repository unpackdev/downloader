// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IWebacyProxy.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Pausable.sol";

contract WebacyProxy is IWebacyProxy, AccessControl, Pausable {
    using SafeERC20 for IERC20;
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    constructor(address _memberAddress, address _webacyAddress) {
        require(_memberAddress != address(0),  "Not valid address");
        require(_webacyAddress != address(0),  "Not valid address");
        _setupRole(DEFAULT_ADMIN_ROLE, _memberAddress);
        _setupRole(EXECUTOR_ROLE, _memberAddress);
        _setupRole(EXECUTOR_ROLE, _webacyAddress);
    }

    function transferErc20TokensAllowed(
        address _contractAddress,
        address _ownerAddress,
        address _recipentAddress,
        uint256 _amount
    ) external override whenNotPaused onlyRole(EXECUTOR_ROLE) {
        IERC20(_contractAddress).safeTransferFrom(_ownerAddress, _recipentAddress, _amount);
    }

    function transferErc721TokensAllowed(
        address _contractAddress,
        address _ownerAddress,
        address _recipentAddress,
        uint256 _tokenId
    ) external override whenNotPaused onlyRole(EXECUTOR_ROLE) {
        IERC721(_contractAddress).safeTransferFrom(_ownerAddress, _recipentAddress, _tokenId);
    }

    function pauseContract() external override whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpauseContract() external override whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
