// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BaseBurner.sol";
import "./ReentrancyGuard.sol";

interface ICurvePool {
    function coins(uint256 index) external returns (address);

    function exchange(
        int128 _i,
        int128 _j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 fx
    ) external returns (uint256);
}

interface ICurvePoolFactory {
    function get_coin_indices(
        address pool,
        address from,
        address to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function get_n_coins(address pool) external view returns (uint256);

    function find_pool_for_coins(
        address _from,
        address _to,
        uint256 i
    ) external returns (address);
}

contract FXBurner is BaseBurner, ReentrancyGuard {
    mapping(address => address) public curvePools;
    address public curvePoolFactory =
        0xB9fC157394Af804a3578134A6585C0dc9cc990d4;

    constructor(address _receiver, address _curvePoolFactory)
        BaseBurner(_receiver)
    {
        curvePoolFactory = _curvePoolFactory;
    }

    /* Admin functions */
    function setCurvePoolFactory(address _curvePoolFactory) external onlyOwner {
        curvePoolFactory = _curvePoolFactory;
    }

    function addBurnableTokens(
        address[] calldata _burnableTokens,
        address[] calldata _targetTokens
    ) external override onlyOwner {
        require(
            _burnableTokens.length == _targetTokens.length,
            "array length mismatch"
        );
        for (uint256 i = 0; i < _burnableTokens.length; i++) {
            address burnableToken = _burnableTokens[i];
            address targetToken = _targetTokens[i];
            address curvePool = ICurvePoolFactory(curvePoolFactory)
                .find_pool_for_coins(burnableToken, targetToken, 0);
            require(
                curvePool != address(0),
                "no pool exists for the given token-targetToken pair"
            );
            burnableTokens[burnableToken] = targetToken;
            curvePools[burnableToken] = curvePool;
            emit addedBurnableToken(burnableToken, targetToken);
        }
    }

    /* User functions */
    function burn(address token)
        external
        onlyBurnableToken(token)
        nonReentrant
        returns (uint256)
    {
        require(receiver != address(0), "receiver not set");
        address targetToken = burnableTokens[token];
        uint256 msgSenderBalance = IERC20(token).balanceOf(msg.sender);
        if (msgSenderBalance != 0) {
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                msgSenderBalance
            );
        }
        uint256 amountToBurn = IERC20(token).balanceOf(address(this));
        if (amountToBurn != 0) {
            address curvePool = curvePools[token];
            IERC20(token).approve(curvePool, amountToBurn);
            (
                int128 inTokenIndex,
                int128 outTokenIndex,
                bool found
            ) = ICurvePoolFactory(curvePoolFactory).get_coin_indices(
                    curvePool,
                    token,
                    targetToken
                );
            ICurvePool(curvePool).exchange(
                inTokenIndex,
                outTokenIndex,
                amountToBurn,
                0,
                receiver
            );
        }
        uint256 targetTokenBalance = IERC20(targetToken).balanceOf(
            address(this)
        );
        if (targetTokenBalance != 0) {
            IERC20(targetToken).transfer(receiver, targetTokenBalance);
        }
        return targetTokenBalance;
    }
}
