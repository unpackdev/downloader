// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./TunnelEnabled.sol";
import "./ISubjectRoot.sol";
import "./Subject.sol";
import "./SubjectWithGeneChanger.sol";

contract SubjectRoot is SubjectWithGeneChanger, ISubjectRoot, TunnelEnabled {
    using SubjectGeneGenerator for SubjectGeneGenerator.Gene;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public subjectPrice;
    uint256 public bulkBuyLimit;

    uint256 public presaleStartDate;
    uint256 public presaleDuration;
    mapping(address => bool) public whitelistedWallets;
    address[] public whitelistedContracts;

    uint256 public baseGenomeChangePrice;
    uint256 public randomizeGenomePrice;

    event SubjectPriceChanged(uint256 newSubjectPrice);
    event MaxSupplyChanged(uint256 newMaxSupply);
    event BulkBuyLimitChanged(uint256 newBulkBuyLimit);
    event BaseGenomeChangePriceChanged(uint256 newGenomeChange);
    event RandomizeGenomePriceChanged(uint256 newRandomizeGenomePriceChange);
    event PresaleStartDateSet(uint256 _presaleStartDate);
    event PresaleDurationSet(uint256 _presaleDuration);
    event WhitelistedWalletsSet(address[] _whitelistedWallets);
    event WhitelistedContractsSet(address[] _whitelistedContracts);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address payable _daoAddress,
        uint256 _subjectPrice,
        uint256 _maxSupply,
        uint256 _bulkBuyLimit,
        uint256 _baseGenomeChangePrice,
        uint256 _randomizeGenomePrice,
        string memory _arweaveAssetsJSON
    )
        SubjectWithGeneChanger(
            name,
            symbol,
            baseURI,
            _daoAddress,
            _maxSupply,
            _arweaveAssetsJSON
        )
    {
        subjectPrice = _subjectPrice;
        bulkBuyLimit = _bulkBuyLimit;
        baseGenomeChangePrice = _baseGenomeChangePrice;
        randomizeGenomePrice = _randomizeGenomePrice;
        arweaveAssetsJSON = _arweaveAssetsJSON;

        geneGenerator.random();
    }

    function mint() private nonReentrant {
        require(_tokenIdTracker.current() < maxSupply, "Total supply reached");

        _tokenIdTracker.increment();

        uint256 tokenId = _tokenIdTracker.current();

        if (_bossTokens[tokenId] != 0) {
            _genes[tokenId] = _bossTokens[tokenId];
        } else {
            _genes[tokenId] = setUpRareTraitsInGenome(geneGenerator.random());
        }

        (bool transferToDaoStatus, ) = daoAddress.call{value: subjectPrice}(
            ""
        );
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(subjectPrice);
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        _mint(_msgSender(), tokenId);
        _setTokenRoyalty(tokenId, daoAddress, royaltyFeeBps);

        emit TokenMinted(tokenId, _genes[tokenId]);
        emit TokenMorphed(
            tokenId,
            0,
            _genes[tokenId],
            subjectPrice,
            SubjectEventType.MINT
        );
    }

    function bulkBuy(uint256 amount) private nonReentrant {
        require(
            amount <= bulkBuyLimit,
            "Cannot bulk buy more than the preset limit"
        );
        require(
            _tokenIdTracker.current().add(amount) <= maxSupply,
            "Total supply reached"
        );

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: subjectPrice.mul(amount)
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(subjectPrice.mul(amount));
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdTracker.increment();

            uint256 tokenId = _tokenIdTracker.current();

            if (_bossTokens[tokenId] != 0) {
                _genes[tokenId] = _bossTokens[tokenId];
            } else {
                _genes[tokenId] = setUpRareTraitsInGenome(geneGenerator.random());
            }

            _mint(_msgSender(), tokenId);
            _setTokenRoyalty(tokenId, daoAddress, royaltyFeeBps);

            emit TokenMinted(tokenId, _genes[tokenId]);
            emit TokenMorphed(
                tokenId,
                0,
                _genes[tokenId],
                subjectPrice,
                SubjectEventType.MINT
            );
        }
    }

    function mint(address to)
        public
        pure
        override(ERC721PresetMinterPauserAutoId)
    {
        revert("Should not use this one");
    }

    /**
    * @notice Invokes `mint` if presale has started and msg.sender is whitelisted.
     *
     * Requirements:
     * - the caller must be whitelisted.
     * - the presale must have started.
     */
    function mintTokenOnPresale() public override payable {
        require(
            (block.timestamp > presaleStartDate) &&
            (block.timestamp < (presaleStartDate + presaleDuration)),
            "Current timestamp is not in the bounds of the presale period"
        );
        require(whitelistedWallets[msg.sender] || isHodler(msg.sender), "You are not eligible for presale");

        mint();
    }

    /**
     * @notice Invokes `mint`.
     */
    function mintTokenOnSale() public override payable {
        require(
            block.timestamp > (presaleStartDate + presaleDuration),
            "Sale period not started!"
        );

        mint();
    }

    /**
    * @notice Invokes `bulkBuy` if presale has started and msg.sender is whitelisted.
     *
     * Requirements:
     * - the caller must be whitelisted.
     * - the presale must have started.
     */
    function bulkBuyTokensOnPresale(uint256 quantity) public override payable {
        require(
            (block.timestamp > presaleStartDate) &&
            (block.timestamp < (presaleStartDate + presaleDuration)),
            "Current timestamp is not in the bounds of the presale period"
        );
        require(whitelistedWallets[msg.sender] || isHodler(msg.sender), "You are not eligible for presale");

        bulkBuy(quantity);
    }

    /**
     * @notice Invokes `bulkBuy` with the quantity requested.
     */
    function bulkBuyTokensOnSale(uint256 quantity) public override payable {
        require(
            block.timestamp > (presaleStartDate + presaleDuration),
            "Sale period not started!"
        );

        bulkBuy(quantity);
    }

    function reserveMint(uint256 amount)
        public
        virtual
        override
        onlyDAO
    {
        require(
            _tokenIdTracker.current().add(amount) <= maxSupply,
            "Total supply reached"
        );

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdTracker.increment();

            uint256 tokenId = _tokenIdTracker.current();

            if (_bossTokens[tokenId] != 0) {
                _genes[tokenId] = _bossTokens[tokenId];
            } else {
                _genes[tokenId] = setUpRareTraitsInGenome(geneGenerator.random());
            }

            _mint(_msgSender(), tokenId);
            _setTokenRoyalty(tokenId, daoAddress, royaltyFeeBps);

            emit TokenMinted(tokenId, _genes[tokenId]);
            emit TokenMorphed(
                tokenId,
                0,
                _genes[tokenId],
                subjectPrice,
                SubjectEventType.MINT
            );
        }
    }

    receive() external payable {
        mint();
    }

    function generateBossCharacters(uint256[] calldata entries)
        public
        virtual
        override
        onlyDAO
    {
        require(entries.length == 10, "Should be 10 boss genes!");

        for (uint256 i = 0; i < entries.length; i++) {
            require(entries[i] != 0, "Null gene");

            uint256 selectedToken = (geneGenerator.random() % (maxSupply - 1)) + 1;

            if (_bossTokens[selectedToken] != 0) {
                i--;
                continue;
            }

            _bossTokens[selectedToken] = entries[i];
        }

        emit BossCharactersGenerated(entries);
    }

    function morphGene(uint256 tokenId, uint256 genePosition) public override payable {
        _morphGene(tokenId, genePosition, priceForGenomeChange(tokenId));
    }

    function randomizeGenome(uint256 tokenId) public override payable {
        _randomizeGenome(tokenId, randomizeGenomePrice);
    }

    function setSubjectPrice(uint256 newSubjectPrice)
        public
        virtual
        override
        onlyDAO
    {
        subjectPrice = newSubjectPrice;

        emit SubjectPriceChanged(newSubjectPrice);
    }

    function setMaxSupply(uint256 _maxSupply)
        public
        virtual
        override
        onlyDAO
    {
        maxSupply = _maxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    function setBulkBuyLimit(uint256 _bulkBuyLimit)
        public
        virtual
        override
        onlyDAO
    {
        bulkBuyLimit = _bulkBuyLimit;

        emit BulkBuyLimitChanged(_bulkBuyLimit);
    }

    function changeBaseGenomeChangePrice(uint256 newGenomeChangePrice)
        public
        virtual
        override
        onlyDAO
    {
        baseGenomeChangePrice = newGenomeChangePrice;
        emit BaseGenomeChangePriceChanged(newGenomeChangePrice);
    }

    function changeRandomizeGenomePrice(uint256 newRandomizeGenomePrice)
        public
        virtual
        override
        onlyDAO
    {
        randomizeGenomePrice = newRandomizeGenomePrice;
        emit RandomizeGenomePriceChanged(newRandomizeGenomePrice);
    }

    /**
    * @notice Sets presaleStartDate.
    * @param _presaleStartDate uint256 representing the start date of the presale
    */
    function setPresaleStartDate(uint256 _presaleStartDate)
        public
        virtual
        override
        onlyDAO
    {
        require(
            _presaleStartDate > block.timestamp,
            "Presale: start must be in future!"
        );
        presaleStartDate = _presaleStartDate;
        emit PresaleStartDateSet(presaleStartDate);
    }

    /**
    * @notice Sets presaleDuration.
    * @param _presaleDuration uint256 representing the duration of the presale
    */
    function setPresaleDuration(uint256 _presaleDuration)
        public
        virtual
        override
        onlyDAO
    {
        require(_presaleDuration > 0, "Presale: not a valid duration!");
        presaleDuration = _presaleDuration;
        emit PresaleDurationSet(presaleDuration);
    }

    /**
    * @notice Sets whitelisted wallets.
    * @param beneficiaries address[] representing the user who will be whitelisted
    */
    function setWhitelistedWallets(address[] memory beneficiaries)
        public
        virtual
        override
        onlyDAO
    {
        require(
            beneficiaries.length > 0,
            "Beneficiaries array length must greater than 0"
        );

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            require(beneficiaries[i] != address(0), "Null address");
            whitelistedWallets[beneficiaries[i]] = true;
        }

        emit WhitelistedWalletsSet(beneficiaries);
    }

    /**
    * @notice Sets whitelisted contracts that implement open zeppelin's IERC721 interface.
    * @param beneficiaries address[] representing the contract which hodlers will be whitelisted
    */
    function setWhitelistedContracts(address[] memory beneficiaries)
        public
        virtual
        override
        onlyDAO
    {
        require(
            beneficiaries.length > 0,
            "Beneficiaries array length must greater than 0"
        );

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            require(beneficiaries[i] != address(0), "Null address");
        }
        whitelistedContracts = beneficiaries;

        emit WhitelistedContractsSet(beneficiaries);
    }

    function isHodler(address walletAddress) internal view returns (bool) {
        for (uint i = 0; i < whitelistedContracts.length; i++) {
            if (IERC721(whitelistedContracts[i]).balanceOf(walletAddress) > 0) {
                return true;
            }
        }

        return false;
    }

    function priceForGenomeChange(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256 price)
    {
        uint256 pastChanges = _genomeChanges[tokenId];

        return baseGenomeChangePrice.mul(1 << pastChanges);
    }

    function isEligibleForPresale(address walletAddress)
        public
        view
        override
        isValidAddress(walletAddress)
        returns (bool)
    {
        return whitelistedWallets[walletAddress] || isHodler(walletAddress);
    }

    function wormholeUpdateGene(
        uint256 tokenId,
        uint256 gene,
        bool _isNotVirgin,
        uint256 genomeChangesCount
    ) external nonReentrant onlyTunnel {
        uint256 oldGene = _genes[tokenId];
        _genes[tokenId] = gene;
        isNotVirgin[tokenId] = _isNotVirgin;
        _genomeChanges[tokenId] = genomeChangesCount;

        emit TokenMorphed(
            tokenId,
            oldGene,
            _genes[tokenId],
            priceForGenomeChange(tokenId),
            SubjectEventType.MORPH
        );
    }

    function whitelistBridgeAddress(address bridgeAddress, bool status)
        external
        override
        onlyDAO
    {
        whitelistTunnelAddresses[bridgeAddress] = status;
    }

}
