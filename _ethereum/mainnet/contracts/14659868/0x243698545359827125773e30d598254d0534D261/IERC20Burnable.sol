interface IERC20Burnable {
	function burn(uint256 _amount) external;

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}
