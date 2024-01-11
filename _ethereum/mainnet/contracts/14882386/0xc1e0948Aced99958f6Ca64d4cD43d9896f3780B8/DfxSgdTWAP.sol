// SPDX-License-Identifier: MIT
// https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "./IDfxOracle.sol";
import "./IChainLinkOracle.sol";

import "./UniswapV2Oracle.sol";

import "./AccessControl.sol";

contract DfxSgdTWAP is AccessControl, UniswapV2Oracle, IDfxOracle {
    // **** Roles **** //
    bytes32 public constant SUDO = keccak256("dfxsgd.twap.sudo");
    bytes32 public constant SUDO_ADMIN = keccak256("dfxsgd.twap.sudo.admin");

    // **** Constants **** //
    address internal constant SUSHI_FACTORY =
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant DFX = 0x888888435FDe8e7d4c54cAb67f206e4199454c60;

    IChainLinkOracle ETH_USD_ORACLE =
        IChainLinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IChainLinkOracle SGD_USD_ORACLE =
        IChainLinkOracle(0xe25277fF4bbF9081C75Ab0EB13B4A13a721f3E13);

    constructor(address _admin)
        UniswapV2Oracle(SUSHI_FACTORY, DFX, WETH, 6 hours)
    {
        _setRoleAdmin(SUDO, SUDO_ADMIN);
        _setupRole(SUDO_ADMIN, _admin);
        _setupRole(SUDO, _admin);
    }

    // **** Restricted functions **** //

    /// @notice Reads the price feed and updates internal TWAP state
    function update() public override onlyRole(SUDO) {
        super.update();
        emit Updated(price0CumulativeLast, price1CumulativeLast, blockTimestampLast);
    }

    /// @notice Changes the TWAP period
    function setPeriod(uint256 _period) public onlyRole(SUDO) {
        period = _period;
        emit PeriodSet(period);
    }

    // **** Public functions **** //

    /// @notice Returns price of DFX in SGD, e.g. 1 DFX = X SGD
    ///         Will assume 1 XSGD = 1 SGD in this case
    function read() public view override returns (uint256) {
        // 18 dec
        uint256 wethPerDfx18 = consult(DFX, 1e18);

        // in256, 8 dec -> uint256 18 dec
        (, int256 usdPerEth8, , , ) = ETH_USD_ORACLE.latestRoundData();
        (, int256 usdPerSgd8, , , ) = SGD_USD_ORACLE.latestRoundData();
        uint256 usdPerEth18 = uint256(usdPerEth8) * 1e10;
        uint256 usdPerSgd18 = uint256(usdPerSgd8) * 1e10;

        // (eth/dfx) * (usd/eth) = usd/dfx
        uint256 usdPerDfx = (wethPerDfx18 * usdPerEth18) / 1e18;

        // (usd/dfx) / (usd/sgd) = sgd/dfx
        uint256 sgdPerDfx = (usdPerDfx * 1e18) / usdPerSgd18;

        return sgdPerDfx;
    }

    /* ========== EVENTS ========== */
    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast, uint32 blockTimestampLast);
    event PeriodSet(uint256 period);
}
