pragma solidity 0.7.6;
pragma abicoder v2;


import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./INXMaster.sol";
import "./IDistributor.sol";


/// @author iTrust Dev Team
/// @title Insurance contract for exchanges to purchase Nexus Mutual cover
contract ITrustInsureV3
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    enum CoverClaimStatus { 
        NoActiveClaim, 
        Processing, 
        PaymentReady, 
        Complete, 
        Rejected 
    }

    struct Exchange {
        bool active;
        uint256 feePercentage;
        address payable treasuryAddress;
        string name;
        uint256[] coverIds;
    }

    struct User {
        address walletAddress;
        uint256[] coverIds;
    }

    struct CoverData {
        uint256 coverId;
        uint8 status;
        uint256 sumAssured;
        uint16 coverPeriod;
        uint256 validUntil;
        address contractAddress;
        address coverAsset;
        uint256 premiumInNXM;
        address memberAddress;
        uint256 claimId;        
        uint256 claimStatus;
        uint256 claimAmountPaid;
        address claimAsset;    
        bool claimsAllowed;
        bool claimed;
        bool iTrustOwned;
    }

    uint8 internal constant FALSE = 0;
    uint8 internal constant TRUE = 1;
    bool internal _paused;
    uint256 internal _iTrustFeePercentage;
    uint256 public addressRequestFee;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address payable public iTrustTreasury;
    address internal _nxmTokenAddress;
    address internal _distributorAddress;
    address[] internal _exchangeList;
    
    string[] internal _userIds;
    uint8 internal LOCKED;
    mapping (address => uint8) internal _adminList;
    mapping(address => Exchange) internal _exchanges;
    mapping(uint256 => address) internal _exchangeLocations;
    mapping(address => string) internal _addressRequests;
    mapping(string => User) internal _userPolicies;
    mapping(uint256 => uint256) internal _claimIds; //key is coverid
    mapping(uint256 => uint256) internal _claimedAmounts; //key is coverid
    mapping(uint256 => uint8) internal _claimCount;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;
   
    uint constant DIV_PRECISION = 10000;

    event ITrustClaimPayoutRedeemed (
        uint indexed coverId,
        uint indexed claimId,
        address indexed receiver,
        uint amountPaid,
        address coverAsset
    );

    event ITrustCoverBought(
        uint256 indexed coverId,
        string exchange,
        string guid,
        address buyer
    );

    function nonReentrant() internal {
        require(LOCKED == FALSE, "reentrant call");        
    }

    function onlyAdmin() internal view {
        require(
            _adminList[msg.sender] ==TRUE,
            "not an admin"
        );
    }

    function ifNotPaused() internal view{
        require(!_paused, "Contract Frozen");
    }
    
    /// @dev - reinitialises distributor in contract
    /// @param distributorAddress - address of distributor
    function setDistributor(address distributorAddress) 
        external 
    {
        onlyAdmin();
        _distributorAddress = distributorAddress;
    }
    
    /// @dev list of users    
    function getGuids() external view returns (string[] memory) {
        return _userIds;
    }
    
    /// @dev extracts price from cover data
    function _getCoverPrice(bytes calldata data) internal pure returns (uint256) {
        uint256 price;
        uint256 priceInNXM;
        uint256 expiresAt;
        uint256 generatedAt;
        uint8 v;
        bytes32 r;
        bytes32 s;
        (price, priceInNXM, expiresAt, generatedAt, v, r, s) = abi.decode(
            data,
            (uint256, uint256, uint256, uint256, uint8, bytes32, bytes32)
        );
        return price;
    }

    /// @dev buy cover on distributor contract
    /// @param exchangeAddress - address of exchange purchasing cover
    /// @param contractAddress - address of contract for cover
    /// @param coverAsset - address of asset
    /// @param sumAssured - amount of cover,
    /// @param coverPeriod - length of cover
    /// @param coverType - type of cover
    /// @param userGUID - user identifier returned by quote api
    /// @param coverData - signature of quote returned by quote api
    /// @return cover id for purchased cover
    function buyCover(
        address exchangeAddress,
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        uint8 coverType,
        string memory userGUID,
        bytes calldata coverData
    ) 
        external 
        payable        
    returns (uint256) {
        nonReentrant();
        ifNotPaused();
        LOCKED = TRUE;
        
        uint coverPrice = _getCoverPrice(coverData);
        uint priceIncludingFee = _iTrustFeePercentage.mul(coverPrice).div(DIV_PRECISION).add(coverPrice);

        if(coverAsset == ETH){
            require(msg.value == priceIncludingFee , "Eth Sent and Price Mismatch" );
        } else {
            IERC20 token = IERC20(coverAsset);
            uint balance = token.balanceOf(msg.sender);
            require(balance >= priceIncludingFee , "Token Balance and Price Mismatch" );
            token.safeTransferFrom(msg.sender, address(this), priceIncludingFee);
            token.approve(address(_distributorAddress), priceIncludingFee);
        }
         
        Exchange memory purchaseExchange = _exchanges[address(exchangeAddress)];
        require(
            purchaseExchange.treasuryAddress != address(0) && purchaseExchange.active,
            "iTrust: Inactive exchange"
        );
        
        uint256 coverId = getDistributorContract().buyCover{ value: msg.value }(
                contractAddress,
                coverAsset,
                sumAssured,
                coverPeriod,
                coverType,
                priceIncludingFee, //max cover price with fee
                coverData
            );
        
        _saveCoverDetails(userGUID, coverId, purchaseExchange.treasuryAddress);

        //send funds to exchange
        if(coverAsset == ETH){
            require(address(this).balance >= msg.value.sub(coverPrice), "iTrust: Insufficient ETH left for commission");
        } else {
            require(IERC20(coverAsset).balanceOf(address(this)) >= priceIncludingFee.sub(coverPrice), "iTrust: Insufficient Token Balance left for commission");
        }
        
        uint256 exchangeCommission;
        if (purchaseExchange.feePercentage > 0) {
             exchangeCommission = coverPrice
                 .mul(purchaseExchange.feePercentage)
                 .div(DIV_PRECISION);
        }        
        
        if(coverAsset == ETH){
            iTrustTreasury.transfer(msg.value.sub(coverPrice).sub(exchangeCommission));
        } else {
            // TODO:: check balance amounts
            IERC20(coverAsset).transfer(iTrustTreasury, priceIncludingFee.sub(coverPrice).sub(exchangeCommission));
        }
        

        if (exchangeCommission > 0) {                                        
            if(coverAsset == ETH){
                purchaseExchange.treasuryAddress.transfer(exchangeCommission);
            } else {
                IERC20(coverAsset).transfer(purchaseExchange.treasuryAddress, exchangeCommission);
            }
        }

        //transfer NFT to itrust Treasury
        getDistributorContract().safeTransferFrom(
            address(this),
            iTrustTreasury,
            coverId
        );   

        emit ITrustCoverBought(
            coverId,
            purchaseExchange.name,
            userGUID,
            msg.sender
        );

        LOCKED = FALSE;    
        return coverId;
    }

    function _saveCoverDetails(
        string memory userGUID,
        uint256 coverId,
        address exchangeAddress
    ) internal {
        _userPolicies[userGUID].coverIds.push(coverId);
        _exchanges[exchangeAddress].coverIds.push(coverId);
        _userIds.push(userGUID);
    }

    /// @dev See {IERC721Receiver-onERC721Received}.
    /// Always returns `IERC721Receiver.onERC721Received.selector`.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) 
        public 
        returns (bytes4) 
    {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /// @notice adds or updates exchange
    /// @param exchangeAddress - treasury of exchange
    /// @param feePercentage - percentage of commission
    /// @param active - flag
    /// @param name - name of exchange
    function addOrUpdateExchange(
        address payable exchangeAddress,
        uint256 feePercentage,
        bool active,
        string memory name
    ) 
        external 
    {
        onlyAdmin();
        if (_exchanges[exchangeAddress].treasuryAddress == address(0)) {
            _exchangeList.push(exchangeAddress);
        }
        _exchanges[exchangeAddress] = Exchange({
            feePercentage: feePercentage,
            treasuryAddress: exchangeAddress,
            active: active,
            name: name,
            coverIds: new uint256[](0)
        });
    }

    /// @notice sets commission for exchange
    /// @param exchangeAddress - address for exchange
    /// @param feePercentage - commision percentage
    function setExchangeFeePercentage(
        address exchangeAddress,
        uint256 feePercentage
    ) 
        external 
    {
        onlyAdmin();
        _exchanges[exchangeAddress].feePercentage = feePercentage;
    }

    /// @notice sets exchangeto active
    /// @param exchangeAddress - address for exchange
    function activateExchange(address exchangeAddress) 
        external 
    {
        onlyAdmin();
        ifNotPaused();
        _exchanges[exchangeAddress].active = true;
    }

    /// @notice sets exchangeto inactive
    /// @param exchangeAddress - address for exchange
    function deactivateExchange(address exchangeAddress) 
        external 
    {
        onlyAdmin();
        _exchanges[exchangeAddress].active = false;
    }

    /// @notice get details of exchange
    /// @param exchangeAddress - address for exchange
    /// @return details of exchange
    function getExchangeDetails(address exchangeAddress)
        external
        view   
        returns (Exchange memory)
    {
        onlyAdmin();        
        return _exchanges[exchangeAddress];
    }

    /// @notice get details of all exchanges
    /// @return details of all exchanges
    function getAllExchanges()
        external
        view      
        returns (Exchange[] memory)
    {
        onlyAdmin();
        
        Exchange[] memory ret = new Exchange[](_exchangeList.length);
        for (uint256 i = 0; i < _exchangeList.length; i++) {
            ret[i] = _exchanges[_exchangeList[i]];
        }
        return ret;
    }

    /// @notice Returns the commission percentage held in the distributor
    /// @return percentage of commission
    function getFeePercentage() external view returns (uint256) {
        return _iTrustFeePercentage;
    }

    /// @notice sets itrust treasury address
    /// @param iTrustTreasuryAddress - new address
    function setItrustTreasury(address payable iTrustTreasuryAddress)
        external
    {
        onlyAdmin();
        ifNotPaused();
        iTrustTreasury = iTrustTreasuryAddress;
    }

    /// @notice submits new claim to nexus
    /// @param userGUID - identifier of user
    /// @param coverId - id for clover to submit claim against
    /// @param coverClaimData - extra claim data abi encoded
    /// @return
    function submitClaim(
        string memory userGUID,
        uint256 coverId,
        bytes calldata coverClaimData
    ) 
        external 
        returns (uint256) 
    {        
        ifNotPaused();
        CoverData memory cover = getCoverDataForCover(coverId);        
        require(cover.iTrustOwned, "submit NFT");
        require(cover.claimsAllowed 
            && _userOwnsCover(userGUID, coverId) == TRUE 
            && msg.sender == _userPolicies[userGUID].walletAddress);//check cover
         
        uint256 claimId =
            getDistributorContract().submitClaim(coverId, coverClaimData);
        _claimIds[coverId] = claimId;
        _claimCount[coverId] = _claimCount[coverId] + TRUE;
        return claimId;
    }

    function _userOwnsCover(string memory userGUID, uint coverId) internal view returns (uint8) {
        uint16 i = 0;
        while (i < _userPolicies[userGUID].coverIds.length) {
            if (_userPolicies[userGUID].coverIds[i] == coverId) {
                return TRUE;
            }
            i++;
        }
        return FALSE;
    }

    function getCoverDataForCover(uint coverId) public view returns (CoverData memory cover){
        cover = CoverData(
            coverId,
            /*status:*/ 0, 
            /*sumAssured:*/ 0, 
            /*coverPeriod:*/ 0, 
            /*validUntil:*/ 0, 
            /*contactAddress:*/ address(0), 
            /*coverAsset:*/ address(0), 
            /*premiumInNXM:*/ 0, 
            /*memberAddress:*/ address(0), 
            /*claimId:*/ 0, 
            /*claimStatus:*/ uint256(CoverClaimStatus.NoActiveClaim),
            /*claimAmountPaid:*/ 0,
            /*claimAsset:*/ address(0),
            /*claimsAllowed:*/ false,
            /*claimed:*/ false,
            /*iTrustOwned:*/ false    
        );       
        
        (
            cover.status,
            cover.sumAssured,
            cover.coverPeriod,
            cover.validUntil,
            cover.contractAddress,
            cover.coverAsset,
            cover.premiumInNXM,
            cover.memberAddress
        ) = getDistributorContract().getCover(coverId);

        
        if (_claimIds[cover.coverId] != uint256(0)) {            
            IDistributor.ClaimStatus status;
            cover.claimStatus = uint256(CoverClaimStatus.Processing);
            cover.claimId = _claimIds[coverId];
            (
                status,
                cover.claimAmountPaid,
                cover.claimAsset
            ) = getDistributorContract().getPayoutOutcome(_claimIds[coverId]);

            if ( _claimedAmounts[coverId] != uint256(0) &&
                status == IDistributor.ClaimStatus.ACCEPTED) {

                cover.claimStatus = uint256(CoverClaimStatus.Complete);
                cover.claimed = true;

            } else if (
                status == IDistributor.ClaimStatus.ACCEPTED &&                
                _claimedAmounts[coverId] == uint256(0)
            ) {

                cover.claimStatus = uint256(CoverClaimStatus.PaymentReady);

            } else if ( status == IDistributor.ClaimStatus.REJECTED ) {

                cover.claimStatus = uint256(CoverClaimStatus.Rejected);

            }
        }
        cover.claimsAllowed = (_canMakeClaim(cover) == TRUE); 

        if(!cover.claimed){
            cover.iTrustOwned = _isItrustOwner(coverId);
        }               
        
        return cover;
    }
    

    /// @notice returns cover held for a user
    /// @param userGUID - user identifier
    /// @return covers - array of covers held by user
    function getCoverData(string memory userGUID)
        external
        view        
        returns (CoverData[] memory covers)
    {
        onlyAdmin();
        
        uint256 i;
        
        CoverData[] memory userCover = new CoverData[](_userPolicies[userGUID].coverIds.length);      
                 
        while (i < _userPolicies[userGUID].coverIds.length) {                            
            userCover[i] = getCoverDataForCover(_userPolicies[userGUID].coverIds[i]);            
            i++;
        }
        return userCover;
    }

    /// @notice creates a wallet registration request
    /// @dev pays eth fee to itrust treasury
    /// @param uid - user identifier
    function addAddressRequest(string memory uid) 
        external 
        payable 
    {        
        ifNotPaused();
        require(
            msg.value >= addressRequestFee,
            "Insufficient ETH"
        );
       
        _addressRequests[msg.sender] = uid;

        iTrustTreasury.transfer(msg.value);
        
    }

    /// @dev  Checks if the current sender has a request matching the _uid
    /// @param uid user identifer
    /// @return boolean
    function hasAddressRequest(string memory uid) external view returns (bool) {
        return
            keccak256(abi.encodePacked(_addressRequests[msg.sender])) ==
            keccak256(abi.encodePacked(uid));
    }

    /// @dev Checks if an _address / _uid combo matches
    /// @param uid - user identifer
    /// @param newAddress - address to check validity
    /// @return boolean
    function isValidAddressRequest(string memory uid, address newAddress)
        external
        view
        returns (bool)
    {
        onlyAdmin();
        
        return
            keccak256(abi.encodePacked(_addressRequests[newAddress])) ==
            keccak256(abi.encodePacked(uid));
    }

    /// @notice validates new address request
    /// @dev Checks if an _address / _uid combo matches
    /// @param uid - user identifer
    /// @param newAddress - address to check validity
     function validateAddressRequest(string memory uid, address newAddress)
        external
    {
        onlyAdmin();
        ifNotPaused();
        require(
            (keccak256(abi.encodePacked(_addressRequests[newAddress])) ==
                keccak256(abi.encodePacked(uid))),
            "address missmatch"
        );

        delete _addressRequests[newAddress];

        _userPolicies[uid].walletAddress = newAddress;
    }

    /**
     * @dev Pauses the vault
     */
    function pause() external  {
        onlyAdmin();
        _paused = true;
    }

    /**
     * @dev Unpauses the vault
     */
    function unpause() external {
        onlyAdmin();
        _paused = false;
    }

    /**
     * @dev add new admin
     */
    function addAdminAddress(address newAddress) external  {
        onlyAdmin();
        require(_adminList[newAddress] ==FALSE);
        _adminList[newAddress] =TRUE;
    }

    /**
     * @dev revoke admin
     */
    function revokeAdminAddress(address newAddress) external {
        onlyAdmin();
        require(msg.sender != newAddress);
        _adminList[newAddress] =FALSE;
    }

    /**
     * @dev Modify the address request fee
     */
    function setaddressRequestFee(uint256 fee) 
        external 
    {
        onlyAdmin();
        
        addressRequestFee = fee;
    }

    /**
     * @dev required to be allow for receiving ETH claim payouts
     */
    receive() external payable {}


    /// @notice withdraws NXM deposit
    /// @dev only Admin
    /// @param amount - amount to withdraw    
    function withdrawNXM(uint256 amount) 
        external 
    {
        onlyAdmin();
        ifNotPaused();
        
        getDistributorContract().withdrawNXM(iTrustTreasury, amount);
    }

    /// @notice redeems claim amount
    /// @dev Checks if an _address / _uid combo matches
    /// @param userId - user identifer
    /// @param coverId - cover claiming against
    function redeemClaim(string memory userId, uint256 coverId) 
        external
    {
        nonReentrant();        
        LOCKED = TRUE;
        require( msg.sender == _userPolicies[userId].walletAddress);
        
        (   
            IDistributor.ClaimStatus claimStatus, 
            uint amountPaid, 
            address coverAsset
        ) = getDistributorContract().getPayoutOutcome(_claimIds[coverId]);
        require(claimStatus == IDistributor.ClaimStatus.ACCEPTED &&
                amountPaid > uint(0) &&
                _claimedAmounts[coverId] == uint(0));

        _claimedAmounts[coverId] = amountPaid;
        getDistributorContract().redeemClaim(coverId, _claimIds[coverId]);
        if (coverAsset == ETH) {
            payable(msg.sender).transfer(amountPaid);            
        } else {
            IERC20 erc20 = IERC20(coverAsset);
            erc20.safeTransfer(msg.sender, amountPaid);
        }
        
        emit ITrustClaimPayoutRedeemed(coverId, _claimIds[coverId], msg.sender, amountPaid, coverAsset);
        LOCKED = FALSE;
    }


    /// @notice Can user make claim on cover
    /// @dev internal
    /// @param cover - cover to check
    /// @return boolean true or false
    function _canMakeClaim(CoverData memory cover) internal view returns (uint8){
        if(_claimCount[cover.coverId] >= 2){
            return FALSE;
        }
        if(cover.claimId != 0 && 
            cover.claimStatus == uint256(CoverClaimStatus.Processing)) {
             
            return FALSE;
        }    
        if(cover.claimId != 0 && 
            cover.claimStatus == uint256(CoverClaimStatus.PaymentReady)) {
            return FALSE;
        }      
        if(cover.claimed) {
            return FALSE;
        }

        return TRUE;
    }

    /// @notice gets NXM balance of distributor
    /// @return uint balance in wei
    function NXMBalance() 
        external 
        view 
        returns (uint) 
    {
        onlyAdmin();
        
        return IERC20(_nxmTokenAddress).balanceOf(_distributorAddress);    
    }      

    /// @notice does itrust have approval to spend nft
    /// @return boolean
    function isTreasuryApproved() 
        external 
        view 
        returns (bool) 
    {
        onlyAdmin();
        
        
        return getDistributorContract().isApprovedForAll(address(iTrustTreasury), address(this)); 
    }

    /// @notice does itrust have custody of the token
    /// @return boolean
    function _isItrustOwner(uint coverId) internal view returns (bool) {
        
        return (getDistributorContract().ownerOf(coverId) == iTrustTreasury); 
    }  

    /// @notice withdraws NFt from itrust treasury
    function withdrawNFT(string memory userGUID, uint coverId) external {
        nonReentrant();
        LOCKED = TRUE;
        require(
            _userOwnsCover(userGUID, coverId) == TRUE &&
            msg.sender == _userPolicies[userGUID].walletAddress);

        IERC721 nftToken = IERC721(_distributorAddress);
        nftToken.safeTransferFrom(iTrustTreasury, payable(_userPolicies[userGUID].walletAddress), coverId);
        LOCKED = FALSE;
    }

    /// @notice transfers ownership of the distributor contract
    function setNewDistributorOwner(address newOwner) external {
        onlyAdmin();
        
        getDistributorContract().transferOwnership(newOwner);
    }

    function getDistributorContract() internal view returns (IDistributor) {
        return IDistributor(_distributorAddress);
    }

}
