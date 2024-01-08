// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./SafeCast.sol";
import "./SafeERC20.sol";
import "./Float.sol";
import "./ILiquidator.sol";
import "./IMochiEngine.sol";

contract DutchAuctionLiquidator is ILiquidator {
    using SafeERC20 for IERC20;
    using SafeERC20 for IUSDM;
    using Float for uint256;

    IMochiEngine public immutable engine;

    uint256 public constant DURATION = 2 days / 15;

    struct Auction {
        uint256 nftId;
        address vault;
        uint64 nonce;
        uint128 startedAt;
        uint128 boughtAt;
        uint256 collateral;
        uint256 debt;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => uint64) public nonces;

    constructor(address _engine) {
        require(_engine != address(0), "engine 0x");
        engine = IMochiEngine(_engine);
    }

    /**
     *@dev Returns number for a uniq auction index
     */
    function auctionId(address asset, uint256 nftId, uint256 nonce)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(asset, nftId, nonce)));
    }


    function price(uint256 _auctionId) external view returns (uint256) {
        Auction memory auction = auctions[_auctionId];
        if (auction.startedAt == 0 || auction.boughtAt != 0) return 0;
        return auction.debt + currentLiquidationFee(_auctionId);
    }

    function currentLiquidationFee(uint256 _auctionId)
        public
        view
        returns (uint256 liquidationFee)
    {
        Auction memory auction = auctions[_auctionId];
        if (auction.startedAt == 0 || auction.boughtAt != 0) return 0;
        liquidationFee = auction.debt.multiply(
            engine.mochiProfile().liquidationFee(
                address(IMochiVault(auction.vault).asset())
            )
        )
        .multiply(
            float({
                numerator: SafeCast.toUint256(
                    SafeCast.toInt256(auction.startedAt)
                ) + DURATION > block.number
                    ? SafeCast.toUint256(
                        SafeCast.toInt256(auction.startedAt)
                    ) +
                        DURATION -
                        block.number : 0,
                denominator: DURATION
            })
        );
    }

    function triggerLiquidation(
        address _asset,
        uint256 _nftId,
        bytes calldata _data
    ) external override {
        IMochiVault vault = engine.vaultFactory().getVault(_asset);
        uint256 debt = vault.currentDebt(_nftId);
        (, uint256 collateral, , , ) = vault.details(_nftId);

        vault.liquidate(_nftId, collateral, debt, _data);

        uint256 id = auctionId(_asset, _nftId, nonces[_nftId]);

        auctions[id] = Auction({
            nftId: _nftId,
            vault: address(vault),
            nonce: nonces[_nftId]++,
            startedAt: SafeCast.toUint128(block.number),
            boughtAt: 0,
            collateral: collateral,
            debt: debt
        });

        uint256 liquidationFee = debt.multiply(
            engine.mochiProfile().liquidationFee(address(_asset))
        );
        emit Triggered(id, debt + liquidationFee);
    }

    function _settleLiquidation(uint256 _auctionId, address buyer) internal {
        Auction storage auction = auctions[_auctionId];
        require(auction.startedAt > 0, "!started");
        require(auction.boughtAt == 0, "liquidated");
        uint256 debt = auction.debt;
        uint256 collateral = auction.collateral;

        IMochiVault vault = IMochiVault(auction.vault);
        //repay the debt first
        IUSDM usdm = engine.usdm();
        uint256 liquidationFee = currentLiquidationFee(_auctionId);
        uint256 requiredUsdm = debt + liquidationFee;
        usdm.safeTransferFrom(buyer, address(this), requiredUsdm);
        usdm.burn(debt);
        //transfer liquidation fee to feePool
        usdm.safeTransfer(address(engine.treasury()), liquidationFee);

        IERC20 asset = vault.asset();
        auction.boughtAt = SafeCast.toUint128(block.number);
        asset.safeTransfer(buyer, collateral);

        emit Settled(_auctionId, requiredUsdm);
    }

    function buy(uint256 _auctionId) external {
        _settleLiquidation(_auctionId, msg.sender);
    }
}
