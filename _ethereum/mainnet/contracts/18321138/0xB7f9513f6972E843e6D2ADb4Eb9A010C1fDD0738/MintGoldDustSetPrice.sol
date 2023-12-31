// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./MintGoldDustMarketplace.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ECDSA.sol";
import "./IERC165.sol";

contract MintGoldDustSetPrice is MintGoldDustMarketplace {
    using ECDSA for bytes32;

    struct DelistDTO {
        uint256 tokenId;
        uint256 amount;
        address contractAddress;
    }

    /**
     * @notice that this event show the info about a new listing to the set price market.
     * @dev this event will be triggered when a MintGoldDustNFT is listed for the set price marketplace.
     * @param tokenId the sequence number for the item.
     * @param seller the seller of this tokenId.
     * @param price the price for this item sale.
     *    @dev it cannot be zero.
     * @param amount the quantity of tokens to be listed for an MintGoldDustERC1155.
     *    @dev For MintGoldDustERC721 the amout must be always one.
     * @param contractAddress the MintGoldDustERC1155 or the MintGoldDustERC721 address.
     */
    event MintGoldDustNftListedToSetPrice(
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        uint256 amount,
        address contractAddress
    );

    /**
     * @notice that this event show the info when a market item has its price updated.
     * @dev this event will be triggered when a market item has its price updated.
     * @param tokenId the sequence number for the item.
     * @param seller the seller of this tokenId.
     * @param price the new price for this item sale.
     *    @dev it cannot be zero.
     * @param contractAddress the MintGoldDustERC1155 or the MintGoldDustERC721 address.
     */
    event MintGoldDustNftListedItemUpdated(
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        address contractAddress
    );

    /**
     * @notice that this event show the info about a delisting.
     * @dev this event will be triggered when a market item is delisted from the marketplace.
     * @param tokenId the sequence number for the item.
     * @param amount the quantity to be delisted.
     * @param seller the seller of this tokenId.
     * @param contractAddress the MintGoldDustERC1155 or the MintGoldDustERC721 address.
     */
    event NftQuantityDelisted(
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        address contractAddress
    );

    error RoyaltyInvalidPercentage();
    error UnauthorizedOnNFT(string message);
    error Log(bytes32 domain, bytes encoded, bytes32 _eip712Hash);
    error ListPriceMustBeGreaterThanZero();

    /// @notice that his function will check if the parameters for the collector mint flow are valid.
    /// @param _artistAddress is the artist address that used collector mint.
    /// @param percentage is the percentage chosen by the artist for its royalty.
    modifier checkParameters(address _artistAddress, uint256 percentage) {
        if (
            !mintGoldDustCompany.isArtistApproved(_artistAddress) ||
            _artistAddress == address(0)
        ) {
            revert UnauthorizedOnNFT("ARTIST");
        }
        if (percentage > mintGoldDustCompany.maxRoyalty()) {
            revert RoyaltyInvalidPercentage();
        }
        _;
    }

    mapping(uint256 => bool) public collectorMintIdUsed;

    /**
     *
     * @notice MGDAuction is a children of MintGoldDustMarketplace and this one is
     * composed by other two contracts.
     * @param _mintGoldDustCompany The contract responsible to MGD management features.
     * @param _mintGoldDustERC721Address The MGD ERC721.
     * @param _mintGoldDustERC1155Address The MGD ERC721.
     */
    function initializeChild(
        address _mintGoldDustCompany,
        address payable _mintGoldDustERC721Address,
        address payable _mintGoldDustERC1155Address
    ) external initializer {
        MintGoldDustMarketplace.initialize(
            _mintGoldDustCompany,
            _mintGoldDustERC721Address,
            _mintGoldDustERC1155Address
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    /**
     *
     * @notice that is function to list a MintGoldDustNFT for the marketplace set price market.
     * @dev This is an implementation of a virtual function declared in the father
     *      contract. Here we're listing an NFT to the MintGoldDustSetPrice market that the item has
     *      a fixed price. After that the user can update the price of this item or if necessary
     *      delist it. After delist is possible to list again here of for auction or another set price.
     *    @notice that here we call the more generic list function passing the correct params for the set price market.
     * @param _tokenId: The tokenId of the marketItem.
     * @param _amount: The quantity of tokens to be listed for an MintGoldDustERC1155.
     *    @dev For MintGoldDustERC721 the amout must be always one.
     * @param _contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     * @param _price: The price or reserve price for the item.
     */
    function list(
        uint256 _tokenId,
        uint256 _amount,
        address _contractAddress,
        uint256 _price
    ) external override whenNotPaused {
        mustBeMintGoldDustERC721Or1155(_contractAddress);

        isNotListed(_tokenId, _contractAddress, msg.sender);

        if (_price == 0) {
            revert ListPriceMustBeGreaterThanZero();
        }

        ListDTO memory _listDTO = ListDTO(
            _tokenId,
            _amount,
            _contractAddress,
            _price
        );

        list(_listDTO, 0, msg.sender);

        emit MintGoldDustNftListedToSetPrice(
            _tokenId,
            msg.sender,
            _price,
            _contractAddress == mintGoldDustERC721Address ? 1 : _amount,
            _contractAddress
        );
    }

    /**
     * Updates an already listed NFT
     * @notice Only seller can call this function and this item must be
     * listed.
     * @dev The intention here is allow a user update the price of a
     * Market Item struct.
     * @param _tokenId The token ID of the the token to update.
     * @param _price The price of the NFT.
     * @param _contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     * @param _seller The seller of the marketItem.
     */
    function updateListedNft(
        uint256 _tokenId,
        uint256 _price,
        address _contractAddress,
        address _seller
    ) external {
        mustBeMintGoldDustERC721Or1155(_contractAddress);
        isTokenIdListed(_tokenId, _contractAddress, _seller);
        isSeller(_tokenId, _contractAddress, _seller);

        if (_price <= 0) {
            revert ListPriceMustBeGreaterThanZero();
        }

        idMarketItemsByContractByOwner[_contractAddress][_tokenId][_seller]
            .price = _price;

        emit MintGoldDustNftListedItemUpdated(
            _tokenId,
            msg.sender,
            _price,
            _contractAddress
        );
    }

    /**
     * Delist NFT from marketplace
     * @notice Only seller can call this function
     * @dev Here we transfer back the token id to the seller that is
     * really the owner of the item. And set the sold attribute to true.
     * This in conjunction with the fact that this contract address is not more the
     * owner of the item, means that the item is not listed.
     * @param _delistDTO The DelistDTO parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be delisted for an MintGoldDustERC1155.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     */
    function delistNft(DelistDTO memory _delistDTO) external nonReentrant {
        mustBeMintGoldDustERC721Or1155(_delistDTO.contractAddress);
        isTokenIdListed(
            _delistDTO.tokenId,
            _delistDTO.contractAddress,
            msg.sender
        );
        isSeller(_delistDTO.tokenId, _delistDTO.contractAddress, msg.sender);

        uint realAmount = 1;

        if (_delistDTO.contractAddress == mintGoldDustERC1155Address) {
            realAmount = _delistDTO.amount;
            hasEnoughAmountListed(
                _delistDTO.tokenId,
                _delistDTO.contractAddress,
                address(this),
                _delistDTO.amount,
                msg.sender
            );
        }

        MarketItem memory _marketItem = idMarketItemsByContractByOwner[
            _delistDTO.contractAddress
        ][_delistDTO.tokenId][msg.sender];

        _marketItem.tokenAmount = _marketItem.tokenAmount - realAmount;

        MintGoldDustNFT _mintGoldDustNFT = getERC1155OrERC721(
            _marketItem.isERC721
        );

        _mintGoldDustNFT.transfer(
            address(this),
            msg.sender,
            _delistDTO.tokenId,
            _delistDTO.amount
        );

        if (_marketItem.tokenAmount == 0) {
            delete idMarketItemsByContractByOwner[_delistDTO.contractAddress][
                _delistDTO.tokenId
            ][msg.sender];
        }

        emit NftQuantityDelisted(
            _delistDTO.tokenId,
            _delistDTO.amount,
            msg.sender,
            _delistDTO.contractAddress
        );
    }

    /**
     * @notice that is a function responsilble by start the collector (lazy) mint process on chain.
     * @param _collectorMintDTO is the CollectorMintDTO struct
     *                It consists of the following fields:
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - tokenURI: The tokenURI of the marketItem.
     *                    - royalty: The royalty of the marketItem.
     *                    - memoir: The memoir of the marketItem.
     *                    - collaborators: The collaborators of the marketItem.
     *                    - ownersPercentage: The ownersPercentage of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - artistSigner: The artistSigner of the marketItem.
     *                    - price: The price or reserve price for the item.
     *                    - collectorMintId: Is the collector mint id generated off chain.
     * @param _eip712HashOffChain is the hash of the eip712 object generated off chain.
     * @param _signature is the _signature of the eip712 object generated off chain.
     * @param _mintGoldDustSignature is the _signature using mintGoldDustCompany private key.
     * @param _amountToBuy is the amount of tokens to buy.
     * @dev See that we have some steps here:
     *      1. Verify if the artist signer address is not a zero address.
     *      2. Verify if contract address is a MintGoldDustERC721 or a MintGoldDustERC1155.
     *      3. Verify if the eip712 hash generated on chain match with the eip712 hash generated off chain.
     *      4. Verify if the collector mint dto hash generated on chain match with the collector mint dto hash generated off chain.
     *      5. Verify if signatures comes from our platform using the public keys.
     *      6. Verify if artist signatures are valid.
     */
    function collectorMintPurchase(
        CollectorMintDTO memory _collectorMintDTO,
        bytes32 _eip712HashOffChain,
        bytes memory _signature,
        bytes memory _mintGoldDustSignature,
        uint256 _amountToBuy
    )
        external
        payable
        nonReentrant
        checkParameters(
            _collectorMintDTO.artistSigner,
            _collectorMintDTO.royalty
        )
        whenNotPaused
    {
        mustBeMintGoldDustERC721Or1155(_collectorMintDTO.contractAddress);

        require(_collectorMintDTO.amount > 0, "Invalid amount to mint");
        require(_amountToBuy > 0, "Invalid amount to buy");

        require(
            collectorMintIdUsed[_collectorMintDTO.collectorMintId] == false,
            "Collector Mint Id already used"
        );

        collectorMintIdUsed[_collectorMintDTO.collectorMintId] = true;

        MintGoldDustNFT _mintGoldDustNFT;
        uint256 realAmount = _collectorMintDTO.amount;

        if (_collectorMintDTO.contractAddress == mintGoldDustERC721Address) {
            _mintGoldDustNFT = MintGoldDustNFT(mintGoldDustERC721Address);
            realAmount = 1;
        } else {
            _mintGoldDustNFT = MintGoldDustNFT(mintGoldDustERC1155Address);
        }

        require(_amountToBuy <= realAmount, "Invalid amount to buy");

        bytes32 _eip712HashOnChain = generateEIP712Hash(_collectorMintDTO);
        require(_eip712HashOnChain == _eip712HashOffChain, "Invalid hash");

        require(
            verifySignature(
                mintGoldDustCompany.publicKey(),
                _eip712HashOffChain,
                _mintGoldDustSignature
            ),
            "Invalid signature"
        );

        require(
            verifySignature(
                _collectorMintDTO.artistSigner,
                _eip712HashOffChain,
                _signature
            ),
            "Invalid signature"
        );

        uint256 _tokenId;

        if (_collectorMintDTO.collaborators.length == 0) {
            _tokenId = _mintGoldDustNFT.collectorMint(
                _collectorMintDTO.tokenURI,
                _collectorMintDTO.royalty,
                _collectorMintDTO.amount,
                _collectorMintDTO.artistSigner,
                _collectorMintDTO.memoir,
                _collectorMintDTO.collectorMintId,
                msg.sender
            );
        } else {
            _tokenId = _mintGoldDustNFT.collectorSplitMint(
                _collectorMintDTO.tokenURI,
                _collectorMintDTO.royalty,
                _collectorMintDTO.collaborators,
                _collectorMintDTO.ownersPercentage,
                _collectorMintDTO.amount,
                _collectorMintDTO.artistSigner,
                _collectorMintDTO.memoir,
                _collectorMintDTO.collectorMintId,
                msg.sender
            );
        }

        ListDTO memory _listDTO = ListDTO(
            _tokenId,
            _collectorMintDTO.amount,
            _collectorMintDTO.contractAddress,
            _collectorMintDTO.price
        );

        list(_listDTO, 0, _collectorMintDTO.artistSigner);

        emit MintGoldDustNftListedToSetPrice(
            _listDTO.tokenId,
            _collectorMintDTO.artistSigner,
            _listDTO.price,
            _collectorMintDTO.amount,
            _collectorMintDTO.contractAddress
        );

        callPurchase(
            _tokenId,
            _amountToBuy,
            _collectorMintDTO.contractAddress,
            _collectorMintDTO.artistSigner,
            msg.value
        );
    }

    /**
     * Acquire a listed NFT to Set Price market
     * @notice function will fail if the market item does has the auction property to true.
     * @notice function will fail if the token was not listed to the set price market.
     * @notice function will fail if the contract address is not a MintGoldDustERC721 neither a MintGoldDustERC1155.
     * @notice function will fail if the amount paid by the buyer does not cover the purshace amount required.
     * @dev This function is specific for the set price market.
     * For the auction market we have a second purchaseAuctionNft function. See below.
     * @param _saleDTO The SaleDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     */
    function purchaseNft(SaleDTO memory _saleDTO) external payable {
        executePurchaseNftFlow(_saleDTO, msg.sender, msg.value);
    }

    /// @notice that is a function responsible by handling the call to the purchase function.
    function callPurchase(
        uint256 _tokenId,
        uint256 _amount,
        address _contractAddress,
        address _artistSigner,
        uint256 _value
    ) private {
        SaleDTO memory _saleDTO = SaleDTO(
            _tokenId,
            _amount,
            _contractAddress,
            _artistSigner
        );
        executePurchaseNftFlow(_saleDTO, msg.sender, _value);
    }

    /**
     * @notice that function is responsible by verify a _signature on top of the eip712 object hash.
     * @param _expectedSigner is the signer address.
     *    @dev in this case is the artist signer address.
     * @param _eip712Hash is the _signature of the eip712 object generated off chain.
     * @param _signature is the collector mint id generated off chain.
     */
    function verifySignature(
        address _expectedSigner,
        bytes32 _eip712Hash,
        bytes memory _signature
    ) private pure returns (bool) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _eip712Hash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        require(_signature.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = ecrecover(prefixedHash, v, r, s);
        return signer == _expectedSigner;
    }

    /**
     * @notice that is a function that will generate the hash of the eip712 object on chain.
     * @param _collectorMintDTO is the CollectorMintDTO struct
     *                It consists of the following fields:
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - tokenURI: The tokenURI of the marketItem.
     *                    - royalty: The royalty of the marketItem.
     *                    - memoir: The memoir of the marketItem.
     *                    - collaborators: The collaborators of the marketItem.
     *                    - ownersPercentage: The ownersPercentage of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - artistSigner: The artistSigner of the marketItem.
     *                    - price: The price or reserve price for the item.
     * @notice that this function depends on another two functions:
     *      1. encodeDomainSeparator: that will encode the domain separator.
     *      2. encodeData: that will encode the _collectorMintDTO.
     */
    function generateEIP712Hash(
        CollectorMintDTO memory _collectorMintDTO
    ) private view returns (bytes32) {
        bytes memory encodedData = encodeData(_collectorMintDTO);
        bytes32 domainSeparator = encodeDomainSeparator();

        bytes32 encodedDataHash = keccak256(
            abi.encode(bytes1(0x19), bytes1(0x01), domainSeparator, encodedData)
        );

        bytes32 hashBytes32 = bytes32(encodedDataHash);

        return (hashBytes32);
    }

    /**
     * @notice that is a function that will create and encode the domain separator of the eip712 object on chain.
     */
    function encodeDomainSeparator() private view returns (bytes32) {
        bytes32 domainTypeHash = keccak256(
            abi.encodePacked(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );

        bytes32 nameHash = keccak256(bytes("MintGoldDustSetPrice"));
        bytes32 versionHash = keccak256(bytes("1.0.0"));

        bytes32 domainSeparator = keccak256(
            abi.encode(
                domainTypeHash,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );

        return domainSeparator;
    }

    /**
     * @notice that is a function that will encode the _collectorMintDTO for the eip712 object on chain.
     * @param _collectorMintDTO is the CollectorMintDTO struct
     *                It consists of the following fields:
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - tokenURI: The tokenURI of the marketItem.
     *                    - royalty: The royalty of the marketItem.
     *                    - memoir: The memoir of the marketItem.
     *                    - collaborators: The collaborators of the marketItem.
     *                    - ownersPercentage: The ownersPercentage of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - artistSigner: The artistSigner of the marketItem.
     *                    - price: The price or reserve price for the item.
     */
    function encodeData(
        CollectorMintDTO memory _collectorMintDTO
    ) private pure returns (bytes memory) {
        bytes memory encodedData = abi.encode(
            _collectorMintDTO.contractAddress,
            _collectorMintDTO.tokenURI,
            _collectorMintDTO.royalty,
            _collectorMintDTO.memoir,
            _collectorMintDTO.collaborators,
            _collectorMintDTO.ownersPercentage,
            _collectorMintDTO.amount,
            _collectorMintDTO.artistSigner,
            _collectorMintDTO.price,
            _collectorMintDTO.collectorMintId
        );

        return encodedData;
    }
}
