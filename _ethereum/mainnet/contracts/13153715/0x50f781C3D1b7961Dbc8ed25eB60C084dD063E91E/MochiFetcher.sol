// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Float.sol";
import "./IMochiCssr.sol";
import "./IMochiNft.sol";
import "./IMochiVault.sol";

contract MochiFetcher is Ownable {
    address public immutable mochiNft;
    address public immutable mochiCssr;

    struct VaultDetail {
        uint256 nftId;
        address asset;
        Status status;
        uint256 collateral;
        uint256 debt;
        uint256 debtIndex;
        address referrer;
    }

    constructor(address _mochiNft, address _mochiCssr) {
        mochiNft = _mochiNft;
        mochiCssr = _mochiCssr;
    }

    function fetchTokenBalances(address[] calldata tokens, address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenBalances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            tokenBalances[i] = IERC20(tokens[i]).balanceOf(user);
        }
        return tokenBalances;
    }

    function fetchTokenPrices(address[] calldata tokens)
        external
        view
        returns (float[] memory)
    {
        float[] memory prices = new float[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            try IMochiCssr(mochiCssr).getPrice(tokens[i]) returns (
                float memory price
            ) {
                prices[i].numerator = price.numerator;
                prices[i].denominator = price.denominator;
            } catch {
                prices[i].numerator = 0;
                prices[i].denominator = 1;
            }
        }
        return prices;
    }

    function fetchNftTokens(address user)
        external
        view
        returns (uint256[] memory, address[] memory)
    {
        uint256 nftBalance = IMochiNft(mochiNft).balanceOf(user);
        uint256[] memory nftIds = new uint256[](nftBalance);
        address[] memory assets = new address[](nftBalance);

        for (uint256 i = 0; i < nftBalance; i += 1) {
            nftIds[i] = IMochiNft(mochiNft).tokenOfOwnerByIndex(user, i);
            assets[i] = IMochiNft(mochiNft).info(nftIds[i]).asset;
        }

        return (nftIds, assets);
    }

    function fetchVaultDetails(uint256[] memory nftIds, address[] memory vaults)
        external
        view
        returns (Detail[] memory)
    {
        Detail[] memory details = new Detail[](nftIds.length);

        for (uint256 i = 0; i < nftIds.length; i += 1) {
            details[i] = IMochiVault(vaults[i]).details(nftIds[i]);
        }

        return details;
    }
}
