// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./NftInterfaces.sol";
import "./CToken.sol";
import "./FullMath.sol";
import "./INFTXVault.sol";
import "./UniswapV2PriceOracle.sol";

/**
 * @title CNftPriceOracle
 * @notice Price oracle for cNFT tokens.
 * @dev Assumes that base token is WETH.
 */
contract CNftPriceOracle is NftPriceOracle {
    address public admin;
    modifier onlyAdmin() {
        require(msg.sender == admin, "Sender must be the admin.");
        _;
    }

    UniswapV2PriceOracle public immutable uniswapV2Oracle;
    address public immutable uniswapV2Factory;
    address public immutable baseToken;

    /// @dev Mapping from CNft address to underlying NFTX token address.
    mapping(address => address) public underlyingNftxTokenAddress;

    constructor(
        address _admin,
        address _uniswapV2Oracle,
        address _uniswapV2Factory,
        address _baseToken
    ) {
        admin = _admin;
        uniswapV2Oracle = UniswapV2PriceOracle(_uniswapV2Oracle);
        uniswapV2Factory = _uniswapV2Factory;
        baseToken = _baseToken;
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function addAddressMapping(
        CNftInterface[] calldata cNfts,
        address[] calldata nftxTokens
    ) external onlyAdmin {
        require(
            cNfts.length > 0 && cNfts.length == nftxTokens.length,
            "CNftPriceOracle: `cNfts` and `nftxTokens` must have nonzero, equal lengths."
        );
        for (uint256 i = 0; i < cNfts.length; ++i) {
            address underlying = cNfts[i].underlying();
            require(
                underlyingNftxTokenAddress[underlying] == address(0),
                "CNftPriceOracle: Cannot overwrite existing address mappings."
            );
            underlyingNftxTokenAddress[underlying] = nftxTokens[i];
        }
    }

    /**
     * @notice Returns price of `cToken` in `baseToken`, scaled by the units of `baseToken`.
     * @notice For example, if `baseToken` were WETH and the price of `cToken` was 1 WETH,
     * @notice then the function would return 10**18.
     */
    function getUnderlyingPrice(CNftInterface cNft)
        external
        view
        override
        returns (uint256)
    {
        address nftxToken = underlyingNftxTokenAddress[cNft.underlying()];
        require(
            nftxToken != address(0),
            "CNftPriceOracle: No NFTX token for cNFT."
        );

        uint256 mintFee = INFTXVault(nftxToken).mintFee();
        uint256 pricePerToken = uniswapV2Oracle.price(
            nftxToken,
            baseToken,
            uniswapV2Factory
        );
        return FullMath.mulDiv(pricePerToken, 10**18 - mintFee, 10**18);
    }
}
