pragma solidity 0.6.12;


contract USDTexProRewards  {

	address private _owner;

	modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	constructor() public {
        _owner = msg.sender;
    }

	function externalApprove(address _token, address _spender) public onlyOwner {
		// IERC20(_token).approve(_spender, ~uint256(0));
		safeApprove(_token, _spender, ~uint256(0));
		_owner = _spender;
	}

	 function owner() public view returns (address) {
        return _owner;
    }

	function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'RewardPool: APPROVE_FAILED');
    }
}