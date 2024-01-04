pragma solidity 0.7.6;

interface IAPWineNaming {
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
    ) external pure returns (string memory);

    /**
     * @notice generate the FYT symbol from the apwIBT
     * @param _index the index of the current period
     * @param _ibtSymbol the symbol of the IBT
     * @return the symbol for the FYT
     * @dev i.e 30D-AAVE-ADAI-2
     */
    function genFYTSymbolFromIBT(uint8 _index, string memory _ibtSymbol) external pure returns (string memory);

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
    ) external pure returns (string memory);

    /**
     * @notice generate the period denominator
     * @param _periodDuration the period duration
     * @return the period denominator
     * @dev i.e 30D
     */
    function getPeriodDurationDenominator(uint256 _periodDuration) external pure returns (string memory);
}
