//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./RequestHandler.sol";

contract OnChainManagerVerifier is RequestHandler {
    struct MintRequest {
        uint256 id;
        address account;
        uint256 raks;
        uint256 plots;
        uint256 bredStrains;
        uint256 createdAt;
    }

    bytes32 private constant MINT_REQUEST_TYPE_HASH =
        keccak256(
            "MintRequest(uint256 id,address account,uint256 raks,uint256 plots,uint256 bredStrains,uint256 createdAt)"
        );

    struct BurnRequest {
        uint256 id;
        address account;
        uint256 raks;
        uint256 plots;
        uint256[] bredStrainIds;
        uint256 createdAt;
    }

    bytes32 private constant BURN_REQUEST_TYPE_HASH =
        keccak256(
            "BurnRequest(uint256 id,address account,uint256 raks,uint256 plots,uint256[] bredStrainIds,uint256 createdAt)"
        );

    modifier onlyIfMintAuthorized(
        MintRequest calldata request,
        bytes calldata signature
    ) {
        address signer = _hashAndRecover(
            keccak256(
                abi.encode(
                    MINT_REQUEST_TYPE_HASH,
                    request.id,
                    request.account,
                    request.raks,
                    request.plots,
                    request.bredStrains,
                    request.createdAt
                )
            ),
            signature
        );
        require(signer == authorizedSigner(), "Mint not authorized");
        _;
    }

    modifier onlyIfBurnAuthorized(
        BurnRequest calldata request,
        bytes calldata signature
    ) {
        address signer = _hashAndRecover(
            keccak256(
                abi.encode(
                    BURN_REQUEST_TYPE_HASH,
                    request.id,
                    request.account,
                    request.raks,
                    request.plots,
                    keccak256(abi.encodePacked(request.bredStrainIds)),
                    request.createdAt
                )
            ),
            signature
        );
        require(signer == authorizedSigner(), "Burn not authorized");
        _;
    }
}
