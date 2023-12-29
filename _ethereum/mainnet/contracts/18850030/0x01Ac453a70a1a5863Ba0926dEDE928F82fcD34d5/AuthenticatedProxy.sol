// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./IAuthenticatedProxy.sol";
import "./IAuthorizationManager.sol";
import "./IWETH.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Address.sol";

contract AuthenticatedProxy is IAuthenticatedProxy, Initializable {
    using SafeERC20 for IERC20;
    address public owner;
    IAuthorizationManager public authorizationManager;
    address public WETH;
    bool public revoked;

    event Revoked(bool revoked);

    modifier onlyOwnerOrAuthed() {
        require(
            msg.sender == owner ||
                (!revoked && !authorizationManager.revoked() && msg.sender == authorizationManager.authorizedAddress()),
            "Proxy: permission denied"
        );
        _;
    }

    modifier onlyAuthed() {
        require(
            !revoked && !authorizationManager.revoked() && msg.sender == authorizationManager.authorizedAddress(),
            "Proxy: permission denied"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Proxy: permission denied");
        _;
    }

    function initialize(
        address _owner,
        address _authorizationManager,
        address _WETH
    ) external initializer {
        owner = _owner;
        authorizationManager = IAuthorizationManager(_authorizationManager);
        WETH = _WETH;
    }

    // only owner
    function setRevoke(bool revoke) external override onlyOwner {
        revoked = revoke;
        emit Revoked(revoke);
    }

    // only authed
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external override onlyAuthed {
        IERC20(token).safeTransferFrom(owner, to, amount);
    }

    function delegatecall(address dest, bytes memory data)
        external
        override
        onlyAuthed
        returns (bool success, bytes memory returndata)
    {
        (success, returndata) = dest.delegatecall(data);
    }

    // only owner or authed
    function withdrawETH() external override onlyOwnerOrAuthed {
        uint256 amount = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amount);
        Address.sendValue(payable(owner), amount);
    }

    function withdrawToken(address token) external override onlyOwnerOrAuthed {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner, amount);
    }

    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }
}
