pragma solidity 0.8.21;
import "./Ownable.sol";
import "./IERC20.sol"; 
import "./IERC20.sol"; 
// import "./console.sol";


contract Vesting is Ownable {


    struct Project{ 
        string name;
        address signer;
        address token;
        uint256 IDOCount;
        uint256 participantsCount;
        uint256 participantsLimit;
    }


    struct ProjectInvestment{ 
        uint256 id;
        uint256 amount;
        uint256 idoNumber;
        uint8 _paymentOption;
    }

   
    mapping (uint256=>Project) public projects;
    // mapping(string=>uint256) public 
    mapping (address=>mapping(uint256 => bool)) public isInvested;

    mapping (bytes32=>bool) public isRedeemed;
    mapping (bytes32=>bool) public idoClaimed;

    // uint256 [] projectList;
    uint256 idCounter = 0;
    
    address public multiSig;
    address[] public paymentOptions = [0xdAC17F958D2ee523a2206206994597C13D831ec7,0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,0xE8799100F8c1C1eD81b62Ba48e9090D5d4f51DC4];
    uint256 constant Wei1 = 10**18;
    event TGEDeposited(uint256 id,uint256 amount,address depositer,address token);
    event ProjectRegistered(uint256 id,string name, address owner,uint256 totalParticipants);
    event IDOInvested(address investor,uint256 id,uint256 amount,uint256 idoNumber,uint256 _paymentOption);
    event IDOClaimed(address claimer,uint256 id,uint256 amount,uint256 vestingNumber,uint256 idoNumber);
 

    constructor(address _multiSig) {
        multiSig = _multiSig;
    }

    function registerProject(string memory name, address owner,uint256 totalParticipants) external onlyOwner{
        Project memory pr = Project(name,owner,address(0),0,0,totalParticipants);
        projects[idCounter] = pr;
        idCounter++;
        emit ProjectRegistered(idCounter-1,name,owner,totalParticipants);
    }

    
    function TGE(uint256 _id,uint256 initialSHO, address token, bytes memory signature) external {
        require(projects[_id].signer!=address(0));
        require(token!=address(0),"Invalid Token Address");
        require(initialSHO>0,"Invalid SHO");
        
        address sender = msg.sender;
        address signer = projects[_id].signer;
        bytes32 message =  keccak256(abi.encode(_id,sender,initialSHO,token,projects[_id].IDOCount));
        // console.logBytes32(message);
        (uint8 v, bytes32 r, bytes32 s) = extractRSV(signature);
        _validate(v, r, s, message, signer);
        // isRedeemed[message] = true;
        require(IERC20(token).transferFrom(sender,address(this),initialSHO),"Transfer_Falied");
        projects[_id].token = token;
        projects[_id].IDOCount += 1;

        emit TGEDeposited(_id,initialSHO,token,sender);

    }

    function purchaseIDO(ProjectInvestment memory pi,bytes memory signature) external {
        // require(projects[id].token!=address(0),"No IDO to claim");
        require(projects[pi.id].signer!=address(0));
        require(projects[pi.id].participantsCount<projects[pi.id].participantsLimit,"Participation Limit Reached");
        address sender = msg.sender;
        address signer = projects[pi.id].signer;
        bytes32 message =  keccak256(abi.encode(pi.id,sender,pi.amount,pi.idoNumber));
        require(!isRedeemed[message],"Signautre Already redeemed");

        (uint8 v, bytes32 r, bytes32 s) = extractRSV(signature);
        _validate(v, r, s, message, signer);
        isRedeemed[message] = true;
        // console.logBytes32(message);
        // console.log(userAmount);
        // uint256 stack_id = id;
        projects[pi.id].participantsCount +=1; 
        isInvested[sender][pi.id] = true;

        if(pi._paymentOption==0){
            TIERC20(paymentOptions[pi._paymentOption]).transferFrom(sender,multiSig,pi.amount);
            // console.log(TIERC20(paymentOptions[pi._paymentOption]).balanceOf(msg.sender));
            // console.log(userAmount);
        }
        else{
        IERC20(paymentOptions[pi._paymentOption]).transferFrom(sender,multiSig,pi.amount);
        }
        // uint256 stack_amount = pi.amount;
        // uint256 stackIDORate = idoRate;
        // uint256 stackIdoNumber = idoNumber;
        // uint256 stackPay = _paymentOption; 
        emit IDOInvested(sender,pi.id,pi.amount,pi.idoNumber,pi._paymentOption);


    }

    function claimIDO(uint256 id,uint256 amount,uint256 vestingNumber,uint256 idoNumber,bytes memory signature) external {
        require(projects[id].token!=address(0),"No IDO to claim");
        address sender = msg.sender;
        address signer = projects[id].signer;
        address idoToken = projects[id].token;
        bytes32 message =  keccak256(abi.encode(id,sender,amount,vestingNumber,idoNumber));
        require(!idoClaimed[message],"Invalid Status For Claim");
        (uint8 v, bytes32 r, bytes32 s) = extractRSV(signature);
        _validate(v, r, s, message, signer);
        idoClaimed[message] = true;

        IERC20(idoToken).transfer(sender,amount);

        emit IDOClaimed(sender, id, amount,idoNumber, vestingNumber);
    }


    function getDomainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode("0x01", address(this)));
    }

    function _validate(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 encodeData,
        address signer
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), encodeData));
        address recoveredAddress = ecrecover(digest, v, r, s);

        // console.logBytes32(digest);
        
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress!= address(0) && (recoveredAddress == signer), "INVALID_SIGNATURE");

    }

    function extractRSV(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            // First 32 bytes are the `r` value
            r := mload(add(signature, 32))

            // Next 32 bytes are the `s` value
            s := mload(add(signature, 64))

            // The last byte is the `v` value
            v := byte(0, mload(add(signature, 96)))
        }
    }

    function updatePaymentOption(address[3] memory _paymentoption) external onlyOwner {
        require(_paymentoption.length==3,"Invalid Array");
        paymentOptions = _paymentoption;
    }


    // Fallback function to reject incoming Ether
    receive() external payable {
        
    }
}


