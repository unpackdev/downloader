// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";

import "./SafeRatioMath.sol";
import "./Ownable.sol";
import "./IToken.sol";

/**
 * @title dForce's Liquid Stability Reserve Calculation Logic
 * @author dForce
 */
abstract contract LSRCalculator is Ownable {
    using SafeMath for uint256;
    using SafeRatioMath for uint256;

    /// @dev Address of liquid stability MSD peg reserve.
    address internal mpr_;

    /// @dev Amount of a MSD.
    uint256 internal msdDecimalScaler_;

    /// @dev Amount of a MPR.
    uint256 internal mprDecimalScaler_;

    /// @dev Max tax.
    uint256 internal constant maxTax_ = 1e18;

    /// @dev MSD tax in.
    uint256 internal taxIn_;

    /// @dev MSD tax out.
    uint256 internal taxOut_;

    /// @dev Emitted when `taxIn_` is changed.
    event SetTaxIn(uint256 oldTaxIn, uint256 taxIn);

    /// @dev Emitted when `taxOut_` is changed.
    event SetTaxOut(uint256 oldTaxOut, uint256 taxOut);

    /**
     * @dev Check the validity of the tax.
     */
    modifier checkTax(uint256 _tax) {
        require(_tax <= maxTax_, "checkTax: _tax > maxTax");
        _;
    }

    /**
     * @notice Initialize the MSD and MPR related data.
     * @param _msd MSD address.
     * @param _mpr MPR address.
     */
    function _initialize(address _msd, address _mpr) internal virtual {
        require(
            IToken(_mpr).decimals() > 0,
            "LSRCalculator: _mpr is not ERC20 contract"
        );

        mpr_ = _mpr;

        msdDecimalScaler_ = 10**uint256(IToken(address(_msd)).decimals());
        mprDecimalScaler_ = 10**uint256(IToken(_mpr).decimals());
    }

    /**
     * @dev Set up tax in.
     * @param _tax Tax in.
     */
    function _setTaxIn(uint256 _tax) external onlyOwner checkTax(_tax) {
        uint256 _oldtaxIn = taxIn_;
        require(
            _tax != _oldtaxIn,
            "_setTaxIn: Old and new tax cannot be the same."
        );
        taxIn_ = _tax;
        emit SetTaxIn(_oldtaxIn, _tax);
    }

    /**
     * @dev Set up tax out.
     * @param _tax Tax out.
     */
    function _setTaxOut(uint256 _tax) external onlyOwner checkTax(_tax) {
        uint256 _oldTaxOut = taxOut_;
        require(
            _tax != _oldTaxOut,
            "_setTaxOut: Old and new tax cannot be the same."
        );
        taxOut_ = _tax;
        emit SetTaxOut(_oldTaxOut, _tax);
    }

    /**
     * @dev When the decimal of the token is different, convert to the same decimal.
     * @param _amount The amount converted.
     * @param _decimalScalerIn Amount of token units converted.
     * @param _decimalScalerOut Amount of target token units.
     * @return The amount of conversion.
     */
    function _calculator(
        uint256 _amount,
        uint256 _decimalScalerIn,
        uint256 _decimalScalerOut
    ) internal pure returns (uint256) {
        return _amount.mul(_decimalScalerOut).div(_decimalScalerIn);
    }

    /**
     * @dev Get the amount of MSD that can be bought.
     * @param _amountIn Amount of spent tokens.
     * @return Amount of MSD that can be bought.
     */
    function _amountToBuy(uint256 _amountIn) internal view returns (uint256) {
        uint256 _msdAmount = _calculator(
            _amountIn,
            mprDecimalScaler_,
            msdDecimalScaler_
        );

        _msdAmount = _msdAmount.sub(_msdAmount.rmul(taxIn_));
        return _msdAmount;
    }

    /**
     * @dev Get the amount of tokens that can be bought.
     * @param _amountIn Amount of spent MSD.
     * @return Amount of tokens that can be bought.
     */
    function _amountToSell(uint256 _amountIn) internal view returns (uint256) {
        uint256 _msdAmount = _amountIn.sub(_amountIn.rmul(taxOut_));
        return _calculator(_msdAmount, msdDecimalScaler_, mprDecimalScaler_);
    }

    /**
     * @dev Get the amount of MSD that can be bought.
     * @param _amountIn Amount of spent tokens.
     * @return Amount of MSD that can be bought.
     */
    function getAmountToBuy(uint256 _amountIn) external view returns (uint256) {
        return _amountToBuy(_amountIn);
    }

    /**
     * @dev Get the amount of tokens that can be bought.
     * @param _amountIn Amount of spent MSD.
     * @return Amount of tokens that can be bought.
     */
    function getAmountToSell(uint256 _amountIn)
        external
        view
        returns (uint256)
    {
        return _amountToSell(_amountIn);
    }

    /**
     * @dev Address of liquid stability MSD peg reserve.
     */
    function mpr() external view returns (address) {
        return mpr_;
    }

    /**
     * @dev Amount of a MSD.
     */
    function msdDecimalScaler() external view returns (uint256) {
        return msdDecimalScaler_;
    }

    /**
     * @dev Amount of a MPR.
     */
    function mprDecimalScaler() external view returns (uint256) {
        return mprDecimalScaler_;
    }

    /**
     * @dev Buy msd tax.
     */
    function taxIn() external view returns (uint256) {
        return taxIn_;
    }

    /**
     * @dev Sell msd tax.
     */
    function taxOut() external view returns (uint256) {
        return taxOut_;
    }
}
