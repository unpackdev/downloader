// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC721Upgradeable.sol";
import "./Counters.sol";
import "./OwnableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./CopMappingInterface.sol";
import "./Versionable.sol";
import "./Moartroller.sol";
import "./ExponentialNoError.sol";
import "./ErrorReporter.sol";
import "./AssetHelpers.sol";
import "./MToken.sol";
import "./EIP20Interface.sol";
import "./SafeEIP20.sol";

/**
 * @title MOAR's MProtection Contract
 * @notice Collateral optimization ERC-721 wrapper
 * @author MOAR
 */
contract MProtection is ERC721Upgradeable, OwnableUpgradeable, ExponentialNoError, AssetHelpers, Versionable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice Event emitted when new MProtection token is minted
     */
    event Mint(address minter, uint tokenId, uint underlyingTokenId, address asset, uint amount, uint strikePrice, uint expirationTime);

    /**
     * @notice Event emitted when MProtection token is redeemed
     */
    event Redeem(address redeemer, uint tokenId, uint underlyingTokenId);

    /**
     * @notice Event emitted when MProtection token changes its locked value
     */
    event LockValue(uint tokenId, uint underlyingTokenId, uint optimizationValue);

    /**
     * @notice Event emitted when maturity window parameter is changed
     */
    event MaturityWindowUpdated(uint newMaturityWindow);

    Counters.Counter private _tokenIds;
    address private _copMappingAddress;
    address private _moartrollerAddress;
    mapping (uint256 => uint256) private _underlyingProtectionTokensMapping;
    mapping (uint256 => uint256) private _underlyingProtectionLockedValue;
    mapping (address => mapping (address => EnumerableSet.UintSet)) private _protectionCurrencyMapping;
    uint256 public _maturityWindow;

    struct ProtectionMappedData{
        address pool;
        address underlyingAsset;
        uint256 amount;
        uint256 strike;
        uint256 premium;
        uint256 lockedValue;
        uint256 totalValue;
        uint issueTime;
        uint expirationTime;
        bool isProtectionAlive;
    }

    /**
     * @notice Constructor for MProtection contract
     * @param copMappingAddress The address of data mapper for C-OP
     * @param moartrollerAddress The address of the Moartroller
     */
    function initialize(address copMappingAddress, address moartrollerAddress) public initializer {
        __Ownable_init();
        __ERC721_init("c-uUNN OC-Protection", "c-uUNN");
        _copMappingAddress = copMappingAddress;
        _moartrollerAddress = moartrollerAddress;
        _setMaturityWindow(10800); // 3 hours default
    }

    /**
     * @notice Returns C-OP mapping contract 
     */
    function copMapping() private view returns (CopMappingInterface){
        return CopMappingInterface(_copMappingAddress);
    }

    /**
     * @notice Mint new MProtection token
     * @param underlyingTokenId Id of C-OP token that will be deposited
     * @return ID of minted MProtection token
     */
    function mint(uint256 underlyingTokenId) public returns (uint256)
    {
        return mintFor(underlyingTokenId, msg.sender);
    }

    /**
     * @notice Mint new MProtection token for specified address
     * @param underlyingTokenId Id of C-OP token that will be deposited
     * @param receiver Address that will receive minted Mprotection token
     * @return ID of minted MProtection token
     */
    function mintFor(uint256 underlyingTokenId, address receiver) public returns (uint256)
    {
        CopMappingInterface copMappingInstance = copMapping();
        ERC721Upgradeable(copMappingInstance.getTokenAddress()).transferFrom(msg.sender, address(this), underlyingTokenId);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        addUProtectionIndexes(receiver, newItemId, underlyingTokenId);
        emit Mint(
            receiver,
            newItemId,
            underlyingTokenId,
            copMappingInstance.getUnderlyingAsset(underlyingTokenId),
            copMappingInstance.getUnderlyingAmount(underlyingTokenId),
            copMappingInstance.getUnderlyingStrikePrice(underlyingTokenId),
            copMappingInstance.getUnderlyingDeadline(underlyingTokenId)
        );
        
        return newItemId;
    }

    /**
     * @notice Redeem C-OP token
     * @param tokenId Id of MProtection token that will be withdrawn
     * @return ID of redeemed C-OP token
     */
    function redeem(uint256 tokenId) external returns (uint256) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "cuUNN: caller is not owner nor approved");
        uint256 underlyingTokenId = getUnderlyingProtectionTokenId(tokenId);
        ERC721Upgradeable(copMapping().getTokenAddress()).transferFrom(address(this), msg.sender, underlyingTokenId);
        removeProtectionIndexes(tokenId);
        _burn(tokenId);
        emit Redeem(msg.sender, tokenId, underlyingTokenId);

        return underlyingTokenId;
    }

    /**
     * @notice Returns set of C-OP data
     * @param tokenId Id of MProtection token 
     * @return ProtectionMappedData struct filled with C-OP data
     */
    function getMappedProtectionData(uint256 tokenId) public view returns (ProtectionMappedData memory){
        ProtectionMappedData memory data;
        (address pool, uint256 amount, uint256 strike, uint256 premium, uint issueTime , uint expirationTime) = getProtectionData(tokenId);
        data = ProtectionMappedData(pool, getUnderlyingAsset(tokenId), amount, strike, premium, getUnderlyingProtectionLockedValue(tokenId), getUnderlyingProtectionTotalValue(tokenId), issueTime, expirationTime, isProtectionAlive(tokenId));
        return data;
    }

    /**
     * @notice Returns underlying token ID
     * @param tokenId Id of MProtection token 
     */
    function getUnderlyingProtectionTokenId(uint256 tokenId) public view returns (uint256){
        return _underlyingProtectionTokensMapping[tokenId];
    }

    /**
     * @notice Returns size of C-OPs filtered by asset address
     * @param owner Address of wallet holding C-OPs
     * @param currency Address of asset used to filter C-OPs
     */
    function getUserUnderlyingProtectionTokenIdByCurrencySize(address owner, address currency) public view returns (uint256){
        return _protectionCurrencyMapping[owner][currency].length();
    }

    /**
     * @notice Returns list of C-OP IDs filtered by asset address
     * @param owner Address of wallet holding C-OPs
     * @param currency Address of asset used to filter C-OPs
     */
    function getUserUnderlyingProtectionTokenIdByCurrency(address owner, address currency, uint256 index) public view returns (uint256){
        return _protectionCurrencyMapping[owner][currency].at(index);
    }

    /**
     * @notice Checks if address is owner of MProtection
     * @param owner Address of potential owner to check
     * @param tokenId ID of MProtection to check
     */
    function isUserProtection(address owner, uint256 tokenId) public view returns(bool) {
        if(Moartroller(_moartrollerAddress).isPrivilegedAddress(msg.sender)){
            return true;
        }
        return owner == ownerOf(tokenId);
    }

    /**
     * @notice Checks if MProtection is stil alive
     * @param tokenId ID of MProtection to check
     */
    function isProtectionAlive(uint256 tokenId) public view returns(bool) {
       uint256 deadline = getUnderlyingDeadline(tokenId);
       return (deadline - _maturityWindow) > now;
    }

    /**
     * @notice Creates appropriate indexes for C-OP
     * @param owner C-OP owner address
     * @param tokenId ID of MProtection 
     * @param underlyingTokenId ID of C-OP 
     */
    function addUProtectionIndexes(address owner, uint256 tokenId, uint256 underlyingTokenId) private{
        address currency = copMapping().getUnderlyingAsset(underlyingTokenId);
        _underlyingProtectionTokensMapping[tokenId] = underlyingTokenId;
        _protectionCurrencyMapping[owner][currency].add(tokenId);
    }

    /**
     * @notice Remove indexes for C-OP
     * @param tokenId ID of MProtection 
     */
    function removeProtectionIndexes(uint256 tokenId) private{
        address owner = ownerOf(tokenId);
        address currency = getUnderlyingAsset(tokenId);
        _underlyingProtectionTokensMapping[tokenId] = 0;
        _protectionCurrencyMapping[owner][currency].remove(tokenId);
    }

    /**
     * @notice Returns C-OP total value
     * @param tokenId ID of MProtection 
     */
    function getUnderlyingProtectionTotalValue(uint256 tokenId) public view returns(uint256){
        address underlyingAsset = getUnderlyingAsset(tokenId);
        uint256 assetDecimalsMantissa = getAssetDecimalsMantissa(underlyingAsset);

        return div_(
            mul_(
                getUnderlyingStrikePrice(tokenId),
                getUnderlyingAmount(tokenId)
            ),
            assetDecimalsMantissa
        );
    }

    /**
     * @notice Returns C-OP locked value
     * @param tokenId ID of MProtection 
     */
    function getUnderlyingProtectionLockedValue(uint256 tokenId) public view returns(uint256){
        return _underlyingProtectionLockedValue[tokenId];
    }

    /**
     * @notice get the amount of underlying asset that is locked
     * @param tokenId CProtection tokenId
     * @return amount locked
     */
    function getUnderlyingProtectionLockedAmount(uint256 tokenId) public view returns(uint256){
        address underlyingAsset = getUnderlyingAsset(tokenId);
        uint256 assetDecimalsMantissa = getAssetDecimalsMantissa(underlyingAsset);

        // calculates total protection value
        uint256 protectionValue = div_(
            mul_(
                getUnderlyingAmount(tokenId),
                getUnderlyingStrikePrice(tokenId)
            ),
            assetDecimalsMantissa
        );

        // return value is lockedValue / totalValue * amount
        return div_(
            mul_(
                getUnderlyingAmount(tokenId),
                div_(
                    mul_(
                        _underlyingProtectionLockedValue[tokenId],
                        1e18
                    ),
                    protectionValue
                )
            ),
            1e18
        );
    }

    /**
     * @notice Locks the given protection value as collateral optimization
     * @param tokenId The MProtection token id
     * @param value The value in stablecoin of protection to be locked as collateral optimization. 0 = max available optimization
     * @return locked protection value
     * TODO: convert semantic errors to standarized error codes
     */
    function lockProtectionValue(uint256 tokenId, uint value) external returns(uint) {
        //check if the protection belongs to the caller
        require(isUserProtection(msg.sender, tokenId), "ERROR: CALLER IS NOT THE OWNER OF PROTECTION");

        address currency = getUnderlyingAsset(tokenId);

        Moartroller moartroller = Moartroller(_moartrollerAddress);
        MToken mToken = moartroller.tokenAddressToMToken(currency);
        require(moartroller.oracle().getUnderlyingPrice(mToken) <= getUnderlyingStrikePrice(tokenId), "ERROR: C-OP STRIKE PRICE IS LOWER THAN ASSET SPOT PRICE");

        uint protectionTotalValue = getUnderlyingProtectionTotalValue(tokenId);
        uint maxOptimizableValue = moartroller.getMaxOptimizableValue(mToken, ownerOf(tokenId));

        // add protection locked value if any
        uint protectionLockedValue = getUnderlyingProtectionLockedValue(tokenId);
        if ( protectionLockedValue > 0) {
            maxOptimizableValue = add_(maxOptimizableValue, protectionLockedValue);
        }

        uint valueToLock;

        if (value != 0) {
            // check if lock value is at most max optimizable value
            require(value <= maxOptimizableValue, "ERROR: VALUE TO BE LOCKED EXCEEDS ALLOWED OPTIMIZATION VALUE");
            // check if lock value is at most protection total value
            require( value <= protectionTotalValue, "ERROR: VALUE TO BE LOCKED EXCEEDS PROTECTION TOTAL VALUE");
            valueToLock = value;
        } else {
            // if we want to lock maximum protection value let's lock the value that is at most max optimizable value
            if (protectionTotalValue > maxOptimizableValue) {
                valueToLock = maxOptimizableValue;
            } else {
                valueToLock = protectionTotalValue;
            }
        }

        _underlyingProtectionLockedValue[tokenId] = valueToLock;
        emit LockValue(tokenId, getUnderlyingProtectionTokenId(tokenId), valueToLock);
        return valueToLock;
    }

    function _setCopMapping(address newMapping) public onlyOwner {
        _copMappingAddress = newMapping;
    }

    function _setMoartroller(address newMoartroller) public onlyOwner {
        _moartrollerAddress = newMoartroller;
    }

    function _setMaturityWindow(uint256 maturityWindow) public onlyOwner {
        emit MaturityWindowUpdated(maturityWindow);
        _maturityWindow = maturityWindow;
    }


    // MAPPINGS 
    function getProtectionData(uint256 tokenId) public view returns (address, uint256, uint256, uint256, uint, uint){
        uint256 underlyingTokenId = getUnderlyingProtectionTokenId(tokenId);
        return copMapping().getProtectionData(underlyingTokenId);
    }

    function getUnderlyingAsset(uint256 tokenId) public view returns (address){
        uint256 underlyingTokenId = getUnderlyingProtectionTokenId(tokenId);
        return copMapping().getUnderlyingAsset(underlyingTokenId);
    }

    function getUnderlyingAmount(uint256 tokenId) public view returns (uint256){
        uint256 underlyingTokenId = getUnderlyingProtectionTokenId(tokenId);
        return copMapping().getUnderlyingAmount(underlyingTokenId);
    }

    function getUnderlyingStrikePrice(uint256 tokenId) public view returns (uint){
        uint256 underlyingTokenId = getUnderlyingProtectionTokenId(tokenId);
        return copMapping().getUnderlyingStrikePrice(underlyingTokenId);
    }

    function getUnderlyingDeadline(uint256 tokenId) public view returns (uint){
        uint256 underlyingTokenId = getUnderlyingProtectionTokenId(tokenId);
        return copMapping().getUnderlyingDeadline(underlyingTokenId);
    }

    function getContractVersion() external override pure returns(string memory){
        return "V1";
    }

}