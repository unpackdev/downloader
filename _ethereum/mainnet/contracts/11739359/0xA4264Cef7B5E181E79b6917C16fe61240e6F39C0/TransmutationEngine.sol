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
    
    address constant rewardsVault = 0x4417e253582B8F9612Bbb0B906339958691D7dCf;
    address constant XPbAddress = 0xbC81BF5B3173BCCDBE62dba5f5b695522aD63559;
    
    uint32 public currentSession = 0;
    uint32 public nextSession = 1;
    
    
     struct Transmute_registry_blueprint { 
        bytes32 randReqId;
        uint16 randomness;
        bool vrf;
        bool complete;
    }
    
    mapping (uint64 => Transmute_registry_blueprint) public transmutation_sessions;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    constructor () 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA 
        ) 
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 5000 * 4000 * 1e11; 
        
        owner = msg.sender;
        operator = msg.sender;
                                                                
    }
    
    
    function init_session() onlyOperator public {
        
        require(currentSession == nextSession -1, 'SESSION_ALREADY_OPEN');
        if(currentSession > 0){
        require(transmutation_sessions[currentSession].complete == true, 'WAIT_FOR_PREV_SESSION');
        }
        
        currentSession = nextSession;
        
        transmutation_sessions[currentSession] = Transmute_registry_blueprint({ 
                                                                                randReqId: 0,
                                                                                randomness: 0,
                                                                                vrf: false,
                                                                                complete: false
                                                                                                });
    }
    
    
    function submit_transmutation(uint8 formula, uint32 session, uint64 amount) public {
        
        require(amount > 0, 'AMMOUNT_CANNOT_BE_0');
        
        require(session == currentSession, 'WRONG_SESSION_ID');
        
        require(currentSession == nextSession, 'SESSION_NOT_OPEN_YET');
        
        IERC20(XPbAddress).transferFrom(msg.sender, rewardsVault, uint128(amount) * 1e9);

            }
    
    
    function close_session() onlyOperator public {
        
        require(currentSession == nextSession, 'SESSION_NOT_OPEN');
        
        bytes32 reqId = requestRandomness(keyHash, fee, block.timestamp);
        
        transmutation_sessions[currentSession].randReqId = reqId;
        
        nextSession = nextSession +1;
        
    }
    
     
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        
        if(transmutation_sessions[currentSession].randReqId == requestId){
            transmutation_sessions[currentSession].randomness = uint16(randomness);     // obtain 5 digit randomness (0 - 65535)
        }
        
    }
    
    
    function complete_session(bool _distribute) onlyOperator public {
        
        require(currentSession == nextSession-1, 'SESSION_STILL_OPEN');
        require(transmutation_sessions[currentSession].complete == false, 'NO_!');
        
        transmutation_sessions[currentSession].complete = true;
        
    }
    
   
    function recoverERC20(address _token, address _to, uint _value) public onlyOwner() {
        IERC20(_token).transfer(_to, _value);
    }

}