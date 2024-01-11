
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Icontroller.sol";
import "./IERC20deployer.sol";



contract BridgePool is Context , ReentrancyGuard {
  
    struct  pool{
        address wrappedAsset;
        uint256 deposited;
        uint256 debt;
        uint256 overFlow;
        uint256 debtThreshold;
        bool isSet;
        
    }
    IController public controller;
    address public bridge;
    address public pendingBridge;
    uint256 public bridgeUpdateInnitiatedAt;
    mapping(address => pool) public pools;
    address[] public poolAddresses;
    uint256 public poolCount;
    uint256 public bridgeUpdateDelay = 2 days;
    
    event PoolToppedUp(address indexed poolAddress,uint256 amount);
    event AssetSentOut(address indexed  poolAddress, address indexed  reciever ,uint256 amount);
    event AssetWithdrawn(address indexed poolAddress , address indexed receiver,uint256  amount);
    event AssetDeposited(address indexed poolAddress , uint256  amount);
    event PoolCreated(address indexed poolAddress, address indexed wrappedAsset); 
    event NewBridgeInnitiated(address indexed curentBridge ,address indexed pendingBridge);
    event NewBridgeActivated(address indexed prevBridge , address indexed newBridge);
    event PoolDebtThresholdUpdated(
        address indexed poolAddress,
        uint256 oldDebtThreshold,
        uint256 newDebtThreshold
    );
    bool initialized;
     modifier onlyBridge() {
         require(bridge == _msgSender(), "Only Bridge Callable");
        _; 
     }
     modifier poolInitialized() {
         require(initialized, "pool not initialized");
        _; 
     }
    
    
    constructor(IController _controller ) {
        require(address(_controller) != address(0), "Zero address Err");
        controller = _controller;
    }
    
    function initializePool(address _bridge) public {
        isOwner();
        require(_bridge != address(0) && !initialized , "Er");
        bridge = _bridge;
        initialized = true;

    }

    function innitiateBridgeUpdate(address newBridge) public poolInitialized{
        isOwner();
        require(pendingBridge == address(0) , "pending Bridge already innitiated");
        pendingBridge = newBridge;
        emit NewBridgeInnitiated(bridge , pendingBridge);
        bridgeUpdateInnitiatedAt = block.timestamp;
    }
    function suspendBridgeUpdate() public poolInitialized{
        isOwner();
        require(pendingBridge != address(0) , "new bridge not innitiated");
        pendingBridge = address(0);
    }
    function activateNewBridge() public  poolInitialized{
        isOwner();
        require(pendingBridge != address(0) , "new bridge not innitiated");
        require(block.timestamp - bridgeUpdateInnitiatedAt > bridgeUpdateDelay , "update delay active");
        emit NewBridgeActivated(bridge , pendingBridge);
        bridge = pendingBridge;
        pendingBridge = address(0);
    }


    function updatePoolDebtThreshold(address poolAddress , uint256 debtThreshold) public poolInitialized{
        isOwner();
        require(pools[poolAddress].isSet , "invalid Pool");
        require(debtThreshold > 0 , "cant be zero");
        emit PoolDebtThresholdUpdated(poolAddress ,pools[poolAddress].debtThreshold , debtThreshold);
        pools[poolAddress].debtThreshold = debtThreshold;
     
    }
     

    function createPool(
        address poolAddress,
        uint256 debtThreshold
    ) 
        public
        onlyBridge
        poolInitialized
    {
        require(!pools[poolAddress].isSet , "pool already Created");
        require(debtThreshold > 0 , "cant be zero");
        WrappedToken wrappedAsset;
        if(poolAddress == address(0)){
             wrappedAsset =    new WrappedToken("brEtherium" , "brEth");
        }else{
            IERC20Metadata token = IERC20Metadata(poolAddress);
            wrappedAsset =    new WrappedToken(string(abi.encodePacked( "br", token.name())) , string(abi.encodePacked("br" , token.symbol())));
        }
        
        pools[poolAddress] = pool(address(wrappedAsset), 0 , 0 , 0, debtThreshold , true);
        poolAddresses.push(poolAddress);
        poolCount++;
        emit PoolCreated(poolAddress , address(wrappedAsset));       
    }
    

    function deposit(address poolAddress, uint256 amount) public payable nonReentrant poolInitialized{
        require(pools[poolAddress].isSet , "invalid Pool");
         (bool success , uint256 amountRecieved) = processedPayment(poolAddress , amount);
         require(success && amountRecieved > 0, "I_F");
         pools[poolAddress].deposited += amountRecieved;
         IwrappedToken(pools[poolAddress].wrappedAsset).mint(msg.sender , amountRecieved);
         emit AssetDeposited(poolAddress , amountRecieved);
        
    }

    function withdraw(address poolAddress , uint256 amount) public nonReentrant poolInitialized{ 

         require(pools[poolAddress].isSet , "invalid Pool");  
         IERC20 token = IERC20(poolAddress);
         IERC20 wrappedToken = IERC20(pools[poolAddress].wrappedAsset);
      
         require(pools[poolAddress].deposited  >= amount && token.balanceOf(address(this)) >= amount , "Insufficent Pool Balance");
         require(wrappedToken.allowance(_msgSender(), address(this)) >= amount , "I_F");
         uint256 balanceBefore = IERC20(pools[poolAddress].wrappedAsset).balanceOf(address(this));
         wrappedToken.transferFrom(_msgSender() , address(this) , amount);
         uint256 balanceAfter = wrappedToken.balanceOf(address(this));
         require(balanceAfter - balanceBefore > 0 , "I_F");
         uint256 amountRecieved = balanceAfter - balanceBefore;
         IwrappedToken(pools[poolAddress].wrappedAsset).burn(amountRecieved);
         payoutUser(payable(_msgSender()) , poolAddress , amountRecieved);
         pools[poolAddress].deposited -= amountRecieved;
         emit AssetWithdrawn(poolAddress , _msgSender() , amountRecieved);

    }


    function sendOut(address poolAddress , address receiver , uint256 amount) public onlyBridge poolInitialized{
        require(receiver != address(0) , "Z_A_E");
       require(pools[poolAddress].isSet , "invalid Pool");
        IERC20 token = IERC20(poolAddress);
        require( pools[poolAddress].overFlow + pools[poolAddress].deposited >= amount && token.balanceOf(address(this)) >= amount , "Insufficent Pool Balance");
        if (pools[poolAddress].overFlow > 0) {
            if (pools[poolAddress].overFlow >= amount){
                pools[poolAddress].overFlow -= amount;
            } else {
                uint256 _debt = amount - pools[poolAddress].overFlow;
                 pools[poolAddress].debt +=  _debt;
                 pools[poolAddress].overFlow = 0;
            }
        } else {
           pools[poolAddress].debt +=  amount;
        }
        require(pools[poolAddress].debt < pools[poolAddress].debtThreshold , "Dept Threshold Exceeded");
        payoutUser(payable(receiver) , poolAddress , amount);
        emit AssetSentOut(poolAddress , receiver , amount);

    }


    function topUp(address poolAddress, uint256 amount) public onlyBridge poolInitialized{
        
        (bool success , uint256 amountRecieved) = processedPayment(poolAddress , amount);
        require(pools[poolAddress].isSet  && success, "invalid Pool");
        if (pools[poolAddress].debt > 0) {
            if (pools[poolAddress].debt >= amountRecieved){
                pools[poolAddress].debt -= amountRecieved;
            } else {
                uint256 _overFlow = amountRecieved - pools[poolAddress].debt;
                 pools[poolAddress].overFlow +=  _overFlow;
                 pools[poolAddress].debt = 0;
            }
        } else {
           pools[poolAddress].overFlow +=  amountRecieved;
        }
        
        emit PoolToppedUp( poolAddress, amountRecieved);

    }
     function processedPayment(address assetAddress , uint256 amount) internal   returns (bool , uint256) {
        if (assetAddress == address(0)) {
            if(msg.value >= amount ){
                uint256 value = msg.value;
                return (true , value);
            } else {
                return (false , 0);
            }
            
        } else {
            IERC20 token = IERC20(assetAddress);
            if (token.allowance(_msgSender(), address(this)) >= amount) {
                uint256 balanceBefore = token.balanceOf(address(this));
                require(token.transferFrom(_msgSender() , address(this) , amount), "I_F");
                uint256 balanceAfter = token.balanceOf(address(this));
               return (true , balanceAfter - balanceBefore);
            } else {
                return (false , 0);
            }
        }
    }

    function payoutUser(address payable recipient , address _paymentMethod , uint256 amount) private {
       require(recipient  != address(0) , "Z_A_E");
        if (_paymentMethod == address(0)) {
          recipient.transfer(amount);
        } else {
             IERC20 currentPaymentMethod = IERC20(_paymentMethod);
             require(currentPaymentMethod.transfer(recipient , amount) ,"I_F");
        }
    }


    function validPool(address poolAddress) public view returns (bool) {
        return pools[poolAddress].isSet;
    }
    function isOwner() internal view returns (bool) {
        require(controller.owner() == _msgSender()  , "U_A");
        return true;
    }
}


