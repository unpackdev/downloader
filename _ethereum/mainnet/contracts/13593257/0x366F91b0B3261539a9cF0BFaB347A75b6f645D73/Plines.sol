// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./AccessControlUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Strings.sol";

/**
 * @title Plines
 * @author Plines team
 **/
contract Plines is ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    using Strings for uint256;

    // Maximum allowed tokenSupply boundary.
    uint256 public maxTotalSupply;
    // Address of IPFS DAG that contains numbered token JSON files
    string public baseUri;
    // Role that can issue new tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize() public virtual initializer {
        __ERC721_init("Plines", "PLN");
        __ERC721Enumerable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        maxTotalSupply = 17000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer incl. minting
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        // check maxTotalSupply is not exceeded on mint
        if (from == address(0)) {
            require(totalSupply() < maxTotalSupply, "Exceeds maxTotalSupply");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev IPFS address that stores JSON with token attributes
     * @param tokenId id of the token
     * @return address of json file `ipfs://<baseUri>/<tokenId>.json`
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseUri, "/", tokenId.toString(), ".json"));
    }

    /**
     * @dev Method to randomly mint desired number of NFTs
     * @param to the address where you want to transfer tokens
     * @param nfts the number of tokens to be minted
     */
    function _mintMultiple(address to, uint256 nfts) internal {
        require(nfts > 0, "nfts cannot be 0");
        require(totalSupply() + nfts <= maxTotalSupply, "Exceeds maxTotalSupply");

        for (uint256 i = 0; i < nfts; i++) {
            uint256 mintIndex = _getRandomAvailableIndex();
            _safeMint(to, mintIndex);
        }
    }

    /**
     * @dev Mints a specific token (with known id) to the given address
     * @param to the receiver
     * @param mintIndex the tokenId to mint
     */
    function mint(address to, uint256 mintIndex) public onlyRole(MINTER_ROLE) {
        require(mintIndex < maxTotalSupply, "mintIndex > maxTotalSupply");
        _safeMint(to, mintIndex);
    }

    /**
     * @dev Public method to randomly mint desired number of NFTs
     * @param to the receiver
     * @param nfts the number of tokens to be minted
     */
    function mintMultiple(address to, uint256 nfts) public onlyRole(MINTER_ROLE) {
        _mintMultiple(to, nfts);
    }

    /**
     * @dev Returns the (pseudo-)random token index free of owner.
     * @return available token index
     */
    function _getRandomAvailableIndex() internal view returns (uint256) {
        uint256 index = (uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, /* solhint-disable not-rely-on-time */
                    gasleft(),
                    blockhash(block.number - 1)
                )
            )
        ) % maxTotalSupply);
        while (_exists(index)) {
            index += 1;
            if (index >= maxTotalSupply) {
                index = 0;
            }
        }
        return index;
    }

    /**
     * @dev Set baseUri of token JSON files
     * @param uri new URI (ipfs://DAG)
     */
    function setBaseUri(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseUri = uri;
    }
}
