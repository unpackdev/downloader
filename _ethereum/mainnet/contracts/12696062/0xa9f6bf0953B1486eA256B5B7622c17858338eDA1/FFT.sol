//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
 
import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IGameCards.sol";
import "./IGameTokens.sol";

contract FFT is ERC721PresetMinterPauserAutoIdUpgradeable, IGameTokens {
    IGameCards private gameCards;
    string private _baseTokenURI;
    
    // /// @dev Init function 
    // /// @param gameCardsAddress - address of 
    // /// @param networkId - networkId use for metadata api 
    // /// @param isDevApi - use dev api for this contract 
    function init (address gameCardsAddress, string calldata networkId, bool isDevApi) public initializer {
        require(gameCardsAddress != address(0), "FFT: gameCards address is required");  
        gameCards = IGameCards(gameCardsAddress);
        string memory baseURI = string(abi.encodePacked("https://api.footballfantasy.io/v1/cards/", networkId, "/"));
        if (isDevApi) 
            baseURI = string(abi.encodePacked("http://apiffc.dev.smcorp.vn/v1/cards/", networkId, "/"));
        _baseTokenURI = baseURI;
        ERC721PresetMinterPauserAutoIdUpgradeable.initialize("Football Fantasy Token", "FFT", _baseTokenURI);
    }

    function mint(address to, uint256 tokenId) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "FFT: must have minter role to mint");
        _mint(to, tokenId);
    }

    function mint(address to) public virtual override {
        require(hasRole(MINTER_ROLE, _msgSender()), "FFT: must have minter role to mint");

    }

    function createCardAndMintToken(
        uint32 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId,
        address to
    ) public override returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "FFT: must have minter role to mint");
        uint256 cardId = gameCards.createCard(
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        );

        _mint(to, cardId);
        return cardId;
    }

    function mintToken(uint256 cardId, address to)
        public
        override 
        returns (uint256)
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "FFT: must have minter role to mint");
        require(gameCards.cardExists(cardId), "FFT: Card does not exist");

        _mint(to, cardId);
        return cardId;
    }

    function tokensOfOwner(address owner, uint8 page, uint8 rows)
        public
        view
        returns (uint256[] memory)
    {
        return tokensOfOwner(address(this), owner, page, rows);
    }

    function getCard(uint256 tokenId)
        public
        view
        returns (
            uint256 playerId,
            uint16 season,
            uint256 scarcity,
            uint16 serialNumber,
            bytes memory metadata,
            uint16 clubId
        )
    {
        (
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        ) = gameCards.getCard(tokenId);
    }

    function getPlayer(uint32 playerId)
        external
        view
        returns (
            string memory name,
            uint16 yearOfBirth,
            uint8 monthOfBirth,
            uint8 dayOfBirth
        )
    {
        (name, yearOfBirth, monthOfBirth, dayOfBirth) = gameCards.getPlayer(
            playerId
        );
    }
 
    function getClub(uint16 clubId)
        external
        view
        returns (
            string memory name,
            string memory country,
            string memory city,
            uint16 yearFounded
        )
    {
        (name, country, city, yearFounded) = gameCards.getClub(clubId);
    }
 
    function getGameCardsMinter()
        external
        view
        returns (address)
    {
        return gameCards.getMinter();
    }

    function setMinter (address minter) external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FFT: must have Admin role to set minter");
        _setupRole (MINTER_ROLE, minter);
        return true;
    }

    function setBaseURI (string memory baseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FFT: must have Admin role to set baseURI");
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //====== NFTClient =======
    bytes4 public constant interfaceIdERC721 = 0x80ac58cd;
    function requireERC721(address _candidate) public view {
        require(
            IERC721EnumerableUpgradeable(_candidate).supportsInterface(interfaceIdERC721),
            "IS_NOT_721_TOKEN"
        );
    }

    function transferTokens(
        IERC721EnumerableUpgradeable _nftContract,
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FFT: must have Admin role to transferTokens");
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            if (_tokenIds[index] == 0) {
                break;
            }

            _nftContract.safeTransferFrom(_from, _to, _tokenIds[index]);
        }
    }

    function transferAll(
        IERC721EnumerableUpgradeable _nftContract,
        address _sender,
        address _receiver
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FFT: must have Admin role to transferAll");
        uint256 balance = _nftContract.balanceOf(_sender);
        while (balance > 0) {
            _nftContract.safeTransferFrom(
                _sender,
                _receiver,
                _nftContract.tokenOfOwnerByIndex(_sender, balance - 1)
            );
            balance--;
        }
    }

    // /// @dev Pagination of owner tokens
    // /// @param owner - address of the token owner
    // /// @param page - page number
    // /// @param rows - number of rows per page
    function tokensOfOwner(
        address _nftContract,
        address owner,
        uint8 page,
        uint8 rows
    ) public view returns (uint256[] memory) {
        requireERC721(_nftContract);
        require(page >= 0, "page should be >= 0");
        require(rows > 0, "rows should be > 0");

        IERC721EnumerableUpgradeable nftContract = IERC721EnumerableUpgradeable(_nftContract);

        uint256 tokenCount = nftContract.balanceOf(owner);
        uint256 offset = page * rows;
        uint256 range = offset > tokenCount
            ? 0
            : min(tokenCount - offset, rows);
        uint256[] memory tokens = new uint256[](range);
        for (uint256 index = 0; index < range; index++) {
            tokens[index] = nftContract.tokenOfOwnerByIndex(
                owner,
                offset + index
            );
        }
        return tokens;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    } 
}
