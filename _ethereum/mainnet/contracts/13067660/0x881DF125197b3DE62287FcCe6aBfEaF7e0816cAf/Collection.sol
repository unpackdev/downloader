// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./AccessControlUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

/**
 * @title Digital art collectible metaverse
 * @author NFT Legends team
 **/
contract Collection is ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    event NameChange(uint256 indexed index, string newName);
    event SkillChange(uint256 indexed index, uint256 newSkill);
    event DnaChange(uint256 indexed index, uint256 newDna);
    event Buy(address indexed _from, uint256 nfts, address referral);

    // each token has its own attributes: Name, Skill and DNA
    // Name is the symbolic string, that can be changed over time
    mapping(uint256 => string) private _tokenName;
    // Skill is a numeric value that represents character's experience
    mapping(uint256 => uint256) private _tokenSkill;
    // DNA is 256-bit map where unique token attributes encoded
    mapping(uint256 => uint256) private _tokenDna;

    // when sale is active, anyone is able to buy the token
    bool public saleActive;

    using SafeMath for uint256;
    using Strings for uint256;

    // The token purchase price depends on how early you buy the character
    // (i.e. sequential number of the purchase)
    struct SaleStage {
        uint256 startTokensBought;
        uint256 endTokensBought;
        uint256 weiPerToken;
    }

    // All the tokens are grouped in batches. Batch is basically IPFS folder (DAG)
    // that stores token descriptions and images. It tokenId falls into batch, the
    // tokenURI = batch.baseURI + "/" + tokenId.
    // All the batches have the same rarity parameter.
    struct Batch {
        uint256 startBatchTokenId;
        uint256 endBatchTokenId;
        string baseURI;
        uint256 rarity;
    }

    // Arrays that store configured batches and saleStages
    Batch[] internal _batches;
    SaleStage[] internal _saleStages;
    // Maximum allowed tokenSupply boundary. Can be extended by adding new stages.
    uint256 internal _maxTotalSupply;
    // Max NFTs that can be bought at once. To avoid gas overspending.
    uint256 public maxPurchaseSize;

    // If tokenId doesn't match any configured batch, defaultURI parameters are used.
    string internal _defaultUri;
    uint256 internal _defaultRarity;
    string internal _defaultName;
    uint256 internal _defaultSkill;
    // Roles that can modify individual characteristics
    bytes32 public constant NAME_SETTER_ROLE = keccak256("NAME_SETTER_ROLE");
    bytes32 public constant SKILL_SETTER_ROLE = keccak256("SKILL_SETTER_ROLE");
    bytes32 public constant DNA_SETTER_ROLE = keccak256("DNA_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Received funds (native Ether or BNB) get transferred to Vault address
    address payable public vault;

    function initialize() public initializer {
        __ERC721_init("CyberPunk", "A-12");
        __ERC721Enumerable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(NAME_SETTER_ROLE, _msgSender());
        _setupRole(SKILL_SETTER_ROLE, _msgSender());
        _setupRole(DNA_SETTER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        maxPurchaseSize = 20;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns current `_maxTotalSupply` value.
     */
    function maxTotalSupply() public view virtual returns (uint256) {
        return _maxTotalSupply;
    }

    /**
     * @dev Hook that is called before any token transfer incl. minting
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // check maxTotalSupply is not exceeded on mint
        if (from == address(0)) {
            require(totalSupply() <= _maxTotalSupply, "Collection: maxSupply achieved");
        }
    }

    /**
     * @dev Returns the number of configured saleStages (tokensale schedule)
     * @return current `_saleStages` array length
     */
    function saleStagesLength() public view returns (uint256) {
        return _saleStages.length;
    }

    /**
     * @dev Returns the saleStage by its index
     * @param saleStageIndex salestage index in the array
     * @return info about sale stage
     */
    function getSaleStage(uint256 saleStageIndex) public view returns (SaleStage memory) {
        require(_saleStages.length > 0, "getSaleStage: no stages");
        require(saleStageIndex < _saleStages.length, "Id must be < sale stages length");

        return _saleStages[saleStageIndex];
    }

    /**
     * @dev Returns the length of configured batches
     * @return current `_batches` array length.
     */
    function batchesLength() public view returns (uint256) {
        return _batches.length;
    }

    /**
     * @dev Returns all the batches
     * @return `_batches`.
     */
    function getBatches() public view returns (Batch[] memory) {
        return _batches;
    }

    /**
     * @dev Returns all sale stages
     * @return `_saleStages`.
     */
    function getSaleStages() public view returns (SaleStage[] memory) {
        return _saleStages;
    }

    /**
     * @dev Returns the batch by its index in the array
     * @param batchIndex batch index
     * @return Batch info
     * Note: batch ids can change over time and reorder as the result of batch removal
     */
    function getBatch(uint256 batchIndex) public view returns (Batch memory) {
        require(_batches.length > 0, "getBatch: no batches");
        require(batchIndex < _batches.length, "Id must be < batch length");

        return _batches[batchIndex];
    }

    /**
     * @dev Return batch by given tokenId
     * @param tokenId token id
     * @return batch structure
     */
    function getBatchByToken(uint256 tokenId) public view returns (Batch memory) {
        require(_batches.length > 0, "getBatchByToken: no batches");

        for (uint256 i; i < _batches.length; i++) {
            if (tokenId > _batches[i].endBatchTokenId || tokenId < _batches[i].startBatchTokenId) {
                continue;
            } else {
                return _batches[i];
            }
        }
        revert("batch doesn't exist");
    }

    /**
     * @dev IPFS address that stores JSON with token attributes
     * Tries to find it by batch first. If token has no batch, returns defaultUri.
     * @param tokenId id of the token
     * @return string with ipfs address to json with token attribute
     * or URI for default token if token doesn`t exist
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_batches.length > 0, "tokenURI: no batches");

        for (uint256 i; i < _batches.length; i++) {
            if (tokenId > _batches[i].endBatchTokenId || tokenId < _batches[i].startBatchTokenId) {
                continue;
            } else {
                return string(abi.encodePacked(_batches[i].baseURI, "/", tokenId.toString(), ".json"));
            }
        }
        return _defaultUri;
    }

    /**
     * @notice Creates the new batch for given token range
     * @param startTokenId index of the first batch token
     * @param endTokenId index of the last batch token
     * @param baseURI ipfs batch URI
     * @param rarity batch rarity
     * Note: batch ids can change over time and reorder as the result of batch removal
     */
    function addBatch(
        uint256 startTokenId,
        uint256 endTokenId,
        string memory baseURI,
        uint256 rarity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _batchesLength = _batches.length;

        require(startTokenId <= endTokenId, "startId must be <= than EndId");
        if (_batchesLength > 0) {
            for (uint256 i; i < _batchesLength; i++) {
                // if both bounds are lower or higher than iter batch
                if (
                    (startTokenId < _batches[i].startBatchTokenId && endTokenId < _batches[i].startBatchTokenId) ||
                    (startTokenId > _batches[i].endBatchTokenId && endTokenId > _batches[i].endBatchTokenId)
                ) {
                    continue;
                } else {
                    revert("batches intersect");
                }
            }
        }

        _batches.push(Batch(startTokenId, endTokenId, baseURI, rarity));
    }

    /**
     * @notice Update existing batch by its index
     * @param batchIndex the index of the batch to be changed
     * @param batchStartId index of the first batch token
     * @param batchEndId index of the last batch token
     * @param baseURI ipfs batch URI
     * @param rarity batch rarity
     * Note: batch ids can change over time and reorder as the result of batch removal
     */
    function setBatch(
        uint256 batchIndex,
        uint256 batchStartId,
        uint256 batchEndId,
        string memory baseURI,
        uint256 rarity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _batchesLength = _batches.length;
        require(_batchesLength > 0, "setBatch: batches is empty");
        require(batchStartId <= batchEndId, "startId must be <= than EndId");

        for (uint256 i; i < _batchesLength; i++) {
            if (i == batchIndex) {
                continue;
            } else {
                // if both bounds are lower or higher than iter batch
                if (
                    (batchStartId < _batches[i].startBatchTokenId && batchEndId < _batches[i].startBatchTokenId) ||
                    (batchStartId > _batches[i].endBatchTokenId && batchEndId > _batches[i].endBatchTokenId)
                ) {
                    continue;
                } else {
                    revert("batches intersect");
                }
            }
        }

        _batches[batchIndex].startBatchTokenId = batchStartId;
        _batches[batchIndex].endBatchTokenId = batchEndId;
        _batches[batchIndex].baseURI = baseURI;
        _batches[batchIndex].rarity = rarity;
    }

    /**
     * @notice Deletes batch by its id. This reorders the index of the token that was last.
     * @param batchIndex the index of the batch to be deteted
     */
    function deleteBatch(uint256 batchIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_batches.length > batchIndex, "index out of batches length");
        _batches[batchIndex] = _batches[_batches.length - 1];
        _batches.pop();
    }

    /**
     * @notice Add sale stage (i.e. tokensale schedule)
     * It takes place at the end of `saleStages array`
     * @param startTokensBought index of the first batch token
     * @param endTokensBought index of the last batch token
     * @param weiPerToken price for token
     */
    function addSaleStage(
        uint256 startTokensBought,
        uint256 endTokensBought,
        uint256 weiPerToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(startTokensBought <= endTokensBought, "startTokensBought must be <= than endTokensBought");
        require(weiPerToken > 0, "weiPerToken must be non-zero");
        uint256 _saleStagesLength = _saleStages.length;

        if (_saleStagesLength > 0) {
            for (uint256 i; i < _saleStagesLength; i++) {
                // if both bounds are lower or higher than iter sale stage
                if (
                    (startTokensBought < _saleStages[i].startTokensBought &&
                        endTokensBought < _saleStages[i].startTokensBought) ||
                    (startTokensBought > _saleStages[i].endTokensBought &&
                        endTokensBought > _saleStages[i].endTokensBought)
                ) {
                    continue;
                } else {
                    revert("intersection _saleStages");
                }
            }
        }

        _saleStages.push(SaleStage(startTokensBought, endTokensBought, weiPerToken));
        _maxTotalSupply += endTokensBought - startTokensBought + 1;
    }

    /**
     * @notice Update (rewrite) saleStage properties by index
     * @param saleStageId index of the first sale stage token
     * @param startTokensBought index of the first batch token
     * @param endTokensBought index of the last batch token
     * @param weiPerToken price for token
     */
    function setSaleStage(
        uint256 saleStageId,
        uint256 startTokensBought,
        uint256 endTokensBought,
        uint256 weiPerToken
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _saleStagesLength = _saleStages.length;
        require(_saleStagesLength > 0, "batches is empty");
        require(startTokensBought <= endTokensBought, "startId must be <= than EndId");
        for (uint256 i; i < _saleStagesLength; i++) {
            if (i == saleStageId) {
                continue;
            } else {
                // if both bounds are lower or higher than iter sale stage
                if (
                    (startTokensBought < _saleStages[i].startTokensBought &&
                        endTokensBought < _saleStages[i].startTokensBought) ||
                    (startTokensBought > _saleStages[i].endTokensBought &&
                        endTokensBought > _saleStages[i].endTokensBought)
                ) {
                    continue;
                } else {
                    revert("intersection _saleStages");
                }
            }
        }
        SaleStage memory _saleStage = _saleStages[saleStageId];
        _maxTotalSupply =
            _maxTotalSupply -
            (_saleStage.endTokensBought - _saleStage.startTokensBought + 1) +
            (endTokensBought - startTokensBought + 1);

        _saleStages[saleStageId].startTokensBought = startTokensBought;
        _saleStages[saleStageId].endTokensBought = endTokensBought;
        _saleStages[saleStageId].weiPerToken = weiPerToken;
    }

    /**
     * @dev Delete sale stage by the given given index
     * @param saleStageIndex index of the batch to be deleted
     */
    function deleteSaleStage(uint256 saleStageIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_saleStages.length > saleStageIndex, "index out of sale stage length");
        SaleStage memory _saleStage = _saleStages[saleStageIndex];
        _maxTotalSupply -= _saleStage.endTokensBought - _saleStage.startTokensBought + 1;

        _saleStages[saleStageIndex] = _saleStages[_saleStages.length - 1];
        _saleStages.pop();
    }

    /**
     * @dev Calculates the total price for the given number of tokens
     * @param tokens number of tokens to be purchased
     * @return summary price
     */
    function getTotalPriceFor(uint256 tokens) public view returns (uint256) {
        require(tokens > 0, "tokens must be more then 0");

        uint256 _saleStagesLength = _saleStages.length;
        uint256 totalSupply = totalSupply();
        uint256 iterPrice = 0;
        uint256 totalPrice = 0;

        SaleStage memory saleStage;
        for (uint256 tokenIndex = 0; tokenIndex < tokens; tokenIndex++) {
            iterPrice = 0;
            for (uint256 i = 0; i < _saleStagesLength; i++) {
                saleStage = _saleStages[i];
                if (totalSupply > saleStage.endTokensBought || totalSupply < saleStage.startTokensBought) continue;
                iterPrice += saleStage.weiPerToken;
            }
            if (iterPrice == 0) {
                revert("saleStage doesn't exist");
            }
            totalPrice += iterPrice;
            totalSupply += 1;
        }
        return totalPrice;
    }

    /**
     * @dev Method to randomly mint desired number of NFTs
     * @param to the address where you want to transfer tokens
     * @param nfts the number of tokens to be minted
     */
    function _mintMultiple(address to, uint256 nfts) internal {
        require(totalSupply() < _maxTotalSupply, "Sale has already ended");
        require(nfts > 0, "nfts cannot be 0");
        require(totalSupply().add(nfts) <= _maxTotalSupply, "Exceeds _maxTotalSupply");

        for (uint256 i = 0; i < nfts; i++) {
            uint256 mintIndex = _getRandomAvailableIndex();
            _safeMint(to, mintIndex);
        }
    }

    /**
     * @dev Mints a specific token (with known id) to the given address
     * @param to the receiver
     * @param mintIndex the tokenId to mint
     */
    function mint(address to, uint256 mintIndex) public onlyRole(MINTER_ROLE) {
        _safeMint(to, mintIndex);
    }

    /**
     * @dev Public method to randomly mint desired number of NFTs
     * @param to the receiver
     * @param nfts the number of tokens to be minted
     */
    function mintMultiple(address to, uint256 nfts) public onlyRole(MINTER_ROLE) {
        _mintMultiple(to, nfts);
    }

    /**
     * @dev Method to purchase and random available NFTs.
     * @param nfts the number of tokens to buy
     * @param referral the address of referral who invited the user to the platform
     */
    function buy(uint256 nfts, address referral) public payable {
        require(saleActive, "Sale is not active");
        require(nfts <= maxPurchaseSize, "Can not buy > maxPurchaseSize");
        require(getTotalPriceFor(nfts) == msg.value, "Ether value sent is not correct");
        emit Buy(msg.sender, nfts, referral);
        vault.transfer(msg.value);
        _mintMultiple(msg.sender, nfts);
    }

    /**
     * @dev Returns the (pseudo-)random token index free of owner.
     * @return available token index
     */
    function _getRandomAvailableIndex() internal view returns (uint256) {
        uint256 index = (uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, /* solhint-disable not-rely-on-time */
                    gasleft(),
                    blockhash(block.number - 1)
                )
            )
        ) % _maxTotalSupply);
        while (_exists(index)) {
            index += 1;
            if (index >= _maxTotalSupply) {
                index = 0;
            }
        }
        return index;
    }

    /**
     * @dev Returns rarity of the NFT by token Id
     * @param tokenId id of the token
     * @return rarity
     */
    function getRarity(uint256 tokenId) public view returns (uint256) {
        require(_batches.length > 0, "getBatchByToken: no batches");

        for (uint256 i; i < _batches.length; i++) {
            if (tokenId > _batches[i].endBatchTokenId || tokenId < _batches[i].startBatchTokenId) {
                continue;
            } else {
                return _batches[i].rarity;
            }
        }
        return _defaultRarity;
    }

    /**
     * @dev Returns name of the NFT at index
     * @param index token id
     * @return NFT name
     */
    function getName(uint256 index) public view returns (string memory) {
        require(index < _maxTotalSupply, "index < _maxTotalSupply");
        bytes memory _tokenWeight = bytes(_tokenName[index]);
        if (_tokenWeight.length == 0) {
            return _defaultName;
        }
        return _tokenName[index];
    }

    /**
     * @dev Returns skill of the NFT at index
     * @param index token id
     * @return NFT skill
     */
    function getSkill(uint256 index) public view returns (uint256) {
        require(index < _maxTotalSupply, "index < _maxTotalSupply");
        if (_tokenSkill[index] == 0) {
            return _defaultSkill;
        }
        return _tokenSkill[index];
    }

    /**
     * @dev Returns individual DNA of the NFT at index
     * @param index token id
     * @return NFT DNA
     */
    function getDna(uint256 index) public view returns (uint256) {
        require(index < _maxTotalSupply, "index < _maxTotalSupply");
        return _tokenDna[index];
    }

    /**
     * @dev Start tokensale process
     */
    function start() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(_defaultUri).length > 0, "_defaultUri is undefined");
        require(vault != address(0), "Vault is undefined");
        saleActive = true;
    }

    /**
     * @dev Stop tokensale
     */
    function stop() public onlyRole(DEFAULT_ADMIN_ROLE) {
        saleActive = false;
    }

    /**
     * @dev Set or change individual token name
     */
    function setName(uint256 index, string memory newName) public onlyRole(NAME_SETTER_ROLE) {
        require(index < _maxTotalSupply, "index < _maxTotalSupply");
        _tokenName[index] = newName;
        emit NameChange(index, newName);
    }

    /**
     * @dev Set or change individual token skill
     */
    function setSkill(uint256 index, uint256 newSkill) public onlyRole(SKILL_SETTER_ROLE) {
        require(index < _maxTotalSupply, "index < _maxTotalSupply");
        _tokenSkill[index] = newSkill;
        emit SkillChange(index, newSkill);
    }

    /**
     * @dev Set or change individual token DNA
     */
    function setDna(uint256 index, uint256 newDna) public onlyRole(DNA_SETTER_ROLE) {
        require(index < _maxTotalSupply, "index < _maxTotalSupply");
        _tokenDna[index] = newDna;
        emit DnaChange(index, newDna);
    }

    /**
     * @dev Set max purchase size (to avoid gas overspending)
     */
    function setMaxPurchaseSize(uint256 newPurchaseSize) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPurchaseSize = newPurchaseSize;
    }

    /**
     * @dev Set defaultUri
     */
    function setDefaultUri(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _defaultUri = uri;
    }

    /**
     * @dev Set vault
     * @param newVault address to receive ethers
     */
    function setVault(address payable newVault) public onlyRole(DEFAULT_ADMIN_ROLE) {
        vault = newVault;
    }

    /**
     * @dev Set defaultRarity
     * @param rarity new default rarity
     */
    function setDefaultRarity(uint256 rarity) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _defaultRarity = rarity;
    }

    /**
     * @dev Set default name.
     * @param name new default name
     */
    function setDefaultName(string memory name) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _defaultName = name;
    }

    /**
     * @dev Set default skill.
     * @param skill new default name
     */
    function setDefaultSkill(uint256 skill) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _defaultSkill = skill;
    }
}
