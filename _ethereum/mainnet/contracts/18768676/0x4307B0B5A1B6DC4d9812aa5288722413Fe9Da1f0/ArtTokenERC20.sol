// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IArtToken.sol";
import "./IArtERC721.sol";

contract ArtTokenERC20 is IArtToken, ERC20Upgradeable, OwnableUpgradeable {
    IArtERC721 internal nftContract;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory ftName,
        string memory ftSymbol,
        address erc721Address
    ) external initializer {
        __ERC20_init(ftName, ftSymbol);
        __Ownable_init_unchained();
        nftContract = IArtERC721(erc721Address);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be an owner
     */
    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
        nftContract.onArtTokenTransfer(address(0), 0, to, 0, amount);
    }

    /**
     * @notice Transfers ERC20 token to a new owner and executes NFT generation callback.
     * @param to New owner address.
     * @param amount Amount of tokens to transfer.
     * @return True if successful.
     */
    function transfer(
        address to,
        uint256 amount
    )
        public
        virtual
        override(ERC20Upgradeable, IERC20Upgradeable)
        returns (bool)
    {
        address owner = _msgSender();
        nftContract.onArtTokenTransfer(
            _msgSender(),
            balanceOf(_msgSender()),
            to,
            balanceOf(to),
            amount
        );
        _transfer(owner, to, amount);
        return true;
    }
}
