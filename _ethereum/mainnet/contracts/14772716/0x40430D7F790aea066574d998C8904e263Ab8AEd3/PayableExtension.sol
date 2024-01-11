// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CreatorExtensionBasic.sol";
import "./IERC721CreatorCore.sol";
import "./AdminControl.sol";
import "./Counters.sol";
import "./TokenAllowlist.sol";
import "./Allowlist.sol";

/**
 * An extension for Manifold contracts that add pay to mint functionalities
 */

contract PayableExtension is
    AdminControl,
    TokenAllowlist,
    Allowlist,
    CreatorExtensionBasic
{
    //
    // Libraries
    //

    using Counters for Counters.Counter;

    //
    // Events
    //

    //event on withdraw
    event Withdraw(uint256 amount);

    //
    // State
    //

    // Counter of minted tokens
    Counters.Counter private _tokenAmountTracker;
    // max supply of the extension
    uint96 public maxSupply;
    // address of the core contract also refered as creator on the manifold nomenclature
    address public creator;
    // price of the mint
    uint96 public mintPrice;
    // payout address
    address private _payout;
    // date in which the mint starts
    uint256 public launchDate;

    constructor(
        uint96 maxSupply_,
        address creator_,
        uint96 mintPrice_,
        address payout_,
        uint256 launchDate_,
        bool tokenAllowlistEnabled_,
        bool allowlistEnabled_
    ) {
        maxSupply = maxSupply_;
        creator = creator_;
        mintPrice = mintPrice_;
        _payout = payout_;
        launchDate = launchDate_;
        setTokenAllowlistStatus(tokenAllowlistEnabled_);
        setAllowlistStatus(allowlistEnabled_);
    }

    //
    // External
    //

    /**
     * Pay to mint a token on the creator contract
     */
    function mint(bytes32[] calldata merkleProof) external payable {
        require(block.timestamp >= launchDate, "minting not enabled");
        require(
            _tokenAmountTracker.current() < maxSupply,
            "Maximum supply reached"
        );
        require(msg.value >= mintPrice, "Insuficient funds");

        require(
            ifEnabledCheckTokenAllowlist(msg.sender),
            "Not on tokenAllowlist"
        );
        require(
            ifEnabledCheckAllowlist(merkleProof),
            "Not on allowlist of addresses"
        );

        IERC721CreatorCore(creator).mintExtension(msg.sender);
        _tokenAmountTracker.increment();
    }

    //
    // Queries
    //

    /**
     * Get the current number of minted tokens on this extension
     */
    function getMintedTokensAmount() external view returns (uint256) {
        return _tokenAmountTracker.current();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, TokenAllowlist, Allowlist, CreatorExtensionBasic)
        returns (bool)
    {
        return
            AdminControl.supportsInterface(interfaceId) ||
            TokenAllowlist.supportsInterface(interfaceId) ||
            Allowlist.supportsInterface(interfaceId) ||
            CreatorExtensionBasic.supportsInterface(interfaceId);
    }

    //
    // Admin required
    //

    /**
     * Withdraw all ETH from the contract to the payout addres.
     */
    function withdraw() external adminRequired {
        require(address(this).balance > 0, "No funds to withdraw");

        uint256 balance = address(this).balance;
        payable(_payout).transfer(balance);

        emit Withdraw(balance);
    }

    /**
     * Change the payout address
     */
    function setPayout(address payout) external adminRequired {
        require(payout != address(0), "can't be null address");
        require(payout != address(this), "can't be this contract");
        require(payout != _payout, "can't be the current Payout ");

        _payout = payout;
    }
}
