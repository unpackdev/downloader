// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IWyvernProxyRegistry.sol";

contract GaslessListingManager is Initializable, OwnableUpgradeable {
    event ApprovalForAll(address indexed operator, bool approved);

    address private _openSeaProxyRegistry;

    mapping(address => bool) private _preapprovedOperators;

    function initialize(
        address looksRareTransferManagerERC721_,
        address openSeaProxyRegistry_,
        address raribleTransferProxy_,
        address sloikaFixedPriceAuction_,
        address sloikaGachaAuction_
    ) public initializer {
        __Ownable_init();

        _setApproval(looksRareTransferManagerERC721_, true);
        _setApproval(raribleTransferProxy_, true);
        _setApproval(sloikaFixedPriceAuction_, true);
        _setApproval(sloikaGachaAuction_, true);

        _openSeaProxyRegistry = openSeaProxyRegistry_;
    }

    function setOpenSeaProxyRegistry(address openSeaProxyRegistry_) external onlyOwner {
        _openSeaProxyRegistry = openSeaProxyRegistry_;
    }

    function checkOpenSeaForGaslessListing(address owner_, address operator_) internal view returns (bool) {
        return address(IWyvernProxyRegistry(_openSeaProxyRegistry).proxies(owner_)) == operator_;
    }

    function isApprovedForAll(address owner_, address operator_) external view returns (bool) {
        return _preapprovedOperators[operator_] || checkOpenSeaForGaslessListing(owner_, operator_);
    }

    function setApprovalForAll(address operator_, bool approved_) external onlyOwner {
        _setApproval(operator_, approved_);
    }

    function _setApproval(address operator_, bool approved_) private {
        _preapprovedOperators[operator_] = approved_;
        emit ApprovalForAll(operator_, approved_);
    }
}
