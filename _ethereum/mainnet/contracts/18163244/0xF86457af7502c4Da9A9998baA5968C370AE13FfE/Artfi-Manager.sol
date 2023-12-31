// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./draft-EIP712Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Artfi-ICollection.sol";
import "./Artfi-IFixedPrice.sol";

enum ContractType {
    ARTFI_V2,
    UNSUPPORTED
}

struct LazyMintSellData {
    address tokenAddress;
    string uri;
    address seller;
    address buyer;
    string uid;
    uint256 fractionId;
    address[] creators;
    uint256[] royalties;
    uint256 minPrice;
    uint256 quantity;
    bytes signature;
    string currency;
}

struct CryptoTokens {
    address tokenAddress;
    uint256 tokenValue;
    bool isEnabled;
}

struct CalculatePayout {
    uint256 tokenId;
    address contractAddress;
    address seller;
    uint256 price;
    uint256 quantity;
}

struct ArtfiCollection {
    address contractAddress;
    address owner;
}

/**
 *@title MarketplaceManager Contract.
 *@dev MarketplaceManager is a implementation contract of both access control contract and ERC721 contract.
 */
contract ArtfiManagerV2 is
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    // using SafeMath for uint256;
    using ECDSAUpgradeable for bytes32;

    //*********************** Declarations ***********************//

    address private _marketplace;
    address private _collectionFactory;
    address private _passFactory;

    // address public serviceFeeWallet;
    // uint256 public serviceFeePercent;
    uint256 private constant PERCENT_UNIT = 1e4;
    ArtfiCollection[] private collectionList;
    string[] private _cryptoTokens;
    uint256 private _cryptoTokenCount;
    mapping(string => CryptoTokens) private _cryptoTokenList;
    mapping(address => bool) public blockList;
    mapping(address => ArtfiCollection) public _collections;

    ArtfiIFixedPrice private _artfiFixedPrice;
    bytes32 public constant BLOCKER_ROLE = keccak256("BLOCKER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    //*********************** Modifiers ***********************//
    modifier isArtfiMarketplace() {
        if (
            msg.sender != address(_artfiFixedPrice) &&
            msg.sender != _marketplace
        ) revert GeneralError("AF:106");
        _;
    }

    event BlockListUpdated(address indexed client, bool value);

    event eCollectionAdded(address collectionAddress, address owner);

    event ePauseContract(bool value);

    //*********************** Admin Functions ***********************//
    /**
     *@notice Initializes the contract by setting a 'name','version','service fee percentage',address of 'service Wallet' and 'weth'.
     *@dev used instead of constructor.
     *@param name_ name of token.
     *@param version_ version of contract.
     */
    function initialize(
        string memory name_,
        string memory version_
    ) external initializer {
        __AccessControl_init();
        __EIP712_init(name_, version_);
        __Pausable_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BLOCKER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    // function setConfiguration(
    //     address serviceFeeWallet_,
    //     uint256 serviceFeePercentage_
    // ) external onlyRole(BLOCKER_ROLE) whenNotPaused {
    //     if (serviceFeePercentage_ > 500) revert GeneralError("AF:130");
    //     if (!isAdmin(msg.sender)) revert GeneralError("AF:101");
    //     if (blockList[msg.sender]) revert GeneralError("AF:126");
    //     if (serviceFeeWallet_ != address(0))
    //         serviceFeeWallet = serviceFeeWallet_;

    //     serviceFeePercent = serviceFeePercentage_;
    // }

    /**
     * @notice Pausing/stopping
     * @dev Only by pauser role
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();

        emit ePauseContract(true);
    }

    /**
     * @notice Unpausing
     * @dev Only by pauser role
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();

        emit ePauseContract(false);
    }

    /**
     * @notice Update list of blocked users
     * @dev Only by default admin role
     * @param _address user's address
     * @param _value block(true) or unblock(false) the user
     */
    function blockListUpdate(
        address _address,
        bool _value
    ) public onlyRole(PAUSER_ROLE) {
        blockList[_address] = _value;
        emit BlockListUpdated(_address, _value);
    }

    /**
     *@notice sets addresses of contracts.
     *@param artfiMarketplace_ address of artfiMarketplace.
     *@param artfiFixedPrice_ address of artfiFixedPrice.
     */
    function setContractAddress(
        address artfiMarketplace_,
        address artfiFixedPrice_,
        address collectionFactory_,
        address passFactory_
    ) external {
        if (
            artfiFixedPrice_ == address(0) ||
            collectionFactory_ == address(0) ||
            artfiMarketplace_ == address(0) ||
            passFactory_ == address(0)
        ) revert GeneralError("AF:205");
        if (!isAdmin(msg.sender)) revert GeneralError("AF:101");
        if (artfiMarketplace_ != address(0)) _marketplace = artfiMarketplace_;
        if (collectionFactory_ != address(0))
            _collectionFactory = collectionFactory_;
        if (passFactory_ != address(0)) _passFactory = passFactory_;
        if (artfiFixedPrice_ != address(0))
            _artfiFixedPrice = ArtfiIFixedPrice(artfiFixedPrice_);
    }

    function addArtfiCollection(
        address collectionAddress,
        address owner
    ) external {
        if (collectionAddress == address(0) || owner == address(0))
            revert GeneralError("AF:205");
        if (!isAdmin(msg.sender)) revert GeneralError("AF:101");
        if (_collections[collectionAddress].contractAddress != address(0))
            revert GeneralError("AF:111");
        _collections[collectionAddress] = ArtfiCollection(
            collectionAddress,
            owner
        );
        collectionList.push(_collections[collectionAddress]);
        emit eCollectionAdded(collectionAddress, owner);
    }

    /**
     *@notice adds Crypto Tokens with token name ,tokenId and value of token.
     *@param tokenName_ name of the token.
     *@param address_ address of token.
     *@param tokenValue_ value of token.
     */
    function addCryptoToken(
        string memory tokenName_,
        address address_,
        uint256 tokenValue_
    ) external {
        if (!isAdmin(msg.sender)) revert GeneralError("AF:101");
        if (tokenExist(tokenName_)) revert GeneralError("AF:111");
        if (!_is20(address_)) revert GeneralError("AF:113");
        if (bytes(tokenName_).length == 0) revert GeneralError("AF:114");
        if (tokenValue_ == 0) revert GeneralError("AF:115");

        _cryptoTokenList[tokenName_] = CryptoTokens(
            address_,
            tokenValue_,
            true
        );
        _cryptoTokens.push(tokenName_);
        ++_cryptoTokenCount;

        ArtfiIFixedPrice(address(_artfiFixedPrice)).enableDisableSaleToken(
            tokenName_,
            true
        );
    }

    /**
     *@notice adds Crypto Tokens with token name ,tokenId and value of token.
     *@param tokenName_ name of the token.
     *@param address_ address of token.
     *@param tokenValue_ value of token.
     */

    function editCryptoToken(
        string memory tokenName_,
        address address_,
        uint256 tokenValue_
    ) external {
        if (!isAdmin(msg.sender)) revert GeneralError("AF:101");
        if (!tokenExist(tokenName_)) revert GeneralError("AF:112");
        if (!_is20(address_)) revert GeneralError("AF:113");
        if (bytes(tokenName_).length == 0) revert GeneralError("AF:114");
        if (tokenValue_ == 0) revert GeneralError("AF:115");

        _cryptoTokenList[tokenName_] = CryptoTokens(
            address_,
            tokenValue_,
            true
        );
    }

    /**
     *@notice enables or disables the token for sale .
     *@param tokenName_ name of token.
     *@param enable_ checks the token is enabled.
     */
    function enableDisableToken(
        string memory tokenName_,
        bool enable_
    ) external whenNotPaused {
        if (!isAdmin(msg.sender)) revert GeneralError("AF:101");
        if (enable_ && _cryptoTokenList[tokenName_].isEnabled)
            revert GeneralError("AF:116");
        if (!enable_ && !_cryptoTokenList[tokenName_].isEnabled)
            revert GeneralError("AF:117");
        _cryptoTokenList[tokenName_].isEnabled = enable_;
        ArtfiIFixedPrice(address(_artfiFixedPrice)).enableDisableSaleToken(
            tokenName_,
            enable_
        );
    }

    //*********************** Getter Functions ***********************//
    /**
     *@notice checks function is called by admin.
     *@param caller_ address of caller.
     *@return isAdmin_ bool .
     */
    function isAdmin(address caller_) public view returns (bool isAdmin_) {
        if (
            hasRole(DEFAULT_ADMIN_ROLE, caller_) ||
            hasRole(BLOCKER_ROLE, caller_)
        ) return true;
        else return false;
    }

    /**
     *@notice checks function is called by admin.
     *@param caller_ address of caller.
     *@return isPauser_ bool .
     */
    function isPauser(address caller_) public view returns (bool isPauser_) {
        if (hasRole(PAUSER_ROLE, caller_)) return true;
        else return false;
    }

    /**
     *@notice checks function is called by admin.
     *@param caller_ address of caller.
     *@return isBlocked_ bool .
     */
    function isBlocked(address caller_) public view returns (bool isBlocked_) {
        if (blockList[caller_]) return true;
        else return false;
    }

    /**
     *@notice checks function is called by admin.
     *@return isPaused_ bool .
     */
    function isPaused() public view returns (bool isPaused_) {
        if (paused()) return true;
        else return false;
    }

    function getConfiguration()
        external
        view
        returns (
            // address serviceFeeWallet_,
            // uint256 serviceFeePercentage_,
            address artfiMarketplace_,
            address artfiCollectionFactory_,
            address artfiPassFactory
        )
    {
        // serviceFeeWallet_ = serviceFeeWallet;
        // serviceFeePercentage_ = serviceFeePercent;
        artfiMarketplace_ = _marketplace;
        artfiCollectionFactory_ = address(_collectionFactory);
        artfiPassFactory = address(_passFactory);
    }

    function tokenExist(
        string memory tokenName_
    ) public view returns (bool tokenExist_) {
        if (_cryptoTokenList[tokenName_].tokenAddress != address(0))
            return true;
        else return false;
    }

    function getTokenCount() public view returns (uint256 tokenCount_) {
        uint256 count = 0;
        for (uint256 i = 0; i < _cryptoTokenCount; i++) {
            if (_cryptoTokenList[_cryptoTokens[i]].isEnabled) {
                count++;
            }
        }
        tokenCount_ = count;
    }

    function getSupportedTokenList()
        external
        view
        returns (string[] memory supportedTokenList_)
    {
        uint256 count = getTokenCount();
        string[] memory tokenlist = new string[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < _cryptoTokenCount; i++) {
            if (_cryptoTokenList[_cryptoTokens[i]].isEnabled) {
                tokenlist[j] = _cryptoTokens[i];
                j++;
            }
        }
        supportedTokenList_ = tokenlist;
    }

    function getTokenDetail(
        string memory tokenName_
    ) external view returns (CryptoTokens memory cryptoToken_) {
        cryptoToken_ = _cryptoTokenList[tokenName_];
    }

    /**
     *@notice returns the type of contract when a contract address is given.
     *@param contractAddress_ address of contracts.
     *@return contractType_ type of contract such as ARTFI_V1,ARTFI_V2,UNSUPPORTED.
     */
    function getContractDetails(
        address contractAddress_
    ) public view isArtfiMarketplace returns (ContractType contractType_) {
        if (_isArtfiCollection(contractAddress_))
            return (ContractType.ARTFI_V2);
        else {
            return (ContractType.UNSUPPORTED);
        }
    }

    function getCollectionList()
        external
        view
        returns (ArtfiCollection[] memory)
    {
        return collectionList;
    }

    /**
     *@notice checks the owner of NFTs.
     *@param address_ address of NFTs.
     *@param tokenId_ id of NFT.
     *@param contractAddress_ address of contract.
     *@return contractType_ type of contract .
     *@return isOwner_ checks the owner of contract.
     */
    function isOwnerOfNFT(
        address address_,
        uint256 tokenId_,
        address contractAddress_
    )
        public
        view
        isArtfiMarketplace
        returns (ContractType contractType_, bool isOwner_)
    {
        (contractType_) = getContractDetails(contractAddress_);
        if (contractType_ != ContractType.UNSUPPORTED) {
            address NftOwner = IERC721(contractAddress_).ownerOf(tokenId_);
            isOwner_ = (NftOwner == address_) ? true : false;
        }
    }

    /**
     *@notice calulates the amount given to creators and inverstors during NFT purchase.
     *@param calculatePayout_ contains tokenId ,contract address,seller address,price and quantity of tokens.
     *@return recepientAddresses_ address of recipient.
     *@return paymentAmount_ Amount for payment.
     *@return isTokenTransferable_ checks if token is transferable.
     *@return isOwner_ checks the onwer.
     */
    function calculatePayout(
        CalculatePayout memory calculatePayout_
    )
        external
        view
        isArtfiMarketplace
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_,
            bool isTokenTransferable_,
            bool isOwner_
        )
    {
        (ContractType contractType, bool isOwner) = isOwnerOfNFT(
            calculatePayout_.seller,
            calculatePayout_.tokenId,
            calculatePayout_.contractAddress
        );
        isOwner_ = isOwner;
        isTokenTransferable_ = _isNftTransferApproved(
            calculatePayout_.seller,
            calculatePayout_.contractAddress
        );
        if (!isTokenTransferable_) revert GeneralError("AF:105");
        if (contractType == ContractType.ARTFI_V2) {
            (recepientAddresses_, paymentAmount_) = _payoutArtfiCollection(
                calculatePayout_.contractAddress,
                calculatePayout_.tokenId,
                calculatePayout_.seller,
                calculatePayout_.price
            );
        }
    }

    //*********************** Verify Signature Functions ***********************//

    /**
     *@notice verifying the signature for lazymintingV2 in fixed price.
     *@param lazyData_ contains tokenAddress,uri,seller address,creater addresses, royalties percentage
     *minimum Price,quantity,currency,signature in bytes.
     *@return address token Address.
     */
    function verifyFixedPriceLazyMintV2(
        LazyMintSellData memory lazyData_
    ) external view isArtfiMarketplace returns (address, bytes32) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(address tokenAddress,string uri,address seller,address buyer,string uid,uint256 fractionId,address[] creators,uint256[] royalties,uint256 minPrice,uint256 quantity,string currency)"
                    ),
                    lazyData_.tokenAddress,
                    keccak256(bytes(lazyData_.uri)),
                    lazyData_.seller,
                    lazyData_.buyer,
                    keccak256(bytes(lazyData_.uid)),
                    lazyData_.fractionId,
                    keccak256(abi.encodePacked(lazyData_.creators)),
                    keccak256(abi.encodePacked(lazyData_.royalties)),
                    lazyData_.minPrice,
                    lazyData_.quantity,
                    keccak256(bytes(lazyData_.currency))
                )
            )
        );
        address signerV2 = digest.toEthSignedMessageHash().recover(
            lazyData_.signature
        );
        return (signerV2, digest);
    }

    //*********************** Internal Functions ***********************//
    function _payoutArtfiCollection(
        address contractAddress_,
        uint256 tokenId_,
        address seller_,
        uint256 price_
    )
        internal
        view
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        ArtfiICollectionV2.NftData memory nftData = ArtfiICollectionV2(
            contractAddress_
        ).getNftInfo(tokenId_);
        uint256 j = 0;
        // uint256 adminfee;
        uint256[] memory payoutFees;
        uint256 netfee;
        if (!nftData.isFirstSale) {
            recepientAddresses_ = new address[](nftData.creators.length + 2);
            paymentAmount_ = new uint256[](nftData.creators.length + 2);
            (payoutFees, netfee) = _calculatePayout(
                price_,
                // serviceFeePercent,
                nftData.royalties
            );
            for (uint256 i = 0; i < nftData.creators.length; i++) {
                recepientAddresses_[j] = nftData.creators[i];
                paymentAmount_[j] = payoutFees[i];
                j = j + 1;
            }
        }
        // recepientAddresses_[j] = serviceFeeWallet;
        // paymentAmount_[j] = adminfee;
        j = j + 1;

        recepientAddresses_[j] = seller_;
        paymentAmount_[j] = netfee;
    }

    function _isNftTransferApproved(
        address seller_,
        address nftContract_
    ) internal view returns (bool) {
        if (_isArtfiCollection(nftContract_)) return true;
        return IERC721(nftContract_).isApprovedForAll(seller_, _marketplace);
    }

    function _calculatePayout(
        uint256 price_,
        // uint256 serviceFeePercent_,
        uint256[] memory payouts_
    )
        internal
        view
        virtual
        returns (
            // uint256 serviceFee_,
            uint256[] memory payoutFees_,
            uint256 netFee_
        )
    {
        payoutFees_ = new uint256[](payouts_.length);
        uint256 payoutSum = 0;
        // serviceFee_ = _percent(price_, serviceFeePercent_);

        for (uint256 i = 0; i < payouts_.length; i++) {
            uint256 royalFee = _percent(price_, payouts_[i]);
            payoutFees_[i] = royalFee;
            payoutSum = payoutSum + royalFee;
        }

        netFee_ = price_ - payoutSum;
    }

    function _percent(
        uint256 value_,
        uint256 percentage_
    ) internal pure virtual returns (uint256) {
        uint256 result = (value_ * percentage_) / PERCENT_UNIT;
        return (result);
    }


    function _is20(address tokenContract) internal returns (bool) {
        bytes memory payload1 = abi.encodeWithSignature("name()");
        (bool success1, ) = tokenContract.call(payload1);

        bytes memory payload2 = abi.encodeWithSignature("symbol()");
        (bool success2, ) = tokenContract.call(payload2);

        bytes memory payload3 = abi.encodeWithSignature("decimals()");
        (bool success3, ) = tokenContract.call(payload3);

        return success1 && success2 && success3;
    }

    function _isArtfiCollection(
        address tokenContract
    ) internal view returns (bool) {
        return (_collections[tokenContract].contractAddress == tokenContract);
    }
}
