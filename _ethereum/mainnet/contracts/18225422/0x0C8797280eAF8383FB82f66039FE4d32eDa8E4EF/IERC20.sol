interface IERC20{
    function balanceOf(address) external view returns(uint256);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function approve(address, uint256) external;
    function totalSupply() external view returns(uint256);
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);

    function withdraw(uint256) external;
    function deposit() external payable;
}

interface _IERC20 is IERC20{}