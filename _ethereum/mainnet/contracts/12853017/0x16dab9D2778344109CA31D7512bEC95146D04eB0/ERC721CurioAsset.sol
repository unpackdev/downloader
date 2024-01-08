// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC721Base.sol";
import "./IWlController.sol";

contract ERC721CurioAsset is ERC721Base {

    /// @notice Whitelist controller
    IWlController public wlController;

    event CreateERC721CurioAsset(address owner, string name, string symbol);
    event SetWlController(address indexed wlController);

    function __ERC721CurioAsset_init(
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
        emit CreateERC721CurioAsset(_msgSender(), _name, _symbol);
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
                    "ERC721CurioAsset: transfer permission denied"
                );
            }

            // check burn case
            if (to != address(0)) {
                require(
                    controller.isInvestorAddressActive(to),
                    "ERC721CurioAsset: transfer permission denied"
                );
            }
        }
    }

    uint256[50] private __gap;
}
