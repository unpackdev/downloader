// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

import "./Portal.sol";
import "./IAssetChainManager.sol";
import "./AssetChainLz.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

contract AssetChainManager is IAssetChainManager {
    using SafeERC20 for IERC20Metadata;

    address public admin;
    address public participatingInterface;
    address public immutable portal;
    address public receiver;

    uint256 defaultMinimumDeposit = 1e6;
    mapping(address => bool) public supportedAsset;
    mapping(address => uint256) public minimumDeposit;

    constructor(address _participatingInterface, address _admin) {
        admin = _admin;
        participatingInterface = _participatingInterface;
        portal = address(new Portal(_participatingInterface, address(this)));
    }

    address public newAdmin;

    function transferAdmin(address _admin) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (_admin == address(0)) revert("New admin cannot be empty");
        if (newAdmin != address(0)) revert("New admin already set");
        newAdmin = _admin;
    }

    function cancelAdminTransfer() external {
        if (msg.sender != admin) revert("Sender not admin");
        newAdmin = address(0);
    }

    function acceptAdminTransfer() external {
        if (msg.sender != newAdmin) revert("Sender not new admin");
        admin = newAdmin;
        newAdmin = address(0);
    }

    function replaceParticipatingInterface(address _participatingInterface) external {
        if (msg.sender != admin) revert("Sender not admin");
        participatingInterface = _participatingInterface;
    }

    function replaceReceiver(address _receiver) external {
        if (msg.sender != admin) revert("Sender not admin");
        if (_receiver == address(0)) revert();
        receiver = _receiver;
    }

    function deployReceiver(address _lzEndpoint, uint16 _lzProcessingChainId) external {
        if (msg.sender != admin) revert();
        if (receiver != address(0)) revert();
        receiver = address(
            new AssetChainLz(
            admin,
            _lzEndpoint,
            _lzProcessingChainId
            )
        );
    }

    /// Called by the admin to add a support for a new asset on this chain.
    /// If the asset is an ERC20 token, it performs a basic sanity check on the token contract.
    /// If an asset is added here, it should also be added on the processing chain's manager.
    /// @param _asset Address of the asset being added (with address(0) representing the native asset)
    /// @param _approved Address that has approved this contract to transfer 1 wei of the asset
    function addSupportedAsset(address _asset, address _approved) external {
        if (msg.sender != admin) revert("Only admin");
        if (supportedAsset[_asset]) revert("Asset already supported");
        if (_asset != address(0)) {
            IERC20Metadata asset = IERC20Metadata(_asset);
            if (asset.decimals() == 0) revert();
            uint256 balance = asset.balanceOf(address(this));
            asset.safeTransferFrom(_approved, address(this), 1);
            require(
                asset.balanceOf(address(this)) == balance + 1,
                "transferFrom didn't update manager contract's balance correctly"
            );
            asset.safeTransfer(_approved, 1);
            require(
                asset.balanceOf(address(this)) == balance,
                "transfer failed to update manager contract's balance correctly"
            );
        }
        supportedAsset[_asset] = true;
    }

    /// Called by admin to set the `_minimum` deposit amount for an `_asset`
    function setMinimumDeposit(address _asset, uint256 _minimum) external {
        if (msg.sender != admin) revert("Only admin");
        if (!supportedAsset[_asset]) revert("Unsupported asset");
        minimumDeposit[_asset] = _minimum;
    }

    function getMinimumDeposit(address _asset) external view returns (uint256) {
        if (!supportedAsset[_asset]) revert("Unsupported asset");
        return minimumDeposit[_asset] == 0 ? defaultMinimumDeposit : minimumDeposit[_asset];
    }
}
