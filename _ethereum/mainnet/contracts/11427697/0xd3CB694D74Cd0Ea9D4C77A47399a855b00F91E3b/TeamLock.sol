pragma solidity 0.6.12;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TeamLock {
    uint256 public unlockAt;
    address public owner;

    constructor() public {
        owner = msg.sender;
        unlockAt = now + 365 days;
    }

    function withdraw(address _token) external {
        require(msg.sender == owner, "Lock: Permission Denied");
        require(now > unlockAt, "Lock: Tokens are still locked");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, amount);
    }

}