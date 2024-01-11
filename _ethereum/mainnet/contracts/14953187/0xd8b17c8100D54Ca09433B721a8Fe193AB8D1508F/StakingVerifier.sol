//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./RequestHandler.sol";

contract StakingVerifier is RequestHandler {
    struct StakeRequest {
        uint256 id;
        address account;
        uint256 plots;
        uint256[] strainIds;
        uint256[] bredStrainIds;
        uint256 createdAt;
    }

    bytes32 private constant STAKE_REQUEST_TYPE_HASH =
        keccak256(
            "StakeRequest(uint256 id,address account,uint256 plots,uint256[] strainIds,uint256[] bredStrainIds,uint256 createdAt)"
        );

    struct WithdrawRequest {
        uint256 id;
        address account;
        uint256 plots;
        uint256[] strainIds;
        uint256[] bredStrainIds;
        uint256 createdAt;
    }

    bytes32 private constant WITHDRAW_REQUEST_TYPE_HASH =
        keccak256(
            "WithdrawRequest(uint256 id,address account,uint256 plots,uint256[] strainIds,uint256[] bredStrainIds,uint256 createdAt)"
        );

    modifier onlyIfStakeAuthorized(
        StakeRequest calldata request,
        bytes calldata signature
    ) {
        address signer = _hashAndRecover(
            keccak256(
                abi.encode(
                    STAKE_REQUEST_TYPE_HASH,
                    request.id,
                    request.account,
                    request.plots,
                    keccak256(abi.encodePacked(request.strainIds)),
                    keccak256(abi.encodePacked(request.bredStrainIds)),
                    request.createdAt
                )
            ),
            signature
        );
        require(signer == authorizedSigner(), "Stake not authorized");
        _;
    }

    modifier onlyIfWithdrawAuthorized(
        WithdrawRequest calldata request,
        bytes calldata signature
    ) {
        address signer = _hashAndRecover(
            keccak256(
                abi.encode(
                    WITHDRAW_REQUEST_TYPE_HASH,
                    request.id,
                    request.account,
                    request.plots,
                    keccak256(abi.encodePacked(request.strainIds)),
                    keccak256(abi.encodePacked(request.bredStrainIds)),
                    request.createdAt
                )
            ),
            signature
        );
        require(signer == authorizedSigner(), "Withdraw not authorized");
        _;
    }
}
