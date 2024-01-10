// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./FixedPoint.sol";

import "./IBondingCalculator.sol";
import "./IXToken.sol";
import "./INFTXInventoryStaking.sol";
import "./INFTXVault.sol";
import "./ITreasury.sol";

contract NFTXXTokenCalculator is IBondingCalculator {

    using FixedPoint for *;
    using SafeMath for uint256;

    INFTXInventoryStaking public nftxInventoryStaking;
    ITreasury public treasury;

    constructor(address _nftxInventoryStaking, address _treasury) {
      require(_nftxInventoryStaking != address(0), "Zero address: _nftxInventoryStaking");
      require(_treasury!= address(0), "Zero address: _treasury");
      nftxInventoryStaking = INFTXInventoryStaking(_nftxInventoryStaking);
      treasury = ITreasury(_treasury);
    }

    function valuation(address xToken_, uint256 amount_) external view override returns (uint256 _value) {
        IXToken _xToken = IXToken(xToken_);

        // Get the vault ID from the xToken address
        INFTXVault _nftxVault = INFTXVault(_xToken.baseToken());
        uint256 _vaultId = _nftxVault.vaultId();

        // Get the underlying vToken amount from this xToken amount
        uint256 _vTokenAmount = amount_.mul(nftxInventoryStaking.xTokenShareValue(_vaultId)).div(1e18);

        // Return the Treasury value of the underlying vToken amount
        _value = treasury.tokenValue(address(_xToken.baseToken()), _vTokenAmount);
    }

}
