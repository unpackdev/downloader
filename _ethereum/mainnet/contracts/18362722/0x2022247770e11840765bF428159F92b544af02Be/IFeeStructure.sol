interface IFeeStructure {
    function calculateFee(
        uint256 wage,
        uint256 feePercent
    ) external view returns (uint256, uint256);

    function calculateDisputeFee(uint256 wage) external view returns (uint256);
}
