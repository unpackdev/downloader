// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


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

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}


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

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract AURSale is Ownable{ 

    IERC20 public AUR;

    uint public minAmount = 1000000000000000;
    uint public price;
    bool public saleStatus;

    function sale(uint _amount) public payable  {
        require(_amount >= minAmount, "Amount must be more then minAmount");
        
        uint _count = _amount/minAmount;
        require(msg.value >= price * _count, "Not enough ETH");
        AUR.transfer(msg.sender, _amount);
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setAURAddress(IERC20 _aur) public onlyOwner {
        AUR = _aur;
    }

    function setMinAmount(uint _minAmount) public onlyOwner {
        minAmount = _minAmount;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function withdrawFromContract(uint amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}