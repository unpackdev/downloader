// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IV3Router.sol";
import "./IWETH.sol";
import "./poolchecker.sol";
import "./IRouter02.sol";
import "./SafeERC20.sol";

contract DonorshipPaymentProcessor is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    //receiver of primary fee
    address public primaryBeneficiary;
    //primary fee applied to donations (base 10_000)(500 = 5%
    uint256 public primaryFee;
    IV3SwapRouter public swapRouter;
    Router02 public router02;
    TokenPoolChecker public poolchecker;
    WETH public weth;
    

    /* MULTI_SIG_CONFIG */
    address public signer1;
    address public signer2;
    address immutable public signerRecovery;
    mapping(address => bool) public signerRecoveryVotes;
    
    struct PoolData {
        bool isPool;
        uint poolVersion;
        address[] v3Path;
        uint24[] poolFees;
    }
    enum PoolVersion {
        None,
        V2,
        V3
    }
        struct V3Data {
        address[] v3Path;
        uint24[] poolFees;
    }
    enum RequestType {
        PrimaryFeeChange,
        PrimaryBeneficiaryChange,
        AffiliateFeeChange,
        AffiliateRemoval,
        AffiliateGlobalFeeToggle,
        IndividualAffiliateFeeToggle,
        AffiliateWalletAddressChange
    }
    struct MultiSigRequest {
        address initiator;
        address newAddress;
        uint256 newFee;
        bytes32 affiliateID;
        bool requestActive;
        RequestType requestType;
    }

    MultiSigRequest public currentRequest;

    /* AFFILIATE_CONFIG */
    struct Affiliate{
        address receiver;
        uint256 feeAmount;
        bool feeEnabledInvidually;
        bytes32 affiliateID;
    }
    Affiliate[] affiliates;
    mapping(bytes32 => uint256) public affiliateIDtoIndex;
    mapping(bytes32 => bool) public affiliateIDexists;
    bool public isAffiliateFeeEnabled;
    /* */

    constructor(
        address payable _irouter,
        address _signer1,
        address _signer2,
        address _primaryBeneficiary,
        uint256 _primaryFee,
        address _weth,
        address payable _router02,
        address _poolchecker
    ){
        swapRouter = IV3SwapRouter(_irouter);
        isAffiliateFeeEnabled = false;
        signer1 = _signer1;
        signer2 = _signer2;
        signerRecovery = msg.sender;
        primaryBeneficiary = _primaryBeneficiary;
        primaryFee = _primaryFee;
        weth = WETH(_weth);
        router02 = Router02(_router02);
        poolchecker = TokenPoolChecker(_poolchecker);
    }

    function enactPrimaryFee(uint256 _amountIn) public view returns(uint256 _amountDeducted, uint256 _totalOutAfterFee)
    {
        require(_amountIn > 0, "Amount must be greater than 0");
        uint256 amountOutAfterFee = (_amountIn * (10_000 - primaryFee)) / 10_000;
        uint256 totalDeduction = (_amountIn - amountOutAfterFee);

        return (totalDeduction, amountOutAfterFee);
    }
    function enactSecondaryFee(uint256 _amountIn, bytes32 _affiliateID) public view returns(uint256 _amountDeducted, uint256 _totalOutAfterFee)
    {
        require(_amountIn > 0, "Amount must be greater than 0");
        uint256 secondaryFee = affiliates[affiliateIDtoIndex[_affiliateID]].feeAmount;

        uint256 amountOutAfterFee = (_amountIn * (10_000 - secondaryFee)) / 10_000;
        uint256 totalDeduction = (_amountIn - amountOutAfterFee);

        return (totalDeduction , amountOutAfterFee);
    }
    function processTokenDonation(
        bytes32 _affiliateID,
        address _charity,
        uint256 _tokenAmount,
        address tokenAddress
        ) public payable  whenNotPaused {
        require(affiliateIDexists[_affiliateID], "Affiliate ID");

        TokenPoolChecker.PoolVersion version = poolchecker.getPoolVersion(tokenAddress);

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenAmount);

        uint256 amountWETH;

        if (version == TokenPoolChecker.PoolVersion.V2) {
            amountWETH = swapV2TokensForEth(tokenAddress, _tokenAmount, address(this));
        } else if (version == TokenPoolChecker.PoolVersion.V3) {
            TokenPoolChecker.V3Data memory v3Data = poolchecker.getV3Data(tokenAddress);
            uint24 fee0 = v3Data.poolFees[0];
            uint24 fee1 = (v3Data.v3Path.length == 3) ? v3Data.poolFees[1] : 0;
            amountWETH = swapV3TokensForEth(tokenAddress, _tokenAmount, v3Data.v3Path, fee0, fee1);
        } else {
            revert("pool not found");
        }
        uint affIndex = affiliateIDtoIndex[_affiliateID];
        //get fee status for individual affiliate
        bool feeEnabledInvidually = affiliates[affIndex].feeEnabledInvidually;
        //always apply primary fee
        (uint256 primaryDeductionAmount, ) = enactPrimaryFee(amountWETH);
        //enum aff receiver
        address affReceiver = affiliates[affIndex].receiver;
        //init the deduction amount to 0 for readibility
        uint256 secondaryDeductionAmount = 0;
        //if affiliate fees enabled, enact second fee from the original msg.value
        if (isAffiliateFeeEnabled && feeEnabledInvidually) {
            (secondaryDeductionAmount, ) = enactSecondaryFee(amountWETH, _affiliateID);
        }
        //get total donation amount
        uint256 totalDonationToCharity = (amountWETH - primaryDeductionAmount - secondaryDeductionAmount);

        weth.withdraw(amountWETH);
        //transfer eth to their locations
        payable(_charity).transfer(totalDonationToCharity);
        payable(primaryBeneficiary).transfer(primaryDeductionAmount);
        //if secondaryDeductionAmount > 0, transfer to affiliate
        if (isAffiliateFeeEnabled && feeEnabledInvidually) {
            payable(affReceiver).transfer(secondaryDeductionAmount);
        }
        //emit event
        emit DonationProcessed(secondaryDeductionAmount, primaryDeductionAmount, totalDonationToCharity);
    }
    function swapV2TokensForEth(address _tokenAddress, uint256 _tokenAmountIn, address _recipient) internal nonReentrant returns(uint256) {
        IERC20(_tokenAddress).safeApprove(address(router02), _tokenAmountIn);
        uint allowance = IERC20(_tokenAddress).allowance(address(this), address(router02));
        require(allowance >= _tokenAmountIn, "Failed to approve tokens for swap");

        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = router02.WETH();

        // Get the estimated output amount
        uint[] memory amountsOut = router02.getAmountsOut(_tokenAmountIn, path);
        uint estimatedOutput = amountsOut[1];

        // Perform the swap
        router02.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmountIn, 
            0, 
            path, 
            _recipient, 
            block.timestamp
        );

        return estimatedOutput; 
    }
    function swapV3TokensForEth(
        address _tokenAddress,
        uint256 _tokenAmountIn,
        address[] memory v3Path,
        uint24 fee0,
        uint24 fee1 // This can be 0 if there's no second fee.
    ) internal nonReentrant returns (uint256 amountETH) {
        IERC20(_tokenAddress).safeApprove(address(swapRouter), _tokenAmountIn);

        bytes memory path;
        if (v3Path.length == 2) { 
            // Direct ETH pair
            path = abi.encodePacked(_tokenAddress, fee0, address(weth));
        } else { 
            // Non-ETH pair
            path = abi.encodePacked(_tokenAddress, fee0, v3Path[1], fee1, address(weth));
        }

        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            amountIn: _tokenAmountIn,
            amountOutMinimum: 0 
        });    

        amountETH = swapRouter.exactInput(params);
        return amountETH;
    }


    function processDonation(bytes32 _affiliateID, address _charity) public payable nonReentrant whenNotPaused{
        require(msg.value > 0, "value must be greater than 0 for msg.value");
        require(_charity != address(0), "invalid address");

        // Check if the affiliate ID exists
        require(affiliateIDexists[_affiliateID], "Affiliate ID does not exist");
        // Fee always active for primary
        (uint256 primaryDeductionAmount, ) = enactPrimaryFee(msg.value);
        //init the deduction amount to 0 for readibility
        uint256 secondaryDeductionAmount = 0;
        //get fee status for individual affiliate
        bool feeEnabledInvidually = affiliates[affiliateIDtoIndex[_affiliateID]].feeEnabledInvidually;
        // if affiliate fees enabled, enact second fee from the original msg.value
        if (isAffiliateFeeEnabled && feeEnabledInvidually) {
            (secondaryDeductionAmount, ) = enactSecondaryFee(msg.value, _affiliateID);
        }
        //get total donation amount
        uint256 totalDonation = msg.value - primaryDeductionAmount - secondaryDeductionAmount;
        uint256 remainingEthFromPrimaryAndSecondary = msg.value - totalDonation;
        //transfer eth to their locations
        payable(_charity).transfer(totalDonation);
        payable(primaryBeneficiary).transfer(primaryDeductionAmount);
        //if affiliate fees enabled, enact second fee from the original msg.value
        if (isAffiliateFeeEnabled && feeEnabledInvidually) {
            address affReceiver = affiliates[affiliateIDtoIndex[_affiliateID]].receiver;
            payable(affReceiver).transfer(secondaryDeductionAmount);
        }
        // Check if there are any remaining funds (due to rounding or other issues)
        uint256 remainingFunds = remainingEthFromPrimaryAndSecondary - primaryDeductionAmount - secondaryDeductionAmount;
        if (remainingFunds > 0) {
            payable(owner()).transfer(remainingFunds);
        }
        //emit event
        emit DonationProcessed(secondaryDeductionAmount, primaryDeductionAmount, totalDonation);
    }
    function addAffiliate(bytes32 _affiliateID, address _receiver, uint256 _feeAmount) internal {
        require(_affiliateID > 0, "Affiliate ID must be greater than 0");
        require(_receiver != address(0), "Receiver must be a valid address");
        require(_feeAmount <= 500, "Fee amount must be <= 500");
        
        uint256 newIndex = affiliates.length; // Get current length as the new index
        affiliates.push(Affiliate(_receiver, _feeAmount, true, _affiliateID));
        affiliateIDtoIndex[_affiliateID] = newIndex; // Set mapping to use newIndex

        emit AffiliateAdded(_receiver, _feeAmount);
    }

    function addManyAffiliates(
    bytes32[] memory _affiliateIDs,
    address[] memory _receivers,
    uint256[] memory _feeAmounts
    ) public onlyOwner {
        require(
            _affiliateIDs.length == _receivers.length && _receivers.length == _feeAmounts.length,
            "Data mis-matching"
        );

        for (uint256 i = 0; i < _affiliateIDs.length; i++) {
            require(affiliateIDtoIndex[_affiliateIDs[i]] == 0, "Affiliate ID already exists");
            require(_receivers[i] != address(0), "Receiver must be a valid address");
            require(_feeAmounts[i] <= 500, "Fee amount must be <= 500");

            uint256 newIndex = affiliates.length; // Get current length as the new index
            affiliates.push(Affiliate(_receivers[i], _feeAmounts[i], true, _affiliateIDs[i])); // Push new affiliate
            affiliateIDtoIndex[_affiliateIDs[i]] = newIndex; // Set mapping to use newIndex
            affiliateIDexists[_affiliateIDs[i]] = true;

            emit AffiliateAdded(_receivers[i], _feeAmounts[i]);
        }
    }

    function getAffiliateFee(bytes32 _affiliateID) public view returns (uint256 _feeAmount) {
        require(affiliateIDexists[_affiliateID], "Affiliate ID does not exist");
        uint256 index = affiliateIDtoIndex[_affiliateID];
        return affiliates[index].feeAmount;
    }
    function getAffiliateAddress(bytes32 _affiliateID) public view returns (address _affiliateAddress) {
        require(affiliateIDexists[_affiliateID], "Affiliate ID does not exist");
        uint256 index = affiliateIDtoIndex[_affiliateID];
        return affiliates[index].receiver;
    }
    function listAllAffiliates() public view returns (Affiliate[] memory) {
        return affiliates;
    }
    function getAffiliateCount() public view returns (uint256 _affiliateCount) {
        return affiliates.length;
    }
    modifier onlySigner {
        require(msg.sender == signer1 || msg.sender == signer2, "Must be a signer");
        _;
    }
    function updateRouterAddress(address _newRouter) public onlyOwner {
        swapRouter = IV3SwapRouter(_newRouter);
    }
    function updateWETHAddress(address _newWETH) public onlyOwner {
        weth = WETH(_newWETH);
    }
    /*CHANGE_PRIMARY_BENEFICIARY_CONFIG */
    event PrimaryBeneficiaryChangeRequested
    (
        address indexed initiator,
        address indexed newBeneficiary
    );
    event PrimaryBeneficiaryChangeApproved
    (
        address indexed initiator,
        address indexed newBeneficiary
    );
    function requestSetPrimaryBeneficiaryChange(address _newPrimary) public onlySigner requireInactiveRequest{
        currentRequest = MultiSigRequest({
            initiator: msg.sender,
            newAddress: _newPrimary,
            newFee: 0,
            affiliateID: 0,
            requestActive: true,
            requestType: RequestType.PrimaryBeneficiaryChange
        });
        emit PrimaryBeneficiaryChangeRequested(msg.sender, _newPrimary);
    }
    /* END_CHANGE_PRIMARY_BENEFICIARY_CONFIG */

    /* CHANGE_PRIMARY_FEE_CONFIG */
    event PrimaryFeeChangeRequested
    (
        address indexed initiator,
        uint256 indexed newFee
    );
    event PrimaryFeeChangeApproved
    (
        address indexed initiator,
        uint256 indexed newFee
    );
    function requestSetPrimaryFeeChange(uint256 _newFee) public onlySigner requireInactiveRequest {
        require(_newFee <= 3000 && _newFee >= 100,"cant raise fee over 30% or set below 1%");

        currentRequest = MultiSigRequest({
            initiator: msg.sender,
            newAddress: address(0),
            newFee: _newFee,
            affiliateID: 0,
            requestActive: true,
            requestType: RequestType.PrimaryFeeChange
        });
        emit PrimaryFeeChangeRequested(msg.sender, _newFee);
    }
    /* END_CHANGE_PRIMARY_FEE_CONFIG */

    /* CHANGE_AFFILIATE_FEE_CONFIG */
    event AffiliateFeeChangeRequested
    (
        address indexed initiator,
        uint256 indexed newFee,
        bytes32 indexed affiliateID
    );
    event AffiliateFeeChangeApproved
    (
        address indexed initiator,
        uint256 indexed newFee,
        bytes32 indexed affiliateID
    );
    function requestSetAffiliateFeeChange(uint256 _newFee, bytes32 _affiliateID) public onlySigner requireInactiveRequest {
        require(_newFee <= 500 && _newFee >= 100,"cant raise fee over 5% or set below 1%");
        require(affiliateIDexists[_affiliateID], "Affiliate ID does not exist");
       
        currentRequest = MultiSigRequest({
            initiator: msg.sender,
            newAddress: address(0),
            newFee: _newFee,
            affiliateID: _affiliateID,
            requestActive: true,
            requestType: RequestType.AffiliateFeeChange
        });
        emit AffiliateFeeChangeRequested(msg.sender, _newFee, _affiliateID);
    }
    /* END_CHANGE_AFFILIATE_FEE_CONFIG */

    /* AFFILIATE_REMOVAL_CONFIG */
    event AffiliateRemovalRequested
    (
        address indexed initiator,
        bytes32 indexed affiliateID
    );
    event AffiliateRemovalApproved
    (
        address indexed initiator,
        bytes32 indexed affiliateID
    );
    function requestAffiliateRemoval(bytes32 _affiliateID) public onlySigner requireInactiveRequest {
        require(affiliateIDexists[_affiliateID], "Affiliate ID does not exist");
    
        currentRequest = MultiSigRequest({
            initiator: msg.sender,
            newAddress: address(0),
            newFee: 0,
            affiliateID: _affiliateID,
            requestActive: true,
            requestType: RequestType.AffiliateRemoval
        });
        emit AffiliateRemovalRequested(msg.sender, _affiliateID);
    }
    /* END_AFFILIATE_REMOVAL_CONFIG */

    /* AFFILIATE_GLOBAL_FEE_TOGGLE_CONFIG */
    event AffiliateGlobalFeeToggleRequested
    (
        address indexed initiator,
        bool indexed isEnabled
    );
    event AffiliateGlobalFeeToggleApproved
    (
        address indexed initiator,
        bool indexed isEnabled
    );
    function requestAffiliateGlobalFeeToggle() public onlySigner requireInactiveRequest{
        
        currentRequest = MultiSigRequest({
            initiator: msg.sender,
            newAddress: address(0),
            newFee: 0,
            affiliateID: 0,
            requestActive: true,
            requestType: RequestType.AffiliateGlobalFeeToggle
        });
        emit AffiliateGlobalFeeToggleRequested(msg.sender, isAffiliateFeeEnabled);
    }
    /* TOGGLE_INDIVIDUAL_AFFILIATE_FEE_CONFIG */
    event IndividualAffiliateFeeToggleRequested(
        address indexed initiator,
        bool indexed isEnabled
    );
    event IndividualAffiliateFeeToggleApproved(
        address indexed initiator,
        bool indexed isEnabled
    );
    function requestIndividualAffiliateFeeToggle(bytes32 _affiliateID) public onlySigner requireInactiveRequest {
        currentRequest = MultiSigRequest({
            initiator: msg.sender,
            newAddress: address(0),
            newFee: 0,
            affiliateID: _affiliateID,
            requestActive: true,
            requestType: RequestType.IndividualAffiliateFeeToggle
        });
        emit IndividualAffiliateFeeToggleRequested(msg.sender, affiliates[affiliateIDtoIndex[_affiliateID]].feeEnabledInvidually);
    }
    event AffiliateWalletAddressChangeRequested(
        address indexed initiator,
        address indexed newAddress,
        bytes32 indexed affiliateID
    );
    event AffiliateWalletAddressChangeApproved(
        address indexed initiator,
        address indexed newAddress,
        bytes32 indexed affiliateID
    );
    function requestAffiliateWalletAddressChange(address _newAddress, bytes32 _affiliateID) public onlySigner requireInactiveRequest {
        require(affiliateIDexists[_affiliateID], "Affiliate ID does not exist");
        currentRequest = MultiSigRequest({
            initiator: msg.sender,
            newAddress: _newAddress,
            newFee: 0,
            affiliateID: _affiliateID,
            requestActive: true,
            requestType: RequestType.AffiliateWalletAddressChange
        });
        emit AffiliateWalletAddressChangeRequested(msg.sender, _newAddress, _affiliateID);
    }
    /* END_AFFILIATE_GLOBAL_FEE_TOGGLE_CONFIG */
    error InvalidRequestType(RequestType requestType);
    function _approveRequest() public onlySigner {
        require(currentRequest.requestActive, "No active request");
        require(msg.sender != currentRequest.initiator, "the other signer must complete the transaction");

        if (currentRequest.requestType == RequestType.PrimaryBeneficiaryChange) {
            primaryBeneficiary = currentRequest.newAddress;
            emit PrimaryBeneficiaryChangeApproved(currentRequest.initiator, currentRequest.newAddress);
        } 
        else if (currentRequest.requestType == RequestType.PrimaryFeeChange) {
            primaryFee = currentRequest.newFee;
            emit PrimaryFeeChangeApproved(currentRequest.initiator, currentRequest.newFee);
        } 
        else if (currentRequest.requestType == RequestType.AffiliateFeeChange) {
            bytes32 _affiliateID = currentRequest.affiliateID;
            //get the index of the affiliate struct from the affiliateID
            uint256 indexToChange = affiliateIDtoIndex[_affiliateID];
            //set the new fee
            affiliates[indexToChange].feeAmount = currentRequest.newFee;
            emit AffiliateFeeChangeApproved(currentRequest.initiator, currentRequest.newFee, currentRequest.affiliateID);
        } 
        else if (currentRequest.requestType == RequestType.AffiliateRemoval) {
            //enum the affiliateID
            bytes32 _affiliateID = currentRequest.affiliateID;
            //get the index of the affiliate struct from the affiliateID
            uint256 indexToRemove = affiliateIDtoIndex[_affiliateID];
            //enumerate the last affiliate in the array
            uint256 lastIndex = affiliates.length - 1;
            //get the affiliateID of the last affiliate in the array
            bytes32 lastAffiliateID = getAffiliateID(affiliates[lastIndex]);
            // Move the last element to the spot of the one to remove
            affiliates[indexToRemove] = affiliates[lastIndex];
            // Update the mapping to point to the new indexA
            affiliateIDtoIndex[lastAffiliateID] = indexToRemove;
            // Delete the last element and reduce the array size
            affiliates.pop();
            // Remove the affiliate ID from the mapping
            delete affiliateIDtoIndex[_affiliateID];
            // set existence to false
            affiliateIDexists[_affiliateID] = false;
            emit AffiliateRemovalApproved(currentRequest.initiator, currentRequest.affiliateID);
        } 
        else if (currentRequest.requestType == RequestType.AffiliateGlobalFeeToggle) {
            isAffiliateFeeEnabled = !isAffiliateFeeEnabled;
            emit AffiliateGlobalFeeToggleApproved(currentRequest.initiator, isAffiliateFeeEnabled);
        }
        else if (currentRequest.requestType == RequestType.IndividualAffiliateFeeToggle) {
            bytes32 _affiliateID = currentRequest.affiliateID;
            //get the index of the affiliate struct from the affiliateID
            uint256 indexToChange = affiliateIDtoIndex[_affiliateID];
            //set the new fee
            affiliates[indexToChange].feeEnabledInvidually = !affiliates[indexToChange].feeEnabledInvidually;
            emit IndividualAffiliateFeeToggleApproved(currentRequest.initiator, affiliates[indexToChange].feeEnabledInvidually);
        }
        else if(currentRequest.requestType == RequestType.AffiliateWalletAddressChange){
            bytes32 _affiliateID = currentRequest.affiliateID;
            //get the index of the affiliate struct from the affiliateID
            uint256 indexToChange = affiliateIDtoIndex[_affiliateID];
            //set the new fee
            affiliates[indexToChange].receiver = currentRequest.newAddress;
            emit AffiliateWalletAddressChangeApproved(currentRequest.initiator, currentRequest.newAddress, currentRequest.affiliateID);
        }
        else {
            revert InvalidRequestType(currentRequest.requestType);
        }
        // Reset the request to indicate that it has been processed
        delete currentRequest;
    }
    /*AFFILIATE_HELPER_FUNCTIONS */
    function getAffiliateID(Affiliate memory affiliate) internal pure returns (bytes32){
        return affiliate.affiliateID;
    }
    function getCurrentRequest() public view returns (MultiSigRequest memory){
        return currentRequest;
    }
    function getCurrentRequestType() public view returns (RequestType){
        return currentRequest.requestType;
    }
    function getCurrentRequestInitiator() public view returns (address){
        return currentRequest.initiator;
    }
    function getIndividualAffiliateFeeStatus(bytes32 _affiliateID) public view returns (bool){
        return affiliates[affiliateIDtoIndex[_affiliateID]].feeEnabledInvidually;
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    address private ownerRequest;
    //override transferOwnership from ownable to allow for multi sig recovery
    function transferOwnership(address newOwner) public override onlySigner {
        require(newOwner != address(0), "Ownable: new owner cannot be the zero address");

        // Only update if no votes have been cast yet
        if(!ownerRecoveryVotes[signer1] && !ownerRecoveryVotes[signer2]) {
            ownerRequest = newOwner;
        }

        require(ownerRequest == newOwner, "Address not matching request. Signers must agree to new owner address");

        ownerRecoveryVotes[msg.sender] = true;

        // Check if both signers have agreed
        if(ownerRecoveryVotes[signer1] && ownerRecoveryVotes[signer2]) {
            _transferOwnership(newOwner);

            // Reset the state
            ownerRecoveryVotes[signer1] = false;
            ownerRecoveryVotes[signer2] = false;
            ownerRequest = address(0);
        }
    }
    /* END_AFFILIATE_HELPER_FUNCTIONS */
    mapping(address => bool) ownerRecoveryVotes;

    modifier onlyRecoveryAndSigners {
        require(msg.sender == signerRecovery || msg.sender == signer1 || msg.sender == signer2, "Must be a signer or recovery");
        _;
    }
    modifier requireInactiveRequest {
        require(currentRequest.requestActive == false, "request already exists");
        _;
    }
    /* RECOVER_FROM_COMPROMISED_SIGNER */
    event SingerRecovered(
        address indexed newSigner,
        address indexed lostSigner
    );
    function recoverLostDelegate(address _newSigner) public onlyRecoveryAndSigners{
        //for each call map address to true
        signerRecoveryVotes[msg.sender] = true;
        //if any 2 of 3 votes are true, reset signers
        if(
            signerRecoveryVotes[signer1] && signerRecoveryVotes[signer2] ||
            signerRecoveryVotes[signer1] && signerRecoveryVotes[signerRecovery] ||
            signerRecoveryVotes[signer2] && signerRecoveryVotes[signerRecovery]
        ){
            //determine which signer has not voted
            // if signer1 has not voted we will assume they are the lost delegate
            if(!signerRecoveryVotes[signer1]){
                signer1 = _newSigner;
                emit SingerRecovered(_newSigner, signer1);
            }
            //else if signer2 has not voted we will assume they are the lost delegate
            else if(!signerRecoveryVotes[signer2]){
                signer2 = _newSigner;
                emit SingerRecovered(_newSigner, signer2);
            }

            //reset votes
            signerRecoveryVotes[signer1] = false;
            signerRecoveryVotes[signer2] = false;
            signerRecoveryVotes[signerRecovery] = false;
        }
        
    }
    /* END_RECOVER_FROM_COMPROMISED_SIGNER */

    receive() payable external {}

    //by logic in contract this should never be able to be used. but in case of emergency and ETH is stuck in contract. this will allow the owner to withdraw it safely and transparently.
    function rescueETHFromContract() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    //by logic in contract this should never be able to be used. but in case of emergency and ERC20 is stuck in contract. this will allow the owner to withdraw it safely and transparently.
    function rescueERC20TokenFromContract(address _tokenAddress) public onlyOwner {
        bool transfer = IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this)));
        require(transfer, "Failed to transfer tokens");
    }
    event EthReceived(address indexed sender, uint256 amount);
    event DonationProcessed
    (
        uint256 affiliateTake,
        uint256 primaryTake,
        uint256 totalDonation
    );
    event AffiliateAdded
    (
        address receiver,
        uint256 feeAmount
    );
    event AffiliateFeeToggled
    (
        bool isEnabled
    );
    event AffiliateFeeChanged
    (
        uint256 affiliateID,
        uint256 newFee
    ); 
    event PrimaryFeeChanged
    (
        uint256 newFee
    );
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        token.safeApprove(spender, value);
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        token.safeTransferFrom(from, to, value);
    }


}