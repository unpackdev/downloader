pragma solidity 0.7.6;

import "./SafeMathUpgradeable.sol";

contract APWineNaming {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice generate the symbol of the FYT
     * @param _index the index of the current period
     * @param _ibtSymbol the symbol of the IBT
     * @param _platform the platform name
     * @param _periodDuration the period duration
     * @return the symbol for the FYT
     * @dev i.e 30D-AAVE-ADAI-2
     */
    function genFYTSymbol(
        uint8 _index,
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) public pure returns (string memory) {
        return concatenate(genIBTSymbol(_ibtSymbol, _platform, _periodDuration), concatenate("-", uintToString(_index)));
    }

    /**
     * @notice generate the symbol from the apwIBT
     * @param _index the index of the current period
     * @param _ibtSymbol the symbol of the IBT
     * @return the symbol for the FYT
     * @dev i.e 30D-AAVE-ADAI-2
     */
    function genFYTSymbolFromIBT(uint8 _index, string memory _ibtSymbol) public pure returns (string memory) {
        return concatenate(_ibtSymbol, concatenate("-", uintToString(_index)));
    }

    /**
     * @notice generate the apwIBT symbol
     * @param _ibtSymbol the symbol of the IBT of the future
     * @param _platform the platform name
     * @param _periodDuration the period duration
     * @return the symbol for the apwIBT
     * @dev i.e 30D-AAVE-ADAI
     */
    function genIBTSymbol(
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) public pure returns (string memory) {
        return
            concatenate(
                getPeriodDurationDenominator(_periodDuration),
                concatenate("-", concatenate(_platform, concatenate("-", _ibtSymbol)))
            );
    }

    /**
     * @notice generate the period denominator
     * @param _periodDuration the period duration
     * @return the period denominator
     * @dev i.e 30D
     */
    function getPeriodDurationDenominator(uint256 _periodDuration) public pure returns (string memory) {
        if (_periodDuration >= 1 days) {
            uint256 numberOfdays = _periodDuration.div(1 days);
            return string(concatenate(uintToString(uint8(numberOfdays)), "D"));
        }
        return "CUSTOM";
    }

    function uintToString(uint8 v) public pure returns (string memory) {
        bytes memory reversed = new bytes(8);
        uint256 i = 0;
        if (v == 0) return "0";
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint256 j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        return string(s);
    }

    function concatenate(string memory a, string memory b) public pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}
