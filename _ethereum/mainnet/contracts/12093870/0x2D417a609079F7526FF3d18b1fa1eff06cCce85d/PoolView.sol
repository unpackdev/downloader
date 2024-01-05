// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IPool.sol";
import "./IERC20Metadata.sol";

contract PoolView {
    struct TokenRecord {
        address self;
        uint256 balance;
        uint256 leverage;
        uint8 decimals;
        uint256 userBalance;
    }

    struct Token {
        address self;
        uint256 totalSupply;
        uint8 decimals;
        uint256 userBalance;
    }

    struct Config {
        address derivativeVault;
        address dynamicFee;
        address repricer;
        uint exposureLimit;
        uint volatility;
        uint pMin;
        uint qMin;
        uint8 qMinDecimals;
        uint baseFee;
        uint maxFee;
        uint feeAmp;
        uint8 decimals;
    }

    function getPoolInfo(address _pool)
    external view
    returns (
        TokenRecord memory primary,
        TokenRecord memory complement,
        Token memory poolToken,
        Config memory config
    )
    {
        IPool pool = IPool(_pool);

        address _primaryAddress = address(pool.derivativeVault().primaryToken());
        primary = TokenRecord(
            _primaryAddress,
            pool.getBalance(_primaryAddress),
            pool.getLeverage(_primaryAddress),
            IERC20Metadata(_primaryAddress).decimals(),
            IERC20(_primaryAddress).balanceOf(msg.sender)
        );

        address _complementAddress = address(pool.derivativeVault().complementToken());
        complement = TokenRecord(
            _complementAddress,
            pool.getBalance(_complementAddress),
            pool.getLeverage(_complementAddress),
            IERC20Metadata(_complementAddress).decimals(),
            IERC20(_complementAddress).balanceOf(msg.sender)
        );

        poolToken = Token(
            _pool,
            pool.totalSupply(),
            IERC20Metadata(_pool).decimals(),
            IERC20(_pool).balanceOf(msg.sender)
        );

        config = Config(
            address(pool.derivativeVault()),
            address(pool.dynamicFee()),
            address(pool.repricer()),
            pool.exposureLimit(),
            pool.volatility(),
            pool.pMin(),
            pool.qMin(),
            IERC20Metadata(_primaryAddress).decimals(),
            pool.baseFee(),
            pool.maxFee(),
            pool.feeAmp(),
            IERC20Metadata(_pool).decimals()
        );
    }

    function getPoolTokenData(address _pool)
    external view
    returns (
        address primary,
        uint primaryBalance,
        uint primaryLeverage,
        uint8 primaryDecimals,
        address complement,
        uint complementBalance,
        uint complementLeverage,
        uint8 complementDecimals,
        uint lpTotalSupply,
        uint8 lpDecimals
    )
    {
        IPool pool = IPool(_pool);

        primary = address(pool.derivativeVault().primaryToken());
        complement = address(pool.derivativeVault().complementToken());

        primaryBalance = pool.getBalance(primary);
        primaryLeverage = pool.getLeverage(primary);
        primaryDecimals = IERC20Metadata(primary).decimals();

        complementBalance = pool.getBalance(complement);
        complementLeverage = pool.getLeverage(complement);
        complementDecimals = IERC20Metadata(complement).decimals();

        lpTotalSupply  = pool.totalSupply();
        lpDecimals = IERC20Metadata(_pool).decimals();
    }

    function getPoolConfig(address _pool)
    external view
    returns (
        address derivativeVault,
        address dynamicFee,
        address repricer,
        uint exposureLimit,
        uint volatility,
        uint pMin,
        uint qMin,
        uint baseFee,
        uint maxFee,
        uint feeAmp
    )
    {
        IPool pool = IPool(_pool);
        derivativeVault = address(pool.derivativeVault());
        dynamicFee = address(pool.dynamicFee());
        repricer = address(pool.repricer());
        pMin = pool.pMin();
        qMin = pool.qMin();
        exposureLimit = pool.exposureLimit();
        baseFee = pool.baseFee();
        feeAmp = pool.feeAmp();
        maxFee = pool.maxFee();
        volatility = pool.volatility();
    }
}
