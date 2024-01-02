// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IPToken.sol";
import "./Utils.sol";
import "./Network.sol";

error InvalidUnderlyingAssetName(string underlyingAssetName, string expectedUnderlyingAssetName);
error InvalidUnderlyingAssetSymbol(string underlyingAssetSymbol, string expectedUnderlyingAssetSymbol);
error InvalidUnderlyingAssetDecimals(uint256 underlyingAssetDecimals, uint256 expectedUnderlyingAssetDecimals);
error InvalidAssetParameters(uint256 assetAmount, address assetTokenAddress);
error SenderIsNotHub();
error InvalidNetwork(bytes4 networkId);

contract PToken is IPToken, ERC20 {
    using SafeERC20 for IERC20Metadata;

    address public immutable hub;
    address public immutable underlyingAssetTokenAddress;
    bytes4 public immutable underlyingAssetNetworkId;
    uint256 public immutable underlyingAssetDecimals;
    string public underlyingAssetName;
    string public underlyingAssetSymbol;

    modifier onlyHub() {
        if (_msgSender() != hub) {
            revert SenderIsNotHub();
        }
        _;
    }

    constructor(
        string memory underlyingAssetName_,
        string memory underlyingAssetSymbol_,
        uint256 underlyingAssetDecimals_,
        address underlyingAssetTokenAddress_,
        bytes4 underlyingAssetNetworkId_,
        address hub_
    ) ERC20(string.concat("p", underlyingAssetName_), string.concat("p", underlyingAssetSymbol_)) {
        if (Network.isCurrentNetwork(underlyingAssetNetworkId_)) {
            string memory expectedUnderlyingAssetName = IERC20Metadata(underlyingAssetTokenAddress_).name();
            if (
                keccak256(abi.encodePacked(underlyingAssetName_)) !=
                keccak256(abi.encodePacked(expectedUnderlyingAssetName))
            ) {
                revert InvalidUnderlyingAssetName(underlyingAssetName_, expectedUnderlyingAssetName);
            }

            string memory expectedUnderlyingAssetSymbol = IERC20Metadata(underlyingAssetTokenAddress_).symbol();
            if (
                keccak256(abi.encodePacked(underlyingAssetSymbol_)) !=
                keccak256(abi.encodePacked(expectedUnderlyingAssetSymbol))
            ) {
                revert InvalidUnderlyingAssetSymbol(underlyingAssetName, expectedUnderlyingAssetName);
            }

            uint256 expectedUnderliyngAssetDecimals = IERC20Metadata(underlyingAssetTokenAddress_).decimals();
            if (underlyingAssetDecimals_ != expectedUnderliyngAssetDecimals || expectedUnderliyngAssetDecimals > 18) {
                revert InvalidUnderlyingAssetDecimals(underlyingAssetDecimals_, expectedUnderliyngAssetDecimals);
            }
        }

        underlyingAssetName = underlyingAssetName_;
        underlyingAssetSymbol = underlyingAssetSymbol_;
        underlyingAssetNetworkId = underlyingAssetNetworkId_;
        underlyingAssetTokenAddress = underlyingAssetTokenAddress_;
        underlyingAssetDecimals = underlyingAssetDecimals_;
        hub = hub_;
    }

    /// @inheritdoc IPToken
    function burn(uint256 amount) external {
        _burnAndReleaseCollateral(_msgSender(), amount);
    }

    /// @inheritdoc IPToken
    function mint(uint256 amount) external {
        _takeCollateralAndMint(_msgSender(), amount);
    }

    /// @inheritdoc IPToken
    function protocolBurn(address account, uint256 amount) external onlyHub {
        _burnAndReleaseCollateral(account, amount);
    }

    /// @inheritdoc IPToken
    function protocolMint(address account, uint256 amount) external onlyHub {
        _mint(account, amount);
    }

    /// @inheritdoc IPToken
    function userBurn(address account, uint256 amount) external onlyHub {
        _burn(account, amount);
    }

    /// @inheritdoc IPToken
    function userMint(address account, uint256 amount) external onlyHub {
        _takeCollateralAndMint(account, amount);
    }

    /// @inheritdoc IPToken
    function userMintAndBurn(address account, uint256 amount) external onlyHub {
        _takeCollateral(account, amount);
        uint256 normalizedAmount = Utils.normalizeAmountToProtocolFormat(amount, underlyingAssetDecimals);
        emit Transfer(address(0), account, normalizedAmount);
        emit Transfer(account, address(0), normalizedAmount);
    }

    function _burnAndReleaseCollateral(address account, uint256 amount) internal {
        if (!Network.isCurrentNetwork(underlyingAssetNetworkId)) revert InvalidNetwork(underlyingAssetNetworkId);
        _burn(account, amount);
        IERC20Metadata(underlyingAssetTokenAddress).safeTransfer(
            account,
            Utils.normalizeAmountToOriginalFormat(amount, underlyingAssetDecimals)
        );
    }

    function _takeCollateral(address account, uint256 amount) internal {
        if (!Network.isCurrentNetwork(underlyingAssetNetworkId)) revert InvalidNetwork(underlyingAssetNetworkId);
        IERC20Metadata(underlyingAssetTokenAddress).safeTransferFrom(account, address(this), amount);
    }

    function _takeCollateralAndMint(address account, uint256 amount) internal {
        _takeCollateral(account, amount);
        _mint(account, Utils.normalizeAmountToProtocolFormat(amount, underlyingAssetDecimals));
    }
}
