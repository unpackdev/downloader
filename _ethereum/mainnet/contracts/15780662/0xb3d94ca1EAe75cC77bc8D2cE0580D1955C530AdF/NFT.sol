// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";

contract NFT is
    Initializable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721BurnableUpgradeable
{
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");

    function initialize(address _admin) public initializer {
        require(_admin != address(0), "zero address");

        __ERC721_init("Bunki Official", "BUNKI");
        __ERC721Enumerable_init();
        __ERC721Pausable_init();
        __ERC721Burnable_init();

        __Ownable_init();

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    string private _contractURI;
    string private _baseURIVal;

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin");
    }

    /**
     * @dev Internal function to view base URI. This will be used internally by NFT library.
     */

    function _baseURI() internal view override returns (string memory) {
        return _baseURIVal;
    }

    /**
     * @notice View Base URI
     *
     * @dev External funciton to view base URI.
     */

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Set Base URI
     *
     * @dev Update base uri for contract. Only admin can call this function.
     * @param _newBaseURI New base uri.
     */

    function setBaseURI(string memory _newBaseURI) external restricted {
        _baseURIVal = _newBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    /**
     * @notice View Contract URI
     *
     * @dev External funciton to view contract URI.
     */

    function contractURI() external view returns(string memory) {
        return _contractURI;
    }

    /**
     * @notice Set Contract URI
     *
     * @dev Update contract uri for contract. Only admin can call this function.
     * @param _newContractURI New contract uri.
     */

    function setContractURI(string memory _newContractURI) external restricted {
        _contractURI = _newContractURI;
    }

    /**
     * @notice Mint
     *
     * @dev Mint new token. Only minter address can call this function.
     */

    function mint(address _recipient, uint256 _amount) external onlyRole(ROLE_MINTER) {
        require(_recipient != address(0), "zero address");
        require(_amount > 0, "zero amount");

        uint256 startTokenId = totalSupply() + 1;
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_recipient, startTokenId + i);   
        }
    }

    /**
     * @notice Pause Contract
     *
     * @dev Only admin can call this function.
     */

    function pause() external restricted {
        _pause();
    }

    /**
     * @notice Un-pause Contract
     *
     * @dev Only admin can call this function.
     */

    function unpause() external restricted {
        _unpause();
    }

    /**
     * ===============================================================
     * OVERRIDE METHOD
     * ===============================================================
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}