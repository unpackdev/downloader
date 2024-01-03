pragma solidity ^0.6.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
}

contract MultiTransferINJ {
    address owner;
    
    IERC20 inj;
    
    constructor (address _inj) public {
        owner = msg.sender;
        inj = IERC20(_inj);
    }
    
    function multiTransferINJ(
        address[] calldata to,
        uint256[] calldata amounts
    )
    external
    {
        require(msg.sender == owner);
        require(to.length == amounts.length);
        for(uint256 i = 0; i < to.length; i++) {
            inj.transfer(to[i], amounts[i]);
        }
    }
    
    function returnINJ() external {
        require(msg.sender == owner);
        inj.transfer(msg.sender, inj.balanceOf(address(this)));
    }
    
    function changeINJ(address _inj) external {
        require(msg.sender == owner);
        inj = IERC20(_inj);
    }
    
    function changeOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }
}