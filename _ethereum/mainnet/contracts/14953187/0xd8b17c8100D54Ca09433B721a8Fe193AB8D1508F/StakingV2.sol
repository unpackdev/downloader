//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./Staking.sol";
import "./StakingVerifier.sol";

contract StakingV2 is Staking, StakingVerifier {
    function stake(StakeRequest calldata request, bytes calldata signature)
        external
        onlyIfStakeAuthorized(request, signature)
        whenNotPaused
        nonReentrant
    {
        _markRequestAsFulfilled(request.id, request.createdAt);

        uint256 plotsAmount = request.plots;
        if (plotsAmount > 0) {
            _plotToken.safeTransferFrom(
                request.account,
                address(this),
                PLOT_ID,
                plotsAmount,
                ""
            );
        }

        if (request.strainIds.length > 0) {
            for (uint256 i = 0; i < request.strainIds.length; i++) {
                _strainToken.safeTransferFrom(
                    request.account,
                    address(this),
                    request.strainIds[i]
                );
            }
        }

        if (request.bredStrainIds.length > 0) {
            for (uint256 i = 0; i < request.bredStrainIds.length; i++) {
                _bredStrainToken.safeTransferFrom(
                    request.account,
                    address(this),
                    request.bredStrainIds[i]
                );
            }
        }
    }

    function withdraw(
        WithdrawRequest calldata request,
        bytes calldata signature
    )
        external
        onlyIfWithdrawAuthorized(request, signature)
        whenNotPaused
        nonReentrant
    {
        _markRequestAsFulfilled(request.id, request.createdAt);

        uint256 plotsAmount = request.plots;
        if (plotsAmount > 0) {
            _plotToken.safeTransferFrom(
                address(this),
                request.account,
                PLOT_ID,
                plotsAmount,
                ""
            );
        }

        if (request.strainIds.length > 0) {
            for (uint256 i = 0; i < request.strainIds.length; i++) {
                _strainToken.safeTransferFrom(
                    address(this),
                    request.account,
                    request.strainIds[i]
                );
            }
        }

        if (request.bredStrainIds.length > 0) {
            for (uint256 i = 0; i < request.bredStrainIds.length; i++) {
                _bredStrainToken.safeTransferFrom(
                    address(this),
                    request.account,
                    request.bredStrainIds[i]
                );
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
}
