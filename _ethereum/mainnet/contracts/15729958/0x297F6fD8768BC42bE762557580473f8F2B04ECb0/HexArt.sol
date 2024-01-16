// SPDX-License-Identifier: None
pragma solidity ^0.8.1;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./IERC165.sol";
import "./TransferHelper.sol";
import "./Address.sol";

interface HexArtMarkets {
    function isListed(uint256 _tokenId) external view returns (bool);

    function distibuteRemovalFee() external payable;
}

interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface ERC20 {
    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

interface FeesCollector {
    function manageArtistFees(uint256 value) external returns (bool);
}

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    modifier checkRoyaltyInfo(address receiver, uint256 feeNumerator) {
        require(receiver != address(0), "ERC2981: invalid receiver");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual checkRoyaltyInfo(receiver, feeNumerator) {
        require(tokenId > 0, "Token Id cannot be zero");
        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }
}

contract HexArt is ERC721URIStorage, ERC2981, Ownable {
    IWETH9 public weth;
    HexArtMarkets public marketplace;
    FeesCollector public feeCollector;
    struct NFTDetail {
        uint256 nftTokenId;
        address assettype;
    }
    struct ECR20Detail {
        uint256 balance;
        address assettype;
    }

    uint256 public counter = 0;
    uint256 constant amountToRemoveAsset = 369000000000000000;
    address internal _weth9;
    mapping(uint256 => address) internal initialOwner;
    mapping(uint256 => NFTDetail[]) internal nftAssetDetails;
    mapping(uint256 => ECR20Detail[]) internal erc20AssetDetails;
    mapping(address => bool) public whitelistedAddresses;
    mapping(uint256 => uint256) public assetLockPeriod;

    modifier onlyInitialOwner(uint256 _tokenId) {
        require(
            initialOwner[_tokenId] == _msgSender(),
            "Collection: only initial owner can set the royality"
        );
        _;
    }
    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "Not have permission");
        _;
    }

    modifier isNFTOwner(uint256 _nftTokenId) {
        require(
            ownerOf(_nftTokenId) == msg.sender,
            "Collection: caller is not owner nor approved"
        );
        _;
    }

    modifier isNotListedOnSale(uint256 _tokenId) {
        require(
            !marketplace.isListed(_tokenId),
            "Cannot add/remove asset to a listed NFT"
        );
        _;
    }

    modifier isBurnable(uint256 _tokenId) {
        NFTDetail[] memory array = getAssetsOfNFT(_tokenId);
        ECR20Detail[] memory array1 = getERC20AssetsOfNFT(_tokenId);
        require(
            (array.length == 0 && array1.length == 0),
            "Remove all attached asset from hexart before burning"
        );
        _;
    }

    event nftMinted(
        uint256 tokenId,
        uint96 feeNumerator,
        uint256 lockperiodInDays,
        uint256 lockperiodInSec
    );
    event assetAdded(uint256 parentNftId, NFTDetail[] _tokenIds);
    event assetRemoved(
        uint256 tokenId,
        uint256[] assetId,
        address assetContract
    );
    event allAssetRemoved(uint256 _nftTokenId, NFTDetail[] array);
    event burnNFT(uint256 _hexartTokenId);
    event erc20AssetAdded(
        uint256 parentNFtId,
        address assetContract,
        uint256 balance
    );
    event erc20AssetRemoved(uint256 parentNFtId, address assetContract);

    constructor(address _weth) ERC721("HEXART", "HXA") {
        weth = IWETH9(_weth);
        _weth9 = _weth;
    }

    receive() external payable {}

    /**
     * @notice Sets the royalty info for any token.
     */
    function setRoyaltyforToken(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyInitialOwner(_tokenId) {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /**
     * @notice Sets the marketplace address.
     */
    function setMarketplace(address _marketplace) external onlyOwner {
        require(
            _marketplace != address(0),
            "Marketplace address cannot be zero."
        );
        marketplace = HexArtMarkets(_marketplace);
    }

    /**
     * @notice Mints single token.
     * @param _tokenURI metadata URI
     * @param _feeNumerator royality percentage (this must be less than max limit)
     */
    function mint(
        string memory _tokenURI,
        uint96 _feeNumerator,
        uint256 _lockperiodInDays
    ) external returns (uint256 tokenId) {
        require(msg.sender != address(0), "Collection: _to address not valid");
        require(
            bytes(_tokenURI).length > 0,
            "Collection: Token URI is not valid"
        );
        counter++;
        tokenId = counter;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        if (_feeNumerator != 0) {
            _setTokenRoyalty(tokenId, msg.sender, _feeNumerator);
        }
        initialOwner[tokenId] = msg.sender;
        assetLockPeriod[tokenId] =
            block.timestamp +
            (86400 * _lockperiodInDays); // 86400 - for 1 day
        emit nftMinted(
            tokenId,
            _feeNumerator,
            _lockperiodInDays,
            assetLockPeriod[tokenId]
        );
    }

    /**
     * @notice Burns token of entered token id.
     */
    function burn(uint256 _tokenId)
        external
        isNFTOwner(_tokenId)
        isBurnable(_tokenId)
        isNotListedOnSale(_tokenId)
    {
        delete initialOwner[_tokenId];
        delete assetLockPeriod[_tokenId];
        _burn(_tokenId);
        emit burnNFT(_tokenId);
    }

    /**
     * @notice Attach NFT(HSI) assets to a given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _tokenIds, Array of asset(HSI) token Ids
     * @param _tokenId, Hexart token ID.
     */
    function addNFTAsset(
        address _assetContract,
        uint256[] calldata _tokenIds,
        uint256 _tokenId
    )
        external
        isWhitelisted(_assetContract)
        isNFTOwner(_tokenId)
        isNotListedOnSale(_tokenId)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ERC721(_assetContract).transferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );

            require(
                ERC721(_assetContract).ownerOf(_tokenIds[i]) == address(this),
                "Asset not added"
            );

            nftAssetDetails[_tokenId].push(
                NFTDetail({nftTokenId: _tokenIds[i], assettype: _assetContract})
            );
        }
        emit assetAdded(_tokenId, nftAssetDetails[_tokenId]);
    }

    /**
     * @notice  Remove NFT(HSI) assets to a given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     */
    function removeNFTAsset(
        uint256 _nftTokenId,
        uint256[] calldata _assetId,
        address _assetContract
    ) external isNFTOwner(_nftTokenId) isNotListedOnSale(_nftTokenId) {
        require(
            isLockPeriodOver(_nftTokenId),
            "Lock period asset is not over."
        );
        removeNFT(_nftTokenId, _assetId, _assetContract);
        emit assetRemoved(_nftTokenId, _assetId, _assetContract);
    }

    /**
     * @notice  Remove NFT(HSI) assets to a given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     */
    function removeNFTPayable(
        uint256 _nftTokenId,
        uint256[] calldata _assetId,
        address _assetContract
    ) external payable isNFTOwner(_nftTokenId) isNotListedOnSale(_nftTokenId) {
        require(
            msg.value >= (amountToRemoveAsset * _assetId.length),
            "Not enough funds sent"
        );
        require(!isLockPeriodOver(_nftTokenId), "Lock period is over");
        marketplace.distibuteRemovalFee{value: msg.value}();
        removeNFT(_nftTokenId, _assetId, _assetContract);
        emit assetRemoved(_nftTokenId, _assetId, _assetContract);
    }

    /**
     * @notice  Payable function to remove all NFT(HSI) assets to a given hexart.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeAllNFTAssetsPayable(uint256 _nftTokenId)
        external
        payable
        isNFTOwner(_nftTokenId)
        isNotListedOnSale(_nftTokenId)
    {
        require(!isLockPeriodOver(_nftTokenId), "Lock period is over");
        NFTDetail[] memory array = getAssetsOfNFT(_nftTokenId);
        require(
            msg.value >= (amountToRemoveAsset * array.length),
            "Not enough funds sent"
        );
        marketplace.distibuteRemovalFee{value: msg.value}();
        removeAllNFT(_nftTokenId);
    }

    /**
     * @notice   Function to remove all NFT(HSI) assets to a given hexart.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeAllNFTAssets(uint256 _nftTokenId)
        external
        isNFTOwner(_nftTokenId)
        isNotListedOnSale(_nftTokenId)
    {
        require(isLockPeriodOver(_nftTokenId), "Lock period is not over");
        removeAllNFT(_nftTokenId);
    }

    /**
     * @notice Attach ERC-20 assets to a given hexart.
     * @param _assetContract , ERC-20 asset contract address.
     * @param _amount, Amount of erc-20 tokens.
     * @param _tokenId, Hexart token ID.
     */
    function addErc20Asset(
        address _assetContract,
        uint256 _tokenId,
        uint256 _amount
    )
        external
        payable
        isWhitelisted(_assetContract)
        isNFTOwner(_tokenId)
        isNotListedOnSale(_tokenId)
    {
        bool check = false;

        if (_assetContract == _weth9) {
            weth.deposit{value: msg.value}();
        } else {
            TransferHelper.safeTransferFrom(
                _assetContract,
                _msgSender(),
                address(this),
                _amount
            );
        }

        for (uint256 i = 0; i < erc20AssetDetails[_tokenId].length; i++) {
            if (erc20AssetDetails[_tokenId][i].assettype == _assetContract) {
                erc20AssetDetails[_tokenId][i].balance += _amount;
                check = true;
                break;
            }
        }
        if (!check) {
            erc20AssetDetails[_tokenId].push(
                ECR20Detail({balance: _amount, assettype: _assetContract})
            );
        }
        emit erc20AssetAdded(_tokenId, _assetContract, _amount);
    }

    /**
     * @notice  Remove erc-20 assets from a given hexart.
     * @param _assetContract , ERC-20 asset contract address.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeErc20Asset(address _assetContract, uint256 _nftTokenId)
        external
        isNFTOwner(_nftTokenId)
        isNotListedOnSale(_nftTokenId)
    {
        require(isLockPeriodOver(_nftTokenId), "Lock period is not over");

        removeErc20(_assetContract, _nftTokenId);
        emit erc20AssetRemoved(_nftTokenId, _assetContract);
    }

    /**
     * @notice  Remove(payable) erc-20 assets from a given hexart.
     * @param _assetContract , ERC-20 asset contract address.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeErc20Assetpayable(
        address _assetContract,
        uint256 _nftTokenId
    ) external payable isNFTOwner(_nftTokenId) isNotListedOnSale(_nftTokenId) {
        require(msg.value >= amountToRemoveAsset, "Not enough funds sent");
        require(!isLockPeriodOver(_nftTokenId), "Lock period is not over");
        marketplace.distibuteRemovalFee{value: msg.value}();
        removeErc20(_assetContract, _nftTokenId);
        emit erc20AssetRemoved(_nftTokenId, _assetContract);
    }

    /**
     * @notice Transfers token from 'from' address to 'to' address.
     * @param _tokenId, Hexart token ID.
     * @param _from, From address.
     * @param _to,To address.
     */
    function transferNFT(
        uint256 _tokenId,
        address _from,
        address _to
    ) external returns (bool) {
        _transfer(_from, _to, _tokenId);
        return true;
    }

    /**
    @notice Add asset address to the whitelist.
    @param _addressToWhitelist, Address to whitelist.
    */
    function addAssetToWhitelist(address _addressToWhitelist) external {
        require(
            Address.isContract(_addressToWhitelist),
            "Only contract address are allowed"
        );
        require(
            _addressToWhitelist != address(0),
            "Zero address is not allowed"
        );
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    /**
    @notice Remove asset address to the whitelist.
    @param _addressToWhitelist, Address to whitelist.
    */
    function removeAssetFromWhitelist(address _addressToWhitelist)
        external
        onlyOwner
    {
        require(
            _addressToWhitelist != address(0),
            "Zero address is not allowed"
        );
        whitelistedAddresses[_addressToWhitelist] = false;
    }

    /**
     * @dev returns true if the contract supports the interface with entered bytecode.
     * @dev 0x2a55205a to test eip 2981
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns an array of NFT assets associated with a hexart.
     */
    function getAssetsOfNFT(uint256 _tokenId)
        public
        view
        returns (NFTDetail[] memory)
    {
        require(_tokenId > 0, "Token Id cannot be zero");
        return nftAssetDetails[_tokenId];
    }

    /**
     * @notice Returns an array of ERC-20  assets associated with a hexart.
     */
    function getERC20AssetsOfNFT(uint256 _tokenId)
        public
        view
        returns (ECR20Detail[] memory)
    {
        require(_tokenId > 0, "Token Id cannot be zero");
        return erc20AssetDetails[_tokenId];
    }

    /**
     * @notice To check the lock period .
     * @param _nftTokenId, Hexart token ID.
     * @return check, bool
     */
    function isLockPeriodOver(uint256 _nftTokenId) public view returns (bool) {
        bool check = block.timestamp >= assetLockPeriod[_nftTokenId];
        return check;
    }

    /**
     * @notice Remove  NFT assets associated with a NFT.
     * @param index, Blockchain index of asset.
     * @param _tokenId , Hexart token ID.
     */
    function removeAssetToken(uint256 index, uint256 _tokenId) internal {
        if (index < nftAssetDetails[_tokenId].length - 1) {
            nftAssetDetails[_tokenId][index] = nftAssetDetails[_tokenId][
                nftAssetDetails[_tokenId].length - 1
            ];
        }
        nftAssetDetails[_tokenId].pop();
    }

    /**
     * @notice Remove  NFT assets associated with a NFT.
     * @param index, Blockchain index of asset.
     * @param _tokenId , Hexart token ID.
     */
    function removeErcAssetToken(uint256 index, uint256 _tokenId) internal {
        if (index < erc20AssetDetails[_tokenId].length - 1) {
            erc20AssetDetails[_tokenId][index] = erc20AssetDetails[_tokenId][
                erc20AssetDetails[_tokenId].length - 1
            ];
        }
        erc20AssetDetails[_tokenId].pop();
    }

    /**
     * @notice  Transfer NFT assets associated with a NFT.
     * @param _nftContract,NFT asset contract address.
     * @param _assetId ,NFT asset token ID.
     */
    function transferAsset(address _nftContract, uint256 _assetId) internal {
        ERC721(_nftContract).transferFrom(address(this), msg.sender, _assetId);
        require(
            ERC721(_nftContract).ownerOf(_assetId) == msg.sender,
            "Asset not removed"
        );
    }

    /**
     * @notice To check if asset is attached to any given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     * @return check assetIndex
     */
    function isAssetAttached(
        uint256 _nftTokenId,
        uint256 _assetId,
        address _assetContract
    ) internal view returns (bool, uint256) {
        bool check;
        uint256 assetIndex;
        NFTDetail[] memory array = getAssetsOfNFT(_nftTokenId);
        for (uint256 i = 0; i < array.length; i++) {
            if (
                array[i].nftTokenId == _assetId &&
                array[i].assettype == _assetContract
            ) {
                check = true;
                assetIndex = i;
                break;
            }
        }
        if (!check) {
            revert("Given Asset Id is not attached to this NFT");
        }
        return (check, assetIndex);
    }

    /**
     * @notice To check if asset is attached to any given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _nftTokenId, Hexart token ID.
     * @return check assetIndex
     */
    function isErcAssetAttached(uint256 _nftTokenId, address _assetContract)
        internal
        view
        returns (bool, uint256)
    {
        bool check;
        uint256 assetIndex;
        ECR20Detail[] memory array = getERC20AssetsOfNFT(_nftTokenId);
        require(array.length > 0, "No asset is attached to this hexart");
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i].assettype == _assetContract) {
                check = true;
                assetIndex = i;
                break;
            }
        }
        if (!check) {
            revert("Given Asset is not attached to this NFT");
        }
        return (check, assetIndex);
    }

    /**
     * @notice  Remove(internal) erc-20 assets from a given hexart.
     * @param _assetContract , ERC-20 asset contract address.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeErc20(address _assetContract, uint256 _nftTokenId) internal {
        (bool check, uint256 index) = isErcAssetAttached(
            _nftTokenId,
            _assetContract
        );
        if (check) {
            if (_assetContract == _weth9) {
                weth.withdraw(erc20AssetDetails[_nftTokenId][index].balance);
                payable(_msgSender()).transfer(
                    erc20AssetDetails[_nftTokenId][index].balance
                );
            } else {
                TransferHelper.safeTransfer(
                    _assetContract,
                    _msgSender(),
                    erc20AssetDetails[_nftTokenId][index].balance
                );
            }
            removeErcAssetToken(index, _nftTokenId);
        }
    }

    /**
     * @notice  Internal function to remove all NFT(HSI) assets to a given hexart.
     * @param _nftTokenId, Hexart token ID.
     */
    function removeAllNFT(uint256 _nftTokenId) internal {
        NFTDetail[] memory array = getAssetsOfNFT(_nftTokenId);
        require(array.length > 0, "No asset is attached to the given NFT.");

        for (uint256 i = 0; i < array.length; i++) {
            transferAsset(array[i].assettype, array[i].nftTokenId);

            removeAssetToken(i, _nftTokenId);
        }
        emit allAssetRemoved(_nftTokenId, array);
    }

    /**
     * @notice  Internal function to remove NFT(HSI) assets to a given hexart.
     * @param _assetContract , NFT asset contract address.
     * @param _assetId, Array of asset(HSI) token Ids
     * @param _nftTokenId, Hexart token ID.
     */
    function removeNFT(
        uint256 _nftTokenId,
        uint256[] calldata _assetId,
        address _assetContract
    ) internal {
        NFTDetail[] memory array = getAssetsOfNFT(_nftTokenId);
        require(array.length > 0, "No asset is attached to the given NFT.");

        for (uint256 i = 0; i < _assetId.length; i++) {
            (bool check, uint256 index) = isAssetAttached(
                _nftTokenId,
                _assetId[i],
                _assetContract
            );
            if (check) {
                transferAsset(_assetContract, _assetId[i]);

                removeAssetToken(index, _nftTokenId);
            }
        }
    }
}
