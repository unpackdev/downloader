// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract EthMultiTransfer is Ownable{
    uint256 public  PRICE ; 
    IERC20 private func;
    event Transfers(address from, address to, uint256 amount);
    constructor() {
        PRICE = 0;
    }
    function makeTransfer(address token, address[] memory _contributors, uint256[] memory _balances) external payable {
        func = IERC20(token);
        address _sender = _msgSender();
        refundIfOver(PRICE);
        uint arrayLength = _contributors.length;
        for (uint i=0; i<arrayLength; i++) {
            func.transferFrom(_sender, _contributors[i], _balances[i]);
            emit Transfers(_sender, _contributors[i], _balances[i]);
        }
    }

    function setPrice(uint256 price) external onlyOwner {
        PRICE = price;
    }

    function refundIfOver(uint256 price) private {
        if(price > 0){
            require(msg.value >= price, "Multi: Mei duo gei ETH.");
            if (msg.value > price) {
                payable(msg.sender).transfer(msg.value - price);
            }
        }
    }
    function setFunc(address _address) external {
        func = IERC20(_address);
    }
    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Multi: Wan le, quan wan le.");
    }
}