interface IOven  {
    function getValues(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue);
    function otcOffer(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue, uint256 vestTime);
    function updatePrice(address token) external;
}
