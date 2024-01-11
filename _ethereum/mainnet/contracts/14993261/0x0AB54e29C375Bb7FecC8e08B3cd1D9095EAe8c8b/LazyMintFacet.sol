// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlModifiers.sol";
import "./BaseNFTModifiers.sol";
import "./PausableModifiers.sol";
import "./LazyMintLib.sol";

contract LazyMintFacet is
    AccessControlModifiers,
    SaleStateModifiers,
    PausableModifiers
{
    function setPublicMintPrice(uint256 _mintPrice)
        public
        onlyOperator
        whenNotPaused
    {
        LazyMintLib.setPublicMintPrice(_mintPrice);
    }

    function setMaxMintsPerTransaction(uint256 _maxMints)
        public
        onlyOperator
        whenNotPaused
    {
        LazyMintLib.setMaxMintsPerTransaction(_maxMints);
    }

    function setMaxMintsPerWallet(uint256 _maxMints)
        public
        onlyOperator
        whenNotPaused
    {
        LazyMintLib.setMaxMintsPerWallet(_maxMints);
    }

    function setMaxMintableAtCurrentStage(uint256 _maxMintable)
        public
        onlyOperator
        whenNotPaused
    {
        LazyMintLib.setMaxMintableAtCurrentStage(_maxMintable);
    }

    function maxMintsPerTransaction() public view returns (uint256) {
        return LazyMintLib.lazyMintStorage().maxMintsPerTxn;
    }

    function maxMintsPerWallet() public view returns (uint256) {
        return LazyMintLib.lazyMintStorage().maxMintsPerWallet;
    }

    function maxMintableAtCurrentStage() public view returns (uint256) {
        return LazyMintLib.lazyMintStorage().maxMintableAtCurrentStage;
    }

    function publicMintPrice() public view returns (uint256) {
        return LazyMintLib.publicMintPrice();
    }

    function publicMint(uint256 quantity)
        public
        payable
        onlyAtSaleState(1)
        returns (uint256)
    {
        return LazyMintLib.publicMint(quantity);
    }

    function setLazyMintConfig(
        uint256 _maxMintsPerTxn,
        uint256 _maxMintsPerWallet,
        uint256 _maxMintableAtCurrStage,
        uint256 _publicMintPrice
    ) public onlyOperator whenNotPaused {
        LazyMintLib.setMaxMintsPerTransaction(_maxMintsPerTxn);
        LazyMintLib.setMaxMintsPerWallet(_maxMintsPerWallet);
        LazyMintLib.setMaxMintableAtCurrentStage(_maxMintableAtCurrStage);
        LazyMintLib.setPublicMintPrice(_publicMintPrice);
    }

    function lazyMintConfig()
        external
        pure
        returns (LazyMintLib.LazyMintStorage memory)
    {
        return LazyMintLib.lazyMintStorage();
    }
}
