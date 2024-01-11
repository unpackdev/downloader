// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.0 <0.9.0;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Context.sol";
import "./AccessControl.sol";

import "./Address.sol";

import "./console.sol";

interface FoundationCollection {
    function safeTransferFrom (address from, address to, uint256 tokenId) external;
}

contract RRBAYCRSVP is ReentrancyGuard, Pausable, AccessControl {
    FoundationCollection public immutable RRBAYCContract;
    
    enum RSVPStatus {
        NEW_RECORD,
        PRE_ORDERED,
        PRE_ORDER_FULFILLED,
        NOT_AVAILABLE_FOR_PRE_ORDER,
        PREVIOUSLY_MINTED
    }
    
    struct RSVP {
        RSVPStatus status;
        uint16 apeId;
        address buyer;
        uint createdAt;
    }
    
    address public ryderAdminAddress;
    
    uint public constant apeSalePrice = 0.15 ether;
    uint public constant maxRsvpsPerTx = 6;
    uint public constant timeUntilUserCanCancel = 14 days;
    
    mapping (uint => RSVP) public apeIdsToRSVPsMapping;
    
    uint public ethAvailableToWithdraw;
    
    event RSVPCreated(uint16 indexed originalApeId, address indexed buyer, uint createdAt);
    event RSVPFulfilled(uint16 indexed originalApeId, uint16 indexed RRBAYCId, address indexed buyer, uint createdAt);
    event RSVPCanceled(uint16 indexed originalApeId, address indexed buyer, uint createdAt);
    event RefundIssued(uint indexed amount, address indexed buyer);
    
    event Withdraw(uint indexed total, uint paulyShare, uint middleShare, uint hwonderShare, uint ryderShare);
    event FailsafeWithdraw(uint indexed amount);
    
    event SeedPreviouslyMinted(uint[] originalApeIds);
    event UnSeedPreviouslyMinted(uint[] originalApeIds);
    event SetSomeApesAside(uint[] originalApeIds);
    event UnSetSomeApesAside(uint[] originalApeIds);
    
    uint public preOrderCount;
    uint public preOrderFulfilledCount;
    uint public preOrderCanceledCount;
    uint public notAvailableForPreOrderCount;
    uint public previouslyMintedCount;
    
    constructor(address RRBAYCAddress, address ryder, address[] memory admins) {
        RRBAYCContract = FoundationCollection(RRBAYCAddress);
        
        ryderAdminAddress = ryder;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, ryderAdminAddress);
        
        for (uint i = 0; i < admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }
    
    function getTotalRSVPCost(uint RSVPCount) public pure returns (uint) {
        return RSVPCount * apeSalePrice;
    }
    
    function availableApesCount() public view returns (uint16) {
        uint neverAvail = previouslyMintedCount + notAvailableForPreOrderCount;
        uint reservedCount = preOrderCount - preOrderCanceledCount;
        
        return uint16(10_000 - neverAvail - reservedCount);
    }
    
    function seedPreviouslyMinted(uint[] memory originalApeIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < originalApeIds.length; i++) {
            uint apeId = originalApeIds[i];
            RSVP storage rsvp = apeIdsToRSVPsMapping[apeId];
            
            require(rsvp.status == RSVPStatus.NEW_RECORD, "Ape is already marked as pre-ordered");
            
            rsvp.status = RSVPStatus.PREVIOUSLY_MINTED;
        }
        
        previouslyMintedCount += originalApeIds.length;
        
        emit SeedPreviouslyMinted(originalApeIds);
    }
    
    function unSeedPreviouslyMinted(uint[] memory originalApeIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < originalApeIds.length; i++) {
            uint apeId = originalApeIds[i];
            RSVP storage rsvp = apeIdsToRSVPsMapping[apeId];
            
            require(rsvp.status == RSVPStatus.PREVIOUSLY_MINTED, "Wrong status");
            
            rsvp.status = RSVPStatus.NEW_RECORD;
        }
        
        previouslyMintedCount -= originalApeIds.length;
        
        emit UnSeedPreviouslyMinted(originalApeIds);
    }
    
    function setSomeApesAside(uint[] memory originalApeIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < originalApeIds.length; i++) {
            uint apeId = originalApeIds[i];
            RSVP storage rsvp = apeIdsToRSVPsMapping[apeId];
            
            require(rsvp.status == RSVPStatus.NEW_RECORD, "Ape is already marked as pre-ordered");
            
            rsvp.status = RSVPStatus.NOT_AVAILABLE_FOR_PRE_ORDER;
        }
        
        notAvailableForPreOrderCount += originalApeIds.length;
        
        emit SetSomeApesAside(originalApeIds);
    }
    
    function unSetSomeApesAside(uint[] memory originalApeIds) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < originalApeIds.length; i++) {
            uint apeId = originalApeIds[i];
            RSVP storage rsvp = apeIdsToRSVPsMapping[apeId];
            
            require(rsvp.status == RSVPStatus.NOT_AVAILABLE_FOR_PRE_ORDER, "Ape isn't set aside");
            
            rsvp.status = RSVPStatus.NEW_RECORD;
        }
        
        notAvailableForPreOrderCount -= originalApeIds.length;
        
        emit UnSetSomeApesAside(originalApeIds);
    }

    function pause() public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    
    function grantAdminRole(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, newAddress);
    }
    
    function setRyderAdminAddress(address newAddr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ryderAdminAddress = newAddr;
    }
    
    function batchCreateRSVP(uint16[] memory originalApeIds) payable external whenNotPaused nonReentrant() {
        uint requestedTokenCount = originalApeIds.length;
        uint refundTokenCount;
        uint initialTotalCost = getTotalRSVPCost(requestedTokenCount);
        
        require(originalApeIds.length <= maxRsvpsPerTx, "Too many ape ids requested");
        require(msg.value == initialTotalCost, "Wrong price");
        
        for (uint i = 0; i < requestedTokenCount; i++) {
            uint16 originalApeId = originalApeIds[i];
            RSVP memory existing = apeIdsToRSVPsMapping[originalApeId];
            
            if (existing.status == RSVPStatus.NEW_RECORD) {
                internalCreateRSVP(originalApeId);
            } else {
                refundTokenCount++;
            }
        }
        
        uint fulfilledTokenCount = requestedTokenCount - refundTokenCount;
        
        require(fulfilledTokenCount > 0, "All requested apes are already reserved");
        
        preOrderCount += fulfilledTokenCount;
        
        if (refundTokenCount > 0) {
            uint newTotalCost = getTotalRSVPCost(fulfilledTokenCount);
            uint refundAmount = initialTotalCost - newTotalCost;
            
            Address.sendValue(payable(msg.sender), refundAmount);
            
            emit RefundIssued(refundAmount, msg.sender);
        }
    }
    
    function internalCreateRSVP(uint16 originalApeId) private {
        RSVP storage existing = apeIdsToRSVPsMapping[originalApeId];
        
        require(originalApeId >= 0 && originalApeId < 10_000, "Invalid ape id");
        require(msg.sender == tx.origin, "No contracts");
        require(existing.status == RSVPStatus.NEW_RECORD, "Ape is already reserved");
        
        existing.apeId = originalApeId;
        existing.status = RSVPStatus.PRE_ORDERED;
        existing.buyer = msg.sender;
        existing.createdAt = block.timestamp;
        
        emit RSVPCreated(originalApeId, msg.sender, block.timestamp);
    }
    
    function batchFulfillRSVP(uint16[] memory originalApeIds, uint16[] memory RRBAYCids) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (originalApeIds.length == RRBAYCids.length, "Mismatched arrays");
        
        for (uint i = 0; i < originalApeIds.length; i++) {
            uint16 originalApeId = originalApeIds[i];
            uint16 RRBAYCid = RRBAYCids[i];
            
            internalFulfillRSVP(originalApeId, RRBAYCid);
        }
        
        preOrderFulfilledCount += originalApeIds.length;
    }
    
    function activePreOrderCount() public view returns (uint) {
        return preOrderCount - preOrderFulfilledCount - preOrderCanceledCount;
    }
    
    function preOrdersToFulfill() public view returns (RSVP[] memory) {
        RSVP[] memory result = new RSVP[](activePreOrderCount());
        
        uint currentApeId = 0;
        uint currentPreOrderIndex = 0;
        
        while (currentApeId < 10_000 && currentPreOrderIndex < preOrderCount) {
            RSVP storage rsvp = apeIdsToRSVPsMapping[currentApeId];
            
            if (rsvp.status == RSVPStatus.PRE_ORDERED) {
                result[currentPreOrderIndex] = rsvp;
                currentPreOrderIndex++;
            }
            
            currentApeId++;
        }
        
        return result;
    }
    
    function internalFulfillRSVP(uint16 originalApeId, uint16 RRBAYCid) private {
        RSVP storage rsvp = apeIdsToRSVPsMapping[originalApeId];
        
        require(rsvp.status == RSVPStatus.PRE_ORDERED, "Not preordered");
        
        rsvp.status = RSVPStatus.PRE_ORDER_FULFILLED;
        
        RRBAYCContract.safeTransferFrom(ryderAdminAddress, rsvp.buyer, RRBAYCid);
        ethAvailableToWithdraw += apeSalePrice;
        
        emit RSVPFulfilled(originalApeId, RRBAYCid, rsvp.buyer, rsvp.createdAt);
    }
    
    function cancelRSVP(uint16 originalApeId) external nonReentrant() {
        require(msg.sender == tx.origin, "No contracts");
        
        RSVP memory existing = apeIdsToRSVPsMapping[originalApeId];
        
        require(existing.status == RSVPStatus.PRE_ORDERED, "Only active RSVPs can be canceled");
        require((existing.buyer == msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized");
        
        uint timePassed = block.timestamp - existing.createdAt;
        
        if (timePassed < timeUntilUserCanCancel) {
            require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not enough time has passed");
        }
        
        delete apeIdsToRSVPsMapping[originalApeId];
        
        preOrderCanceledCount++;
        
        Address.sendValue(payable(existing.buyer), apeSalePrice);
        
        emit RSVPCanceled(originalApeId, existing.buyer, existing.createdAt);
    }
    
    address public constant ryderPaymentAddress = 0x592814FF14E030B51F6087032DB0f88F4214F254;
    address public constant middlePaymentAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    address public constant hwonderPaymentAddress = 0xF9C2Ba78aE44ba98888B0e9EB27EB63d576F261B;
    address public constant paulyPaymentAddress = 0x7D2550161E8A31D0b9585Bb9c88E63E9644af740;
    
    function withdraw() external nonReentrant() {
        require(msg.sender == tx.origin, "No contracts");
        
        uint balance = ethAvailableToWithdraw;
        
        require(balance > 0, "Nothing to withdraw");
        
        uint paulyShare = (balance * 15) / 100;
        uint middleShare = (balance * 15) / 100;
        uint hwonderShare = (balance * 15) / 100;
        uint ryderShare = balance - paulyShare - middleShare - hwonderShare;
        
        emit Withdraw(ethAvailableToWithdraw, paulyShare, middleShare, hwonderShare, ryderShare);
        
        ethAvailableToWithdraw = 0;
        
        Address.sendValue(payable(paulyPaymentAddress), paulyShare);
        Address.sendValue(payable(middlePaymentAddress), middleShare);
        Address.sendValue(payable(hwonderPaymentAddress), hwonderShare);
        Address.sendValue(payable(ryderPaymentAddress), ryderShare);
    }
    
    function failsafeWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit FailsafeWithdraw(address(this).balance);
        
        require(payable(msg.sender).send(address(this).balance));
    }
    
    fallback() external payable {
        ethAvailableToWithdraw += msg.value;
    }
    receive() external payable {
        ethAvailableToWithdraw += msg.value;
    }
}
