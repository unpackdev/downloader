// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Proxy.sol";
import "./Initializable.sol";
import "./Artfi-CollectionProxy.sol";
import "./Artfi-PassVoucher.sol";

/** @title Collection Factory contract
 * @dev Factory contract for collection contract.
 */

contract PassVoucherFactory is Initializable {
    error GeneralError(string errorCode);
    address private _artfiMarketplace;
    address private _admin;
    uint256 private _version;

    event ePassVoucherContractCreated(address proxyContract);

    event eUpdateMarketplace(address artfiMarketplace_);

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert GeneralError("AF:101");
        _;
    }

    /** @notice Initializes the contract by setting the address of artfi Marketplace.
     * @dev used instead of constructor.
     * @param artfiMarketplace_ address of artfi Marketplace.
     */
    function initialize(address artfiMarketplace_) external initializer {
        _artfiMarketplace = artfiMarketplace_;
        _admin = msg.sender;
        _version = 2;
    }

    /** @notice updates the address of marketplace contract.
     * @param  artfiMarketplace_ address of artfi Marketplace.
     */
    function updateMarketplaceaddress(
        address artfiMarketplace_
    ) external onlyAdmin {
        _artfiMarketplace = artfiMarketplace_;

        emit eUpdateMarketplace(artfiMarketplace_);
    }

    /** @notice deploys pass voucher contract and proxy contract.
     *@dev deploys collection contract and proxy contract by creating an instance of both.
     *@param voucherName_ The name of nft created.
     *@param baseURI_ baseUri of token.
     *@param description_ description for collection.
     */
    function createNewPassVoucher(
        string memory voucherName_,
        string memory baseURI_,
        string memory description_,
        string memory imageURI_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) external {
        ArtfiPassVoucherV2 passvoucherV2 = new ArtfiPassVoucherV2();
        ArtfiProxy passVoucherProxy = new ArtfiProxy(
            address(passvoucherV2),
            _admin,
            abi.encodeWithSelector(
                ArtfiPassVoucherV2(address(0)).initialize.selector,
                _version,
                voucherName_,
                baseURI_,
                description_,
                imageURI_,
                _admin,
                _artfiMarketplace,
                maxBatchSize_,
                collectionSize_
            )
        );

        emit ePassVoucherContractCreated(address(passVoucherProxy));
    }
}
