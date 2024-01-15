// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
//pragma experimental ABIEncoderV2;

import "./Include.sol";

struct SMake {
    address maker;
    bool    isBid;
    address asset;
    uint    tokenId;
    bytes32 currency;
    uint    price;
    uint    payType;
    Status  status;
    string  link;
}

struct STake {
    uint    makeID;
    address taker;
    Status  status;
    uint    expiry;
    string  link;
}

struct AppealInfo{
    uint takeID;
    address appeal;
    address arbiter;
    Status winner;   //0 Status.None  Status.Buyer Status.seller  assetTo
}


enum Status { None, Take, Paid, Cancel, Done, Appeal, Buyer, Seller,Vault} 



contract NftMarketplace is Configurable,ContextUpgradeable,IERC721ReceiverUpgradeable {
    using AddressUpgradeable for address;
    //using SafeERC20Upgradeable for IERC20;

    bytes32 internal constant _expiry_      = "expiry";
    bytes32 internal constant _feeRate_     = "feeRate";
    bytes32 internal constant _feeToken_    = "feeToken";    
    bytes32 internal constant _vault_  = "vault";
    bytes32 internal constant _mine_        = "mine";
    bytes32 internal constant _usd_   = "usd";
    bytes32 internal constant _bank_   = "bank";
    
    address[] public arbiters;
    mapping (address => bool) public    isArbiter;
    mapping (uint => SMake) public makes;
    mapping (uint => STake) public takes;
    mapping (uint =>AppealInfo) public appealInfos; //takeID=> AppealInfo
    uint public makesN;
    uint public takesN;
    
    uint private _entered;
    modifier nonReentrant {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }

    mapping (address => string) public links; //tg link


    function toUint(address addr) public pure returns(uint){
        return uint(uint160(addr));
    }


    function __NftMarketplace_init(address governor_) public initializer {
        __Governable_init_unchained(governor_);
        __NftMarketplace_init_unchained();
    }

    function __NftMarketplace_init_unchained() internal governance onlyInitializing{
        //config[_usd_ ] = uint(uint160(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56));      // BUSD
        config[_expiry_]    = 30 minutes;
        config[_feeRate_    ] = 0.01e18;        //  1%
    }

    function __NftMarketplace_set_param(address vault_,address mine_,address feeToken_,uint feeRate_,uint expiry_) public governance {
        config[_vault_] = toUint(vault_);
        config[_mine_] = toUint(mine_);
        config[_feeToken_] = toUint(feeToken_);
        config[_feeRate_    ] = feeRate_;//0.01e18;        //  1%
        config[_expiry_]    = expiry_;
    }


    function setArbiters_(address[] calldata arbiters_,string[] calldata links_) external governance {
        for(uint i=0; i<arbiters.length; i++)
            isArbiter[arbiters[i]] = false;
            
        arbiters = arbiters_;
        
        for(uint i=0; i<arbiters.length; i++){
            isArbiter[arbiters[i]] = true;
            links[arbiters[i]] = links_[i];
        }
            
        emit SetArbiters(arbiters_);
    }
    event SetArbiters(address[] arbiters_);



    function make(SMake memory make_) virtual external nonReentrant returns(uint makeID) { 
        require(!make_.isBid, 'only not Bid');
        IERC721(make_.asset).safeTransferFrom(msg.sender, address(this), make_.tokenId);
        makeID = makesN;
        make_.maker = msg.sender;
        make_.status = Status.None;
        makes[makeID]=make_;
        makesN++;
        emit Make(makeID, msg.sender, make_.asset, make_);
    }
    event Make(uint indexed makeID, address indexed maker, address indexed asset, SMake smake) ;

    function cancelMake(uint makeID) virtual external nonReentrant {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].maker == msg.sender, 'only maker');
        require(makes[makeID].status == Status.None, 'make pending...');
      
        if (!makes[makeID].isBid)
            IERC721(makes[makeID].asset).safeTransferFrom(address(this), msg.sender, makes[makeID].tokenId);
        makes[makeID].status = Status.Cancel;
        emit CancelMake(makeID, msg.sender, makes[makeID].asset, makes[makeID].tokenId );
    }
    event CancelMake(uint indexed makeID, address indexed maker, address indexed asset,uint tokenId);
    
    function reprice(uint makeID, uint newPrice) virtual external {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].maker == msg.sender, 'only maker');
        require(makes[makeID].status == Status.None, 'make pending...');
        
        makes[makeID].price = newPrice;
        emit Reprice(makeID, msg.sender, newPrice,makes[makeID]);

    }
    event Reprice(uint indexed makeID, address indexed maker, uint price, SMake smake);

 

    function take(uint makeID,string memory link) virtual external nonReentrant returns (uint takeID) {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].status == Status.None, 'make pending...');
        makes[makeID].status = Status.Take;
        takeID = takesN;
        takes[takeID] = STake(makeID, msg.sender, Status.Take, block.timestamp+config[_expiry_],link);
        takesN++;
        emit Take(takeID, makeID, msg.sender, STake(makeID, msg.sender, Status.Take, block.timestamp+config[_expiry_],link));
    }
    event Take(uint indexed takeID, uint indexed makeID, address indexed taker,STake stake);

    function cancelTake(uint takeID) virtual external nonReentrant {
        //require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].taker == msg.sender, 'only taker cancel');
        uint makeID = takes[takeID].makeID;
        require(takes[takeID].status <= Status.Paid, 'buyer can cancel neither Status.None nor Status.Paid take order');
        makes[makeID].status = Status.None;
        takes[takeID].status = Status.Cancel;
        emit CancelTake(takeID, makeID, msg.sender);
    }
    event CancelTake(uint indexed takeID, uint indexed makeID, address indexed sender);
    
    /*function paid(uint takeID) virtual external {
        require(msg.sender == takes[takeID].taker, 'only taker');
        require(takes[takeID].status == Status.Take, 'only Status.Take');
        uint makeID = takes[takeID].makeID;
        takes[takeID].status = Status.Paid;
        takes[takeID].expiry = block.timestamp+config[_expiry_];
        emit Paid(takeID, makeID, msg.sender);
    }
    event Paid(uint indexed takeID, uint indexed makeID, address indexed sender);*/

    function deliver(uint takeID) virtual external nonReentrant {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only Status.None or Paid');
        uint makeID = takes[takeID].makeID;
        require(msg.sender == makes[makeID].maker, 'only maker');
        IERC721(makes[makeID].asset).safeTransferFrom(address(this), takes[takeID].taker, makes[makeID].tokenId);
        makes[makeID].status = Status.Done;
        takes[takeID].status = Status.Done;
        emit Deliver(takeID, makeID, msg.sender);
    }
    event Deliver(uint indexed takeID, uint indexed makeID, address indexed sender);


    /*function appeal(uint takeID) virtual external nonReentrant {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only Status.Paid');
        uint makeID = takes[takeID].makeID;
        require(msg.sender == makes[makeID].maker || msg.sender == takes[takeID].taker, 'only maker or taker');
        //require(takes[takeID].expiry < block.timestamp, 'only expired');
        takes[takeID].status = Status.Appeal;
        appealInfos[takeID].takeID = takeID;
        appealInfos[takeID].appeal = msg.sender;
        emit Appeal(takeID, makeID, msg.sender);
    }
    event Appeal(uint indexed takeID, uint indexed makeID, address indexed sender);*/



    function arbitrate(uint takeID, Status winner) virtual external nonReentrant{
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only < Status.Paid');
        require(isArbiter[msg.sender], 'only arbiter');
        uint makeID = takes[takeID].makeID;
        appealInfos[takeID].arbiter   = msg.sender;
        appealInfos[takeID].winner = winner;
        if(winner == Status.Buyer) {
            IERC721(makes[makeID].asset).safeTransferFrom(address(this), takes[takeID].taker, makes[makeID].tokenId);
            makes[makeID].status = Status.Done;
            emit Deliver(takeID, makeID, msg.sender);            
        } else if(winner == Status.Seller) {
            makes[makeID].status = Status.None;
        } else
            revert('status should be Buyer or Seller');
        takes[takeID].status = winner;
        emit Arbitrate(takeID, makeID, msg.sender,winner);
   }

    event Arbitrate(uint indexed takeID, uint indexed makeID, address indexed arbiter, Status status);
    
    
    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
 
    // Reserved storage space to allow for layout changes in the future.
    uint256[41] private ______gap;
}


interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router01 {
    //function factory() external pure returns (address);
    function WETH() external pure returns (address);
    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}
