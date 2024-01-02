pragma solidity >=0.6.6;

interface IDropBase {
    event Deposit(address indexed token, address indexed sender, uint256 tokenAmount, uint256 usdAmount);
    event FinAddressTransferred(address indexed previousFinAddress, address indexed newFinAddress);
    event SetTokenInfo(
        address indexed token,
        uint256 maxAmount,
        uint256 minAmountEachDeposit,
        uint256 maxAmountEachDeposit,
        uint256 usdPrice,
        uint256 bakePowerPrice
    );

    function setTokenInfo(
        address _token,
        uint256 _maxAmount,
        uint256 _minAmountEachDeposit,
        uint256 _maxAmountEachDeposit,
        uint256 _usdPrice,
        uint256 _bakePowerPrice
    ) external;

    function getRemainDropAmount(address _token, address _user) external view returns (uint256);

    function deposit(address _token, uint256 _amount) external payable returns (uint256 amount, uint256 ethAmount);

    function transferDropFinAddress(address _finAddr) external;
}
