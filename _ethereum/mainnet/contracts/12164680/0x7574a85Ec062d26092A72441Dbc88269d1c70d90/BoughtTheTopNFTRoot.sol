// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IMintableERC721.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./Context.sol";

contract BoughtTheTopNFTRoot is Context, AccessControl, ERC721Enumerable, IMintableERC721  {

    /// @notice Base of metdata URI
    string public baseTokenURI;

    /// @notice Role identifer for cross-chain minter
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    
    /// @notice Emitted when the base token URI changes
    event BaseTokenURIChanged(string uri);

    /**
     * @dev Initialize contract, owner will be set to the
     * account that deploys the contract.
     */
    constructor() ERC721("BoughtThe.top NFT", "BTT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Set the base URI for all tokens.
     *
     * See {ERC721-tokenURI}
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setBaseTokenURI(string calldata uri) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BoughtTheTopNFT: must have admin role");

        baseTokenURI = uri;
        emit BaseTokenURIChanged(uri);
    }

    /**
     * @dev See {IMintableERC721-mint}.
     */
    function mint(address user, uint256 tokenId) external override {
        require(hasRole(PREDICATE_ROLE, _msgSender()), "BoughtTheTopNFT: must have predicate role");
        _mint(user, tokenId);
    }

    /**
     * @dev See {IMintableERC721-mint}.
     * 
     */
    function mint(address user, uint256 tokenId, bytes calldata) external override {
        require(hasRole(PREDICATE_ROLE, _msgSender()), "BoughtTheTopNFT: must have predicate role");
        _mint(user, tokenId);
    }

    /**
     * @dev See {IMintableERC721-exists}.
     */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Rescue any ERC-20 token the contract may hold
     *
     * @param _token ERC-20 token address
     *
     * Requirements:
     *
     * - the caller must have the `WITHDRAW_ROLE`.
     */
    function rescue(address _token) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BoughtTheTopNFT: must have withdraw role");
        IERC20 token = IERC20(_token);
        token.transfer(_msgSender(), token.balanceOf(address(this)));
    }
}
