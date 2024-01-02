pragma solidity 0.8.21;
import "./Ownable.sol";
import "./SafeERC20.sol"; 
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
// import "./console.sol";


contract ApeInvestment is Ownable,Pausable,ReentrancyGuard {

using SafeERC20 for IERC20;

    struct Project{ 
        string name;
        address signer;
        address[] paymentOptions;
        uint256 participantsCount;
        uint256 participantsLimit;
        bytes32 merkleRoot;
    }


    struct ProjectInvestment{ 
        uint256 id;
        uint256 amount;
        uint8 _paymentOption;
    }

   
    mapping (uint256=>Project) public projects;
    // mapping(string=>uint256) public 

    mapping (bytes32=>bool) public isRedeemed;

    // uint256 [] projectList;
    uint256 idCounter = 0;
    
    address public multiSig;



    event ProjectRegistered(uint256 id,string name, address owner,uint256 totalParticipants, address[] paymentOptions);
    event IDOInvested(address investor,uint256 id,uint256 amount,uint256 _paymentOption);
    event MerkleRootSet(uint256 id, address setter, bytes32 merkleRoot);
 

    constructor(address _multiSig) {
        multiSig = _multiSig;
  
    }

    function registerProject(address[] memory _paymentOptions,string calldata  name, address owner,uint256 totalParticipants) external onlyOwner{
        require(_paymentOptions[0]!=address(0),"Empty Array");

        Project memory pr = Project(name,owner,_paymentOptions,0,totalParticipants,bytes32(0));
        projects[idCounter] = pr;
        idCounter++;
        emit ProjectRegistered(idCounter-1,name,owner,totalParticipants,_paymentOptions);
    }

    
    function setMerkleRoot(uint256 id,bytes32 _merkleRoot) external {
        address sender = msg.sender;
        require(sender==owner() || sender==projects[id].signer,"Unauthorized Sender");
        require(projects[id].signer!=address(0),"Project Not Initialized");
        projects[id].merkleRoot = _merkleRoot;
        emit MerkleRootSet(id,sender,_merkleRoot);
    }

    function purchaseIDO(ProjectInvestment calldata pi,bytes32[] calldata proof) external whenNotPaused nonReentrant{
        require(projects[pi.id].merkleRoot!=bytes32(0),"Merkle Root Not Initialized");
        require(projects[pi.id].signer!=address(0),"Invalid Project");
        require(projects[pi.id].participantsCount<projects[pi.id].participantsLimit,"Participation Limit Reached");
        address sender = msg.sender;
        bytes32 leaf =  keccak256(abi.encode(pi.id,sender,pi.amount,address(this)));

        require(!isRedeemed[leaf],"Leaf Already redeemed");
        bool verified = MerkleProof.verify(proof, projects[pi.id].merkleRoot, leaf);
        require(verified,"Incorrect Leaf");
        isRedeemed[leaf] = true;

        projects[pi.id].participantsCount +=1; 
        IERC20(projects[pi.id].paymentOptions[pi._paymentOption]).safeTransferFrom(sender,multiSig,pi.amount);
        emit IDOInvested(sender,pi.id,pi.amount,pi._paymentOption);
    }


    





}


