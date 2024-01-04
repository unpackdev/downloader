// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

// v. 0.9 comments in future versions

library SafeMathChainlink {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

contract VRFRequestIDBase {

  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;


  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link)  {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
}

contract OwnableOperable {
    
    address public owner;
    address public operator;
    
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function isOwner(address account) public view returns(bool) {
        return account == owner;
    }
    
    
    function transferOwnership(address newOwner) public onlyOwner  {
        
    _transferOwnership(newOwner);
    }

  function _transferOwnership(address newOwner)  internal {
    owner = newOwner;
    
  }
    
    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }
    
    function isOperator(address account) public view returns(bool) {
    return account == operator;
    }
    
    function addOperator(address account) public onlyOwner {
    _addOperator(account);
    }
    
  function _addOperator(address account) internal {
    operator = account;
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract TransmutationEngine is VRFConsumerBase, OwnableOperable {
    using SafeMathChainlink for uint256;
    
    uint64 public currentSession = 0;
    uint64 public nextSession = 1;
    
    struct Engine_params { 
        address rewardsVault;
        uint8 alchemyCut;
        uint8 minAlchemists;
        uint16 maxAlchemists;
        uint64 minXpb;
        uint16 minTime;
        bool formulaOverflow;
        bool enabled;
    }
    
    
    struct Tokens_blueprint { 
        address tokenAddress;
        address pairAddress;
        uint64 vaultBalance;
        uint64 rewardAmount;
        uint64 decimals;
        bool enabled;
    }
    
    
    struct Transmute_registry_entry { 
        address alchemist;  // wallet address attemtping the transmutation
        uint8 reward;     // ERC-20 address of reward token
        // uint64 amount;      // (9 decimals), committed amount of XPb
        uint16 chance;      // ( 0 decimals)
        // uint32 timestamp;    // timestamp of operation, as reference for prices verification and general timestamp-stuff
        // bool successful;    // marked as true if randomness <= chance. if true, the transmutation is successful and the alchemist receives the reward.
    }
    
    struct Transmute_registry_blueprint { 
        uint32 timestamp_init;
        uint32 timestamp_end;
        bytes32 randReqId;
        uint16 randomness;  // ( 0 decimals) -> received randomnes, simmered down to a more usable (5 digit max 65535) degree of resolution
        uint16 total_entries;
        uint64 total_xpb;
        bool vrf;      // marked as true when the VRF callback function is triggered and the transmutation attempt is complete
        bool complete;      
    }
    
    
    
    Engine_params public EngineParameters;
    
    mapping (uint8 => Tokens_blueprint) public tokens;
    mapping (uint64 => mapping (uint8 => uint64)) public token_prices; 
    mapping (uint64 => Transmute_registry_blueprint) public transmutation_sessions;  // maximum frequency - hourly
    mapping (uint64 => mapping (uint16 => Transmute_registry_entry)) public transmutation_sessions_entries;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    constructor () 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) 
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 1e18; // 2 LINK for VRF Fees
        
        owner = msg.sender;
        operator = msg.sender;
        
    
        EngineParameters = Engine_params({ 
                                                   rewardsVault: 0x4417e253582B8F9612Bbb0B906339958691D7dCf,
                                                   alchemyCut: 3, //%
                                                   minAlchemists: 5,
                                                   maxAlchemists: 50,
                                                   minXpb: 777*1e9, 
                                                   minTime: 300, //seconds
                                                   formulaOverflow: false,
                                                   enabled: true
            
                                                                });
        
        tokens[0] = Tokens_blueprint({ 
                                                   tokenAddress: 0xbC81BF5B3173BCCDBE62dba5f5b695522aD63559,  // XPb
                                                   pairAddress: 0x1ab24a692EFf49b9712CEaCdEf853152d78b9050,
                                                   rewardAmount: 0,      
                                                   vaultBalance: 0,
                                                   decimals: 1e18,
                                                   enabled: false
            
                                                                });

        tokens[1] = Tokens_blueprint({ 
                                                   tokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,  // LINK
                                                   pairAddress: 0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974,
                                                   rewardAmount: 1e9,      
                                                   vaultBalance: 0,
                                                   decimals: 1e18,
                                                   enabled: true
            
                                                                });
        tokens[2] = Tokens_blueprint({ 
                                                   tokenAddress: 0xb9871cB10738eADA636432E86FC0Cb920Dc3De24,  // PRIA
                                                   pairAddress: 0xAc350EefCCdAE050614070E5040e17759Cebb3e9,
                                                   rewardAmount: 1e9,      
                                                   vaultBalance: 0,
                                                   decimals: 1e18,
                                                   enabled: false
            
                                                                });
                                                                
        tokens[3] = Tokens_blueprint({ 
                                                   tokenAddress: 0x6810e776880C02933D47DB1b9fc05908e5386b96,  // GNO
                                                   pairAddress: 0x3e8468f66d30Fc99F745481d4B383f89861702C6,
                                                   rewardAmount: 1e9,      
                                                   vaultBalance: 0,
                                                   decimals: 1e18,
                                                   enabled: true
            
                                                                });
                                                                
        tokens[4] = Tokens_blueprint({ 
                                                   tokenAddress: 0xc00e94Cb662C3520282E6f5717214004A7f26888,  // COMP
                                                   pairAddress: 0xCFfDdeD873554F362Ac02f8Fb1f02E5ada10516f,
                                                   rewardAmount: 1e9,      
                                                   vaultBalance: 0,
                                                   decimals: 1e18,
                                                   enabled: true
            
                                                                });
                                                                
        tokens[5] = Tokens_blueprint({ 
                                                   tokenAddress: 0xD5525D397898e5502075Ea5E830d8914f6F0affe,  // MEME
                                                   pairAddress: 0x5DFbe95925FFeb68f7d17920Be7b313289a1a583,
                                                   rewardAmount: 1e9,      
                                                   vaultBalance: 0,
                                                   decimals: 1e8,
                                                   enabled: true
            
                                                                });
                                                                
        tokens[6] = Tokens_blueprint({ 
                                                   tokenAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,  // WETH
                                                   pairAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                                                   rewardAmount: 1e9,      
                                                   vaultBalance: 0,
                                                   decimals: 1e18,
                                                   enabled: true
            
                                                                });
                                                                
        tokens[7] = Tokens_blueprint({ 
                                                   tokenAddress: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,  // WBTC
                                                   pairAddress: 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940,
                                                   rewardAmount: 1e8,      
                                                   vaultBalance: 0,
                                                   decimals: 1e8,
                                                   enabled: true
            
                                                                });
                                                                
    }
    
    function modify_token(uint8 _token, address _tokenAddress, address _pairAddress, uint64 _rewardAmount, uint64 _decimals, bool _enabled  ) onlyOwner public {
        
        tokens[_token] = Tokens_blueprint({ 
                                                   tokenAddress: _tokenAddress,
                                                   pairAddress: _pairAddress,
                                                   rewardAmount: _rewardAmount, // 9 dec
                                                   decimals: _decimals,
                                                   vaultBalance: 0,
                                                   enabled: _enabled
            
                                                                });
                                                                
                                                                // add events
    }
    
    function modify_params(uint128 _alchemyCut ) onlyOwner public {
        
        
                                                                
    }
    
    function init_session() onlyOperator public {
        
        require(currentSession == nextSession -1, 'SESSION_ALREADY_OPEN');
        if(currentSession > 0){
        require(transmutation_sessions[currentSession].complete == true, 'WAIT_FOR_PREV_SESSION');
        }
        
        currentSession = nextSession;
        
        token_prices[currentSession][0] = getUniTokenPrice(tokens[0].pairAddress, 0); // XPB
        
        if(tokens[1].enabled == true){
        token_prices[currentSession][1] = getUniTokenPrice(tokens[1].pairAddress, 0); // LINK
        tokens[1].vaultBalance = uint64(IERC20(tokens[1].tokenAddress).balanceOf(EngineParameters.rewardsVault) / 1e9);
        }
        if(tokens[1].enabled == true){
        token_prices[currentSession][2] = getUniTokenPrice(tokens[2].pairAddress, 0); // PRIA
        tokens[2].vaultBalance = uint64(IERC20(tokens[2].tokenAddress).balanceOf(EngineParameters.rewardsVault) / 1e9);
        }
        if(tokens[1].enabled == true){
        token_prices[currentSession][3] = getUniTokenPrice(tokens[3].pairAddress, 0); // GNO
        tokens[3].vaultBalance = uint64(IERC20(tokens[3].tokenAddress).balanceOf(EngineParameters.rewardsVault) / 1e9);
        }
        if(tokens[1].enabled == true){
        token_prices[currentSession][4] = getUniTokenPrice(tokens[4].pairAddress, 0); // COMP
        tokens[4].vaultBalance = uint64(IERC20(tokens[4].tokenAddress).balanceOf(EngineParameters.rewardsVault) / 1e9);
        }
        if(tokens[1].enabled == true){
        token_prices[currentSession][5] = getUniTokenPrice(tokens[5].pairAddress, 1);  // MEME
        tokens[5].vaultBalance = uint64(IERC20(tokens[5].tokenAddress).balanceOf(EngineParameters.rewardsVault)  * 10);
        }
        if(tokens[1].enabled == true){
        token_prices[currentSession][6] = 1e9;                                            // WETH
        tokens[6].vaultBalance = uint64(IERC20(tokens[6].tokenAddress).balanceOf(EngineParameters.rewardsVault) / 1e9);
        }
        if(tokens[1].enabled == true){
        token_prices[currentSession][7] = getUniTokenPrice(tokens[7].pairAddress, 2); //WBTC
        tokens[7].vaultBalance = uint64(IERC20(tokens[7].tokenAddress).balanceOf(EngineParameters.rewardsVault) * 10);
        }
        
        
        transmutation_sessions[currentSession] = Transmute_registry_blueprint({ 
                                                                                randReqId: 0,
                                                                                randomness: 0,
                                                                                timestamp_init: uint32(block.timestamp),
                                                                                timestamp_end: 0,
                                                                                complete: false,
                                                                                vrf: false,
                                                                                total_entries: 0,
                                                                                total_xpb: 0
                                                                                                });
    }
    
    
    function submit_transmutation(uint8 formula, uint64 amount) public {
        
        require(EngineParameters.enabled == true, 'TRANSMUTATION_ENGINE_DISABLED');
        
        require(amount > 0, 'AMMOUNT_CANNOT_BE_0');
        
        require(currentSession == nextSession, 'SESSION_NOT_OPEN_YET');
        
        require(tokens[formula].enabled == true, 'FORMULA_NOT_ENABLED');
        
        require(transmutation_sessions[currentSession].total_entries <= EngineParameters.maxAlchemists, 'ROUND_IS_FULL');
        
        if(EngineParameters.formulaOverflow == false){
            
        require(tokens[formula].vaultBalance >= tokens[formula].rewardAmount, 'FORMULA_IS_FULL');
        
        }
        
        
        IERC20(tokens[0].tokenAddress).transferFrom(msg.sender, EngineParameters.rewardsVault, uint128(amount) * 1e9);
        
        uint16 this_entry = transmutation_sessions[currentSession].total_entries + 1;
        uint64 total_xpb = transmutation_sessions[currentSession].total_xpb + amount;
        
        transmutation_sessions[currentSession].total_xpb = total_xpb; 
        transmutation_sessions[currentSession].total_entries = this_entry;
        
        uint128 sentEtherValue = uint128(token_prices[currentSession][0]) * amount;  // 9 -> 18 dec 
        
        uint128 rewardEtherValue = uint128(token_prices[currentSession][formula]) * tokens[formula].rewardAmount / 1e9;   // 9 - 18 - 9 dec
        
        uint128 transmuteChance = sentEtherValue / rewardEtherValue * (100-EngineParameters.alchemyCut) * 65535 / 1e11 ; // 18 - 9 - 11 - 11 - 0  dec
        
        if(transmuteChance > 65535){ transmuteChance = 65535; } 
        
        
        
        transmutation_sessions_entries[currentSession][this_entry] = Transmute_registry_entry({
                                                                                                alchemist: msg.sender,
                                                                                                reward: formula,
                                                                                                chance: uint16(transmuteChance)
                                                                                                // amount: amount,
                                                                                                // timestamp: uint32(block.timestamp),
                                                                                                // successful: false
                                                                                                                  });
                                                                                                                 
                                                                                                                  
    }
    
    
    
    
    function close_session() onlyOperator public {
        
        require(currentSession == nextSession, 'SESSION_NOT_OPEN');
        require(EngineParameters.minAlchemists <= transmutation_sessions[currentSession].total_entries, 'REQUIRED_ALCHEMISTS_NOT_REACHED');
        require(EngineParameters.minXpb <= transmutation_sessions[currentSession].total_xpb, 'REQUIRED_LEAD_NOT_REACHED');
        require(block.timestamp >= (transmutation_sessions[currentSession].timestamp_init + EngineParameters.minTime), 'MIN_TIME_NOT_ELAPSED' );
        
        bytes32 reqId = requestRandomness(keyHash, fee, block.timestamp);
        
        transmutation_sessions[currentSession].randReqId = reqId;
        
        transmutation_sessions[currentSession].timestamp_end = uint32(block.timestamp);
        
        nextSession = nextSession +1;
        
    }
    
    
    
    function complete_session(bool _distribute) onlyOperator public {
        
        require(currentSession == nextSession-1, 'SESSION_STILL_OPEN');
        require(transmutation_sessions[currentSession].complete == false, 'NO_!');
        
        if(_distribute == false){
            
            // do manual distribution for this round. 
            
        } else {
            
        if(transmutation_sessions[currentSession].vrf == true){
            uint16 i = 0;
            for (i = 1; i <= transmutation_sessions[currentSession].total_entries ; i++) { 
         if(transmutation_sessions_entries[currentSession][i].chance >= transmutation_sessions[currentSession].randomness){
             
             uint8 _reward = transmutation_sessions_entries[currentSession][i].reward;
             address _rewardAddress = tokens[_reward].tokenAddress;
             address _alchemistAddress = transmutation_sessions_entries[currentSession][i].alchemist;
             
             
             uint128 _rewardAmt = uint128(tokens[_reward].rewardAmount) * tokens[_reward].decimals / 1e9; // 9-27-18 \ 8-17-8
             
             IERC20(_rewardAddress).transferFrom(EngineParameters.rewardsVault, _alchemistAddress, _rewardAmt);
         }      
      }
           
            
        } else {
            // round forfeited. VRF not showing, etc....
        }
        }
        transmutation_sessions[currentSession].complete = true;
        
        
    }
    
    
        /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        
        if(transmutation_sessions[currentSession].randReqId == requestId){
            transmutation_sessions[currentSession].randomness = uint16(randomness);     // obtain 5 digit randomness (0 - 65535)
            transmutation_sessions[currentSession].vrf = true;
        }
        
    }
    
    
    function getUniTokenPrice(address _pair, uint8 _exception) public view returns(uint64 price){
        
        (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(_pair).getReserves();
        if(_exception == 1){
           price = uint64(reserve0.div(reserve1));
        } else if(_exception == 2){
            price = uint64(reserve1.div(reserve0));
        } else {
        price = uint64(reserve1.mul(1e8).div(reserve0));
    }
        
       
    }
    
    
    
    function recoverETH(address  _to, uint _value) external onlyOwner() payable{
        payable(_to).transfer(_value);
    }

    function recoverERC20(address _token, address _to, uint _value) public onlyOwner() {
        IERC20(_token).transfer(_to, _value);
    }

    receive() external payable { 
        //ty
    }
    
    

}