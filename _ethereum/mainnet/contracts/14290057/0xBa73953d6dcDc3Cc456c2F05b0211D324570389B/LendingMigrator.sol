// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
// Euler
import "./IEulerMarkets.sol";
import "./IEToken.sol";
// Aave
import "./ILendingPool.sol";
import "./IAToken.sol";
// Compound
import "./ICToken.sol";
// libs
import "./BoringBatchable.sol";


contract LendingMigrator is BoringBatchable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // Euler
    address public immutable EULER;
    IEulerMarkets public immutable EULER_MARKETS;

    // Aave v2
    ILendingPool public immutable AAVE_V2_LENDING_POOL;
    uint16 public immutable AAVE_V2_REFERRAL;

    // Compound 
    // TODO setters for these functions
    mapping(address => address) public cTokenToUnderlying;
    mapping(address => address) public underlyingToCToken;

    constructor(
        address _euler,
        address _eulerMarkets,
        address _aaveV2LendingPool,
        uint16 _aaveV2Referral
    ) {
        EULER = _euler;
        EULER_MARKETS = IEulerMarkets(_eulerMarkets);
        AAVE_V2_LENDING_POOL = ILendingPool(_aaveV2LendingPool);
        AAVE_V2_REFERRAL = _aaveV2Referral;
    }


    // Euler
    function depositEuler(address _token, address _receiver) external {
        IERC20 token = IERC20(_token);
        IEToken eToken = IEToken(EULER_MARKETS.underlyingToEToken(_token));

        // TODO consider using type(uint256).max
        uint256 amount = token.balanceOf(address(this));
        token.approve(EULER, amount);
        eToken.deposit(0, amount);

        if(_receiver != address(0)) {
            eToken.transfer(_receiver, eToken.balanceOf(address(this)));
        }
    }

    function withdrawEuler(address _eToken, address _receiver) external {
        IERC20 token = IERC20(EULER_MARKETS.eTokenToUnderlying(_eToken));
        IEToken eToken = IEToken(_eToken);

        eToken.withdraw(0, type(uint256).max);

        if(_receiver != address(0)) {
            token.transfer(_receiver, token.balanceOf(address(this)));
        }
    }


    // Aave
    function depositAaveV2(address _token, address _receiver) external {
        IERC20 token = IERC20(_token);

        uint256 amount = token.balanceOf(address(this));
        token.approve(address(AAVE_V2_LENDING_POOL), amount);

        if(_receiver == address(0)) {
            _receiver = address(this);
        }

        AAVE_V2_LENDING_POOL.deposit(_token, amount, _receiver, AAVE_V2_REFERRAL);
    }

    function withdrawAaveV2(address _aToken, address _receiver) external {
        IAToken aToken = IAToken(_aToken);
        IERC20 token = IERC20(aToken.UNDERLYING_ASSET_ADDRESS());

        if(_receiver == address(0)) {
            _receiver = address(this);
        }

        AAVE_V2_LENDING_POOL.withdraw(address(token), type(uint256).max, _receiver);
    }


    // Compound
    function depositCompound(address _token, address _receiver) external {
        IERC20 token = IERC20(_token);
        ICToken cToken = ICToken(underlyingToCToken[_token]);

        uint256 amount = token.balanceOf(address(this));
        token.approve(address(cToken), amount);

        // Replace for custom error
        require(cToken.mint(amount) == 0, "ERROR deposit Compound");

        if(_receiver != address(0)) {
            uint256 cTokenAmount = cToken.balanceOf(address(this));
            cToken.transfer(_receiver, cTokenAmount);
        }
    }


    function withdrawCompound(address _cToken, address _receiver) external {
        IERC20 token = IERC20(cTokenToUnderlying[_cToken]);
        ICToken cToken = ICToken(_cToken);

        uint256 amount = cToken.balanceOf(address(this));

        require(cToken.redeem(amount) == 0, "Error withdraw Compound");

        if(_receiver != address(0)) {
            uint256 tokenAmount = token.balanceOf(address(this));
            token.transfer(msg.sender, tokenAmount);
        }
    }

    function pullToken(address _token, uint256 _amount) external {
        uint256 amount = IERC20(_token).balanceOf(msg.sender).min(_amount);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function sendToken(address _token, address _receiver) external {
        IERC20 token = IERC20(_token);
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(_receiver, amount);
    }

}