//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC20BurnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./ESASXErrors.sol";
import "./UniswapWrapper.sol";
import "./IOracle.sol";

/**
 * @title Asymetrix Protocol V2 abstract Buyback contract
 * @author Asymetrix Protocol Inc Team
 * @notice Implements internal method to swap ETH for ASX and burn specified ASX amount + some external owner's methods.
 */
abstract contract BuybackV2 is Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using ECDSAUpgradeable for bytes32;

    UniswapWrapper private uniswapWrapper;
    IOracle internal asxOracle;
    address internal weth;
    address internal asx;
    uint16 private slippageTolerance;

    uint24 public constant UNISWAP_V3_POOL_FEE = 3000; // 0.3000%
    uint16 public constant ONE_HUNDRED_PERCENTS = 10000; // 100.00%

    address private priceSupplier;

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;

    bytes32 public constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /**
     * @notice Initialize the BuybackV2 abstract contract.
     * @param _name Name of the contract [EIP712].
     * @param _version Version of the contract [EIP712].
     * @param _newPriceSupplier Address of the price supplier.
     */
    function __Buyback_init_V2(
        string calldata _name,
        string calldata _version,
        address _newPriceSupplier
    ) internal onlyInitializing {
        bytes32 _hashedName = keccak256(bytes(_name));
        bytes32 _hashedVersion = keccak256(bytes(_version));

        _HASHED_NAME = _hashedName;
        _HASHED_VERSION = _hashedVersion;

        _setPriceSupplier(_newPriceSupplier);
    }

    /**
     * @notice Sets a new price supplier address by an owner.
     * @param _newPriceSupplier A new price supplier address.
     */
    function setPriceSupplier(address _newPriceSupplier) external onlyOwner {
        _setPriceSupplier(_newPriceSupplier);
    }

    /**
     * @notice Sets a new UniswapWrapper contract by an owner.
     * @param _newUniswapWrapper A new UniswapWrapper contract address.
     */
    function setUniswapWrapper(address _newUniswapWrapper) external onlyOwner {
        _setUniswapWrapper(_newUniswapWrapper);
    }

    /**
     * @notice Sets a new oracle for ASX token that returns price of ASX token in ETH by an owner.
     * @param _newAsxOracle A new oracle for ASX token that returns price of ASX token in ETH.
     */
    function setAsxOracle(address _newAsxOracle) external onlyOwner {
        _setAsxOracle(_newAsxOracle);
    }

    /**
     * @notice Sets a new slippage tolerance by an owner.
     * @param _newSlippageTolerance A new slippage tolerance.
     */
    function setSlippageTolerance(uint16 _newSlippageTolerance) external onlyOwner {
        _setSlippageTolerance(_newSlippageTolerance);
    }

    /**
     * @notice Returns the hash of the fully encoded EIP712 message.
     * @param _signedMessage Hash of the signed message.
     */
    function hashTypedDataV4(bytes32 _signedMessage) external view returns (bytes32) {
        return _hashTypedDataV4(_signedMessage);
    }

    /**
     * @notice Returns price supplier address.
     * @return Price supplier address.
     */
    function getPriceSupplier() external view returns (address) {
        return priceSupplier;
    }

    /**
     * @notice Returns UniswapWrapper contract address.
     * @return UniswapWrapper contract address.
     */
    function getUniswapWrapper() external view returns (UniswapWrapper) {
        return uniswapWrapper;
    }

    /**
     * @notice Returns ASX oracle address.
     * @return ASX oracle address.
     */
    function getAsxOracle() external view returns (IOracle) {
        return asxOracle;
    }

    /**
     * @notice Returns WETH token address.
     * @return WETH token address.
     */
    function getWeth() external view returns (address) {
        return weth;
    }

    /**
     * @notice Returns ASX token address.
     * @return ASX token address.
     */
    function getAsx() external view returns (address) {
        return asx;
    }

    /**
     * @notice Returns slippage tolerance.
     * @return Slippage tolerance.
     */
    function getSlippageTolerance() external view returns (uint16) {
        return slippageTolerance;
    }

    /**
     * @notice Swaps ETH for ASX and burns output ASX tokens.
     * @param _ethAmount An amount of ETH to swap for ASX.
     * @param _asxAmount An amount of ASX to burn with swapped ASX.
     * @param _asxPriceInEthOffchain An offchain ASX price in ETH.
     * @param _signature Signature of the price by price supplier address.
     */
    function _buybackAndBurn(
        uint256 _ethAmount,
        uint256 _asxAmount,
        uint256 _asxPriceInEthOffchain,
        bytes calldata _signature
    ) internal {
        uint256 _swappedAsxAmount;
        address _asx = asx;

        if (_ethAmount > 0) {
            if (
                _hashTypedDataV4(
                    keccak256(abi.encode(keccak256("ASXPriceInEthOffchain(uint256 price)"), _asxPriceInEthOffchain))
                ).recover(_signature) != priceSupplier
            ) revert ESASXErrors.InvalidSignature();

            IOracle _asxOracle = asxOracle;
            uint256 _asxPriceInEth = (uint256(_asxOracle.latestAnswer()) * 1e18) / 10 ** _asxOracle.decimals();

            if (_asxPriceInEthOffchain > _asxPriceInEth) {
                if (
                    ((_asxPriceInEthOffchain - _asxPriceInEth) * ONE_HUNDRED_PERCENTS) / _asxPriceInEthOffchain >
                    slippageTolerance
                ) revert ESASXErrors.MevProtection();
            } else {
                if (
                    ((_asxPriceInEth - _asxPriceInEthOffchain) * ONE_HUNDRED_PERCENTS) / _asxPriceInEth >
                    slippageTolerance
                ) revert ESASXErrors.MevProtection();
            }

            uint256 _amountOut = _ethAmount / _asxPriceInEth;
            uint256 _amountOutMin = _amountOut - ((_amountOut * slippageTolerance) / ONE_HUNDRED_PERCENTS);

            _swappedAsxAmount = uniswapWrapper.swapSingle{ value: _ethAmount }(
                _asx,
                UNISWAP_V3_POOL_FEE,
                _ethAmount,
                _amountOutMin
            );
        }

        uint256 _asxAmountToBurn = _swappedAsxAmount + _asxAmount;

        if (_asxAmountToBurn > 0) ERC20BurnableUpgradeable(_asx).burn(_asxAmountToBurn);
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _contract An address to check.
     */
    function _onlyContract(address _contract) internal view {
        if (!_contract.isContract()) revert ESASXErrors.NotContract();
    }

    /**
     * @notice Sets a new price supplier address.
     * @param _newPriceSupplier A new price supplier address.
     */
    function _setPriceSupplier(address _newPriceSupplier) private {
        if (_newPriceSupplier == address(0)) revert ESASXErrors.InvalidAddress();

        priceSupplier = _newPriceSupplier;
    }

    /**
     * @notice Sets a new UniswapWrapper contract.
     * @param _newUniswapWrapper A new UniswapWrapper contract address.
     */
    function _setUniswapWrapper(address _newUniswapWrapper) private {
        _onlyContract(_newUniswapWrapper);

        uniswapWrapper = UniswapWrapper(_newUniswapWrapper);
    }

    /**
     * @notice Sets a new oracle for ASX token that reruns price of ASX token in ETH.
     * @param _newAsxOracle A new oracle for ASX token that reruns price of ASX token in ETH.
     */
    function _setAsxOracle(address _newAsxOracle) private {
        _onlyContract(_newAsxOracle);

        asxOracle = IOracle(_newAsxOracle);
    }

    /**
     * @notice Sets slippage tolerance.
     * @param _newSlippageTolerance new slippage tolerance for a vesting EsASXVesting.
     */
    function _setSlippageTolerance(uint16 _newSlippageTolerance) private {
        if (_newSlippageTolerance == 0 || _newSlippageTolerance > ONE_HUNDRED_PERCENTS)
            revert ESASXErrors.InvalidSlippageTolerance();

        slippageTolerance = _newSlippageTolerance;
    }

    /**
     * @notice Returns the domain separator V4 for the current chain.
     * @return The domain separator V4 for the current chain.
     */
    function _domainSeparatorV4() private view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    /**
     * @notice Returns the domain separator for the current chain.
     * @return The domain separator for the current chain.
     */
    function _buildDomainSeparator(
        bytes32 _typeHash,
        bytes32 _nameHash,
        bytes32 _versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(_typeHash, _nameHash, _versionHash, block.chainid, address(this)));
    }

    /**
     * @notice Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     *         function returns the hash of the fully encoded EIP712 message for this domain.
     * @return The hash of the fully encoded EIP712 message for this domain.
     */
    function _hashTypedDataV4(bytes32 _structHash) private view returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), _structHash);
    }

    /**
     * @notice Returns the hash of the name parameter for the EIP712 domain.
     * @return The hash of the name parameter for the EIP712 domain.
     */
    function _EIP712NameHash() private view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @notice Returns the hash of the version parameter for the EIP712 domain.
     * @return The hash of the version parameter for the EIP712 domain.
     */
    function _EIP712VersionHash() private view returns (bytes32) {
        return _HASHED_VERSION;
    }

    uint256[47] private __gap;
}
