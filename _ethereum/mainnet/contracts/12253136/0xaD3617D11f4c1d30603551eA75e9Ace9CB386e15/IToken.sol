interface IToken {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
}