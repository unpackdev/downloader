//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC20BurnableUpgradeable.sol";
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
abstract contract Buyback is Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;

    UniswapWrapper private uniswapWrapper;
    IOracle internal asxOracle;
    address internal weth;
    address internal asx;
    uint16 private slippageTolerance;

    uint24 public constant UNISWAP_V3_POOL_FEE = 3000; // 0.3000%
    uint16 public constant ONE_HUNDRED_PERCENTS = 10000; // 100.00%

    /**
     * @notice Initialize the Buyback abstract contract.
     * @param _uniswapWrapper A wrapper contract address that helps to interact with Uniswap V3.
     * @param _asxOracle An oracle for ASX token that returns price of ASX token in ETH.
     * @param _weth WETH token address.
     * @param _asx ASX token address.
     * @param _slippageTolerance A slippage tolerance to apply in time of swap of ETH for ASX.
     */
    function __Buyback_init(
        address _uniswapWrapper,
        address _asxOracle,
        address _weth,
        address _asx,
        uint16 _slippageTolerance
    ) internal onlyInitializing {
        __Ownable_init();

        _setUniswapWrapper(_uniswapWrapper);
        _setAsxOracle(_asxOracle);
        _onlyContract(_weth);
        _onlyContract(_asx);

        weth = _weth;
        asx = _asx;

        _setSlippageTolerance(_slippageTolerance);
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
     */
    function _buybackAndBurn(uint256 _ethAmount, uint256 _asxAmount) internal {
        uint256 _swappedAsxAmount;
        address _asx = asx;

        if (_ethAmount > 0) {
            IOracle _asxOracle = asxOracle;
            uint256 _asxPriceInEth = (uint256(_asxOracle.latestAnswer()) * 1e18) / 10 ** _asxOracle.decimals();
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
     * @notice Checks if an address is a contract.
     * @param _contract An address to check.
     */
    function _onlyContract(address _contract) internal view {
        if (!_contract.isContract()) revert ESASXErrors.NotContract();
    }

    uint256[50] private __gap;
}
