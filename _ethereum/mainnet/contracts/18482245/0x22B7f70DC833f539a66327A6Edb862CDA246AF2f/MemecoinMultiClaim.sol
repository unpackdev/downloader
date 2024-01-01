// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Context.sol";
import "./IDelegationRegistry.sol";
import "./IDelegateRegistry.sol";
import "./Structs.sol";

error InvalidDelegate();

interface IMemecoinClaim {
    function claimFromMulti(address _requester, ClaimType[] calldata _claimTypes) external;
    function claimInNFTsFromMulti(
        address _requester,
        NFTCollectionClaimRequest[] calldata _nftCollectionClaimRequests,
        bool _withWalletRewards
    ) external;
}

contract MemecoinMultiClaim is Context {
    IMemecoinClaim public immutable presaleClaim;
    IMemecoinClaim public immutable airdropClaim;
    IDelegationRegistry public immutable dc;
    IDelegateRegistry public immutable dcV2;

    constructor(address _presaleClaim, address _airdropClaim) {
        presaleClaim = IMemecoinClaim(_presaleClaim);
        airdropClaim = IMemecoinClaim(_airdropClaim);
        dc = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
        dcV2 = IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);
    }

    /// @dev Cross contract claim on Presale, OPTIONALLY ON NFTAirdrop/NFTRewards/WalletRewards
    /// @param _vault Vault address of delegate.xyz; pass address(0) if not using delegate wallet
    /// @param _claimTypes Array of ClaimType to claim
    /// @param _nftCollectionClaimRequests Array of NFTCollectionClaimRequest that consists collection ID of the NFT, token ID(s) the owner owns, array of booleans to indicate NFTAirdrop/NFTRewards claim for each token ID
    /// @param _withWalletRewards Boolean to dictate if claimer will claim WalletRewards as well
    function multiClaim(
        address _vault,
        ClaimType[] calldata _claimTypes,
        NFTCollectionClaimRequest[] calldata _nftCollectionClaimRequests,
        bool _withWalletRewards
    ) external {
        address requester = _getRequester(_vault);
        presaleClaim.claimFromMulti(requester, _claimTypes);
        airdropClaim.claimInNFTsFromMulti(requester, _nftCollectionClaimRequests, _withWalletRewards);
    }

    /// @notice Support both v1 and v2 delegate wallet during the v1 to v2 migration
    /// @dev Given _vault (cold wallet) address, verify whether _msgSender() is a permitted delegate to operate on behalf of it
    /// @param _vault Address to verify against _msgSender
    function _getRequester(address _vault) private view returns (address) {
        if (_vault == address(0)) return _msgSender();
        bool isDelegateValid = dcV2.checkDelegateForAll(_msgSender(), _vault, "");
        if (isDelegateValid) return _vault;
        isDelegateValid = dc.checkDelegateForAll(_msgSender(), _vault);
        if (!isDelegateValid) revert InvalidDelegate();
        return _vault;
    }
}
