pragma solidity 0.7.6;

import "./SafeMathUpgradeable.sol";

contract APWineMaths {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice scale an input
     * @param _actualValue the original value of the input
     * @param _initialSum the scaled value of the sum of the inputs
     * @param _actualSum the current value of the sum of the inputs
     */
    function getScaledInput(
        uint256 _actualValue,
        uint256 _initialSum,
        uint256 _actualSum
    ) public pure returns (uint256) {
        if (_initialSum == 0) return _actualValue;
        require(_actualSum > 0, "The actual value of the sum should not be zero");
        return
            ((_actualValue.mul(_actualValue).mul(_initialSum)).add(_actualValue.mul(_initialSum).mul(_actualSum))).div(
                (_actualValue.mul(_actualSum)).add(_actualSum.mul(_actualSum))
            );
    }

    /**
     * @notice scale back a value to the output
     * @param _scaledOutput the current scaled output
     * @param _initialSum the scaled value of the sum of the inputs
     * @param _actualSum the current value of the sum of the inputs
     */
    function getActualOutput(
        uint256 _scaledOutput,
        uint256 _initialSum,
        uint256 _actualSum
    ) public pure returns (uint256) {
        if (_initialSum == 0 || _actualSum == 0) return 0;
        return (_scaledOutput.mul(_actualSum)).div(_initialSum);
    }
}
