// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract LlamaDropper {

    address public owner;
    mapping (address => bool) public isAuthorized;

    constructor() {
	    owner = msg.sender;
	    isAuthorized[msg.sender] = true;
    }

    modifier onlyOwner {
	    require(msg.sender == owner, "Caller not Owner");
	    _;
    }

    modifier onlyAuth {
	    require(isAuthorized[msg.sender], "Caller not authorized");
	    _;
    }

    function massDistributeTokens(address _token, uint _decimals, address[] calldata _airdropAddresses, uint _amtPerAddress) external onlyAuth {
        uint amtPerAddress = _amtPerAddress * (10 ** _decimals);
	    for (uint i = 0; i < _airdropAddresses.length; i++) {
	        IERC20(_token).transfer(_airdropAddresses[i], amtPerAddress);
        }
    }

    function distributeTokensByAmount(address _token, uint _decimals, address[] calldata _airdropAddresses, uint[] calldata _airdropAmounts) external onlyAuth {
	    for (uint i = 0; i < _airdropAddresses.length; i++) {
            uint airdropAmount = _airdropAmounts[i] * (10 ** _decimals);
	        IERC20(_token).transfer(_airdropAddresses[i], airdropAmount);
        }
    }

    function updateAuthorized(address _authAddress, bool _isAuth) external onlyOwner {
	    isAuthorized[_authAddress] = _isAuth;
    }

    function clearStuckTokens(address contractAddress) external onlyOwner {
        IERC20 erc20Token = IERC20(contractAddress);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(msg.sender, balance);
    }

}