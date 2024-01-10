// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./SafeERC20.sol";

contract RareMintCollection is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant RECOVERY_ROLE = keccak256("RECOVERY_ROLE");

    event SafePullETH(address indexed user, uint256 balance);
    event SafePullERC20(address indexed user, uint256 balance);

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("RareMint Collection", "RMC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(RECOVERY_ROLE, msg.sender);
    }

    /**
     * @dev Mints with tokenURI rareMint metadata
     * @param to: receiving address
     * @param uri: metadata uri
     */
    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /* ========================================================================================= */
    /*                                            Management                                     */
    /* ========================================================================================= */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev called by the BURNER_ROLE to burn tokens
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyRole(BURNER_ROLE) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @notice Emergency functions - use with extreme care !
     */
    function safePullETH() external onlyRole(RECOVERY_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit SafePullETH(msg.sender, balance);
    }

    /**
     * @dev allows to recover ERC20 tokens which were (accidently) sent to this contract
     */
    function safePullERC20(address erc20) external onlyRole(RECOVERY_ROLE) {
        uint256 balance = IERC20(erc20).balanceOf(address(this));
        IERC20(erc20).safeTransfer(msg.sender, balance);
        emit SafePullERC20(msg.sender, balance);
    }

    /**
     * @dev The following functions are overrides required by Solidity
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
