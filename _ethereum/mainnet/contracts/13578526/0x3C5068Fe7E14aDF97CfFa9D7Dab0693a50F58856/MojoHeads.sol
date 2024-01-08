//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./ERC721URIStorage.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

import "./Counters.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

import "./IAccessPass.sol";


contract MojoHeads is ERC721URIStorage, AccessControl, IERC2981, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    Counters.Counter private campaignCounter;

    Counters.Counter private artistTokensCounter;

    enum CampaignState {PENDING, READY, PRESALE, ONGOING, PAUSED, FINISH}

    struct NftHash {
        bytes32 hash;
        bool sold;
    }

    //TODO tokenURI pre reveal in backend (ipfs folder)
    //TODO mintArtistToken batch also in backend
    struct Campaign {
        CampaignState state;
        address accessPassAddress;
        uint256 preSalePassId;
        uint256 vipSalePassId;
        string defaultUri;
        bool mintFromArtistEnabled;
        uint256 totalHashCount;
        uint256 freeHashCount;
        uint256 maxPresaleTokens;
        uint256 maxOngoingTokens;
    }

    struct CampaignPrice {
        uint256 unitPricePresale;
        uint256 unitPriceVipSale;
        uint256 unitPriceStartPublicSale;
        uint256 unitPriceEndPublicSale;
        uint256 totalBlockUntilUnitPriceEnd;
        uint256 publicSaleStartBlock;
    }

    struct CampaignPriceInput {
        uint256 unitPricePresale;
        uint256 unitPriceVipSale;
        uint256 unitPriceStartPublicSale;
        uint256 unitPriceEndPublicSale;
        uint256 totalBlockUntilUnitPriceEnd;
    }

    mapping(uint256 => NftHash[]) hashListMapping;

    event CampaignRegisteredEvent(
        uint256 indexed campaignId,
        string defaultUri
    );

    event CampaignUpdatedEvent(
        uint256 indexed campaignId,
        string defaultUri
    );

    event CampaignStateChangedEvent(
        uint256 indexed campaignId,
        CampaignState state
    );

    event CampaignNewHashAddedEvent(
        uint256 indexed campaignId
    );

    event WithdrawEth(
        uint256 indexed amount,
        address indexed receiver
    );

    event WithdrawERC20(
        address indexed token,
        uint256 indexed amount,
        address indexed receiver
    );


    mapping(uint256 => mapping(uint256 => uint256)) campaignArtistFreeTokenMapping;
    mapping(uint256 => Campaign) public campaignList;
    mapping(uint256 => CampaignPrice) public campaignPriceList;
    mapping(uint256 => bytes32) public tokenHashMapping;
    mapping(bytes32 => uint256) public hashTokenMapping;
    mapping(uint256 => uint256) public tokenToArtistMapping;
    mapping(uint256 => address) public tokenRoyaltyMapping;

    mapping(uint256 => bool) public tokenRevealMapping;

    address public defaultRoyaltyAddress;
    uint256 public royaltyPercentage;
    uint256 public artistTokenReserve;

    bytes32 public constant CAMPAIGN_ADMIN_ROLE = keccak256("CAMPAIGN_ADMIN");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW");

    constructor(string memory name_, string memory symbol_, uint256 artistTokenReserve_, uint256 royaltyPercentage_, address defaultRoyaltyAddress_) ERC721(name_, symbol_) {
        require(royaltyPercentage_ <= 10000, "royaltyPercentage_ must be lte 10000.");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CAMPAIGN_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(WITHDRAW_ROLE, DEFAULT_ADMIN_ROLE);
        artistTokenReserve = artistTokenReserve_;
        royaltyPercentage = royaltyPercentage_;
        defaultRoyaltyAddress = defaultRoyaltyAddress_;
    }

    function register(address accessPassAddress,
        uint256 preSalePassId,
        uint256 vipSalePassId,
        CampaignPriceInput memory campaignPriceInput,
        string memory defaultUri,
        uint256 maxPresaleTokens,
        uint256 maxOngoingTokens,
        bool mintFromArtistEnabled) public onlyRole(CAMPAIGN_ADMIN_ROLE) returns (uint256) {

        campaignCounter.increment();
        uint256 campaignId = campaignCounter.current();
        campaignList[campaignId].state = CampaignState.PENDING;
        campaignList[campaignId].accessPassAddress = accessPassAddress;
        campaignList[campaignId].preSalePassId = preSalePassId;
        campaignList[campaignId].vipSalePassId = vipSalePassId;
        campaignList[campaignId].mintFromArtistEnabled = mintFromArtistEnabled;

        campaignList[campaignId].maxPresaleTokens = maxPresaleTokens;
        campaignList[campaignId].maxOngoingTokens = maxOngoingTokens;

        campaignPriceList[campaignId].unitPricePresale = campaignPriceInput.unitPricePresale;
        campaignPriceList[campaignId].unitPriceVipSale = campaignPriceInput.unitPriceVipSale;
        campaignPriceList[campaignId].unitPriceStartPublicSale = campaignPriceInput.unitPriceStartPublicSale;
        campaignPriceList[campaignId].unitPriceEndPublicSale = campaignPriceInput.unitPriceEndPublicSale;
        campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd = campaignPriceInput.totalBlockUntilUnitPriceEnd;

        campaignList[campaignId].totalHashCount = 0;
        campaignList[campaignId].freeHashCount = 0;
        campaignList[campaignId].defaultUri = defaultUri;


        emit CampaignRegisteredEvent(
            campaignId,
            defaultUri
        );

        return campaignId;

    }

    function finishCampaign(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.PAUSED || campaignList[campaignId].state == CampaignState.ONGOING, "Campaign should be started.");

        campaignList[campaignId].state = CampaignState.FINISH;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.FINISH
        );
    }

    function setCampaignReady(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.PENDING, "Campaign should be pending.");

        campaignList[campaignId].state = CampaignState.READY;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.READY
        );
    }


    function startPresale(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.READY
        || campaignList[campaignId].state == CampaignState.ONGOING
            || campaignList[campaignId].state == CampaignState.PAUSED, "Campaign should be READY, PAUSED or ONGOING.");

        campaignList[campaignId].state = CampaignState.PRESALE;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.PRESALE
        );
    }

    function startCampaign(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.READY
        || campaignList[campaignId].state == CampaignState.PAUSED
            || campaignList[campaignId].state == CampaignState.PRESALE, "Campaign should be READY or PAUSED.");

        campaignList[campaignId].state = CampaignState.ONGOING;
        campaignPriceList[campaignId].publicSaleStartBlock = block.number;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.ONGOING
        );
    }


    function pauseCampaign(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.ONGOING
            || campaignList[campaignId].state == CampaignState.PRESALE, "Campaign should be ONGOING.");

        campaignList[campaignId].state = CampaignState.PAUSED;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.PAUSED
        );
    }

    function update(uint256 campaignId, address accessPassAddress,
        uint256 preSalePassId,
        uint256 vipSalePassId,
        CampaignPriceInput memory campaignPriceInput,
        string memory defaultUri,
        uint256 maxPresaleTokens,
        uint256 maxOngoingTokens,
        bool mintFromArtistEnabled) public onlyRole(CAMPAIGN_ADMIN_ROLE) returns (uint256) {

        campaignList[campaignId].accessPassAddress = accessPassAddress;
        campaignList[campaignId].preSalePassId = preSalePassId;
        campaignList[campaignId].vipSalePassId = vipSalePassId;
        campaignList[campaignId].defaultUri = defaultUri;
        campaignList[campaignId].maxPresaleTokens = maxPresaleTokens;
        campaignList[campaignId].maxOngoingTokens = maxOngoingTokens;
        campaignList[campaignId].mintFromArtistEnabled = mintFromArtistEnabled;

        campaignPriceList[campaignId].unitPricePresale = campaignPriceInput.unitPricePresale;
        campaignPriceList[campaignId].unitPriceVipSale = campaignPriceInput.unitPriceVipSale;
        campaignPriceList[campaignId].unitPriceStartPublicSale = campaignPriceInput.unitPriceStartPublicSale;
        campaignPriceList[campaignId].unitPriceEndPublicSale = campaignPriceInput.unitPriceEndPublicSale;
        campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd = campaignPriceInput.totalBlockUntilUnitPriceEnd;


        emit CampaignUpdatedEvent(
            campaignId,
            defaultUri
        );

        return campaignId;

    }

    function addNewHash(uint256 campaignId, bytes32[] calldata hashList, uint256[] calldata artistTokenList) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.PENDING, "Can not add hash to Started campaign");
        require(hashList.length == artistTokenList.length, "hashList and artistTokenList must be in same length");

        campaignList[campaignId].totalHashCount += hashList.length;
        campaignList[campaignId].freeHashCount += hashList.length;

        for (uint i = 0; i < hashList.length; i++) {
            hashListMapping[campaignId].push(NftHash(hashList[i], false));
            tokenIdCounter.increment();
            uint256 tokenId = artistTokenReserve + tokenIdCounter.current();
            hashTokenMapping[hashList[i]] = tokenId;
            tokenHashMapping[tokenId] = hashList[i];
            tokenToArtistMapping[tokenId] = artistTokenList[i];
            campaignArtistFreeTokenMapping[campaignId][artistTokenList[i]] = campaignArtistFreeTokenMapping[campaignId][artistTokenList[i]] + 1;
        }

        emit CampaignNewHashAddedEvent(
            campaignId
        );
    }

    function mintFromArtist(uint256 campaignId, uint256 artistTokenId, address receiver) public payable {
        require(campaignList[campaignId].mintFromArtistEnabled, "Minting from an artist is not enabled for this campaign.");
        uint256 price = _checkCampaignStateForMinting(campaignId);
        require(msg.value >= price, "Insufficient funds.");
        require(_exists(artistTokenId), "Artist token is nonexistent.");

        _randomMintFromArtist(campaignId, artistTokenId, receiver);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function mint(uint256 campaignId, uint256 amount, address receiver) public payable {
        if (campaignList[campaignId].state == CampaignState.PRESALE) {
            require(amount <= campaignList[campaignId].maxPresaleTokens, "Can not mint more than allowed in presale.");
        } else {
            require(amount <= campaignList[campaignId].maxOngoingTokens, "Can not mint more than allowed.");
        }

        uint256 totalCost = 0;

        for (uint i; i < amount; i++) {
            uint256 price = _checkCampaignStateForMinting(campaignId);
            totalCost = totalCost + price;
            _randomMint(campaignId, receiver);
        }


        require(msg.value >= totalCost, "Insufficient funds.");

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function getOngoingPrice(uint256 campaignId) public view returns (uint256) {
        require(campaignList[campaignId].state == CampaignState.ONGOING, "Campaign is not started yet.");
        uint256 blockPasted = block.number - campaignPriceList[campaignId].publicSaleStartBlock;

        if (blockPasted > campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd) {
            blockPasted = campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd;
        }
        if (campaignPriceList[campaignId].unitPriceEndPublicSale > campaignPriceList[campaignId].unitPriceStartPublicSale) {
            return campaignPriceList[campaignId].unitPriceStartPublicSale + (campaignPriceList[campaignId].unitPriceEndPublicSale - campaignPriceList[campaignId].unitPriceStartPublicSale) / campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd * blockPasted;
        } else {
            return campaignPriceList[campaignId].unitPriceStartPublicSale - (campaignPriceList[campaignId].unitPriceStartPublicSale - campaignPriceList[campaignId].unitPriceEndPublicSale) / campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd * blockPasted;
        }
    }
    //TODO improve
    function _checkCampaignStateForMinting(uint256 campaignId) internal returns (uint256) {
        if (campaignList[campaignId].state == CampaignState.PRESALE) {
            IAccessPass accessPass = IAccessPass(campaignList[campaignId].accessPassAddress);
            if (accessPass.balanceOf(msg.sender, campaignList[campaignId].vipSalePassId) > 0) {
                accessPass.burn(msg.sender, campaignList[campaignId].vipSalePassId, 1);
                return campaignPriceList[campaignId].unitPriceVipSale;
            } else if (accessPass.balanceOf(msg.sender, campaignList[campaignId].preSalePassId) > 0) {
                accessPass.burn(msg.sender, campaignList[campaignId].preSalePassId, 1);
                return campaignPriceList[campaignId].unitPricePresale;
            } else {
                revert("No Access token.");
            }

        } else {
            return getOngoingPrice(campaignId);
        }
    }

    function preMint(uint256 campaignId, address receiver) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state != CampaignState.PENDING, "Campaign is not ready yet.");
        _randomMint(campaignId, receiver);
    }

    function preMintBatch(uint256 campaignId, address[] memory receiverList) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state != CampaignState.PENDING, "Campaign is not ready yet.");
        require(receiverList.length <= campaignList[campaignId].freeHashCount, "Campaign does not have enough hashes.");
        for (uint i = 0; i < receiverList.length; i++) {
            _randomMint(campaignId, receiverList[i]);
        }
    }

    function _randomMint(uint256 campaignId, address receiver) private {
        require(campaignList[campaignId].freeHashCount > 0, "All NFTs are sold.");
        uint256 random;
        if (campaignList[campaignId].freeHashCount > 1) {
            random = uint256(keccak256(abi.encodePacked(campaignList[campaignId].freeHashCount, blockhash(block.number), block.difficulty))) % campaignList[campaignId].freeHashCount;
        } else {
            random = 0;
        }

        uint256 foundAt = 0;
        uint256 unsoldCounter = 0;

        for (uint i = 0; i < campaignList[campaignId].totalHashCount; i++) {
            if (!hashListMapping[campaignId][i].sold) {
                if (unsoldCounter == random) {
                    foundAt = i;
                    break;
                }
                unsoldCounter += 1;
            }

        }

        hashListMapping[campaignId][foundAt].sold = true;
        campaignList[campaignId].freeHashCount -= 1;
        uint256 tokenId = hashTokenMapping[hashListMapping[campaignId][foundAt].hash];
        _mint(receiver, tokenId);

        _setTokenURI(tokenId, campaignList[campaignId].defaultUri);

    }

    function _randomMintFromArtist(uint256 campaignId, uint256 artistTokenId, address receiver) private {
        require(campaignArtistFreeTokenMapping[campaignId][artistTokenId] > 0, "All ntfs are sold for artist.");
        uint256 random;
        if (campaignArtistFreeTokenMapping[campaignId][artistTokenId] > 1) {
            random = uint256(keccak256(abi.encodePacked(campaignArtistFreeTokenMapping[campaignId][artistTokenId], blockhash(block.number), block.difficulty))) % campaignArtistFreeTokenMapping[campaignId][artistTokenId];
        } else {
            random = 0;
        }

        uint256 foundAt = 0;
        uint256 unsoldCounter = 0;

        for (uint i = 0; i < campaignList[campaignId].totalHashCount; i++) {
            if (!hashListMapping[campaignId][i].sold
            && artistTokenId == tokenToArtistMapping[hashTokenMapping[hashListMapping[campaignId][i].hash]]) {
                if (unsoldCounter == random) {
                    foundAt = i;
                    break;
                }
                unsoldCounter += 1;
            }

        }
        require(!hashListMapping[campaignId][foundAt].sold
        && artistTokenId == tokenToArtistMapping[hashTokenMapping[hashListMapping[campaignId][foundAt].hash]], "Token must be found.");

        campaignArtistFreeTokenMapping[campaignId][artistTokenId] = campaignArtistFreeTokenMapping[campaignId][artistTokenId] - 1;

        hashListMapping[campaignId][foundAt].sold = true;
        campaignList[campaignId].freeHashCount -= 1;
        uint256 tokenId = hashTokenMapping[hashListMapping[campaignId][foundAt].hash];
        _mint(receiver, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(campaignList[campaignId].defaultUri, tokenId)));

    }


    function mintArtistToken(address to, string calldata uri) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        artistTokensCounter.increment();
        uint256 tokenId = artistTokensCounter.current();
        require(tokenId <= artistTokenReserve, "Artist token id reserves finished.");
        _mint(to, tokenId);
        tokenRoyaltyMapping[tokenId] = defaultRoyaltyAddress;
        _setTokenURI(tokenId, uri);

    }

    //TODO ERC20

    function withdrawERC20(address token, uint256 amount, address payable receiver) external onlyRole(WITHDRAW_ROLE) {
        IERC20(token).transfer(receiver, amount);
        emit WithdrawERC20(token, amount, receiver);
    }

    function withdrawEth(uint256 amount, address payable receiver) external onlyRole(WITHDRAW_ROLE) {
        receiver.transfer(amount);
        emit WithdrawEth(amount, receiver);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, IERC165) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
        || interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC2981).interfaceId
        || interfaceId == type(ERC721URIStorage).interfaceId;
    }

    function campaignCount() public view returns (uint256) {
        return campaignCounter.current();
    }

    function getCampaign(uint256 id) public view returns (Campaign memory) {
        return campaignList[id];
    }

    function getCampaignPrice(uint256 id) public view returns (CampaignPrice memory) {
        return campaignPriceList[id];
    }


    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        uint256 artistTokenId = tokenToArtistMapping[tokenId];
        address royaltyAddress = tokenRoyaltyMapping[artistTokenId];
        if (royaltyAddress == address(0)) {
            return (address(0), 0);
        }
        uint256 royaltyAmount = salePrice * royaltyPercentage / 10000;
        return (royaltyAddress, royaltyAmount);
    }

    //TODO USE default royalty address if not set.
    function setTokenRoyaltyAddress(uint256 tokenId, address royaltyAddress) external onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(_exists(tokenId), "Token must be exist to set royalty info.");
        tokenRoyaltyMapping[tokenId] = royaltyAddress;
    }

    function revealToken(uint256 tokenId, string calldata tokenUri) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(_exists(tokenId), "URI set of nonexistent token");
        tokenRevealMapping[tokenId] = true;
        _setTokenURI(tokenId, tokenUri);
    }

    function batchRevealToken(uint256[] calldata tokenIds, string[] calldata tokenUris) external onlyRole(CAMPAIGN_ADMIN_ROLE) {
        for (uint256 i; i < tokenIds.length; i ++) {
            revealToken(tokenIds[i], tokenUris[i]);
        }
    }

    function getCampaignHash(uint256 campaignId, uint256 hashIndex) external view returns (bytes32, bool) {
        return (hashListMapping[campaignId][hashIndex].hash, hashListMapping[campaignId][hashIndex].sold);
    }

    function getMaxTokenIndex() external view returns (uint256) {
        return tokenIdCounter.current();
    }

    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyRole(CAMPAIGN_ADMIN_ROLE) {
        royaltyPercentage = _royaltyPercentage;
    }

}
