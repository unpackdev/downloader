// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IMellowBaseOracle.sol";
import "./UniV3TokenRegistry.sol";
import "./UniV3Token.sol";

contract UniV3ERC20Oracle is IMellowBaseOracle {
    error PoolIsNotStable();

    UniV3TokenRegistry public immutable registry;

    constructor(UniV3TokenRegistry registry_) {
        registry = registry_;
    }

    function isTokenSupported(address token) external view override returns (bool) {
        if (registry.idByToken(token) != 0) {
            return true;
        }

        try IERC165(token).supportsInterface(type(IProxyToken).interfaceId) returns (bool isSupported) {
            if (isSupported) {
                address implementation = ProxyToken(payable(token)).token();
                return (registry.idByToken(implementation) != 0 && UniV3Token(implementation).admin() == token);
            }
        } catch {}
        return false;
    }

    function quote(
        address token,
        uint256 amount,
        bytes memory
    ) public view override returns (address[] memory tokens, uint256[] memory tokenAmounts) {
        tokens = new address[](2);
        tokens[0] = UniV3Token(token).token0();
        tokens[1] = UniV3Token(token).token1();
        tokenAmounts = UniV3Token(token).tvl();
        uint256 totalSupply = UniV3Token(token).totalSupply();
        tokenAmounts[0] = FullMath.mulDiv(tokenAmounts[0], amount, totalSupply);
        tokenAmounts[1] = FullMath.mulDiv(tokenAmounts[1], amount, totalSupply);
    }
}
