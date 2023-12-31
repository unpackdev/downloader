// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ILendingLogic.sol";

import "./IPool.sol";

contract AToken {
    address public UNDERLYING_ASSET_ADDRESS;
}

contract LendingLogicAaveV3 is ILendingLogic {
    using SafeMath for uint128;

    IPool public lendingPool;
    uint16 public referralCode;

    constructor() {
        lendingPool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
        referralCode = 0;
    }

    function getAPRFromWrapped(address _token) external view override returns (uint256) {
        address underlying = AToken(_token).UNDERLYING_ASSET_ADDRESS();
        return getAPRFromUnderlying(underlying);
    }

    function getAPRFromUnderlying(address _token) public view override returns (uint256) {
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(_token);
        return reserveData.currentLiquidityRate.div(1000000000);
    }

    function lend(address _underlying, uint256 _amount, address _tokenHolder)
        external
        view
        override
        returns (address[] memory targets, bytes[] memory data)
    {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);

        // Set approval
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, address(lendingPool), _amount);

        // Deposit into Aave
        targets[1] = address(lendingPool);
        data[1] = abi.encodeWithSelector(lendingPool.supply.selector, _underlying, _amount, _tokenHolder, referralCode);

        // zero out approval to be sure
        targets[2] = _underlying;
        data[2] = abi.encodeWithSelector(underlying.approve.selector, address(lendingPool), 0);

        return (targets, data);
    }

    function unlend(address _wrapped, uint256 _amount, address _tokenHolder)
        external
        view
        override
        returns (address[] memory targets, bytes[] memory data)
    {
        AToken wrapped = AToken(_wrapped);

        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = address(lendingPool);
        data[0] = abi.encodeWithSelector(
            lendingPool.withdraw.selector, wrapped.UNDERLYING_ASSET_ADDRESS(), _amount, _tokenHolder
        );

        return (targets, data);
    }

    function exchangeRate(address) external pure override returns (uint256) {
        return 10 ** 18;
    }

    function exchangeRateView(address) external pure override returns (uint256) {
        return 10 ** 18;
    }
}
