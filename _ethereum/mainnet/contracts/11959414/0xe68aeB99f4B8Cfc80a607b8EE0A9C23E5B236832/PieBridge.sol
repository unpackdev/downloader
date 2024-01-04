// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract PieBridge {
    using SafeERC20 for IERC20;

    address public admin;
    address public pendingAdmin;
    address public courier;
    address public bridgeToken;

    uint[] public routes;

    // chainId => nonce
    mapping (uint => uint) crossNonce;
    // chainId => (nonce => deliver)
    mapping (uint => mapping (uint => bool)) public deliverNonces;

    uint public fee;

    event Cross(address from, address to, uint amount, uint chainId, uint nonce);
    event Deliver(uint fromChainId, address to, uint amount, uint nonce);
    event NewFee(uint newFee);

    constructor(address _courier, address _bridgeToken, uint _fee) {
        admin = msg.sender;

        require(_courier != address(0), "PieBridge: courier address is 0");
        courier = _courier;

        require(_bridgeToken != address(0), "PieBridge: bridgeToken address is 0");
        bridgeToken = _bridgeToken;

        fee = _fee;
    }

    function cross(uint chainId, address to, uint amount) public returns (bool) {
        require(amount > fee, "PieBridge: amount must be more than fee");
        require(to != address(0), "PieBridge: to address is 0");
        require(checkRoute(chainId), "PieBridge: chainId is not support");

        doTransferIn(msg.sender, bridgeToken, amount);
        doTransferOut(bridgeToken, courier, fee);

        crossNonce[chainId]++;

        emit Cross(msg.sender, to, amount - fee, chainId, crossNonce[chainId]);

        return true;
    }

    function deliver(uint fromChainId, address to, uint amount, uint nonce) public returns (bool) {
        require(msg.sender == courier, 'PieBridge: Only courier can send tokens');
        require(amount > 0, "PieBridge: must be positive");
        require(to != address(0), "PieBridge: to address is 0");
        require(!deliverNonces[fromChainId][nonce], "PieBridge: bad nonce");

        doTransferOut(bridgeToken, to, amount);

        deliverNonces[fromChainId][nonce] = true;

        emit Deliver(fromChainId, to, amount, nonce);

        return true;
    }

    function _setPendingAdmin(address newPendingAdmin) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'PieBridge: Only admin can set pending admin');

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        return true;
    }

    function _acceptAdmin() public returns (bool) {
        // Check caller is pendingAdmin
        require(msg.sender == pendingAdmin, 'PieBridge: Only pendingAdmin can accept admin');

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        return true;
    }

    function _setCourier(address newCourier) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'PieBridge: Only admin can set pending courier');

        // Store courier with value pendingCourier
        courier = newCourier;

        return true;
    }

    function _setFee(uint newFee) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'PieBridge: Only admin can set fee');

        // Store fee with value newFee
        fee = newFee;

        emit NewFee(newFee);

        return true;
    }

    function getRoutes() public view returns (uint[] memory) {
        return routes;
    }

    function setRoutes(uint[] memory newRoutes) public {
        // Check caller = admin
        require(msg.sender == admin, 'PieBridge: Only admin can set routes');

        routes = newRoutes;
    }

    function checkRoute(uint toChainId) public view returns (bool) {
        for(uint i = 0; i < routes.length; i++) {
            if (routes[i] == toChainId) {
                return true;
            }
        }

        return false;
    }

    function doTransferOut(address token, address to, uint amount) internal {
        IERC20 ERC20Interface = IERC20(token);
        ERC20Interface.safeTransfer(to, amount);
    }

    function doTransferIn(address from, address token, uint amount) internal {
        IERC20 ERC20Interface = IERC20(token);
        ERC20Interface.safeTransferFrom(from, address(this), amount);
    }
}
