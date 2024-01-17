// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

/// @title Handle authorizations in dex platform
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract TokenApprove is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public tokenApproveProxy;

    function initialize(address _tokenApproveProxy) public initializer {
        __Ownable_init();
        tokenApproveProxy = _tokenApproveProxy;
    }

    //-------------------------------
    //------- Events ----------------
    //-------------------------------

    event ProxyUpdate(address indexed oldProxy, address indexed newProxy);

    //-------------------------------
    //------- Modifier --------------
    //-------------------------------

    //--------------------------------
    //------- Internal Functions -----
    //--------------------------------

    //---------------------------------
    //------- Admin functions ---------
    //---------------------------------

    function setApproveProxy(address _newTokenApproveProxy) external onlyOwner {
        emit ProxyUpdate(tokenApproveProxy, _newTokenApproveProxy);
        tokenApproveProxy = _newTokenApproveProxy;
    }

    //---------------------------------
    //-------  Users Functions --------
    //---------------------------------

    function claimTokens(
        address _token,
        address _who,
        address _dest,
        uint256 _amount
    ) external {
        require(msg.sender == tokenApproveProxy, "TokenApprove: Access restricted");
        if (_amount > 0) {
            IERC20(_token).safeTransferFrom(_who, _dest, _amount);
        }
    }
}
