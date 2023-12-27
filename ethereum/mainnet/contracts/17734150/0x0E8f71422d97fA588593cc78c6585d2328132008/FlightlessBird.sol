// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./Math.sol";
import "./Strings.sol";

import "./IFlightlessBirdMintableNFT.sol";

contract FlightlessBird is ERC721Enumerable, AccessControlEnumerable, ERC2981, IFlightlessBirdMintableNFT, ReentrancyGuard {
    using Math for uint256;
    using Strings for uint256;

    error ConstructorParamError(string param);
    error OnlyFundsClaimerError();
    error OnlyAdminError();
    error ZeroMintError();
    error InsufficientETHError();
    error UserCapMintError();
    error ZeroAddressError();
    error EmptyURIError();
    error MintNotStartedError();
    error OnlyUriSetterError();

    bytes32 public constant FUNDS_CLAIMER_ROLE = keccak256("FUNDS_CLAIMER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    string internal baseTokenURI;

    uint256 public immutable mintCap;
    uint256 public immutable capPerUser;
    uint256 public immutable price;
    uint256 public immutable idOffset; // ID to start minting at
    uint256 public startTimestamp;

    uint256 public totalMinted;
    mapping(address => uint256) public userMints;

    modifier onlyFundsClaimer {
        if(!hasRole(FUNDS_CLAIMER_ROLE, _msgSender())) {
            revert OnlyFundsClaimerError();
        }
        _;
    }

    modifier onlyUriSetter {
        if(!hasRole(URI_SETTER_ROLE, _msgSender())) {
            revert OnlyUriSetterError();
        }
        _;
    }

    modifier onlyAdmin {
        if(!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert OnlyAdminError();
        }
        _;
    }

    /// @notice Constructor
    /// @param _name The name of the NFT
    /// @param _symbol Symbol aka ticker
    /// @param _baseTokenURI Prepends the tokenId for the tokenURI
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address[] memory _deployMints,
        uint256 _mintCap,
        uint256 _capPerUser,
        uint256 _price,
        uint256 _idOffset,
        uint256 _startTimestamp
    ) ERC721(_name, _symbol) {
        if(_mintCap == 0) {
            revert ConstructorParamError("_mintCap == 0");
        }
        if(_capPerUser == 0) {
            revert ConstructorParamError("_capPerUser == 0");
        }
        if(_price == 0) {
            revert ConstructorParamError("_price == 0");
        }
        if(_deployMints.length > _mintCap) {
            revert ConstructorParamError("_deployMints.length > _mintCap");
        }
        if(type(uint256).max - _idOffset < _mintCap) {
            revert ConstructorParamError("type(uint256).max - _idOffset < _mintCap");
        }
        if(_capPerUser > _mintCap) {
            revert ConstructorParamError("_capPerUser > _mintCap");
        }
        if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(""))) {
            revert ConstructorParamError("_name empty");
        }
        if(keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(""))) {
            revert ConstructorParamError("_symbol empty");
        }

        baseTokenURI = _baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        mintCap = _mintCap;
        capPerUser = _capPerUser;
        price = _price;
        idOffset = _idOffset;
        // No checks on startTimestamp as it can have any value and be change by admin.
        startTimestamp = _startTimestamp;
        
        for(uint256 i = 0; i < _deployMints.length; i ++) {
            if(userMints[_deployMints[i]] >= _capPerUser) {
                revert UserCapMintError();
            }
            _safeMint(_deployMints[i], i + _idOffset);
            userMints[_deployMints[i]] ++;
            totalMinted ++;
        }
    }

    /// @notice Claim funds received from the mint
    /// @param _receiver address receiving the funds
    function claimFunds(address _receiver) external onlyFundsClaimer() {
        if(_receiver == address(0)) {
            revert ZeroAddressError();
        }
        (bool success, ) = payable(_receiver).call{value: address(this).balance}("");
        require(success);
    }

    /// @notice Mints an NFT. Can be called by anyone.
    /// @param _receiver Address receiving the NFT
    function mint(uint256 _amount, address _receiver) public payable override nonReentrant() {
        if(startTimestamp > block.timestamp) {
            revert MintNotStartedError();
        }

        uint256 amount = _amount.min(mintCap - totalMinted).min(capPerUser - userMints[_msgSender()]);

        if(amount == 0) {
            revert ZeroMintError();
        }

        uint256 totalEthRequired = amount * price;

        if(totalEthRequired > msg.value) {
            revert InsufficientETHError();
        }

        // Reading totalMinted once to save on storage writes
        uint256 nextId = totalMinted + idOffset;
        totalMinted += amount;
        userMints[_msgSender()] += amount;

        // Mint NFTS
        for(uint256 i = 0; i < amount; i ++) {
            _safeMint(_receiver, nextId);
            nextId ++;
        }

        // return excess ETH
        if(msg.value > totalEthRequired) {
            (bool success, ) = payable(_msgSender()).call{value: msg.value - totalEthRequired}("");
            require(success);
        }
    }

    /// @notice Sets the base token URI. Can only be called by an address with the default admin role
    /// @param _newBaseURI New baseURI
    function setBaseURI(string memory _newBaseURI) external onlyUriSetter {
        if(keccak256(abi.encodePacked(_newBaseURI)) == keccak256(abi.encodePacked(""))) {
            revert EmptyURIError();
        }
        baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice returns the baseURI
    /// @return The tokenURI
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /// @notice Signals support for a given interface
    /// @param interfaceId 4bytes signature of the interface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, AccessControlEnumerable, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /// @notice sets the startTimestamp. Only callable by admin role.
    function setTimestamp(uint256 _timestamp) public onlyAdmin() {
        startTimestamp = _timestamp;
    }

    /// @notice Sets the receiver and fee info
    /// @param _receiver Address that receives the fees
    /// @param _feeNumerator Basis points of the fee to be received
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyAdmin {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}