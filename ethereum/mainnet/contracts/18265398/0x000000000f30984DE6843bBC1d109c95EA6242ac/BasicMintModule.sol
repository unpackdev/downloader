// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IBasicMintModule.sol";
import "./IMintPayout.sol";
import "./IMintContract.sol";
import "./BasicMintConfiguration.sol";
import "./Version.sol";

contract BasicMintModule is IBasicMintModule, Version {
    IMintPayout public immutable mintPayout;

    mapping(address => BasicMintConfiguration) private _configurations;
    mapping(address => mapping(address => uint256)) private _mintedByAddress;
    mapping(address => uint256) public mintedByContract;

    /// @notice Emitted when quantity is zero.
    error InvalidQuantity();
    /// @notice Emitted if the collector is minting too many tokens per transaction.
    error TooManyTokensPerTransaction();
    /// @notice Emitted if the collector is minting too many tokens per wallet.
    error TooManyTokensPerCollector();
    /// @notice Emitted if the collector is minting more tokens than this module is allowed to mint.
    error TooManyTokensForModule();
    /// @notice Emitted if the mint has not started yet.
    error MintNotStarted();
    /// @notice Emitted if the mint has ended.
    error MintEnded();
    /// @notice Emitted when the value sent is incorrect.
    error IncorrectPayment();
    /// @notice Emitted when the max supply is reached.
    error MaxSupplyReached();

    constructor(address _mintPayout) Version(1) {
        mintPayout = IMintPayout(_mintPayout);
    }

    /// @inheritdoc IConfigurable
    function updateConfiguration(bytes calldata args) external override {
        BasicMintConfiguration memory _config = abi.decode(args, (BasicMintConfiguration));

        _configurations[msg.sender] = _config;
        emit ConfigurationUpdated(msg.sender, _config);
    }

    /// @inheritdoc IBasicMintModule
    function configuration(address _contract) external view returns (BasicMintConfiguration memory) {
        return _configurations[_contract];
    }

    /// @inheritdoc IBasicMintModule
    function mint(address _contract, address _to, address _referrer, uint256 _quantity) external payable {
        _mint(_contract, _to, _referrer, _quantity);
    }

    /// @inheritdoc IBasicMintModule
    function mint_efficient_7e80c46e(address _contract, address _to, address _referrer, uint256 _quantity)
        external
        payable
    {
        _mint(_contract, _to, _referrer, _quantity);
    }

    /// @notice The implementation of the mint function.
    /// @dev This is implemented as an internal function to share the logic between the `mint` and `mint_efficient_7e80c46e` functions.
    /// See the documentation for those functions for information on the parameters.
    function _mint(address _contract, address _to, address _referrer, uint256 _quantity) internal {
        BasicMintConfiguration memory config = _configurations[_contract];

        if (_quantity == 0) revert InvalidQuantity();
        if (config.maxPerTransaction > 0 && _quantity > config.maxPerTransaction) revert TooManyTokensPerTransaction();

        if (config.maxPerWallet > 0) {
            if (_mintedByAddress[_contract][_to] + _quantity > config.maxPerWallet) {
                revert TooManyTokensPerCollector();
            }
        }

        if (config.maxForModule > 0 && mintedByContract[_contract] + _quantity > config.maxForModule) {
            revert TooManyTokensForModule();
        }

        if (block.timestamp < config.mintStart) revert MintNotStarted();
        if (config.mintEnd > 0 && block.timestamp > config.mintEnd) revert MintEnded();

        uint256 protocolFee = mintPayout.protocolFee();
        if (msg.value != (config.price + protocolFee) * _quantity) revert IncorrectPayment();

        if (config.maxSupply > 0 && IMintContract(_contract).totalMinted() + _quantity > config.maxSupply) {
            revert MaxSupplyReached();
        }

        _mintedByAddress[_contract][_to] += _quantity;
        mintedByContract[_contract] += _quantity;

        mintPayout.mintDeposit{value: msg.value}(_contract, msg.sender, _referrer, _quantity);
        IMintContract(_contract).mint(_to, _quantity);
    }
}
