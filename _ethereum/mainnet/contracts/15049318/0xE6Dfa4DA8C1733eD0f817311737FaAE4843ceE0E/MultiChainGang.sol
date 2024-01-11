// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Operatorable.sol";

contract MultiChainGang is ERC721URIStorage, Operatorable, ReentrancyGuard {
    using SafeMath for uint256;

    //Last stake token id, start from 1
    uint256 public tokenIds;

    //Number of items in q, start from 1, add 1 when new item in q, subtract when popped from q
    uint256 public queueIds;

    //NFT Base URI
    string public baseURI;

    //NFT Collection Description
    string public collectionDescription;

    //cap on # of nfts in collection
    uint256 public _cap;

    //info about tokenId stored in contract
    struct NFTInfo {
        string[] badges;
        bool upgraded;
        string upgradeRank;
        uint256 upgradeCount;
    }

    //info about an upgrade in queue i.e. before tokenuri gets set
    struct UpgradeInQ {
        uint256 _tokenID_;
        string[] inputBadges;
        string upgradeType;
        string upgradeRank;
        bool isDeleted;
    }

    //Collection wallet => nft id
    mapping(address => uint256[]) public collectionIds;

    //info for a given tokenId
    mapping(uint256 => NFTInfo) public tokenInfo;

    //info about an upgrade by its id - get count and then call this for each up to the num in queueIds
    mapping(uint256 => UpgradeInQ) public upgradesInQ;

    event NFTCreated(uint256 indexed nftId, address indexed account);
    event NFTUpgraded(
        uint256 indexed previousTokenId,
        uint256 indexed newTokenId,
        uint256 offChainTokenId,
        string offChainChainName,
        string[] _badges,
        string _upgradeRank,
        uint256 _upgradeCount,
        string _upgradeType,
        address indexed mintToAddress
    );

    constructor(
        string memory collectionName,
        string memory collectionSymbol,
        string memory collectionBaseURI,
        uint256 cap
    ) ERC721(collectionName, collectionSymbol) {
        require(
            cap > 0,
            "StandardCappedNFTCollection#constructor: CAP_MUST_BE_GREATER_THAN_0"
        );
        baseURI = collectionBaseURI;
        _cap = cap;
    }

    /**
     * @dev Override supportInterface.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Get collection token id array owned by wallet address.
     * @param account address
     */
    function getCollectionIds(address account)
        public
        view
        returns (uint256[] memory)
    {
        return collectionIds[account];
    }

    /**********************|
    |          URI         |
    |_____________________*/

    /**
     * @dev Set token URI
     * Only `operator` can call
     *
     * - `tokenId` must exist, see {ERC721URIStorage:_setTokenURI}
     */
    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI,
        uint256 qId
    ) public onlyOperator {
        UpgradeInQ storage tokenQueueItem = upgradesInQ[qId];

        //create a check here that the tokenId is in the queue as an upgrade, otherwise it fails
        require(
            upgradesInQ[qId]._tokenID_ == tokenId,
            "MultiChainGang: NOT_VALID_UPGRADE"
        );
        require(
            !(tokenQueueItem.isDeleted),
            "MultiChainGang: ALREADY_UPGRADED"
        );
        super._setTokenURI(tokenId, _tokenURI);
        //after setting the tokenUri, then set isDeleted to true
        tokenQueueItem.isDeleted = true;
    }

    /**
     * @dev Set `baseURI`
     * Only `operator` can call
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Return base URI
     * Override {ERC721:_baseURI}
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**********************|
    |          Description |
    |_____________________*/

    function addDescription(string memory description) public onlyOperator {
        collectionDescription = description;
    }

    /**********************|
    |          MINT        |
    |_____________________*/

    /**
     * @dev Mint a new token.
     * @param recipient address
     */
    function mintNFT(
        address recipient,
        string memory _tokenURI,
        string[] memory _badges,
        uint256 _upgradeCount,
        string memory _upgradeRank
    ) public onlyOperator returns (uint256) {
        tokenIds++;

        NFTInfo storage theTokenIdInfo = tokenInfo[tokenIds];
        theTokenIdInfo.badges = _badges;
        theTokenIdInfo.upgraded = false;
        theTokenIdInfo.upgradeRank = _upgradeRank;
        theTokenIdInfo.upgradeCount = _upgradeCount;

        _mint(recipient, tokenIds);
        super._setTokenURI(tokenIds, _tokenURI);
        return tokenIds;
    }

    function upgradeNFT(
        uint256 onChainTokenId,
        uint256 offChainTokenId,
        string memory offChainChainName,
        string[] memory _badges,
        string memory _upgradeRank,
        uint256 _upgradeCount,
        string memory _upgradeType,
        address mintToAddress
    ) public onlyOperator {
        tokenIds++;

        NFTInfo storage onChainTokenInfo = tokenInfo[onChainTokenId];
        NFTInfo storage tokenIdInfo = tokenInfo[tokenIds];
        require(
            onChainTokenInfo.upgradeCount > 0,
            "MultiChainGang: NOT_AVAILABLE_UPGRADE"
        );

        //add info to NFTInfo: upgraded to true, upgradeRank and badges and reducing upgradeCount by 1 i.e. available upgrades count
        tokenIdInfo.badges = _badges;
        tokenIdInfo.upgraded = true;
        tokenIdInfo.upgradeRank = _upgradeRank;
        tokenIdInfo.upgradeCount = _upgradeCount;

        //reduce upgradeCount on the onChainTokenId used as input by 1
        onChainTokenInfo.upgradeCount = onChainTokenInfo.upgradeCount - 1;

        //add tokenId and info to upgradeQueue
        queueIds++;
        UpgradeInQ storage tokenQueue = upgradesInQ[queueIds];
        tokenQueue._tokenID_ = tokenIds;
        tokenQueue.inputBadges = _badges;
        tokenQueue.upgradeType = _upgradeType;
        tokenQueue.upgradeRank = _upgradeRank;
        tokenQueue.isDeleted = false;

        //mint the token without setting the tokenURI
        _mint(mintToAddress, tokenIds);

        emit NFTUpgraded(
            onChainTokenId,
            tokenIds,
            offChainTokenId,
            offChainChainName,
            _badges,
            _upgradeRank,
            _upgradeCount,
            _upgradeType,
            mintToAddress
        );
    }

    /**
     * @dev Check if wallet address owns any nfts in the collection.
     * @param account address
     */
    function isHolder(address account) public view returns (bool) {
        return balanceOf(account) > 0;
    }

    /**
     * @dev Remove the given token from collectionIds.
     *
     * @param from address from
     * @param tokenId tokenId to remove
     */
    function _popId(address from, uint256 tokenId) internal {
        uint256[] storage _collectionIds = collectionIds[from];
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            if (_collectionIds[i] == tokenId) {
                if (i != _collectionIds.length - 1) {
                    _collectionIds[i] = _collectionIds[
                        _collectionIds.length - 1
                    ];
                }
                _collectionIds.pop();
                break;
            }
        }
    }

    /**
     * @dev Mint a new NFT in the Collection.
     * Requirements:
     *
     * - `account` must not be zero address, check ERC721 {_mint}
     * @param account address of recipient.
     */
    function _mint(address account, uint256 tokenId) internal virtual override {
        require(
            tokenId <= _cap,
            "StandardCappedNFTCollection#_mint: CANNOT_EXCEED_MINTING_CAP"
        );
        super._mint(account, tokenId);
        collectionIds[account].push(tokenId);
        emit NFTCreated(tokenId, account);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * @param from address from
     * @param to address to
     * @param tokenId tokenId to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(
            to != address(0),
            "CommunityNFT#_transfer: TRANSFER_TO_THE_ZERO_ADDRESS"
        );
        super._transfer(from, to, tokenId);
        _popId(from, tokenId);
        collectionIds[to].push(tokenId);
    }
}
