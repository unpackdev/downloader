pragma solidity 0.7.3;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function harvest(uint256 _denom, address sender) external;
    function depositArbCheck() external view returns(bool);
}
