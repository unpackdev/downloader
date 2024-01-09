// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./IERC721.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

abstract contract IWatts is IERC20 {
    function mintClaimable(address _to, uint256 _amount) external {}
}

contract WattsClaim is AccessControl, Ownable {
    using ECDSA for bytes32;

    /** CONTRACTS */
    IERC721 public slotieNFT;
    IWatts public watts;

    /** ROLES */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    /** GENERAL */
    uint256 public deployedTime = block.timestamp;

    /** CLAIMING */
    uint256 public issuanceRate = 10 * 10**18; // 10 per day
    uint256 public issuancePeriod = 1 days; 
    uint256 public claimStart = 1644624000; // 12 feb 00:00:00 UTC
    uint256 public slotieDeployTime = 1638877989; // 7 dec 11:53:09 UTC
    uint256 public earnPeriod = 90 days - (deployedTime - slotieDeployTime); // lock period minus time since slotie deploy
    uint256 public claimEndTime = deployedTime + earnPeriod;
    
    mapping(address => uint256) addressToAccumulatedWATTs; // accumulated watts before 12 feb 00:00
    mapping(address => uint256) addressToLastClaimedTimeStamp; // last time a claimed happened for a user

    /**  GIVEAWAYS */    
    bytes32 public preClaimMerkleProof = "";
    bytes32 public EHRMerkleProof = "";
    mapping(address => uint256) public addressToPreClaim; // whether an address claimed their initial claim or not
    mapping(address => uint256) public addressToEHRNonce; // safeguard against reusing proofs attack

    /** EVENTS */
    event ClaimedReward(address indexed user, uint256 reward, uint256 timestamp);
    event AccumulatedReward(address indexed user, uint256 reward, uint256 timestamp);
    event setSlotieNFTEvent(address indexed slotieNFT);

    event setIssuanceRateEvent(uint256 indexed issuanceRate);
    event setIssuancePeriodEvent(uint256 indexed issuancePeriod);
    event setClaimStartEvent(uint256 indexed claimStart);
    event setEarnPeriodEvent(uint256 indexed earnPeriod);
    event setClaimEndTimeEvent(uint256 indexed claimEndTime);

    event setPreClaimMerkleProofEvent(bytes32 indexed preClaimMerkleProof);
    event setEHRMerkleProofEvent(bytes32 indexed EHRMerkleProof);
    event setDeployTimeEvent(uint256 indexed deployTime);

    /** MODIFIERS */
    modifier slotieCanClaim() {
        //require(slotieNFT.balanceOf(msg.sender) > 0, "NOT A SLOTIE HOLDER");
        require(block.timestamp >= claimStart, "CLAIM LOCKED");
        require(address(slotieNFT) != address(0), "SLOTIE NFT NOT SET");
        require(address(watts) != address(0), "WATTS NOT SET");
        _;
    }

    constructor(
        address _slotieNFT,
        address _watts
    ) Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        slotieNFT = IERC721(_slotieNFT);
        watts = IWatts(_watts);
    }

    /** CLAIMING */
    function _slotieClaim(address recipient, uint256 preClaimAmount, uint256 ehrAmount, uint256 nonce, bytes32[] memory preClaimProof, bytes32[] memory ehrProof) internal {
        uint256 preClaimApplicable;
        uint256 ehrApplicable;

        if (preClaimProof.length > 0 && preClaimAmount != 0) {
            require(addressToPreClaim[recipient] == 0, "SLOTIE PRE CLAIM ALREADY DONE");
            bytes32 leaf = keccak256(abi.encodePacked(recipient, preClaimAmount));
            require(MerkleProof.verify(preClaimProof, preClaimMerkleProof, leaf), "SLOTIE INVALID PRE CLAIM PROOF");            
            addressToPreClaim[recipient] = 1;
            preClaimApplicable = 1;
        } 
        
        if (ehrProof.length > 0 && ehrAmount != 0) {
            require(nonce == addressToEHRNonce[recipient], "SLOTIE INCORRECT NONCE");
            bytes32 leaf = keccak256(abi.encodePacked(recipient, ehrAmount, addressToEHRNonce[recipient]));            
            require(MerkleProof.verify(ehrProof, EHRMerkleProof, leaf), "SLOTIE INVALID EHR PROOF");
            addressToEHRNonce[recipient] = addressToEHRNonce[recipient] + 1;
            ehrApplicable = 1;
        }

        uint256 balance = slotieNFT.balanceOf(recipient);
        uint256 accumulatedWatts = addressToAccumulatedWATTs[recipient];
        
        uint256 lastClaimed = addressToLastClaimedTimeStamp[recipient];  
        uint256 currentTime = block.timestamp;

        if (currentTime >= claimEndTime) {
            currentTime = claimEndTime; // we can only claim up to slotieClaimEndTime
        }

        if (deployedTime > lastClaimed) {
            lastClaimed = deployedTime; // we start from time of deployment
        } else if (lastClaimed == claimEndTime) {
            lastClaimed = currentTime; // if we claimed all we set reward to zero
        }
        
        uint256 reward = (currentTime - lastClaimed) * issuanceRate * balance / issuancePeriod;

        if (currentTime >= claimStart && accumulatedWatts != 0) {
            reward = reward + accumulatedWatts;
            delete addressToAccumulatedWATTs[recipient];
        }

        if (preClaimApplicable != 0) {
            reward = reward + preClaimAmount;
        }

        if (ehrApplicable != 0) {
            reward = reward + ehrAmount;
        }

        addressToLastClaimedTimeStamp[recipient] = currentTime;
        if (reward > 0) {            
            if (currentTime < claimStart) {
                addressToAccumulatedWATTs[recipient] = addressToAccumulatedWATTs[recipient] + reward;
                emit AccumulatedReward(recipient, reward, currentTime);
            } else {                
                watts.mintClaimable(recipient, reward);
                emit ClaimedReward(recipient, reward, currentTime);
            }
        }            
    }    

    function slotieGetClaimableBalance(address recipient, uint256 preClaimAmount, uint256 ehrAmount, uint256 nonce, bytes32[] memory preClaimProof, bytes32[] memory ehrProof) external view returns (uint256) {
        require(address(slotieNFT) != address(0), "SLOTIE NFT NOT SET");

        uint256 preClaimApplicable;
        uint256 ehrApplicable;

        if (preClaimProof.length > 0 && preClaimAmount != 0) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient, preClaimAmount));
            preClaimApplicable = MerkleProof.verify(preClaimProof, preClaimMerkleProof, leaf) && addressToPreClaim[recipient] == 0 ? 1 : 0;
        } 
        
        if (ehrProof.length > 0 && ehrAmount != 0) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient, ehrAmount, nonce));
            ehrApplicable = MerkleProof.verify(ehrProof, EHRMerkleProof, leaf) && nonce == addressToEHRNonce[recipient] ? 1 : 0;
        }

        uint256 balance = slotieNFT.balanceOf(recipient);
        uint256 lastClaimed = addressToLastClaimedTimeStamp[recipient];  
        uint256 accumulatedWatts = addressToAccumulatedWATTs[recipient];
        uint256 currentTime = block.timestamp;

        if (currentTime >= claimEndTime) {
            currentTime = claimEndTime;
        }

        if (deployedTime > lastClaimed) {
            lastClaimed = deployedTime;
        } else if (lastClaimed == claimEndTime) {
            lastClaimed = currentTime;
        }
        
        uint256 reward = (currentTime - lastClaimed) * issuanceRate * balance / issuancePeriod;

        if (accumulatedWatts != 0) {
            reward = reward + accumulatedWatts;
        }

        if (preClaimApplicable != 0) {
            reward = reward + preClaimAmount;
        }

        if (ehrApplicable != 0) {
            reward = reward + ehrAmount;
        }

        return reward;
    }

    function slotieClaim(uint256 preClaimAmount, uint256 ehrAmount, uint256 nonce, bytes32[] memory preClaimProof, bytes32[] memory ehrProof) external slotieCanClaim {
        _slotieClaim(msg.sender, preClaimAmount, ehrAmount, nonce, preClaimProof, ehrProof);
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(slotieNFT), "ONLY CALLABLE FROM SLOTIE");
        bytes32[] memory empty;

        if (from != address(0)) {
            _slotieClaim(from, 0, 0, 0, empty, empty);
        }

        if (to != address(0)) {
            _slotieClaim(to, 0, 0, 0, empty, empty);
        }
    }


    /** OWNER */
    function setSlotieNFT(address newSlotieNFT) external onlyOwner {
        slotieNFT = IERC721(newSlotieNFT);
        emit setSlotieNFTEvent(newSlotieNFT);
    }

    function setDeployTime(uint256 newDeployTime) external onlyOwner {
        deployedTime = newDeployTime;
        emit setDeployTimeEvent(newDeployTime);
    }

    /** Slotie Claim variables */
    function setIssuanceRate(uint256 newIssuanceRate) external onlyOwner {
        issuanceRate = newIssuanceRate;
        emit setIssuanceRateEvent(newIssuanceRate);
    }

    function setIssuancePeriod(uint256 newIssuancePeriod) external onlyOwner {
        issuancePeriod = newIssuancePeriod;
        emit setIssuancePeriodEvent(newIssuancePeriod);
    }

    function setClaimStart(uint256 newClaimStart) external onlyOwner {
        claimStart = newClaimStart;
        emit setClaimStartEvent(newClaimStart);
    }

    function setEarnPeriod(uint256 newEarnPeriod) external onlyOwner {
        earnPeriod = newEarnPeriod;       
        emit setEarnPeriodEvent(newEarnPeriod);
    }

    function setClaimEndTime(uint256 newClaimEndTime) external onlyOwner {
        claimEndTime = newClaimEndTime;
        emit setClaimEndTimeEvent(newClaimEndTime);
    }

    function setPreClaimMerkleProof(bytes32 newPreClaimMerkleProof) external onlyOwner {
        preClaimMerkleProof = newPreClaimMerkleProof;
        emit setPreClaimMerkleProofEvent(newPreClaimMerkleProof);
    }

    function setEHRMerkleProof(bytes32 newEHRMerkleProof) external onlyOwner {
        EHRMerkleProof = newEHRMerkleProof;
        emit setEHRMerkleProofEvent(newEHRMerkleProof);
    }

    function setSlotieDeployTimeAndClaimEndTime(uint256 newDeployTime, uint256 newSlotieClaimEndTime) external onlyOwner {
        deployedTime = newDeployTime;
        claimEndTime = newSlotieClaimEndTime;
        emit setDeployTimeEvent(newDeployTime);
        emit setClaimEndTimeEvent(newSlotieClaimEndTime);
    }
}