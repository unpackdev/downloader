// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./IERC721Enumerable.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

/**
 * @title Token contract
 * @dev Extends ERC20 Token Standard basic implementation
 */
contract Token is ERC20, Ownable {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Address of NFT Smart contract. Only owners of this NFT can claim tokens
    address public nftAddress;

    // How much tokens can be claimed by one address (10k)
    uint256 public constant TOKENS_PER_ADDRESS = 10000 * (10 ** 18);

    // Mapping if tokens for certain NFT ID has already been claimed
    mapping (uint256 => bool) private _claimedNfts;

    // Addresses that were claimed tokens
    EnumerableSet.AddressSet private _claimedOwners;

    // Airdrop will be active for 1 month
    bool public isAirdropActive = true;

    constructor(string memory name, string memory symbol, address _nftAddress) ERC20(name, symbol) {
        nftAddress = _nftAddress;
    }

    /**
     * @dev Pause airdrop if active, make active if paused
     */
    function flipAirdropState() public onlyOwner {
        isAirdropActive = !isAirdropActive;
    }

    /**
     * @dev Returns if tokens for certain NFT ID has already been claimed
     */
    function isTokensForNftClaimed(uint256 nftId) public view returns (bool) {
        return _claimedNfts[nftId];
    }

    /**
     * @dev Returns if `owner` address has already claimed tokens
     */
    function isOwnerClaimedTokens(address owner) public view returns (bool) {
        return _claimedOwners.contains(owner);
    }

    /**
     * @dev Returns number of NFTs in `owner`'s account.
     */
    function nftBalanceOf(address owner) public view returns (uint256) {
        return IERC721Enumerable(nftAddress).balanceOf(owner);
    }

    /**
     * @dev Check if an `owner` address can claim tokens
     * Only the frontend calls this function just to display that a user can claim
     */
    function canClaim(address owner) external view returns (bool) {

        // one address can claim only once
        if (isOwnerClaimedTokens(owner) == true || isAirdropActive == false) {
            return false;
        }

        bool _canOwnerClaim = false;

        uint256 nftsNumber = nftBalanceOf(owner);
        for (uint i = 0; i < nftsNumber; i++) {
            uint256 currentNftId = IERC721Enumerable(nftAddress).tokenOfOwnerByIndex(owner, i);

            if (isTokensForNftClaimed(currentNftId) == false) {
                _canOwnerClaim = true;
            }
        }

        return _canOwnerClaim;
    }

    /**
     * @dev The same as the external `canClaim()` but also sets `_claimedNfts`=true for all NFTs
     * and add an `owner` address to `_claimedOwners`
     * This function can be called only by `claim()`
     * 
     * Duplicate code is required to save gas; otherwise, we need to iterate NFTs twice:
     * The first time is to call the external `canClaim()`
     * (i.e. check if an `owner` address can claim tokens)
     * The second is to update `_claimedNfts` and `_claimedOwners`
     */
    function _canClaim(address owner) internal returns (bool) {

        // one address can claim only once
        if (isOwnerClaimedTokens(owner) == true) {
            return false;
        }

        bool _canOwnerClaim = false;

        uint256 nftsNumber = nftBalanceOf(owner);
        for (uint i = 0; i < nftsNumber; i++) {
            uint256 currentNftId = IERC721Enumerable(nftAddress).tokenOfOwnerByIndex(owner, i);

            if (isTokensForNftClaimed(currentNftId) == false) {
                _canOwnerClaim = true;
                _claimedNfts[currentNftId] = true;
            }
        }

        if (_canOwnerClaim == true) {
            _claimedOwners.add(owner);
        }
        return _canOwnerClaim;
    }

    /**
     * @dev Claim tokens
     */
    function claim() public returns (bool) {
        require(isAirdropActive == true, "Airdrop is finished");

        bool canSenderClaim = _canClaim(msg.sender);
        require(canSenderClaim == true, "Sender cannot claim");

        _mint(msg.sender, TOKENS_PER_ADDRESS); 
        return canSenderClaim;
    }
}
