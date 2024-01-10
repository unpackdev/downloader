//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IStrain.sol";
import "./IBredStrain.sol";
import "./IRaks.sol";
import "./IPlot.sol";
import "./AdminManager.sol";

contract PlotWithRaks is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AdminManagerUpgradable
{
    IPlot private _plotToken;
    IStrain private _strainToken;
    IBredStrain private _bredStrainToken;
    IRaks private _raksToken;

    function initialize(
        address plotToken,
        address strainToken,
        address bredStrainToken,
        address raksToken
    ) public initializer {
        _plotToken = IPlot(plotToken);
        _strainToken = IStrain(strainToken);
        _bredStrainToken = IBredStrain(bredStrainToken);
        _raksToken = IRaks(raksToken);
        __Pausable_init();
        __ReentrancyGuard_init();
        __AdminManager_init();
    }

    function mint(uint256 amount) external whenNotPaused nonReentrant {
        _raksToken.burn(msg.sender, _calculateRaksCost() * amount);
        _plotToken.adminMint(msg.sender, amount);
    }

    function _calculateRaksCost() private returns (uint256) {
        uint256 totalStrains = _strainToken.genesisSupply() +
            _bredStrainToken.bredSupply();
        if (totalStrains < 6000) {
            totalStrains = 6000;
        }
        uint256 multiplier = totalStrains / 6000;
        return 5873094715440096000 * 10000 * multiplier;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setPlotToken(address plotToken) external onlyAdmin {
        _plotToken = IPlot(plotToken);
    }

    function setStrainToken(address strainTokenAddress) external onlyAdmin {
        _strainToken = IStrain(strainTokenAddress);
    }

    function setBredStrainToken(address bredStrainTokenAddress)
        external
        onlyAdmin
    {
        _bredStrainToken = IBredStrain(bredStrainTokenAddress);
    }

    function setRaksToken(address raksTokenAddress) external onlyAdmin {
        _raksToken = IRaks(raksTokenAddress);
    }
}
