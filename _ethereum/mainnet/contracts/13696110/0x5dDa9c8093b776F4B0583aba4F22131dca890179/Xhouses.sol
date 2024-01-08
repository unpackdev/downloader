// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./VRFConsumerBase.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract XHouses is
    ERC721,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBase,
    PaymentSplitter
{
    using Strings for uint256;

    uint256 public SEASON_COUNT = 0;
    uint256 totalPublicMinted = 0;

    struct Season {
        uint256 season_number;
        uint256 price;
        uint256 unit_count; // @dev total supply
        uint256 walletLimit; // @dev per wallet mint limit
        uint256 tokenOffset; // @dev each season has a unique offset
        string provenanceHash;
        string uri;
        bool paused;
        bool publicOpen;
        bool revealed;
    }

    struct WalletCount {
        mapping(uint256 => uint256) season_mints;
    }

    // address => season mapping
    mapping(uint256 => Season) public seasons;
    mapping(uint256 => uint256) public season_offsets;
    mapping(uint256 => uint256) public season_minted;
    mapping(address => WalletCount) internal season_wallet_mints;

    mapping(uint256 => bool) seasonPresale;
    mapping(address => uint256[]) public presaleList;

    mapping(bytes32 => uint256) internal season_randIDs;

    address[] internal payees;

    // LINK
    uint256 internal LINK_FEE;
    bytes32 internal LINK_KEY_HASH;

    constructor(
        bytes32 _keyHash,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _linkFee,
        address[] memory _payees,
        uint256[] memory _shares
    )
        payable
        ERC721("X Houses", "XHS")
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        PaymentSplitter(_payees, _shares)
    {
        payees = _payees;

        LINK_KEY_HASH = _keyHash;
        LINK_FEE = _linkFee;
    }

    // @dev convinence function for returning the offset token ID
    function xhouseID(uint256 _id) public view returns (uint256 houseID) {
        for (uint256 i = 1; i <= SEASON_COUNT; i++) {
            if (_id < seasons[i].unit_count) {
                return (_id + seasons[i].tokenOffset) % seasons[i].unit_count;
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');

        // @dev Return the base URI with the tokenId and .json extension if isRevealed
        // otherwise return just the baseTokenURI
        // find which seasons
        // tokenId <= season limit
        uint256 _season;
        for (uint256 i = 0; i <= SEASON_COUNT; i++) {
            if (tokenId <= season_offsets[i]) {
                _season = i;
                break;
            }
        }

        return
            seasons[_season].revealed
                ? string(
                    abi.encodePacked(seasons[_season].uri, tokenId.toString())
                )
                : seasons[_season].uri;
    }

    function presalePurchase(uint256 _season, uint256 _quantity)
        public
        payable
        nonReentrant
    {
        require(!seasons[_season].paused, "Season minting is Paused");
        require(
            onPresaleList(_season, msg.sender) == true,
            "Wallet not on the presale list"
        );
        _mint(_season, _quantity);
    }

    function purchase(uint256 _season, uint256 _quantity)
        public
        payable
        nonReentrant
    {
        require(!seasons[_season].paused, "Season minting is Paused");
        require(seasons[_season].publicOpen, "Public sales are closed");

        require(
            seasons[_season].season_number == _season,
            "Season does not exist"
        );

        _mint(_season, _quantity);
    }

    function _mint(uint256 _season, uint256 _quantity) internal {
        require(
            _quantity * seasons[_season].price <= msg.value,
            "Not enough minerals"
        );
        require(
            season_wallet_mints[msg.sender].season_mints[_season] <
                seasons[_season].walletLimit,
            "Wallet has minted maximum allowed"
        );
        require(
            season_minted[_season] + _quantity <= seasons[_season].unit_count,
            "not enough tokens in available supply"
        );
        // mint and increment once for each number;
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenID = season_offsets[_season - 1] +
                season_minted[_season] +
                1;
            _safeMint(msg.sender, tokenID);
            totalPublicMinted += 1;
            season_minted[_season] += 1;
            season_wallet_mints[msg.sender].season_mints[_season] += 1;
        }
    }

    function onPresaleList(uint256 _season, address _address)
        public
        view
        returns (bool)
    {
        bool onList = false;

        for (uint256 i = 0; i < presaleList[_address].length; i++) {
            if (presaleList[_address][i] == _season) {
                onList = true;
            }
        }

        return onList;
    }

    // onlyOwner functions

    function addSeason(
        uint256 _seasonNum,
        uint256 _price,
        uint256 _count,
        uint256 _walletLimit,
        string memory _provenance,
        string memory _baseURI
    ) external onlyOwner {
        require(seasons[_seasonNum].unit_count == 0, "Season Already exists");
        seasons[_seasonNum] = Season(
            _seasonNum,
            _price,
            _count,
            _walletLimit,
            0, // offset init
            _provenance,
            _baseURI,
            true, // paused
            false, // publicSales
            false // revealed
        );
        SEASON_COUNT += 1;
        // season 1 , 111
        // season 2, 111 + 111
        // season 3 , 222 + 111
        season_offsets[_seasonNum] = season_offsets[_seasonNum - 1] + _count;
        season_minted[_seasonNum] = 0;
    }

    function addSeasonPresale(uint256 _season, address[] calldata _list)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _list.length; i++) {
            presaleList[_list[i]].push(_season);
        }
    }

    function requestSeasonRandom(uint256 _season) public onlyOwner {
        require(seasons[_season].season_number != 0, "Season doesn't exist");
        require(seasons[_season].tokenOffset == 0, "Offset already set");

        bytes32 requestId = requestRandomness(LINK_KEY_HASH, LINK_FEE);
        setSeasonRequestID(requestId, _season);
    }

    function setSeasonRequestID(bytes32 _requestId, uint256 _season) public {
        season_randIDs[_requestId] = _season;
    }

    // @dev chainlink callback function for requestRandomness
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 offset = randomness %
            seasons[season_randIDs[requestId]].unit_count;

        seasons[season_randIDs[requestId]].tokenOffset = offset;
    }

    function setSeasonURI(uint256 _season, string memory _uri)
        external
        onlyOwner
    {
        seasons[_season].uri = _uri;
    }

    function setSeasonPause(uint256 _season, bool _state) external onlyOwner {
        seasons[_season].paused = _state;
    }

    function setSeasonPublic(uint256 _season, bool _state) external onlyOwner {
        seasons[_season].publicOpen = _state;
    }

    function revealSeason(uint256 _season, bool _state) external onlyOwner {
        seasons[_season].revealed = _state;
    }

    function setSeasonWalletLimit(uint256 _season, uint256 _limit)
        external
        onlyOwner
    {
        seasons[_season].walletLimit = _limit;
    }

    // @dev gift a single token to each address passed in through calldata
    // @param _season uint256 season number
    // @param _recipients Array of addresses to send a single token to
    function gift(uint256 _season, address[] calldata _recipients)
        external
        onlyOwner
    {
        require(
            _recipients.length + season_minted[_season] <=
                seasons[_season].unit_count,
            "Number of gifts exceeds season supply"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 tokenID = season_offsets[_season - 1] +
                season_minted[_season] +
                1;
            _safeMint(_recipients[i], tokenID);
            totalPublicMinted += 1;
            season_minted[_season] += 1;
        }
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            release(payable(payees[i]));
        }
    }
}
