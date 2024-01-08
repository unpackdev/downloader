// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC20.sol";

import "./IYRegistry.sol";
import "./CurveToken.sol";

import "./IENS.sol";
import "./IENSResolver.sol";


contract YearnVaultExplorer is Ownable {
    bytes32 private node = 0x15e1d52381c87881e27faf6f0123992c93652facf5eb0b6d063d5eef4ed9c32d; // v2.registry.ychad.eth
    IENS private ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    struct TokenInfo {
        address addr;
        string symbol;
        string name;
        uint decimals;
        uint numVaults;
        uint virtualPrice;
    }

    struct VaultInfo {
        address addr;
        string symbol;
        string name;
        uint decimals;
        uint totalAssets;
        uint pricePerShare;
    }

    function finalize() public onlyOwner {
        address payable receiver = payable(msg.sender);
        selfdestruct(receiver);
    }

    function resolveYearnRegistry() public view returns (IYRegistry) {
        return IYRegistry(ens.resolver(node).addr(node));
    }

    function getNumTokens() public view returns (uint) {
        return resolveYearnRegistry().numTokens();
    }

    function exploreByTokenIndex(uint from, uint count) public view
    returns(TokenInfo[] memory tokens, VaultInfo[] memory vaults) {
        IYRegistry registry = resolveYearnRegistry();

        uint numTokens = registry.numTokens();
        uint to = from + count;
        if (to > numTokens) {
            to = numTokens;
        }
        if (from > numTokens) {
            from = numTokens;
        }

        count = to - from;

        // resolve tokens
        tokens = new TokenInfo[](count);
        uint totalVaults = 0;
        for (uint i = 0; i < count; ++i) {
            address token = registry.tokens(i + from);
            if (token == address(0)) {
                break;
            }

            tokens[i] = resolveToken(registry, token);
            totalVaults += tokens[i].numVaults;
        }

        // resolve vaults
        vaults = resolveVaults(registry, tokens, totalVaults);
    }

    function exploreByTokenAddress(address[] memory inputTokens) public view
    returns (TokenInfo[] memory tokens, VaultInfo[] memory vaults) {
        IYRegistry registry = resolveYearnRegistry();

        uint numTokens = inputTokens.length;

        // resolve tokens
        uint totalVaults = 0;
        tokens = new TokenInfo[](numTokens);
        for (uint i = 0; i < numTokens; ++i) {
            tokens[i] = resolveToken(registry, inputTokens[i]);
            totalVaults += tokens[i].numVaults;
        }

        // resolve vaults
        vaults = resolveVaults(registry, tokens, totalVaults);
    }

    function resolveToken(IYRegistry registry, address addr) internal view returns (TokenInfo memory tokenInfo) {
        tokenInfo = TokenInfo(
            addr,
            ERC20(addr).symbol(),
            ERC20(addr).name(),
            ERC20(addr).decimals(),
            registry.numVaults(addr),
            0
        );

        if (stringStartsWith("Curve.fi", tokenInfo.name)) {
            tokenInfo.virtualPrice = getCurveTokenVirtualPrice(addr);
        }
    }

    function resolveVaults(IYRegistry registry, TokenInfo[] memory tokens, uint totalVaults) internal view
    returns (VaultInfo[] memory vaults) {
        vaults = new VaultInfo[](totalVaults);
        uint k = 0;
        for (uint i = 0; i < tokens.length; ++i) {
            uint numVaults = tokens[i].numVaults;
            for (uint j = 0; j < numVaults; ++j) {
                vaults[k++] = resolveVault(IVault(registry.vaults(tokens[i].addr, j)));
            }
        }
    }

    function resolveVault(IVault vault) internal view returns (VaultInfo memory vaultInfo) {
        vaultInfo = VaultInfo(
            address(vault),
            vault.symbol(),
            vault.name(),
            vault.decimals(),
            vault.totalAssets(),
            vault.pricePerShare()
        );
    }

    /* solhint-disable indent, no-unused-vars */
    function getCurveTokenVirtualPrice(address token) internal view returns (uint) {
        try CurveToken(token).get_virtual_price() returns (uint virtualPrice) {
            return virtualPrice;
        } catch (bytes memory) {
            try CurveToken(token).minter() returns (address miner) {
                try CurveToken(miner).get_virtual_price() returns (uint minterVirtualPrice) {
                    return minterVirtualPrice;
                } catch (bytes memory) {}
            } catch (bytes memory) {}
        }

        return 0;
    }
    /* solhint-enable indent, no-unused-vars */

    function stringStartsWith(string memory what, string memory where) private pure returns (bool result) {
        bytes memory whatBytes = bytes(what);
        bytes memory whereBytes = bytes(where);

        if (whatBytes.length > whereBytes.length) {
            return false;
        }

        if (whereBytes.length == 0) {
            return false;
        }

        uint i = 0;
        uint j = 0;

        for (; i < whatBytes.length;) {
            if (whatBytes[i] != whereBytes[j]) {
                return false;
            }

            i += 1;
            j += 1;
        }

        return true;
    }
}
