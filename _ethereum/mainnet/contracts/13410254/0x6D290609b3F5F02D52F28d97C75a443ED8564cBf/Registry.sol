// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./errors.sol";
import "./ImplBase.sol";
import "./MiddlewareImplBase.sol";

/**
// @title Movr Regisrtry Contract.
// @notice This is the main contract that is called using fund movr.
// This contains all the bridge and middleware ids. 
// RouteIds signify which bridge to be used. 
// Middleware Id signifies which aggregator will be used for swapping if required. 
*/
contract Registry is Ownable {
    using SafeERC20 for IERC20;

    ///@notice route 0 has to have isMiddleWare true.
    struct RouteData {
        address route;
        bool enabled;
        bool isMiddleware;
    }

    RouteData[] public routes;

    modifier onlyExistingRoute(uint256 _routeId) {
        require(
            routes[_routeId].route != address(0),
            MovrErrors.ROUTE_NOT_FOUND
        );
        _;
    }

    //
    // Events
    //
    event NewRouteAdded(uint256, address, bool, bool);
    event RouteUpdated(uint256, address, bool, bool);
    event ExecutionCompleted(uint256, uint256);

    /**
    // @param to Recipient address to recieve funds on destination chain
    // @param toChainId Destination ChainId
    // @param amount amount to be swapped if middlewareId is 0  it will be
    // the amount to be bridged
    // @param tokenToBridge token addresss which will be bridged 
    // @param middlewareInputToken token address which will be swapped to
    // tokenToBridge Address
    // @param bridgeID route id of bridge to be used
    // @param middlewareID route id of middleware to be used
    // @param bridgeData bridgeData to be used by bridge
    // @param middlewareData to be used by middleware
    */
    struct InputData {
        // user request data
        address to;
        uint256 toChainId;
        uint256 amount;
        // token addresses
        address tokenToBridge;
        address middlewareInputToken;
        // route details
        uint256 bridgeID;
        uint256 middlewareID;
        // auxillary data
        bytes bridgeData;
        bytes middlewareData;
    }

    /**
    // @notice function responsible for calling the respective implementation 
    // depending on the bridge to be used
    // If the middlewareId is 0 then no swap is required,
    // we can directly bridge the source token to wherever required,
    // else, we first call the Swap Impl Base for swapping to the required 
    // token and then start the bridging
    // @dev It is required for isMiddleWare to be true for route 0 as it is a special case
    // @param _input calldata follows the input data struct
    */
    function outboundTransferTo(InputData calldata _input) external payable {
        require(_input.amount != 0, MovrErrors.INVALID_AMT);
        require(_input.bridgeID != 0, MovrErrors.INVALID_BRIDGE_ID);

        // read middleware info and validate
        RouteData memory middlewareInfo = routes[_input.middlewareID];
        require(
            middlewareInfo.route != address(0) &&
                middlewareInfo.enabled &&
                middlewareInfo.isMiddleware,
            MovrErrors.ROUTE_NOT_ALLOWED
        );

        // read bridge info and validate
        RouteData memory bridgeInfo = routes[_input.bridgeID];
        require(
            bridgeInfo.route != address(0) &&
                bridgeInfo.enabled &&
                !bridgeInfo.isMiddleware,
            MovrErrors.ROUTE_NOT_ALLOWED
        );

        // if middlewareID is 0 it means we dont want to perform a action before bridging
        // and directly want to move for bridging
        if (_input.middlewareID == 0) {
            // perform the bridging
            ImplBase(bridgeInfo.route).outboundTransferTo(
                _input.amount,
                msg.sender,
                _input.to,
                _input.tokenToBridge,
                _input.toChainId,
                _input.bridgeData
            );
        } else {
            // we perform an action using a middleware
            uint256 _amountOut =
                MiddlewareImplBase(middlewareInfo.route).performAction{
                    value: msg.value
                }(
                    msg.sender,
                    _input.middlewareInputToken,
                    _input.amount,
                    address(this),
                    _input.middlewareData
                );

            // we give allowance to the bridge
            IERC20(_input.tokenToBridge).safeIncreaseAllowance(
                bridgeInfo.route,
                _amountOut
            );

            // perform the bridging
            ImplBase(bridgeInfo.route).outboundTransferTo(
                _amountOut,
                address(this),
                _input.to,
                _input.tokenToBridge,
                _input.toChainId,
                _input.bridgeData
            );
        }

        emit ExecutionCompleted(_input.middlewareID, _input.bridgeID);
    }

    //
    // Route management functions
    //

    /// @notice add routes to the registry.
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
            emit NewRouteAdded(
                i,
                _routes[i].route,
                _routes[i].enabled,
                _routes[i].isMiddleware
            );
        }

        return _routeIds;
    }

    ///@notice Updates the route data if required.
    function updateRoute(uint256 _routeId, RouteData calldata _routeData)
        external
        onlyOwner
        onlyExistingRoute(_routeId)
    {
        routes[_routeId] = _routeData;
        emit RouteUpdated(
            _routeId,
            _routeData.route,
            _routeData.enabled,
            _routeData.isMiddleware
        );
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }
}
