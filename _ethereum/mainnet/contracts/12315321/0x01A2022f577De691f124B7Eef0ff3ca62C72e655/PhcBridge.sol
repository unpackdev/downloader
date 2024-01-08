// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./ProxyStorage.sol";
import "./BridgeStorage.sol";

contract PhcBridge is ProxyStorage, BridgeStorageV1 {
    using SafeERC20 for IERC20;

    event Cross(address from, address to, uint amount, uint chainId, uint nonce);
    event Deliver(uint fromChainId, address to, uint amount, uint nonce);
    event NewFee(uint newFee);
    event NewRoutes(uint[] newRoutes);
    event NewCourier(address newCourier);
    event NewGuardian(address newGuardian);

    constructor() {}

    function initialize(address _courier, address _guardian, address _bridgeToken, uint _fee, uint[] memory newRoutes) public {
        require(
            courier == address(0) &&
            guardian == address(0) &&
            bridgeToken == address(0) &&
            fee == 0 &&
            routes.length == 0
            , "PhcBridge may only be initialized once"
        );

        admin = msg.sender;

        require(_courier != address(0), "PhcBridge: courier address is 0");
        _setCourier(_courier);

        require(_guardian != address(0), "PhcBridge: guardian address is 0");
        _setGuardian(_guardian);

        require(_bridgeToken != address(0), "PhcBridge: bridgeToken address is 0");
        bridgeToken = _bridgeToken;

        _setFee(_fee);
        _setRoutes(newRoutes);

    }

    function cross(uint chainId, address to, uint amount) public returns (bool) {
        require(amount > fee, "PhcBridge: amount must be more than fee");
        require(to != address(0), "PhcBridge: to address is 0");
        require(checkRoute(chainId), "PhcBridge: chainId is not support");

        doTransferIn(msg.sender, bridgeToken, amount);
        doTransferOut(bridgeToken, courier, fee);

        crossNonce[chainId]++;

        emit Cross(msg.sender, to, amount - fee, chainId, crossNonce[chainId]);

        return true;
    }

    function deliver(uint fromChainId, address to, uint amount, uint nonce) public returns (bool) {
        require(msg.sender == courier, 'PhcBridge: Only courier can deliver tokens');
        require(amount > 0, "PhcBridge: amount must be positive");
        require(to != address(0), "PhcBridge: to address is 0");
        require(!deliverNonces[fromChainId][nonce], "PhcBridge: bad nonce");

        doTransferOut(bridgeToken, to, amount);

        deliverNonces[fromChainId][nonce] = true;

        emit Deliver(fromChainId, to, amount, nonce);

        return true;
    }

    function _setCourier(address newCourier) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'PhcBridge: Only admin can set courier');

        // Store courier with value newCourier
        courier = newCourier;

        emit NewCourier(courier);

        return true;
    }

    function _setGuardian(address newGuadrdian) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'PhcBridge: Only admin can set guardian');

        // Store guardian with value guardian
        guardian = newGuadrdian;

        emit NewGuardian(guardian);

        return true;
    }

    function unsetCourier() public returns (bool) {
        // Check caller = guardian
        require(msg.sender == guardian, 'PhcBridge: Only guardian can unset courier');

        // Store courier with value address(0)
        courier = address(0);

        emit NewCourier(courier);

        return true;
    }

    function _setFee(uint newFee) public returns (bool) {
        // Check caller = admin
        require(msg.sender == admin, 'PhcBridge: Only admin can set fee');

        // Store fee with value newFee
        fee = newFee;

        emit NewFee(newFee);

        return true;
    }

    function getRoutes() public view returns (uint[] memory) {
        return routes;
    }

    function _setRoutes(uint[] memory newRoutes) public {
        // Check caller = admin
        require(msg.sender == admin, 'PhcBridge: Only admin can set routes');

        routes = newRoutes;

        emit NewRoutes(routes);
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
