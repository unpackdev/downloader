// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract Ownable{
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Btcmeme is Ownable {
    IERC20 public memeToken= IERC20(0x5441765d3Ab74E0347Df52FFAB5A69e5146B5D26);
   
    mapping(uint => address) public userAdr;
    mapping(uint => uint) public userTime;
    mapping(uint => uint) public userSend;

    uint public ids = 1;

    event SetPledge (address indexed sender, uint  num, uint pledgeTime,uint id );
    event GetPledge (address indexed sender, uint  num, uint getTime,uint id );
    constructor() {}
    function setMemeToken(address _adr) external onlyOwner{
        memeToken = IERC20(_adr);
    }

    function pledge(uint num) external{
        require(num > 0,"num must be greater than 0");

        memeToken.transferFrom(msg.sender, address(this),num);
        userAdr[ids] = msg.sender;
        userTime[ids] = block.timestamp + 300;
        userSend[ids] = num;
        emit SetPledge(msg.sender, num ,block.timestamp,ids);
        ids += 1;
    }
   

    function withdrawal(uint _id) external {
        require(_id <= ids,"id is error");
        require(userAdr[_id] == msg.sender,"it's not yours");
        require(userTime[_id] < block.timestamp ,"unexpired");
        require(userSend[_id] > 0 ,"extracted");

        memeToken.transfer(msg.sender, userSend[_id]);
        emit GetPledge(msg.sender, userSend[_id] ,userTime[_id],_id);
        delete userAdr[_id];
        delete userTime[_id];
        delete userSend[_id];
        
    }

}