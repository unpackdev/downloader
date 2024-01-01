// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControlUpgradeable.sol";
import "./IERC2981.sol";
import "./IERC165.sol";
import "./Clone.sol";
import "./FullMath.sol";
import "./MintingStages.sol";
import "./ERC721A.sol";

//
// ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗██╗   ██╗███████╗██████╗  █████╗
// ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██║   ██║██╔════╝██╔══██╗██╔══██╗
// ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██║   ██║█████╗  ██████╔╝███████║
// ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██╔══██╗██╔══██║
// ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║ ╚████╔╝ ███████╗██║  ██║██║  ██║
// ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
//
/// @title Art Collection ERC721A Upgradable
/// @notice This contract is made only for the Arab Collectors Club ACC
/// @author MoonveraLabs
contract MvxCollection is Clone, ERC721A, IERC2981, MintingStages {
    string public baseURI;
    string public baseExtension;
    uint256 public maxSupply;
    uint96 public platformFee; // basis points
    address private platformFeeReceiver;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo public royaltyData;

    // Cap number of mint per user
    mapping(address => uint256) public mintsPerWallet;

    event WithdrawEvent(
        address indexed sender, uint256 balanceAfterFee, address platformFeeReceiver, uint256 platformFee
    );
    event OGmintEvent(address indexed sender, uint256 value, address to, uint256 amount, uint256 _ogMintPrice);
    event WLmintEvent(address indexed sender, uint256 value, address to, uint256 amount, uint256 wlMintPrice);
    event MintEvent(address indexed sender, uint256 value, address to, uint256 amount, uint256 mintPrice);
    event OwnerMintEvent(address indexed sender, address to, uint256 amount);
    event RoyaltyFeeUpdate(address indexed sender, address receiver, uint96 royaltyFee);
    event BurnEvent(address indexed sender, uint256 tokenId);

    /// @notice Called by MvxFactory on Deployment
    /// @param _platformFee description
    /// @param _nftData description
    /// @param _initialOGMinters description
    /// @param _initialWLMinters description
    /// @param _mintingStages description
    function initialize(
        uint96 _platformFee,
        bytes calldata _nftData,
        address[] calldata _initialOGMinters,
        address[] calldata _initialWLMinters,
        uint256[] calldata _mintingStages
    ) public initializer {
        (uint256 _maxSupply, uint96 _royaltyFee, string memory _name, string memory _symbol, string memory _initBaseURI)
        = abi.decode(_nftData, (uint256, uint96, string, string, string));
        __ERC721A_init(_name, _symbol);
        __AccessControl_init();
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        // Granting Admin to MvxFactory to be able to grant roles for user
        // since user is not msg.sender, but revoking at the end of function
        // Trade-off to manage minting roles with OZ AccessControl  
            
        // ADMIN is onlyOwner that can add OPERATORS
        _grantRole(ADMIN_ROLE, msg.sender); // not caching due to Stack error
        platformFeeReceiver = msg.sender;
        // immutable arguments set at clone deployment, storage slot 0 always = collection owner/admin
        _grantRole(ADMIN_ROLE, _getArgAddress(0));
        _updateRoyaltyInfo(_getArgAddress(0), _royaltyFee);
        _setRoleAdmin(OG_MINTER_ROLE, ADMIN_ROLE); // set ADMIN_ROLE as admin of OG's
        _setRoleAdmin(WL_MINTER_ROLE, ADMIN_ROLE); // set ADMIN_ROLE as admin of WL's

        baseURI = _initBaseURI;
        baseExtension = ".json";
        maxSupply = _maxSupply;

        // OG minting stage details
        ogMintPrice = _mintingStages[0];
        ogMintMaxPerUser = _mintingStages[1];
        ogMintStart = _mintingStages[2];
        ogMintEnd = _mintingStages[3];

        // WL minting stage details
        whitelistMintPrice = _mintingStages[4];
        whitelistMintMaxPerUser = _mintingStages[5];
        whitelistMintStart = _mintingStages[6];
        whitelistMintEnd = _mintingStages[7];

        // Regular minting stage details
        mintPrice = _mintingStages[8];
        mintMaxPerUser = _mintingStages[9];
        mintStart = _mintingStages[10];
        mintEnd = _mintingStages[11];
        // init minting roles OG=0, WL=1
        updateMinterRoles(_initialOGMinters, 0);
        updateMinterRoles(_initialWLMinters, 1);

        require(_platformFee < _feeDenominator(), "Invalid PF");
        platformFee = _platformFee;

        // revoke ADMIN_ROLE to MvxFactory, ADMIN is the OWNER of collection
        revokeRole(ADMIN_ROLE, platformFeeReceiver);
    }

    /// @notice access: ADMIN_ROLE
    /// @param _to address to mint to
    /// @param _amount amount to mint (batch minting)
    function mintForOwner(address _to, uint256 _amount) external payable nonReentrant OnlyAdminOrOperator {
        require(totalSupply() + _amount <= maxSupply, "Over mintMax error");
        _safeMint(_to, _amount);
        emit OwnerMintEvent(msg.sender, _to, _amount);
    }

    /// @notice access: OG_MINTER_ROLE
    /// @param _to address to mint to
    /// @param _amount amount to mint (batch minting)
    function mintForOG(address _to, uint256 _amount) external payable nonReentrant onlyRole(OG_MINTER_ROLE) {
        uint256 _currentTime = block.timestamp;
        require(_currentTime <= ogMintEnd && _currentTime >= ogMintStart, "Not OG mint time");
        require(totalSupply() + _amount <= maxSupply, "Over mintMax error");
        _internalSafeMint(msg.value, _to, ogMintPrice, _amount, ogMintMaxPerUser);
        emit OGmintEvent(msg.sender, msg.value, _to, _amount, ogMintPrice);
    }

    /// @notice access: WL_MINTER_ROLE
    /// @param _to address to mint to
    /// @param _amount amount to mint (batch minting)
    function mintForWhitelist(address _to, uint256 _amount) external payable onlyRole(WL_MINTER_ROLE) nonReentrant {
        uint256 _currentTime = block.timestamp;
        require(_currentTime <= whitelistMintEnd && _currentTime >= whitelistMintStart, "Not OG mint time");
        require(totalSupply() + _amount <= maxSupply, "Over mintMax error");
        _internalSafeMint(msg.value, _to, whitelistMintPrice, _amount, whitelistMintMaxPerUser);
        emit WLmintEvent(msg.sender, msg.value, _to, _amount, whitelistMintPrice);
    }

    /// @notice access: any
    /// @param _to address to mint to
    /// @param _amount amount to mint (batch minting)
    function mintForRegular(address _to, uint256 _amount) external payable nonReentrant {
        uint256 _currentTime = block.timestamp;
        require(_currentTime <= mintEnd && _currentTime >= mintStart, "Not Regular minTime");
        require(totalSupply() + _amount <= maxSupply, "Over mintMax error");
        _internalSafeMint(msg.value, _to, mintPrice, _amount, mintMaxPerUser);
        emit MintEvent(msg.sender, msg.value, _to, _amount, mintPrice);
    }

    /// @notice Checks for ether sent to this contract before calling _safeMint
    function _internalSafeMint(
        uint256 _msgValue,
        address _mintTo,
        uint256 _mintPrice,
        uint256 _mintAmount,
        uint256 _maxMintAmount
    ) internal {
        require(mintsPerWallet[msg.sender] + _mintAmount <= _maxMintAmount, "Exceeds maxMint");
        require(_msgValue >= (_mintAmount * _mintPrice), "Insufficient mint payment");
        unchecked {
            mintsPerWallet[msg.sender] += _mintAmount;
        }
        _safeMint(_mintTo, _mintAmount);
    }

    /// @notice access: only ADMIN ROLE
    function updateRoyaltyInfo(address _receiver, uint96 _royaltyFee) external onlyRole(ADMIN_ROLE) {
        _updateRoyaltyInfo(_receiver, _royaltyFee);
        emit RoyaltyFeeUpdate(msg.sender, _receiver, _royaltyFee);
    }

    function _updateRoyaltyInfo(address _receiver, uint96 _royaltyFee) internal {
        require(_royaltyFee <= _feeDenominator(), "ERC2981: fee exceed salePrice");
        require(_receiver != address(0), "ERC2981: invalid receiver");
        royaltyData = RoyaltyInfo(_receiver, _royaltyFee);
    }

    // @dev Inherits IERC2981
    function royaltyInfo(uint256 tokenId, uint256 _salePrice) external view override returns (address, uint256) {
        return (royaltyData.receiver, (_salePrice * royaltyData.royaltyFraction) / _feeDenominator());
    }

    /// @notice The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
    /// fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
    /// override.
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10_000;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory current_baseURI = baseURI;

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(current_baseURI, _toString(_tokenId), baseExtension))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public {
        baseURI = _newBaseURI;
    }

    function getMintCountOf(address _user) public view returns (uint256) {
        return mintsPerWallet[_user];
    }

    function setBaseExtension(string memory _newBaseExtension) public {
        baseExtension = _newBaseExtension;
    }

    function burn(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner");
        _burn(_tokenId);
        emit BurnEvent(_msgSender(), _tokenId);
    }

    /// @notice only ADMIN access withdraw royalties
    function withdraw() external payable nonReentrant onlyRole(ADMIN_ROLE) {
        require(platformFeeReceiver != address(0x0), "Address Zero");
        uint256 _balance = address(this).balance;
        uint256 _platformFee = _balance * platformFee / _feeDenominator();
        uint256 _balanceAfterFee = _balance - _platformFee;

        (bool feeSent,) = payable(platformFeeReceiver).call{value: _platformFee}("");
        require(feeSent, "Withdraw _platformFee fail");

        (bool sent,) = payable(msg.sender).call{value: _balanceAfterFee}("");
        require(sent, "Withdraw _balanceAfterFee fail");
        emit WithdrawEvent(msg.sender, _balanceAfterFee, platformFeeReceiver, _platformFee);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721A, AccessControlUpgradeable,IERC165)
        returns (bool)
    {
        return _interfaceId == type(IERC721A).interfaceId || _interfaceId == type(IERC2981).interfaceId
            || super.supportsInterface(_interfaceId);
    }

    function version() external pure returns (uint8 _version) {
        _version = 1;
    }
}
