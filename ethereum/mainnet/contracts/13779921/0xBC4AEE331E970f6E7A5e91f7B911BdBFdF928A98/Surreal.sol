//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";
import "./Strings.sol";

import "./SignedMinting.sol";

interface IERC1155Burnable is IERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

contract Surreal is
    AccessControlEnumerable,
    ERC721URIStorage,
    ERC721Enumerable,
    PaymentSplitter,
    Pausable,
    ReentrancyGuard,
    SignedMinting
{
    using Address for address;
    using Strings for string;

    event PermanentURI(string _value, uint256 indexed _id);
    event Claimed(uint256 indexed _id, address by);

    bytes32 public constant INTEGRATION_ROLE = keccak256("INTEGRATION_ROLE");

    mapping(uint256 => string) private mintPassTokenURIs;
    mapping(uint256 => uint256) private burnedMintPass;

    IERC1155Burnable private mintPassContract;

    constructor(
        address signer,
        address adminAddress,
        address[] memory payees,
        uint256[] memory shares_
    )
        ERC721("SURREAL", "SURREAL")
        PaymentSplitter(payees, shares_)
        ReentrancyGuard()
        SignedMinting(signer)
    {
        _pause();
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }

    /*
     * @note Approval for this contract gets hardcoded into the mintpass contract
     */
    function claim(bytes memory signature, uint256 mintPassTokenId)
        public
        whenNotPaused
        nonReentrant
        isValidSignature(signature)
    {
        require(
            mintPassContract.balanceOf(_msgSender(), mintPassTokenId) > 0,
            "Must own mintpass"
        );
        mintPassContract.burn(_msgSender(), mintPassTokenId, 1);
        uint256 tokenId = totalSupply();
        _mintPrivate(_msgSender(), 1, mintPassTokenId);

        emit Claimed(tokenId, _msgSender());
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory tokenURI_ = super.tokenURI(tokenId);
        if (bytes(tokenURI_).length == 0) {
            return mintPassTokenURIs[burnedMintPass[tokenId]];
        }
        return tokenURI_;
    }

    /*
     * @dev Integrations can mint in case we want to change the mechanism
     */
    function mint(
        address to,
        uint256 amount,
        uint256 mintPassTokenId
    ) public onlyAuthorized {
        _mintPrivate(to, amount, mintPassTokenId);
    }

    /*
     * @note For OpenSea Integration
     */
    function owner() public view returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function setMintPassContract(address _address) public onlyAuthorized {
        mintPassContract = IERC1155Burnable(_address);
    }

    function setMintPassTokenURI(
        uint256 mintPassTokenId,
        string memory mintPassTokenURI
    ) public onlyAuthorized {
        mintPassTokenURIs[mintPassTokenId] = mintPassTokenURI;
    }

    function pauseClaiming() public onlyAuthorized {
        _pause();
    }

    function unpauseClaiming() public onlyAuthorized {
        _unpause();
    }

    function reveal(uint256 tokenId, string memory revealedTokenURI)
        public
        onlyAuthorized
    {
        require(
            bytes(super.tokenURI(tokenId)).length == 0,
            "Token already revealed"
        );
        _setTokenURI(tokenId, revealedTokenURI);

        // Freeze metadata
        emit PermanentURI(revealedTokenURI, tokenId);
    }

    /*
     * @dev Only admin can update the signer. No integrations.
     */
    function setMintingSigner(address _signer)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setMintingSigner(_signer);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function addIntegration(address account) public {
        grantRole(INTEGRATION_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function removeIntegration(address account) public {
        require(account != _msgSender(), "Cannot remove yourself");
        revokeRole(INTEGRATION_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function grantAdminRole(address account) public {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function removeAdminRole(address account) public {
        require(account != _msgSender(), "Cannot revoke yourself");
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721Enumerable, ERC721)
        returns (bool)
    {
        return
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721URIStorage, ERC721)
    {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        return super._beforeTokenTransfer(from, to, tokenId);
    }

    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        require(
            role != INTEGRATION_ROLE || account.isContract(),
            "Integration must be a contract"
        );
        super._grantRole(role, account);
    }

    function _mintPrivate(
        address to,
        uint256 amount,
        uint256 mintPassTokenId
    ) private {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(to, tokenId);
            burnedMintPass[tokenId] = mintPassTokenId;
        }
    }

    modifier onlyAuthorized() {
        require(
            hasRole(INTEGRATION_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Not authorized to perform that action"
        );
        _;
    }
}
