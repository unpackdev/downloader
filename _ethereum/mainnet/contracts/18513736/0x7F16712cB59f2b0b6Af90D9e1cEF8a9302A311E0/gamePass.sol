//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn (uint256 amount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}
contract gamePass is Ownable {
    mapping (address => uint256) public totalBurnedByUser;
    uint256 public totalBurnedSoFar;
    uint256 public minimumBurnAmount;
    IERC20  public token;
    
    event TokenBurned (address indexed user, uint256 indexed amount);
    constructor () {
        minimumBurnAmount = 100; // 100 tokens
    }

    function enterGame (uint256 amount) external {
        require(amount >= minimumBurnAmount, "amount is not enough");
        require(token.balanceOf(msg.sender) >= amount * 1e9, "Not enough balance");
        token.burn(amount * 1e9);
        totalBurnedByUser[msg.sender] = totalBurnedByUser[msg.sender] + amount;
        totalBurnedSoFar = totalBurnedSoFar + amount;
        emit TokenBurned (msg.sender, amount);
    }

    function setToken (IERC20 _token) external onlyOwner {
        token = _token;
    }

    function setMinimumBurnAmount (uint256 amount) external onlyOwner {
        minimumBurnAmount = amount;
    }
}