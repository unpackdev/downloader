// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BBBBBBBGG&@@@@@@@@@&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P!:          :P@@@@&P7^.        .^?G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&J.            :#@@@#7.                  :Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&!              Y@@@B:                        !&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@P               B@@@~                            J@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@J               B@@&.                              ~@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@G               7@@@.                                7@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.               &@@Y                                  #@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&               .@@@&##########&&&&&&&&&&&#############@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&               .@@@@@@@@@@@@@@#B######&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.               &@@@@@@@@@@@@@B~         .:!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@B               !@@@@@@@@@@@@@@@&!            .7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@Y               G@@@@@@@@@@@@@@@@B.             ^#@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@G               B@@@@@@@@@@@@@@@@@:              7@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@?              J@@@@@@@@@@@@@@@@@.              ^@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@5:            .B@@@@@@@@@@@@@@@B               ~@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7^.         :P@@@@@@@@@@@@@@:               #@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#######BB&@@@@@@@@@@@@@7               J@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?               J@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.                                 ^@@@:               B@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@Y                                 G@@#               ^@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@!                               Y@@@:              .@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@Y                             P@@@^              ~@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&~                         !&@@&.             :B@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&?.                   .J&@@@?             !B@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y~.           :!5&@@@#7          .^JB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGGGB#&@@@@@@@@BPGGGGGGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "./ERC721RoyaltyUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC165Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IMintable.sol";
import "./Minting.sol";
import "./IExtensionManager.sol";

contract StoryversePlot is
    Initializable,
    ERC721RoyaltyUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IMintable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // token state variables
    string public baseURI;
    uint256 public totalSupply;

    IExtensionManager public extensionManager;

    address public imx;
    mapping(uint256 => bytes) public blueprints;

    // ------------------ keep state variables above this line ------------------

    /// @notice Emitted when a new extension manager is set
    /// @param who Admin that set the extension manager
    /// @param extensionManager New extension manager contract
    event ExtensionManagerSet(address indexed who, address indexed extensionManager);

    /// @notice Emitted when a new Immutable X is set
    /// @param who Admin that set the extension manager
    /// @param imx New Immutable X address
    event IMXSet(address indexed who, address indexed imx);

    /// @notice Emitted when a new token is minted and a blueprint is set
    /// @param to Owner of the newly minted token
    /// @param tokenId Token ID that was minted
    /// @param blueprint Blueprint extracted from the blob
    event AssetMinted(address to, uint256 tokenId, bytes blueprint);

    /// @notice Emitted when the new base URI is set
    /// @param who Admin that set the base URI
    event BaseURISet(address indexed who);

    /// @notice Emitted when funds are withdrawn from the contract
    /// @param to Recipient of the funds
    /// @param amount Amount sent in Wei
    event FundsWithdrawn(address to, uint256 amount);

    /// @notice Checks if the extension manager is set
    modifier extensionManagerSet() {
        if (isExtensionManagerSet()) {
            _;
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializes the contract
    /// @param _uri Base URI
    function initialize(string calldata _uri) public initializer {
        __ERC721_init("Storyverse Plot", "PLOT");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _transferOwnership(msg.sender);

        baseURI = _uri;
        emit BaseURISet(msg.sender);
    }

    /// @notice Checks if the extension manager is set
    /// @return true if the extension manager is set to non-zero address
    function isExtensionManagerSet() internal view returns (bool) {
        return address(extensionManager) != address(0);
    }

    /// @notice Sets a new extension manager
    /// @param _extensionManager New extension manager
    function setExtensionManager(address _extensionManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _extensionManager == address(0) ||
                IERC165Upgradeable(_extensionManager).supportsInterface(
                    type(IExtensionManager).interfaceId
                ),
            "invalid extension manager"
        );

        extensionManager = IExtensionManager(_extensionManager);
        emit ExtensionManagerSet(msg.sender, _extensionManager);
    }

    /// @notice Mint a new token
    /// @param _to Owner of the newly minted token
    /// @param _tokenId Token ID
    function safeMint(address _to, uint256 _tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(_to, _tokenId);
    }

    /// @notice Grants approval to an address for a token ID
    /// @param _to Delegate who will be able to transfer the token on behalf of the owner
    /// @param _tokenId Token ID
    function approve(address _to, uint256 _tokenId) public override {
        if (isExtensionManagerSet()) {
            extensionManager.beforeTokenApprove(_to, _tokenId);
        }
        super.approve(_to, _tokenId);
        if (isExtensionManagerSet()) {
            extensionManager.afterTokenApprove(_to, _tokenId);
        }
    }

    /// @notice Approves or disapproves for all the tokens owned by an address
    /// @param _operator Delegate who will be able to transfer all tokens on behalf of the owner
    /// @param _approved Whether to grant or revoke approval
    function setApprovalForAll(address _operator, bool _approved) public override {
        if (isExtensionManagerSet()) {
            extensionManager.beforeApproveAll(_operator, _approved);
        }
        super.setApprovalForAll(_operator, _approved);
        if (isExtensionManagerSet()) {
            extensionManager.afterApproveAll(_operator, _approved);
        }
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        if (isExtensionManagerSet()) {
            extensionManager.beforeTokenTransfer(_from, _to, _tokenId);
        }
        super._beforeTokenTransfer(_from, _to, _tokenId);

        if (_from == address(0)) {
            totalSupply++;
        }
        if (_to == address(0)) {
            totalSupply--;
        }
    }

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        if (isExtensionManagerSet()) {
            extensionManager.afterTokenTransfer(_from, _to, _tokenId);
        }
        super._afterTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Sets a base URI
    /// @param _uri Base URI
    function setBaseURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
        emit BaseURISet(msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Get a token's URI
    /// @param _tokenId Token ID
    /// @return uri_ URI of the token
    function tokenURI(uint256 _tokenId) public view override returns (string memory uri_) {
        if (isExtensionManagerSet()) {
            return extensionManager.tokenURI(_tokenId);
        }

        return super.tokenURI(_tokenId);
    }

    /// @notice Get the royalty information of the token, conforms to the EIP-2981 specification
    /// @param _tokenId Token ID
    /// @param _salePrice Sale price of the token
    /// @return receiver_ Receiver of the royalty
    /// @return royaltyAmount_ Royalty amount
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        extensionManagerSet
        returns (address receiver_, uint256 royaltyAmount_)
    {
        return extensionManager.royaltyInfo(_tokenId, _salePrice);
    }

    /// @notice Get PLOT data for the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function getPLOTData(uint256 _tokenId, bytes memory _in)
        public
        view
        extensionManagerSet
        returns (bytes memory out_)
    {
        return extensionManager.getPLOTData(_tokenId, _in);
    }

    /// @notice Sets PLOT data for the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function setPLOTData(uint256 _tokenId, bytes memory _in)
        public
        extensionManagerSet
        returns (bytes memory out_)
    {
        return extensionManager.setPLOTData(_tokenId, _in);
    }

    /// @notice Pays for PLOT data of the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function payPLOTData(uint256 _tokenId, bytes memory _in)
        public
        payable
        extensionManagerSet
        returns (bytes memory out_)
    {
        bool ok;
        (ok, out_) = payable(address(extensionManager)).call{value: msg.value}(
            abi.encodeCall(extensionManager.payPLOTData, (_tokenId, _in))
        );

        require(ok, "payment failed");
        return out_;
    }

    /// @notice Get data
    /// @param _in Input data
    /// @return out_ Output data
    function getData(bytes memory _in)
        public
        view
        extensionManagerSet
        returns (bytes memory out_)
    {
        return extensionManager.getData(_in);
    }

    /// @notice Sets data
    /// @param _in Input data
    /// @return out_ Output data
    function setData(bytes memory _in) public extensionManagerSet returns (bytes memory out_) {
        return extensionManager.setData(_in);
    }

    /// @notice Pays for data
    /// @param _in Input data
    /// @return out_ Output data
    function payData(bytes memory _in)
        public
        payable
        extensionManagerSet
        returns (bytes memory out_)
    {
        bool ok;
        (ok, out_) = payable(address(extensionManager)).call{value: msg.value}(
            abi.encodeCall(extensionManager.payData, _in)
        );

        require(ok, "payment failed");
        return out_;
    }

    /// @notice Transfers the ownership of the contract
    /// @param newOwner New owner of the contract
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newOwner != address(0), "new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /// @notice Sets the Immutable X address
    /// @param _imx New Immutable X
    function setIMX(address _imx) external onlyRole(DEFAULT_ADMIN_ROLE) {
        imx = _imx;
        emit IMXSet(msg.sender, imx);
    }

    /// @notice Mints a new token from a blob
    /// @param _to Owner of the newly minted token
    /// @param _quantity Token quantity, only 1 is supported
    /// @param _mintingBlob Blob of the format {token_id}:{blueprint}
    function mintFor(
        address _to,
        uint256 _quantity,
        bytes calldata _mintingBlob
    ) external {
        require(
            hasRole(MINTER_ROLE, msg.sender) || msg.sender == imx,
            "function can only be called by owner or IMX"
        );
        require(_quantity == 1, "Mintable: invalid quantity");
        (uint256 tokenId, bytes memory blueprint) = Minting.split(_mintingBlob);
        _safeMint(_to, tokenId);
        blueprints[tokenId] = blueprint;
        emit AssetMinted(_to, tokenId, blueprint);
    }

    /// @notice Withdraw funds from the contract
    /// @param _to Recipient of the funds
    /// @param _amount Amount sent, in Wei
    function withdrawFunds(address payable _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_amount <= address(this).balance, "not enough funds");
        _to.transfer(_amount);
        emit FundsWithdrawn(_to, _amount);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721RoyaltyUpgradeable, ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 _tokenId)
        internal
        override(ERC721RoyaltyUpgradeable, ERC721Upgradeable)
    {
        super._burn(_tokenId);
    }
}
