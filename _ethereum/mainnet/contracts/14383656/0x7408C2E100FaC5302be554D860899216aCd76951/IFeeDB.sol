pragma solidity >=0.5.6;

interface IFeeDB {
    event UpdateFeeAndRecipient(uint256 newFee, address newRecipient);
    event UpdatePaysFeeWhenSending(bool newType);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function paysFeeWhenSending() external view returns (bool);

    function userDiscountRate(address user) external view returns (uint256);

    function userFee(address user, uint256 amount) external view returns (uint256);
}
