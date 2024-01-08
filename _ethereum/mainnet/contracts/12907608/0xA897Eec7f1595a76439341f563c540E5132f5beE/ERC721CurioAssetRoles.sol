// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC721Base.sol";
import "./IWlController.sol";

contract ERC721CurioAssetRoles is ERC721Base {

    /// @notice Whitelist controller
    IWlController public wlController;

    /// @notice Admins managing minters
    mapping(address => bool) public isAdmin;

    /// @notice Minters managing mint logic
    mapping(address => bool) public isMinter;

    event CreateERC721CurioAssetRoles(address owner, string name, string symbol);
    event SetWlController(address indexed wlController);

    event SetAdminPermission(address indexed admin, bool permission);
    event SetMinterPermission(address indexed minter, bool permission, address indexed admin);

    modifier onlyAdmin {
        require(isAdmin[_msgSender()], "ERC721CurioAssetRoles: caller is not the admin");
        _;
    }

    modifier onlyMinter {
        require(isMinter[_msgSender()], "ERC721CurioAssetRoles: caller is not the minter");
        _;
    }

    function __ERC721CurioAssetRoles_init(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        string memory contractURI
    ) external initializer {
        _setBaseURI(baseURI);
        __ERC721Lazy_init_unchained();
        __RoyaltiesV2Upgradeable_init_unchained();
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Mint721Validator_init_unchained();
        __HasContractURI_init_unchained(contractURI);
        __ERC721_init_unchained(_name, _symbol);
        emit CreateERC721CurioAssetRoles(_msgSender(), _name, _symbol);
    }

    /**
     * @dev Mint new tokens only by Minter role.
     */
    function mintAndTransfer(LibERC721LazyMint.Mint721Data memory data, address to) public override virtual onlyMinter {
        super.mintAndTransfer(data, to);
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // require from and to addresses in whitelist
        IWlController controller = wlController;
        if (address(controller) != address(0)) {
            // check mint case
            if (from != address(0)) {
                require(
                    controller.isInvestorAddressActive(from),
                    "ERC721CurioAssetRoles: transfer permission denied"
                );
            }

            // check burn case
            if (to != address(0)) {
                require(
                    controller.isInvestorAddressActive(to),
                    "ERC721CurioAssetRoles: transfer permission denied"
                );
            }
        }
    }

    uint256[50] private __gap;
}
