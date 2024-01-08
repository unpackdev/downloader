import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./IERC20.sol";


contract Slime is Ownable, Pausable, VRFConsumerBase {

    using Counters for Counters.Counter;

    bytes32 internal keyHash;
    uint256 public fee;
    uint256 internal randomResult;
    uint256 internal randomNumber;
    address public linkToken;
    uint256 public vrfcooldown = 100;
    Counters.Counter public vrfReqd;
    mapping (address => bool) whitelistedContracts;    
    bytes32 private lastReqID;


    constructor(address _vrfCoordinator, address _link) 
        VRFConsumerBase(_vrfCoordinator, _link)  
    { 
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; 
        linkToken = _link;
        vrfReqd.increment();
        
    }


    function getRandomChainlink() internal returns (bytes32 requestId) {

        if (vrfReqd.current() <= vrfcooldown) {
        vrfReqd.increment();
        return lastReqID;
        }

        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        vrfReqd.reset();
        lastReqID = requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        bytes32 reqId = requestId;
        randomNumber = randomness;
    }

    function bigSlime(uint256 xyz) external returns (uint256 slime) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
        bytes32 requestId = getRandomChainlink();
        slime = uint256(keccak256(abi.encodePacked(requestId,"hendrixfuture",tx.origin, blockhash(block.number - 1), block.timestamp, xyz, randomNumber)));

    }


    /** ADMIN FUNCTIONS */

    function setWhitelistContract(address contract_address, bool status) public onlyOwner{
        whitelistedContracts[contract_address] = status;
    }

    function withdrawLINK() external onlyOwner {
        uint256 tokenSupply = IERC20(linkToken).balanceOf(address(this));
        IERC20(linkToken).transfer(msg.sender, tokenSupply);
    }

    function getLastRequestID() external view onlyOwner returns (bytes32 requestId )  {
        requestId =  lastReqID;
    }

    function changeVrfCooldown(uint256 _cooldown) external onlyOwner{
        vrfcooldown = _cooldown;
    }

    function changeLinkFee(uint256 _fee) external onlyOwner {
        fee = _fee * 10 ** 18;
    }

    function ForceChainLink() internal onlyOwner returns (bytes32 requestId){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

}