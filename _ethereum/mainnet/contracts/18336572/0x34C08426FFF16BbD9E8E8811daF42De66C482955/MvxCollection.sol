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
    string public _baseExtension;
    uint256 public _maxSupply;
    uint256 public _mintFee; // basis points
    uint256 public _royaltyFee; // basis points

    // Cap number of mint per user
    mapping(address => uint256) public _mintsPerWallet;

    event OGmintEvent(address indexed sender, uint256 value, address to, uint256 amount, uint256 _ogMintPrice);
    event WLmintEvent(address indexed sender, uint256 value, address to, uint256 amount, uint256 wlMintPrice);
    event MintEvent(address indexed sender, uint256 value, address to, uint256 amount, uint256 mintPrice);
    event OwnerMintEvent(address indexed sender, address to, uint256 amount);

    event BurnEvent(address indexed sender, uint256 tokenId);

    /// @notice Called by MvxFactory on Deployment
    /// @param mintFee description
    /// @param nftData description
    /// @param initialOGMinters description
    /// @param initialWLMinters description
    /// @param mintingStages description
    function initialize(
        uint256 mintFee,
        bytes calldata nftData,
        address[] calldata initialOGMinters,
        address[] calldata initialWLMinters,
        uint256[] calldata mintingStages
    ) public initializer {
        (uint256 maxSupply, uint256 royaltyFee, string memory name, string memory symbol, string memory initBaseURI) =
            abi.decode(nftData, (uint256, uint256, string, string, string));

        __ERC721A_init(name, symbol);
        __AccessControl_init();
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        // Granting Admin to MvxFactory to be able to grant roles for user
        // since user is not msg.sender, but revoking at the end of function
        // Trade-off to manage minting roles with OZ AccessControl
        _grantRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        // immutable arguments set at clone deployment, storage slot 0 always = collection owner/admin
        _grantRole(ADMIN_ROLE, _getArgAddress(0));
        _setRoleAdmin(OG_MINTER_ROLE, ADMIN_ROLE); // set ADMIN_ROLE as admin of OG's
        _setRoleAdmin(WL_MINTER_ROLE, ADMIN_ROLE); // set ADMIN_ROLE as admin of WL's

        baseURI = initBaseURI;
        _baseExtension = ".json";
        _maxSupply = maxSupply;
        _royaltyFee = royaltyFee;

        // OG minting stage details
        _ogMintPrice = mintingStages[0];
        _ogMintMaxPerUser = mintingStages[1];
        _ogMintStart = mintingStages[2];
        _ogMintEnd = mintingStages[3];

        // WL minting stage details
        _whitelistMintPrice = mintingStages[4];
        _whitelistMintMaxPerUser = mintingStages[5];
        _whitelistMintStart = mintingStages[6];
        _whitelistMintEnd = mintingStages[7];

        // Regular minting stage details
        _mintPrice = mintingStages[8];
        _mintMaxPerUser = mintingStages[9];
        _mintStart = mintingStages[10];
        _mintEnd = mintingStages[11];
        // init minting roles OG=0, WL=1
        updateMinterRoles(initialOGMinters, 0);
        updateMinterRoles(initialWLMinters, 1);
        _mintFee = mintFee;

        // revoke ADMIN_ROLE to MvxFactory, ADMIN is the OWNER of collection
        revokeRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice access: ADMIN_ROLE
    /// @param to address to mint to
    /// @param amount amount to mint (batch minting)
    function mintForOwner(address to, uint256 amount) external payable nonReentrant OnlyAdminOrOperator {
        require(totalSupply() + amount <= _maxSupply, "Over mintMax error");
        _safeMint(to, amount);
        emit OwnerMintEvent(msg.sender, to, amount);
    }

    /// @notice access: OG_MINTER_ROLE
    /// @param to address to mint to
    /// @param amount amount to mint (batch minting)
    function mintForOG(address to, uint256 amount) external payable nonReentrant onlyRole(OG_MINTER_ROLE) {
        uint256 currentTime = block.timestamp;
        require(currentTime <= _ogMintEnd && currentTime >= _ogMintStart, "Not OG mint time");
        require(totalSupply() + amount <= _maxSupply, "Over mintMax error");
        _internalSafeMint(msg.value, to, _ogMintPrice, amount, _ogMintMaxPerUser);
        emit OGmintEvent(msg.sender, msg.value, to, amount, _ogMintPrice);
    }

    /// @notice access: WL_MINTER_ROLE
    /// @param to address to mint to
    /// @param amount amount to mint (batch minting)
    function mintForWhitelist(address to, uint256 amount) external payable onlyRole(WL_MINTER_ROLE) nonReentrant {
        uint256 currentTime = block.timestamp;
        require(currentTime <= _whitelistMintEnd && currentTime >= _whitelistMintStart, "Not OG mint time");
        require(totalSupply() + amount <= _maxSupply, "Over mintMax error");
        _internalSafeMint(msg.value, to, _whitelistMintPrice, amount, _whitelistMintMaxPerUser);
        emit WLmintEvent(msg.sender, msg.value, to, amount, _whitelistMintPrice);
    }

    /// @notice access: any
    /// @param to address to mint to
    /// @param amount amount to mint (batch minting)
    function mintForRegular(address to, uint256 amount) external payable nonReentrant {
        uint256 currentTime = block.timestamp;
        require(currentTime <= _mintEnd && currentTime >= _mintStart, "Not Regular minTime");
        require(totalSupply() + amount <= _maxSupply, "Over mintMax error");
        _internalSafeMint(msg.value, to, _mintPrice, amount, _mintMaxPerUser);
        emit MintEvent(msg.sender, msg.value, to, amount, _mintPrice);
    }

    /// @notice Checks for ether sent to this contract before calling _safeMint
    /// @param msgValue internal values set at minting call
    /// @param mintTo internal values set at minting call
    /// @param mintPrice internal values set at minting call
    /// @param mintAmount internal values set at minting call
    /// @param maxMintAmount internal values set at minting call
    function _internalSafeMint(
        uint256 msgValue,
        address mintTo,
        uint256 mintPrice,
        uint256 mintAmount,
        uint256 maxMintAmount
    ) internal {
        require(_mintsPerWallet[msg.sender] + mintAmount <= maxMintAmount, "Exceeds maxMint");

        uint256 price = mintAmount * mintPrice;
        uint256 mintFee = _mintFee != 0 ? _calculateFee(price, _mintFee) : 0;

        require(msgValue >= (price + mintFee), "Insufficient mint payment");

        unchecked {
            _mintsPerWallet[msg.sender] += mintAmount;
        }
        _safeMint(mintTo, mintAmount);
    }

    /// @notice Quote based on current OG Mint price and amount
    /// @param amount amount to mint
    function quoteOgMints(uint256 amount) external view returns (uint256 quote) {
        uint256 price = _ogMintPrice * amount;
        quote = price + (_mintFee != 0 ? _calculateFee(price, _mintFee) : 0);
    }

    /// @notice Quote based on current WL Mint price and amount
    /// @param amount amount to mint
    function quoteWLMints(uint256 amount) external view returns (uint256 quote) {
        uint256 price = _whitelistMintPrice * amount;
        quote = price + (_mintFee != 0 ? _calculateFee(price, _mintFee) : 0);
    }

    /// @notice Quote based on current Regular Mint price and amount
    /// @param amount amount to mint
    function quoteMints(uint256 amount) external view returns (uint256 quote) {
        uint256 price = _mintPrice * amount;
        quote = price + (_mintFee != 0 ? _calculateFee(price, _mintFee) : 0);
    }

    /// @notice Using basis Points as measurement units.
    /// @dev FullMath: core uniswap v3 to mittigate phantom overflow
    function _calculateFee(uint256 price, uint256 mintFee) internal pure returns (uint256 _fee) {
        // 0.003 (aka 0.3%) feeOnMint = 3000
        _fee = FullMath.mulDiv(uint256(price), 1e6 - mintFee, 1e6);
    }

    /// @notice IERC2981 compatible
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // The receiver will be the contract owner
        receiver = _getArgAddress(0);

        royaltyAmount = FullMath.mulDiv(uint256(salePrice), 1e6 - _royaltyFee, 1e6);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory current_baseURI = _baseURI();

        return bytes(current_baseURI).length > 0
            ? string(abi.encodePacked(current_baseURI, _toString(tokenId), _baseExtension))
            : "";
    }

    function setBaseURI(string memory newBaseURI) public {
        baseURI = newBaseURI;
    }

    function getMintCountOf(address user) public view returns (uint256) {
        return _mintsPerWallet[user];
    }

    function setBaseExtension(string memory newBaseExtension) public {
        _baseExtension = newBaseExtension;
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not Owner");

        _burn(tokenId);

        emit BurnEvent(_msgSender(), tokenId);
    }

    /// @notice only ADMIN access withdraw royalties
    function withdraw() external payable onlyRole(ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControlUpgradeable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC721A).interfaceId || interfaceId == type(IERC2981).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function version() external pure returns (bytes16) {
        return "0.1";
    }
}
