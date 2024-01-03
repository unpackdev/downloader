pragma solidity =0.6.6;
interface INewSageRouterFactory{
    function creatNewSageRouter(address _uniswapV2Router02Address,
        address _WETHAddress,
        address _DETOAddress,
        address _uniswapV2PairAddress,
        address _factoryAddress,
        uint256 _threshold,
        address _ownerAddress)
       external   returns(address);
}
interface ISmartMatrixNewsageFactory{
    function creatSmartMatrixNewsage(address ownerAddress,address routerAddress)
      external    returns(address);
}
interface IDETORole {
    function upRoleMinter(address minter) external;
    function upRoleBurner(address burner) external;
}
contract Factory  {
    INewSageRouterFactory public  NewSageRouterFactory ;
    ISmartMatrixNewsageFactory public  SmartMatrixNewsageFactory ;
     address public uniswapV2Router02Address;
     address public WETHAddress;
     address public DETOAddress;
     address public uniswapV2PairAddress;
    uint256 public lastId ;
    IDETORole public DETO;
    address public owner;
    struct Game {
        uint256 id;
        address NewSageRouterAddress;
        address SmartMatrixNewsageAddress;
        address ownerAddress;
        bool isStart;
    }
    mapping(uint256 => Game) public Games;
     constructor(
        address _NewSageRouterFactoryAddress,
        address _SmartMatrixNewsageFactoryAddress,
        address _uniswapV2Router02Address,
        address _WETHAddress,
        address _DETOAddress,
        address _uniswapV2PairAddress,
        address _ownerAddress
     ) public  {
         owner=_ownerAddress;
        NewSageRouterFactory= INewSageRouterFactory(_NewSageRouterFactoryAddress);
        SmartMatrixNewsageFactory= ISmartMatrixNewsageFactory(_SmartMatrixNewsageFactoryAddress);
         DETO = IDETORole(_DETOAddress);
         lastId = 0;
        uniswapV2Router02Address=_uniswapV2Router02Address;
        WETHAddress=_WETHAddress;
        DETOAddress=_DETOAddress;
        uniswapV2PairAddress=_uniswapV2PairAddress;
    }
    function startGame()public {
        require(lastId>0, "Factory: lastId>0");
        require(!Games[lastId-1].isStart, "Factory: !Games[lastId-1].isStart");
        require(Games[lastId-1].SmartMatrixNewsageAddress==address(0), "Factory: Games[lastId-1].SmartMatrixNewsageAddress==address(0)");
        Games[lastId-1].SmartMatrixNewsageAddress = SmartMatrixNewsageFactory.creatSmartMatrixNewsage(Games[lastId-1].ownerAddress,Games[lastId-1].NewSageRouterAddress);
        Games[lastId-1].isStart=true;


    }
    function init(uint256 _threshold)public{
        require(lastId==0, "Factory: lastId==0");
            address NewSageRouterAddress=NewSageRouterFactory.creatNewSageRouter(uniswapV2Router02Address,WETHAddress,DETOAddress,uniswapV2PairAddress,address(this),_threshold,owner);
             DETO.upRoleMinter(NewSageRouterAddress);
             DETO.upRoleBurner(NewSageRouterAddress);
            Game  memory game = Game({
                id: lastId,
                NewSageRouterAddress: NewSageRouterAddress,
                SmartMatrixNewsageAddress:address(0),
                ownerAddress:owner,
                isStart:false
            });
             Games[lastId]=game;
            lastId++;
        
    }
    function newFactory(address _ownerAddress,uint256 _threshold)public{
        if(msg.sender==owner){
            address NewSageRouterAddress=NewSageRouterFactory.creatNewSageRouter(uniswapV2Router02Address,WETHAddress,DETOAddress,uniswapV2PairAddress,address(this),_threshold,owner);
             DETO.upRoleMinter(NewSageRouterAddress);
             DETO.upRoleBurner(NewSageRouterAddress);
            Game  memory game = Game({
                id: lastId,
                NewSageRouterAddress: NewSageRouterAddress,
                SmartMatrixNewsageAddress:address(0),
                ownerAddress:owner,
                isStart:false
            });
             Games[lastId]=game;
            lastId++;
            return;
        }
        bool isRouterMS= false;
        for(uint256 i=0;i<lastId;i++){
            if(Games[i].NewSageRouterAddress==msg.sender){
                isRouterMS=true;
                break;
            }
        }
        if(isRouterMS){
           address NewSageRouterAddress=NewSageRouterFactory.creatNewSageRouter(uniswapV2Router02Address,WETHAddress,DETOAddress,uniswapV2PairAddress,address(this),_threshold,owner);
           
             DETO.upRoleMinter(NewSageRouterAddress);
             DETO.upRoleBurner(NewSageRouterAddress);

            Game  memory game = Game({
                id: lastId,
                NewSageRouterAddress: NewSageRouterAddress,
                SmartMatrixNewsageAddress:address(0),
                ownerAddress:_ownerAddress,
                isStart:false
            });
        
             Games[lastId]=game;
            lastId++;
        }
        
    }
    function getlastRouterAndNewsageAddress()public view returns(address NewSageRouterAddress,address SmartMatrixNewsageAddress){
        NewSageRouterAddress= Games[lastId-1].NewSageRouterAddress;
        SmartMatrixNewsageAddress= Games[lastId-1].SmartMatrixNewsageAddress;
    }
    receive () external payable { 
    	
	}
}