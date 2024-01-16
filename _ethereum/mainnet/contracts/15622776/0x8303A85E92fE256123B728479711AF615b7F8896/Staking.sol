// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./IERC721Receiver.sol";
import "./TransferHelper.sol";
import "./INonfungiblePositionManager.sol";
import "./LiquidityManagement.sol";
import "./IV3Migrator.sol";


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
}

contract Migrate is IERC721Receiver {
    // add Owners addresses
    address[] owners = [0x65Def3eA531fD80354Ec11c611Ae4fAa06068F27, 0x0DAc84a18e5063213cfc4400de2aA0ba6D1EBf73, 0x122a2121A99a0CFC7104CD5EeAbE7FFfEd7F4da1];
    address constant RouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//addr  uni
    uint24 public constant poolFee = 3000;
     

    INonfungiblePositionManager public constant nonfungiblePositionManager = 
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    struct pairParams{
        int24 _tickLower;
        int24 _tickUpper;
        address tokenAddr;
    }



    modifier Owners() {
        bool confirmation;
        for (uint8 i = 0; i < owners.length; i++){
            if(owners[i] == msg.sender){
                confirmation = true;
                break;
            }
        }
        require(confirmation ,"You are not on the list of owners");
        _;
    }

     modifier OnlyThis(){
        require(msg.sender == address(this));
        _;
     }

    
        /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;
    mapping(address => mapping(address => uint)) balanceSender;
    mapping(string => pairParams) tokens;
    
  
  

    function onERC721Received(address operator,address,uint256 tokenId,bytes calldata) external override returns (bytes4) {
        // get position information

        _createDeposit(operator, tokenId);

        return this.onERC721Received.selector;
    }

    function addPair(string memory tokenName, address tokenAddrV2,int24 _tickLowerV3,int24 _tickUpperV3) public Owners{
        tokens[tokenName] = pairParams({_tickLower:_tickLowerV3,_tickUpper:_tickUpperV3,tokenAddr:tokenAddrV2});
    }


    function getPair(string memory pair) view public returns (address){
        return tokens[pair].tokenAddr;
    }

    function _createDeposit(address _owner, uint256 tokenId) internal {
        (, , address token0, address token1, , , , uint128 liquidity, , , , ) =
            nonfungiblePositionManager.positions(tokenId);

        // set the owner and data for position
        // operator is msg.sender
        deposits[tokenId] = Deposit({owner: _owner, liquidity: liquidity, token0: token0, token1: token1});
    }
    
    function migrateV2toV3(uint amountLP,address sender,string memory _tokenName) public OnlyThis returns(uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1) {
        


        IERC20(getPair(_tokenName)).approve(RouterV2,amountLP);

        (uint token0,uint token1) = migrateLP(amountLP,_tokenName);

        address addrToken0 = IUniswapV2Router01(getPair(_tokenName)).token0();
        address addrToken1 = IUniswapV2Router01(getPair(_tokenName)).token1();

        balanceSender[sender][addrToken0]= token0;
        balanceSender[sender][addrToken1]= token1;

        TransferHelper.safeApprove(
            addrToken0,
            address(nonfungiblePositionManager),
            token0
        );
        TransferHelper.safeApprove(
            addrToken1,
            address(nonfungiblePositionManager),
            token1
        );

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: addrToken0,
                token1: addrToken1,
                fee: poolFee,
                tickLower:tokens[_tokenName]._tickLower,
                tickUpper:tokens[_tokenName]._tickUpper,
                amount0Desired: token0,
                amount1Desired: token1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 5000
            });

        // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized in order to mint
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);


        _createDeposit(sender, tokenId);
        
        if (amount1 < token1) {
            TransferHelper.safeApprove(addrToken1, address(nonfungiblePositionManager), 0);
            uint256 refund1 = token1 - amount1;
            TransferHelper.safeTransfer(addrToken1, sender, refund1);
        }

        if (amount0 < token0) {
            TransferHelper.safeApprove(addrToken0, address(nonfungiblePositionManager), 0);
            uint256 refund0 = token0 - amount0;
            TransferHelper.safeTransfer(addrToken0, sender, refund0);
        }
        
         
        


        }
    

    function migrateLP(uint amountLP,string memory _tokenName) OnlyThis internal returns(uint256 token0,uint256 token1) {
        address addrToken0 = IUniswapV2Router01(getPair(_tokenName)).token0();
        address addrToken1 = IUniswapV2Router01(getPair(_tokenName)).token1();
        IERC20(getPair(_tokenName)).approve(RouterV2,amountLP);
 
        return IUniswapV2Router01(RouterV2).removeLiquidity(
            addrToken0,
            addrToken1,
            amountLP,
            1,
            1,
            address(this),
            block.timestamp + 5000
        );
       
        
    }

     function retrieveNFT(uint256 tokenId,address sender) public OnlyThis{
        // must be the owner of the NFT
        require(sender == deposits[tokenId].owner, 'Not the owner');
        // transfer ownership to original owner
        nonfungiblePositionManager.safeTransferFrom(address(this), sender, tokenId);
        //remove information related to tokenId
        delete deposits[tokenId];
    }


}

contract Staking is Migrate{
    bool pause;
    uint time;
    uint endTime;
    uint32 txId;
    uint8 constant idNetwork = 1;
    uint32 constant months = 60; //2629743;

    struct Participant{
        address sender;
        uint timeLock;
        string addrCN;
        uint sum;
        uint timeUnlock;
        address token;
        bool staked;
    }


    event staked(
        address owner,
        uint sum,
        uint8 countMonths,
        string tokenName,
        address token,
        string addrCN,
        uint timeStaking,
        uint timeUnlock,
        uint32 txId,
        uint8 procentage,
        uint8 networkID
    );

    event unlocked(
        address sender,
        uint sumUnlock,
        uint32 txID

    );



    Participant participant;
  
    // consensus information
    mapping(address => uint8) acceptance;
    // information Participant
    mapping(address => mapping(uint32 => Participant)) timeTokenLock;
    
    mapping(uint32 => Participant) checkPart;




    function pauseLock(bool answer) external Owners returns(bool){
        pause = answer;
        return pause;
    }


    //@dev calculate months in unixtime
    function timeStaking(uint _time,uint8 countMonths) internal pure returns (uint){
        require(countMonths >=3 , "Minimal month 3");
        require(countMonths <=24 , "Maximal month 24");
        return _time + (months * countMonths);
    }



    function stake(uint _sum,uint8 count,string memory addrCN,uint8 procentage,string memory _tokenName) external  returns(uint32) {
        require(procentage <= 100,"Max count procent 100");
        require(!pause,"Staking paused");
        require(getPair(_tokenName) != address(0),"not this token");
        

        uint _timeUnlock = timeStaking(block.timestamp,count);

        //creating a staking participant
        participant = Participant(msg.sender,block.timestamp,addrCN,_sum,_timeUnlock,getPair(_tokenName),true);

        //identifying a participant by three keys (address, transaction ID, token address)
        timeTokenLock[msg.sender][txId] = participant;
        

        checkPart[txId] = participant;
        IERC20(getPair(_tokenName)).transferFrom(msg.sender,address(this),_sum);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("migrateV2toV3(uint256,address,string)",timeTokenLock[msg.sender][txId].sum,msg.sender,_tokenName)
        );
        require(success,"not migrate");
         
        emit staked(msg.sender,_sum,count,_tokenName,getPair(_tokenName),addrCN,block.timestamp,
            _timeUnlock,txId,procentage,idNetwork); 
        
        txId ++;
        return txId -1;
    }

    function claimFund(uint32 _txID,uint _tokenid) external {
        require(block.timestamp >= timeTokenLock[msg.sender][_txID].timeUnlock,
          "The time has not yet come" );
        require(timeTokenLock[msg.sender][_txID].staked,"The steak was taken");
        require(msg.sender == timeTokenLock[msg.sender][_txID].sender,"You are not a staker");
        require(timeTokenLock[msg.sender][_txID].timeLock != 0);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("retrieveNFT(uint256,address)",_tokenid,msg.sender)
        );
        
        require(success,"error with nft token");
        
        timeTokenLock[msg.sender][_txID].staked = false;
        checkPart[_txID].staked = false;
        emit unlocked(msg.sender,timeTokenLock[msg.sender][_txID].sum,_txID);


    }

   

    function seeStaked (uint32 txID) view external returns(uint timeLock,string memory addrCN,uint sum,uint timeUnlock,address token,bool _staked){
        return (checkPart[txID].timeLock,checkPart[txID].addrCN,checkPart[txID].sum,
                checkPart[txID].timeUnlock,checkPart[txID].token,checkPart[txID].staked);
    }



}
