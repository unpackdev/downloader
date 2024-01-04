pragma solidity 0.6.12;

interface IERC20Simple {
    function transferFrom(
        address _from,
        address _to,
        uint256 amount
    ) external;

    function transfer(
        address _to,
        uint256 amount
    ) external;

    function balanceOf(address addr) external view returns (uint256);
}

contract Multisend {
    address public owner;
    address public source;
    constructor(address _source) public {
        owner = msg.sender;
        source = _source;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setSource(address _source) external onlyOwner {
        source = _source;
    }
    
    function withdraw(address _token) external onlyOwner {
        IERC20Simple token = IERC20Simple(_token);
        IERC20Simple(_token).transfer(owner, token.balanceOf(address(this)));
    }

    function multisend(address _token, address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        IERC20Simple token = IERC20Simple(_token);
        require(_addresses.length == _amounts.length);
        for(uint i = 0; i < _addresses.length; i++) {
            token.transferFrom(source, _addresses[i], _amounts[i]);
        }
    }
}