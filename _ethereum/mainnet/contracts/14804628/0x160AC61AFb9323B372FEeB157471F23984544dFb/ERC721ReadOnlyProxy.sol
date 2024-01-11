// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import "./IERC721ReadOnlyProxy.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";

// References
import "./ERC721Upgradeable.sol";

/// @title ERC721 Proxy
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice Simple mintable/burnable read-only proxy
contract ERC721ReadOnlyProxy is
    IERC721ReadOnlyProxy,
    OwnableUpgradeable,
    ERC721Upgradeable
{
    /* ========== STATE VARIABLES ========== */

    // wrapped token address
    address private _wrapped;
    // minter address
    address private _minter;

    /* ========== MODIFIERS ========== */

    /// @dev Prevent calling a function from anyone except the minter
    modifier onlyMinter() {
        require(_msgSender() == _minter, "Only minter");
        _;
    }

    /* ========== EVENTS ========== */

    /// @notice Emitted on minter change
    /// @param previousMinter previous minter address
    /// @param newMinter new minter address
    event MinterTransferred(
        address indexed previousMinter,
        address indexed newMinter
    );

    /* ========== CONSTRUCTOR ========== */

    /* ---------- INITIALIZER ---------- */

    /// @dev Initialize ERC721ReadOnlyProxy (to be used with proxies)
    /// @param wrapped wrapped token address
    /// @param prefix prefix to prepend to the token symbol
    /// @param owner admin for the contract
    // slither-disable-next-line naming-convention
    function __ERC721ReadOnlyProxy_init(
        address wrapped,
        string memory prefix,
        address owner
    ) internal onlyInitializing {
        __Context_init_unchained();
        _transferOwnership(owner);

        __ERC721_init(
            string(abi.encodePacked(prefix, ERC721Upgradeable(wrapped).name())),
            string(
                abi.encodePacked(prefix, ERC721Upgradeable(wrapped).symbol())
            )
        );

        _wrapped = wrapped;
    }

    /* ========== SETTERS ========== */

    /* ---------- Internal ---------- */

    /// @notice Set minter role
    /// @param newMinter wrapped token address
    function _setMinter(address newMinter) internal {
        address previousMinter = _minter;

        // enable disable minting
        // slither-disable-next-line missing-zero-check
        _minter = newMinter;

        emit MinterTransferred(previousMinter, newMinter);
    }

    /* ---------- Public ---------- */

    /// @notice Set minter role
    /// @param newMinter wrapped token address
    function setMinter(address newMinter) external onlyOwner {
        _setMinter(newMinter);
    }

    /* ========== VIEWS ========== */

    /// @inheritdoc IERC721ReadOnlyProxy
    function getWrapped() public view override returns (address) {
        return _wrapped;
    }

    /// @notice Get minter role address
    /// @return minter role address
    // slither-disable-next-line external-function
    function getMinter() public view returns (address) {
        return _minter;
    }

    /// @inheritdoc IERC721MetadataUpgradeable
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // return the underlying wrapped token uri
        return IERC721MetadataUpgradeable(_wrapped).tokenURI(tokenId);
    }

    /// @notice Fallback any (static) call to the wrapped token
    // slither-disable-next-line assembly
    fallback() external {
        assembly {
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize())

            let result := staticcall(
                gas(),
                sload(_wrapped.slot),
                free_ptr,
                calldatasize(),
                0,
                0
            )
            returndatacopy(free_ptr, 0, returndatasize())

            if iszero(result) {
                revert(free_ptr, returndatasize())
            }
            return(free_ptr, returndatasize())
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @inheritdoc IERC721ReadOnlyProxy
    function mint(address to, uint256 tokenId) external override onlyMinter {
        _mint(to, tokenId);
    }

    /// @inheritdoc IERC721ReadOnlyProxy
    function burn(uint256 tokenId) external override onlyMinter {
        _burn(tokenId);
    }
}
