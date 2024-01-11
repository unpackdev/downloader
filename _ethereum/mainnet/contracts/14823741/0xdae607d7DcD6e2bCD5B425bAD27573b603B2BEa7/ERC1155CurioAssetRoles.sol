// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC1155Base.sol";
import "./IWlController.sol";

contract ERC1155CurioAssetRoles is ERC1155Base {

    /// @notice Whitelist controller
    IWlController public wlController;

    /// @notice Admins managing minters
    mapping(address => bool) public isAdmin;

    /// @notice Minters managing mint logic
    mapping(address => bool) public isMinter;

    event CreateERC1155CurioAssetRoles(address owner, string name, string symbol);
    event SetWlController(address indexed wlController);

    event SetAdminPermission(address indexed admin, bool permission);
    event SetMinterPermission(address indexed minter, bool permission, address indexed admin);

    event SetContractURI(string contractURI);
    event SetBaseURI(string baseURI);

    modifier onlyAdmin {
        require(isAdmin[_msgSender()], "ERC1155CurioAssetRoles: caller is not the admin");
        _;
    }

    modifier onlyMinter {
        require(isMinter[_msgSender()], "ERC1155CurioAssetRoles: caller is not the minter");
        _;
    }

    function __ERC1155CurioAssetRoles_init(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        string memory contractURI
    ) external initializer {
        __Ownable_init_unchained();
        __ERC1155Lazy_init_unchained();
        __ERC165_init_unchained();
        __Context_init_unchained();
        __Mint1155Validator_init_unchained();
        __ERC1155_init_unchained("");
        __HasContractURI_init_unchained(contractURI);
        __ERC1155Burnable_init_unchained();
        __RoyaltiesV2Upgradeable_init_unchained();
        __ERC1155Base_init_unchained(_name, _symbol);
        _setBaseURI(baseURI);
        emit CreateERC1155CurioAssetRoles(_msgSender(), _name, _symbol);
    }

    /**
     * @notice Mint new tokens only by Minter role.
     */
    function mintAndTransfer(LibERC1155LazyMint.Mint1155Data memory data, address to, uint256 _amount) public override virtual onlyMinter {
        super.mintAndTransfer(data, to, _amount);
    }

    /**
     * @notice Mint new token only by Minter role.
     */
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlyMinter {
        ERC1155Upgradeable._mint(account, id, amount, data);
    }

    /**
     * @notice Mint new tokens only by Minter role.
     */
    function mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyMinter {
        ERC1155Upgradeable._mintBatch(account, ids, amounts, data);
    }

    /**
     * @notice Burn tokens only by Minter role.
     */
    function burn(address account, uint256 id, uint256 value) public override virtual onlyMinter {
        super.burn(account, id, value);
    }

    /**
     * @notice Burn batch of tokens only by Minter role.
     */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override virtual onlyMinter {
        super.burnBatch(account, ids, values);
    }

    /**
     * @notice Set a new whitelist controller.
     * @param _wlController New whitelist controller.
     */
    function setWlController(IWlController _wlController) external onlyOwner {
        wlController = _wlController;
        emit SetWlController(address(_wlController));
    }

    /**
     * @notice Set an admin permission.
     * @param _user Account address.
     * @param _permission Is there permission or not.
     */
    function setAdminPermission(address _user, bool _permission) external onlyOwner {
        isAdmin[_user] = _permission;
        emit SetAdminPermission(_user, _permission);
    }

    /**
     * @notice Set a minter permission.
     * @param _user Account address.
     * @param _permission Is there permission or not.
     */
    function setMinterPermission(address _user, bool _permission) external onlyAdmin {
        isMinter[_user] = _permission;
        emit SetMinterPermission(_user, _permission, _msgSender());
    }

    /**
     * @notice Set contractURI.
     * @param _contractURI New contractURI.
     */
    function setContractURI(string memory _contractURI) external onlyAdmin {
        _setContractURI(_contractURI);
        emit SetContractURI(_contractURI);
    }

    /**
     * @notice Set _baseURI.
     * @param _baseURI Base URI of all tokens.
     */
    function setBaseURI(string memory _baseURI) external onlyMinter {
        _setBaseURI(_baseURI);
        emit SetBaseURI(_baseURI);
    }

    /**
     * @notice Set URI to target token by tokenId.
     * @param _tokenId Target tokenId.
     * @param _uri New URI of target tokenId.
     */
    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyMinter {
        _setTokenURI(_tokenId, _uri);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // require from and to addresses in whitelist
        IWlController controller = wlController;
        if (address(controller) != address(0)) {
            // check mint case
            if (from != address(0)) {
                require(
                    controller.isInvestorAddressActive(from),
                    "ERC1155CurioAssetRoles: transfer permission denied"
                );
            }

            // check burn case
            if (to != address(0)) {
                require(
                    controller.isInvestorAddressActive(to),
                    "ERC1155CurioAssetRoles: transfer permission denied"
                );
            }
        }
    }

    uint256[50] private __gap;
}
