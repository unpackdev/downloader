// SPDX-License-Identifier: MIT

// Crypto Boss Concierge NFTs are governed by the following terms & conditions: https://www.cryptobossconcierge.com/terms-and-conditions/

pragma solidity 0.8.14;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./MerkleProof.sol";
import "./AccessControl.sol";
import "./Strings.sol";

/*
* @title Guarded ERC-721 Token for Crypto Boss Concierge Service
* @author max @ thejelly.io
*/

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

contract ConciergePass is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    EIP712Base
{

    mapping(uint256 => mapping(string => uint256)) public maxTokenIdByStageAndTier;
    mapping(string => uint256) public tokenIdToMintByTier;

    address payable constant CRYPTOBOSS = payable(address(0x5e49973fb1a71dD555B848371737e02B1C32d221));
    address payable constant BOOST = payable(address(0x93C2FC5A8e4f985F1C4dbCb4D9AC9b4F3C2e19B4));
    address payable constant JELLY = payable(address(0x447EAA443C017284EcFB7Fa39a6548B6908f7f0e));

    uint8 maxTxPublic = 4;
    uint256 public currentContractStage = 1;

    uint256 public mintPriceAlpha = 7500000000000000000; // 7.5 ETH at the start
    uint256 public mintPriceWhale = 20000000000000000000; // 20 ETH at the start
    uint256 public onboardingFeeAlpha = 6500000000000000000; // 6.5 ETH at the start, subscription renewal fee
    uint256 public onboardingFeeWhale = 15000000000000000000; // 15 ETH at the start, subscription renewal fee

    bytes32 public merkleRootPresale;
    bytes32 public merkleRootPublicSale;
    string public baseUri = "";

    struct MetaDataToken {
        bool forResale;
        bool transferFeePaid;
        string tier;
        uint256 price;
    }

    mapping(uint256 => MetaDataToken) public nftMetaData;
    mapping(uint256 => mapping(address => bool)) public whitelistClaimedPerStage;

    mapping(uint256 => uint256) public resaleTokenIndex;
    mapping(uint256 => uint256) public resaleTokenByIndex;
    uint256[] public resaleToken;

    event TokenMinted(
        address indexed minter,
        uint256 indexed tokenId,
        string tier
    );

    event PricesChanged(
        uint256 mintPriceAlpha,
        uint256 mintPriceWhale,
        uint256 onboardingFeeAlpha,
        uint256 onboardingFeeWhale
    );

    event TokenOnResale(uint256 indexed tokenId, uint256 price);
    event TokenRevoked(uint256 indexed tokenId);
    event ContractStageChanged(uint256 newStage);
    event BaseUriUpdated(string newUri);

    /**
     * set the merkle-root for whitelisting
     */
    constructor() ERC721("CryptoBoss Concierge", "BOSS") {
        _initializeEIP712("CryptoBoss Concierge");
        merkleRootPresale = bytes32("XXXXXXXXXXXXXXXX");
        merkleRootPublicSale = bytes32("XXXXXXXXXXXXX");
        baseUri = "https://storage.googleapis.com/cryptoboss-concierge-nft-metadata/gen/";

        maxTokenIdByStageAndTier[1]["ALPHA"] = 1200; // 1001 - 1200 --> 200 presale alpha
        maxTokenIdByStageAndTier[1]["WHALE"] = 100; // 1 - 100 --> 100 presale whale
        maxTokenIdByStageAndTier[2]["ALPHA"] = 1500; // 1201 - 1500 --> 300 WL public sale alpha, may change
        maxTokenIdByStageAndTier[2]["WHALE"] = 200; // 101 - 200 --> 100 WL public sale whale, may change
        maxTokenIdByStageAndTier[3]["ALPHA"] = 2500; // 1501 - 2500 --> 1000 alpha public sale
        maxTokenIdByStageAndTier[3]["WHALE"] = 500; // 201 - 500 --> 300 whale public sale

        tokenIdToMintByTier["WHALE"] = 1;
        tokenIdToMintByTier["ALPHA"] = 1001;

    }

    modifier onlyAdmin {
        require(msg.sender == JELLY || msg.sender == CRYPTOBOSS,"CONCIERGE: unauthorized access");
        _;
    }

    modifier canMint(address payable _sender) {
        require(balanceOf(_sender) < maxTxPublic);
        _;
    }

    modifier tokenAvailable(string calldata _tier) {
        require(
            keccak256(abi.encodePacked(_tier)) == keccak256(abi.encodePacked("ALPHA")) 
            || 
            keccak256(abi.encodePacked(_tier)) == keccak256(abi.encodePacked("WHALE"))
            , "non-existent tier");
        require(
            tokenIdToMintByTier[_tier] 
            <= 
            maxTokenIdByStageAndTier[currentContractStage][_tier], 
            "CONCIERGE: no more token available at the moment"
        );
        _;
    }

    modifier correctPaymentMint(string calldata _tier) {
        if (keccak256(abi.encodePacked(_tier)) == keccak256(abi.encodePacked("ALPHA"))) {
            require(msg.value == mintPriceAlpha, "CONCIERGE: incorrect mint price");
        } else {
            require(msg.value == mintPriceWhale, "CONCIERGE: incorrect mint price");
        }
        _;
    }

    modifier correctPaymentMarketplace(uint256 _tokenId) {
        if (_tokenId < 1001) {
            require(
                msg.value == (nftMetaData[_tokenId].price + onboardingFeeWhale)
            );
        } else {
            require(
                msg.value == (nftMetaData[_tokenId].price + onboardingFeeAlpha)
            );
        }
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        require(from == address(0) || nftMetaData[tokenId].transferFeePaid == true, "CONCIERGE: transfer without paid onboarding fee initiated");
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) 
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory) {
            return string(abi.encodePacked(baseUri, Strings.toString(tokenId), ".json"));
    }

    /**
    * @notice edit the merkle root for presale
    * @param _merkleRoot the new merkle root
    */
    function setMerkleRootPresale(bytes32 _merkleRoot) external onlyAdmin {
        merkleRootPresale = _merkleRoot;
    }

    function initialSubgraphPopulate() external onlyAdmin {
        emit BaseUriUpdated(baseUri);
        emit PricesChanged(mintPriceAlpha, mintPriceWhale, onboardingFeeAlpha, onboardingFeeWhale);
    }

    /**
    * @notice edit the merkle root for the whitelist of the public sale
    * @param _merkleRoot the new merkle root
    */
    function setMerkleRootPublicSale(bytes32 _merkleRoot) external onlyAdmin {
        merkleRootPublicSale = _merkleRoot;
    }

    /**
    * @notice edit the contract's baseUri, normally points to GCS-bucket
    * @param _baseUri the new baseUri
    */
    function setBaseUri(string calldata _baseUri) external onlyAdmin {
        baseUri = _baseUri;
        emit BaseUriUpdated(_baseUri);
    }

    /**
    * @notice edit the contract stage regulating the access-mode
    * @notice 1 = presale
    * @notice 2 = publice sale WL-access
    * @notice 3 = public sale
    * @param _newStage the new contract stage
    */
    function setContractStage(uint256 _newStage) external onlyAdmin {
        currentContractStage = _newStage;
        emit ContractStageChanged(_newStage);
    }

    /**
    * @notice edit the mint prices and onboarding fees
    * @param _mintPriceAlpha the new price for "alpha" token in wei
    * @param _mintPriceWhale the new price for "alpha" token in wei
    * @param _onboardingFeeAlpha the new onboarding fee for "alpha" token in wei
    * @param _onboardingFeeWhale the new onboarding fee for "whale" token in wei
    */
    function setPrices(
        uint256 _mintPriceAlpha,
        uint256 _mintPriceWhale,
        uint256 _onboardingFeeAlpha,
        uint256 _onboardingFeeWhale
    ) external onlyAdmin {
        mintPriceAlpha = _mintPriceAlpha;
        mintPriceWhale = _mintPriceWhale;
        onboardingFeeAlpha = _onboardingFeeAlpha;
        onboardingFeeWhale = _onboardingFeeWhale;

        emit PricesChanged(mintPriceAlpha, mintPriceWhale, onboardingFeeAlpha, onboardingFeeWhale);
    }

    /**
     * @notice edit the amounts of token mintable per stage and tier
     * @param _contractStage contractStage to be altered
     * @param _tier tier to be altered
     * @param _newMaxId new maximum tokenId reachable for this contractstage-tier combination
     */
    function setTokenAmounts(
        uint256 _contractStage,
        string calldata _tier,
        uint256 _newMaxId
    ) external onlyAdmin {
        maxTokenIdByStageAndTier[_contractStage][_tier] = _newMaxId;
    }

    /**
    * @notice edit the transaction limits
    * @param _maxTxPublic new max transaction limit for public sale
    */
    function setTransactionLimits(
        uint8 _maxTxPublic
    ) external onlyAdmin {
        maxTxPublic = _maxTxPublic;
    }

    function earlyAccessMint(
        string calldata _tier,
        bytes32[] calldata _merkleProof
    ) external payable {
        earlyAccessMintRecipient(payable(msg.sender), _tier, _merkleProof);
    }

    function earlyAccessMintRecipient(
        address payable _recipient,
        string calldata _tier,
        bytes32[] calldata _merkleProof
    ) public payable canMint(_recipient) correctPaymentMint(_tier) tokenAvailable(_tier) {
        require(currentContractStage < 3, "CONCIERGE: wl-access not open");
        require(whitelistClaimedPerStage[currentContractStage][_recipient] == false, "CONCIERGE: wl-spot already claimed");
        if (currentContractStage == 1) {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    merkleRootPresale,
                    keccak256(abi.encodePacked(_recipient))
                ),
                "CONCIERGE: invalid proof"
            );
        } else {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    merkleRootPublicSale,
                    keccak256(abi.encodePacked(_recipient))
                ),
                "CONCIERGE: invalid proof"
            );
        }

        whitelistClaimedPerStage[currentContractStage][_recipient] = true;
        _mintConciergePass(_recipient, _tier);
    }

    function publicMint(string calldata _tier) external payable {
        publicMintRecipient(payable(msg.sender), _tier);
    }

    // public regular mint
    function publicMintRecipient(
        address payable _recipient,
        string calldata _tier
    ) public payable canMint(_recipient) tokenAvailable(_tier) correctPaymentMint(_tier) {
        require(currentContractStage >= 3, "CONCIERGE: public sale hasn't started yet");
        _mintConciergePass(_recipient, _tier);
    }

    function _mintConciergePass(address payable _recipient, string calldata _tier) internal {
        uint256 tokenId = tokenIdToMintByTier[_tier];
        tokenIdToMintByTier[_tier]++;

        _mint(_recipient, tokenId);
        nftMetaData[tokenId] = MetaDataToken(false, false, _tier, 0);

        (bool success, ) = CRYPTOBOSS.call{value: (msg.value * 925) / 1000}("");
        require(success, 'transfer to cryptoboss failed');
        (success, ) = BOOST.call{value: (msg.value * 50) / 1000}("");
        require(success, 'transfer to boost failed');
        (success, ) = JELLY.call{value: (msg.value * 25) / 1000}("");
        require(success, 'transfer to jelly failed');
        
        emit TokenMinted(_recipient, tokenId, _tier);
    }

    /**
     * @notice Function that allows users to resell their token
     * @dev should add the token to the array of token on resale, and add it
     * the indices necessary to retrieve/remove it later on
     * @param _tokenId token to be resold
     * @param _price price for which the token should be resold
     */
    function setTokenForResale(uint256 _tokenId, uint256 _price) external {
        require(msg.sender == ownerOf(_tokenId), "CONCIERGE: Unauthorized Account");
        _setTokenForResale(_tokenId, _price);
    }

    function _setTokenForResale(uint256 _tokenId, uint256 _price) internal {
        require(nftMetaData[_tokenId].forResale == false, "CONCIERGE: token already set");
        require(_price > 0, "CONCIERGE: price can't be 0");

        nftMetaData[_tokenId].price = _price;
        nftMetaData[_tokenId].forResale = true;

        resaleTokenIndex[_tokenId] = resaleToken.length;
        resaleTokenByIndex[resaleToken.length] = _tokenId;
        resaleToken.push(_tokenId);

        emit TokenOnResale(_tokenId, _price);
    }

    /**
     * @notice function that unlists a token from the marketplace
     * @dev reverses 'setTokenForResale'
     * @param _tokenId token to be unlisted
     */
    function revokeTokenMarketPlace(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "CONCIERGE: Non-Owner trying to set price");
        require(nftMetaData[_tokenId].forResale == true, "CONCIERGE: This token is currently not set for sale");

        nftMetaData[_tokenId].price = 0;
        nftMetaData[_tokenId].forResale = false;
        _removeFromEnumeration(_tokenId);

        emit TokenRevoked(_tokenId);
    }

    function purchaseTokenMarketPlace(uint256 _tokenId) external payable {
        purchaseTokenMarketPlaceRecipient(_tokenId, payable(msg.sender));
    }

    /**
     * @notice takes payment from buyer, calls the transfer function, and distributes payment
     * @notice sends 98% of ether to former owner, 2% to CryptoBoss
     * @param _tokenId token that is being bought
     * @param _recipient recipient of the token
     */
    function purchaseTokenMarketPlaceRecipient(
        uint256 _tokenId, 
        address payable _recipient
    ) public payable canMint(_recipient) correctPaymentMarketplace(_tokenId) {
        require(nftMetaData[_tokenId].forResale == true, "CONCIERGE: This Token is not for sale");

        nftMetaData[_tokenId].forResale = false;
        nftMetaData[_tokenId].transferFeePaid = true;

        address payable owner = payable(ownerOf(_tokenId));
        _transfer(owner, payable(_recipient), _tokenId);
        _removeFromEnumeration(_tokenId);
        nftMetaData[_tokenId].transferFeePaid = false;

        // transfer 2% and the 12-month subscription fee for that tier to concierge service
        uint256 _onboardingFee = keccak256(abi.encodePacked(nftMetaData[_tokenId].tier))
            == 
            keccak256(abi.encodePacked("ALPHA"))
            ? onboardingFeeAlpha
            : onboardingFeeWhale;

        (bool success, ) = CRYPTOBOSS.call{
            value: (
                _onboardingFee
                + ((msg.value - _onboardingFee) * 2) / 100
            )
        }("");
        require(success, 'transfer to cryptoboss failed');
        (success, ) = owner.call{value: ((msg.value - _onboardingFee) * 98) / 100}("");
        require(success, 'transfer to old owner failed');

    }

    /**
     * @notice takes token away from people no longer paying for their service 
     * @notice puts it up for resale
     * @param _tokenId token to take away
     */
    function bounceFreeriders(uint256 _tokenId) external onlyAdmin {
        // admin does not have to pay onboarding-fee
        nftMetaData[_tokenId].transferFeePaid = true;
        address owner = ownerOf(_tokenId);
        _transfer(owner, CRYPTOBOSS, _tokenId);
        nftMetaData[_tokenId].transferFeePaid = false;

        uint256 mintPrice = (_tokenId > 1000) ? mintPriceAlpha : mintPriceWhale;
        _setTokenForResale(_tokenId, mintPrice);

    }

    /**
     * @notice function that returns the amount of token currently listed
     * on the marketplace for iteration in the front-end
     */
    function balanceMarketPlace() external view returns(uint256 length) {
        return resaleToken.length;

    }

    /**
     * @notice function that removes a token listed on the marketplace from
     * all relevant enumerations
     * @dev usage of the swap&pop pattern
     * @param tokenId token to be removed
     */
    function _removeFromEnumeration(uint256 tokenId) internal {
        uint256 lastTokenIndex = resaleToken.length - 1;
        uint256 tokenIndex = resaleTokenIndex[tokenId];

        uint256 lastTokenId = resaleToken[lastTokenIndex];
        resaleToken[tokenIndex] = lastTokenId;
        resaleToken[lastTokenIndex] = tokenId;
        resaleTokenIndex[lastTokenId] = tokenIndex;
        resaleTokenIndex[tokenId] = lastTokenIndex;

        delete resaleTokenByIndex[resaleTokenIndex[tokenId]];
        delete resaleTokenIndex[tokenId];
        resaleToken.pop();

    }

    function supportsInterface(bytes4 interfaceId) 
        public
        view 
        override (
        ERC721, 
        ERC721Enumerable
        ) returns (bool) {
            return super.supportsInterface(interfaceId);
    }

}