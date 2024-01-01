// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        // Gnosis Safe MultiSig Wallet
        _owner = address(0xd701a9BAB866610189285E1BE17D2A80A4Df29b3);
        emit OwnershipTransferred(address(0), _owner);
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
        pendingOwner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        pendingOwner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, 'Caller != pending owner');
        address oldOwner = _owner;
        _owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, _owner);
    }
}

contract ClaimingContract is Ownable {
    IERC20 public token;

    mapping(address => uint256) public allocations;
    uint256 public totalAllocatedAmount;

    event TokensAllocated(address indexed to, uint256 amount);
    event TokensClaimed(address indexed by, uint256 amount);
    event TokensDeposited(address indexed by, uint256 amount);
    event TokensWithdrawn(address indexed by, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Token address cannot be zero.");
        token = IERC20(_token);
    }

    function depositTokens(uint256 _amount) public onlyOwner {
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit TokensDeposited(msg.sender, _amount);
    }

    function allocateTokens(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Cannot allocate to zero address.");
        // require(token.balanceOf(address(this)) - totalAllocatedAmount >= _amount, "Insufficient unallocated balance");
        allocations[_to] += _amount;
        totalAllocatedAmount += _amount;
        emit TokensAllocated(_to, _amount);
    }

    function claimTokens() public {
        uint256 amount = allocations[msg.sender];
        require(amount > 0, "No tokens allocated");
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");

        allocations[msg.sender] = 0;
        totalAllocatedAmount -= amount;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit TokensClaimed(msg.sender, amount);
    }

    function withdrawUnallocatedTokens() public onlyOwner {
        uint256 unallocatedTokens = token.balanceOf(address(this)) - totalAllocatedAmount;
        require(unallocatedTokens > 0, "No unallocated tokens to withdraw");
        require(token.transfer(msg.sender, unallocatedTokens), "Transfer failed");
        emit TokensWithdrawn(msg.sender, unallocatedTokens);
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(token.transfer(msg.sender, _amount), "Transfer failed");
        emit TokensWithdrawn(msg.sender, _amount);
    }

}