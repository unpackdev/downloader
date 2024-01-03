/*
  ____    __             __                                                                  __                   
/\  _`\ /\ \__         /\ \      __                      /'\_/`\  __                       /\ \__                
\ \,\L\_\ \ ,_\    __  \ \ \/'\ /\_\    ___      __     /\      \/\_\     __   _ __    __  \ \ ,_\   ___   _ __  
 \/_\__ \\ \ \/  /'__`\ \ \ , < \/\ \ /' _ `\  /'_ `\   \ \ \__\ \/\ \  /'_ `\/\`'__\/'__`\ \ \ \/  / __`\/\`'__\
   /\ \L\ \ \ \_/\ \L\.\_\ \ \\`\\ \ \/\ \/\ \/\ \L\ \   \ \ \_/\ \ \ \/\ \L\ \ \ \//\ \L\.\_\ \ \_/\ \L\ \ \ \/ 
   \ `\____\ \__\ \__/.\_\\ \_\ \_\ \_\ \_\ \_\ \____ \   \ \_\\ \_\ \_\ \____ \ \_\\ \__/.\_\\ \__\ \____/\ \_\ 
    \/_____/\/__/\/__/\/_/ \/_/\/_/\/_/\/_/\/_/\/___L\ \   \/_/ \/_/\/_/\/___L\ \/_/ \/__/\/_/ \/__/\/___/  \/_/ 
                                                 /\____/                  /\____/                                
                                                 \_/__/                   \_/__/                                  
*/
pragma solidity 0.5.12;

interface IERC20{
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}

interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function burn(address to) external returns (uint amount0, uint amount1);
}

interface IBPool{
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)external;
    function getSwapFee()external view returns (uint);
    function getCurrentTokens()external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token)external view returns (uint);
    function setController(address manager)external;
}

interface IMAction {
    function create(address MFactory, address[] calldata tokens, uint[] calldata balances, uint[] calldata denorms,uint swapFee, uint initLpSupply, bool finalize) external returns (IBPool pool);
}

contract Migrator {
   
    address public lpStaking;   /* staking address */
    address public controller;  /* controller address */
    address public MFactory;    /* factory address */
    
    uint256 public notBeforeBlock; /* blockLimted */
    uint256 private UNI_SWAPFEE = 0.003 * 10 ** 18; /* uni swapFee 3/1000 */
    uint256 private UNI_DENORM = 10 ** 18;  /* uni denorm 3/1000 */
    bool private FINALIZE = true;

    IMAction public action;
    mapping(address => bool) public isBpool;

    constructor(
        address _lpStaking,
        address _controller,
        address _MFactory,
        IMAction  _action,
        uint256 _notBeforeBlock
    ) public {
        lpStaking = _lpStaking;
        controller = _controller;
        MFactory = _MFactory;
        notBeforeBlock = _notBeforeBlock;
        action = _action;
    }

    function migrate(IERC20 lp) public returns (IERC20 pool){
   
        require(msg.sender == lpStaking, "not from lpStaking");/* only staking call */
        require(block.number >= notBeforeBlock, "too early to migrate");
        require(lp.balanceOf(msg.sender) > 0,"have no balance for migrate");
        
        address lpAddress = address(lp);

        if(!isBpool[lpAddress]){
           
           uint256 swapFee = UNI_SWAPFEE;
           (address[] memory tokens, uint[] memory balances, uint[] memory denorms,uint initLpSupply) = _migrateUniLp(lpAddress); 

            IBPool bPool = action.create(MFactory, tokens, balances, denorms, swapFee, initLpSupply,FINALIZE);

            bPool.setController(controller);

            pool = IERC20(address(bPool));
        
            require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");

        }else{    
            uint256 swapFee = IBPool(lpAddress).getSwapFee();
            
           (address[] memory tokens, uint[] memory balances, uint[] memory denorms, uint initLpSupply) = _migrateBLp(lpAddress);
           
           IBPool bPool =  action.create(MFactory, tokens, balances, denorms, swapFee, initLpSupply,FINALIZE);

           bPool.setController(controller);

           pool = IERC20(address(bPool)); 

           require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        }

    }
    
    function _migrateUniLp(address _uniLpAddress) internal returns(address[] memory,uint256[] memory,uint256[] memory, uint256) {
        IUniswapV2Pair uniLp = IUniswapV2Pair(_uniLpAddress);
    
        address[] memory tokens = new address[](2);/* uniswap tokens length is  2 */
        uint256[] memory balances = new uint256[](2);
        uint256[] memory denorms = new uint256[](2);

        tokens[0] = uniLp.token0();
        tokens[1] = uniLp.token1();

        uint256 lpAmount = uniLp.balanceOf(msg.sender);
        uniLp.transferFrom(msg.sender, address(uniLp), lpAmount);
        uniLp.burn(address(this));

        for(uint256 i = 0; i < tokens.length; i++){
             uint256 value = IERC20(tokens[i]).balanceOf(address(this)); 
             IERC20(tokens[i]).approve(address(action),value);
             balances[i] = value;
             denorms[i] = UNI_DENORM;      
        }
        
        return(tokens,balances,denorms,lpAmount); 
    }

    function _migrateBLp(address _bLpAddress) internal returns(address[] memory,uint256[] memory,uint256[] memory, uint256){
        
        IBPool bLp = IBPool(_bLpAddress);

        address[] memory tokens = bLp.getCurrentTokens();

        uint256 len = tokens.length;

        uint256[] memory balances = new uint256[](len);

        uint256[] memory denorms = new uint256[](len);
        
        uint256[] memory minAmountOut = new uint256[](len);

        uint256 lpAmount = bLp.balanceOf(msg.sender);

        bLp.transferFrom(msg.sender,address(this),lpAmount);
        
        bLp.exitPool(lpAmount,minAmountOut);

        for(uint256 i = 0; i < len; i++){
             uint256 value = IERC20(tokens[i]).balanceOf(address(this));
            
             IERC20(tokens[i]).approve(address(action),value);/* token approve address(this) => address(action) value*/
             balances[i] = value;
             denorms[i] =  bLp.getDenormalizedWeight(tokens[i]);      
        }

        return(tokens,balances,denorms,lpAmount);      
    }

    function setBPool(address bLp, bool isBLp) public {
        require(msg.sender == controller,"not controller call");
        isBpool[bLp] = isBLp;
    }
}