pragma solidity 0.6.6;

interface ICToken {
    function mint(uint256 _mintAmount) external returns (uint256);
    function redeem(uint256 _redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 _amountUnderlying) external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function exchangeRateCurrent() external view returns (uint256);
    function balanceOfUnderlying(address _account) external returns (uint256);
    function underlying() external view returns(address);
    function supplyRatePerBlock() external view returns(uint256);

    // ERC20 Methods
    function totalSupply() external view returns(uint256);
    function balanceOf(address _of) external view returns(uint256);
    function transfer(address _to, uint256 _amount) external view returns(bool);
    function transferFrom(address _from, address _to, uint256 _amount) external view returns(bool);
}