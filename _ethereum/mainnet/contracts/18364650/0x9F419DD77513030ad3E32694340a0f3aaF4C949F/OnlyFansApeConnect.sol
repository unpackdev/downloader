// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract owned {
    address payable public owner;
    address payable internal newOwner;

    constructor()  {
        owner = payable ( msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        //emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = payable(address(0));
    }
}

contract ReentrancyGuard {
    uint256 private _status = 1;

    modifier nonReentrant() {
        require(_status == 1, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }
}

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


contract OnlyFansApeConnect is owned,ReentrancyGuard {
    struct Item {
        bytes32 itemCodeHash; // Store the hash of the item code
        bytes32 itemName;
        uint256 price;
        address itemOwner;
        mapping(address=>bool)  userInfo;
    }

   


    mapping(address=>uint) public  balance;
    mapping(uint256 => Item) public items;
    
    uint256 public itemCount;


    address payable public address1 = payable(0x0Dc64D5826C9137721696583D8f889806c45b850); // 3% share buyback
    address payable public address2 = payable(0x7DF7f1D897A011f4487c7BD453E6dD1777b3E28F); // 2% share revenue
    address payable public address3 = payable(0x32Fb293035490aA343a4c95c32B1CAe45aEAd69d); // 5% share development
    uint public itemFee = 10;


    event setAnItem(uint256 indexed itemId, bytes32 itemCode, bytes32 itemName, uint256 price,address _sender); 
    event boughtAnItem(address indexed  user,uint itemId);
    event Withdraw(address indexed  user,uint indexed amount);
    constructor() {
        itemCount = 0;
    }

    function listItem(bytes32 _itemCode, bytes32 _itemName, uint256 _price) public nonReentrant returns (uint itemId) {
        itemCount++;
        bytes32 itemCodeHash = _itemCode; // Hash the item code
        items[itemCount].itemCodeHash = itemCodeHash;
        items[itemCount].itemName = _itemName;
        items[itemCount].price = _price;
        items[itemCount].itemOwner = msg.sender;
        emit setAnItem(itemCount, _itemCode, _itemName, _price,msg.sender);
        return itemCount;
    }

    function getItem(uint256 _itemId) public view returns ( bytes32,bytes32, uint256 ,address) {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        Item storage item = items[_itemId];
        return (item.itemCodeHash, item.itemName, item.price,item.itemOwner);
    }



    function payitem (uint itemId) public  payable  returns (bool success, bytes32 itemName,uint256 price,address itemOwner) {
     require(msg.value >= items[itemId].price,"not enough balance to pay");
     require(msg.sender != items[itemId].itemOwner,"You cannot buy your own item");
     require(items[itemId].userInfo[msg.sender ] == false, "You already bought this item");

     // Calculate the 10% of the received Ether
     uint256 totalAmount = (msg.value * itemFee) / 100;


    // Calculate the individual shares
     uint256 share1 = (totalAmount * 3) / itemFee;
     uint256 share2 = (totalAmount * 2) / itemFee;
     uint256 share3 = (totalAmount * 5) / itemFee;

     balance[address1] += share1;
     balance[address2] += share2;
     balance[address3] += share3;
     balance[items[itemId].itemOwner] += (msg.value - totalAmount);
     items[itemId].userInfo[msg.sender] = true;

     emit boughtAnItem(msg.sender,itemId);
     return  (true,items[itemId].itemName,items[itemId].price,items[itemId].itemOwner);
    }

    function getUserItemInfo (address _user,uint itemId) public view returns  (bool status)  {
        return (items[itemId].userInfo[_user]);
    }

    function withdraw () public nonReentrant {
        require(balance[msg.sender] > 0,"you do not enough balance to withdraw");
        address payable to = payable(msg.sender);
        to.transfer( balance[msg.sender]);
        emit Withdraw(msg.sender,balance[msg.sender]);
        balance[msg.sender] = 0;
    }
    
    function withdraw(uint amount ) public nonReentrant {
        require(balance[msg.sender] >= amount,"you do not enough balance to withdraw");
        address payable to = payable(msg.sender);
        to.transfer( amount);
        emit Withdraw(msg.sender,amount);
        balance[msg.sender] -= amount;

    }

    function changeFeeWallets(address _address1,address _address2,address _address3) external onlyOwner {
        address1 = payable(_address1);
        address2 = payable(_address2);
        address3 = payable(_address3);
    }


    function changeItemFee(uint8 _itemFee) external onlyOwner {
        itemFee = _itemFee;
    }

    function sendBalance() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "No balance to recover");
        owner.transfer(bal);
    }

    function sendTokens(address tokenAddress, uint256 amount,address to) public onlyOwner returns (bool success) {
        bool valid = IERC20(tokenAddress).transfer(to, amount);
        return valid;
    }
}