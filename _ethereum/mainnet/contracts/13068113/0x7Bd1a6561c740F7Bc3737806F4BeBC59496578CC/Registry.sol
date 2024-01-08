// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./errors.sol";
import "./ImplBase.sol";

abstract contract Registry is Ownable {
    using SafeERC20 for IERC20;
    struct RouteData {
        address route;
        bool enabled;
    }
    RouteData[] public routes;
    modifier onlyExistingRoute(uint256 _routeId) {
        require(
            routes[_routeId].route != address(0),
            MovrErrors.ROUTE_NOT_FOUND
        );
        _;
    }

    /// @notice public / external functions allowed to owner
    function addRoutes(RouteData[] calldata _routes)
        external
        onlyOwner
        returns (uint256[] memory)
    {
        require(_routes.length != 0, MovrErrors.EMPTY_INPUT);
        uint256[] memory _routeIds = new uint256[](_routes.length);
        for (uint256 i = 0; i < _routes.length; i++) {
            require(
                _routes[i].route != address(0),
                MovrErrors.ADDRESS_0_PROVIDED
            );
            routes.push(_routes[i]);
            _routeIds[i] = routes.length - 1;
        }

        return _routeIds;
    }

    function updateRoute(uint256 _routeId, RouteData calldata _routeData)
        external
        onlyOwner
        onlyExistingRoute(_routeId)
    {
        require(_routeData.route != address(0), MovrErrors.ADDRESS_0_PROVIDED);
        routes[_routeId] = _routeData;
    }

    struct TransferData {
        uint256 amount;
        address to;
        address token;
        uint256 toChainId;
        uint256 routeId;
        bytes extraData;
    }

    function outboundTransferTo(TransferData calldata _data) external {
        require(_data.amount != 0, "amount cannot be 0");
        RouteData memory _routeData = routes[_data.routeId];
        require(
            _routeData.route != address(0) && _routeData.enabled,
            "route not allowed"
        );
        ImplBase(_routeData.route).outboundTransferTo(
            _data.amount,
            msg.sender,
            _data.to,
            _data.token,
            _data.toChainId,
            _data.extraData
        );
    }

    function calculateSwap(
        uint256 _amount,
        address _token,
        bytes calldata _data
    ) external view returns (uint256) {
        (uint256 _routeId, bytes memory _extraData) =
            abi.decode(_data, (uint256, bytes));

        RouteData memory _routeData = routes[_routeId];
        onlyEnabledRoute(_routeData);

        return
            ImplBase(_routeData.route).calculateOutput(
                _amount,
                _token,
                _extraData
            );
    }

    function getRouteId(address _route) public view returns (uint256) {
        for (uint256 i = 0; i < routes.length; i++) {
            if (routes[i].route == _route) return i;
        }
        revert(MovrErrors.ROUTE_NOT_FOUND);
    }

    // @notice pure functions below
    function onlyEnabledRoute(RouteData memory _routeData) internal pure {
        require(_routeData.route != address(0), MovrErrors.ROUTE_NOT_FOUND);
        require(_routeData.enabled, MovrErrors.ROUTE_NOT_ALLOWED);
    }
}

contract MovrRegistry is Registry {
    string public constant name = "MovrRegistry";
}
