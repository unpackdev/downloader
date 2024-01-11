//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AdminManager.sol";
import "./OnChainManagerVerifier.sol";
import "./IBredStrain.sol";
import "./IRaks.sol";
import "./IPlot.sol";

contract OnChainManager is
    Initializable,
    AdminManagerUpgradable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OnChainManagerVerifier
{
    IRaks public raksToken;
    IPlot public plotToken;
    IBredStrain public bredStrainToken;

    function initialize(
        address raksTokenAddress,
        address plotTokenAddress,
        address bredStrainTokenAddress
    ) public initializer {
        __AdminManager_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        raksToken = IRaks(raksTokenAddress);
        plotToken = IPlot(plotTokenAddress);
        bredStrainToken = IBredStrain(bredStrainTokenAddress);
    }

    function mint(MintRequest calldata request, bytes calldata signature)
        external
        onlyIfMintAuthorized(request, signature)
        whenNotPaused
        nonReentrant
    {
        _markRequestAsFulfilled(request.id, request.createdAt);

        if (request.raks > 0) {
            raksToken.mint(request.account, request.raks);
        }

        if (request.plots > 0) {
            plotToken.mint(request.account, request.plots);
        }

        if (request.bredStrains > 0) {
            bredStrainToken.mint(request.account, request.bredStrains);
        }
    }

    function burn(BurnRequest calldata request, bytes calldata signature)
        external
        onlyIfBurnAuthorized(request, signature)
        whenNotPaused
        nonReentrant
    {
        _markRequestAsFulfilled(request.id, request.createdAt);

        if (request.raks > 0) {
            raksToken.burn(request.account, request.raks);
        }

        if (request.plots > 0) {
            plotToken.burn(request.account, request.plots);
        }

        if (request.bredStrainIds.length > 0) {
            for (uint256 i = 0; i < request.bredStrainIds.length; i++) {
                bredStrainToken.burn(request.bredStrainIds[i]);
            }
        }
    }

    function cancelRequest(
        CancelRequest calldata request,
        bytes calldata signature
    ) external {
        _markRequestAsCancelled(request, signature);
    }

    function setRequestDuration(uint256 duration) external onlyAdmin {
        _setRequestDuration(duration);
    }

    function setAuthorizedSigner(address signer) external onlyAdmin {
        _setAuthorizedSigner(signer);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setRaksToken(address raksTokenAddress) external onlyAdmin {
        raksToken = IRaks(raksTokenAddress);
    }

    function setPlotToken(address plotTokenAddress) external onlyAdmin {
        plotToken = IPlot(plotTokenAddress);
    }

    function setBredStrainToken(address bredStrainTokenAddress)
        external
        onlyAdmin
    {
        bredStrainToken = IBredStrain(bredStrainTokenAddress);
    }
}
