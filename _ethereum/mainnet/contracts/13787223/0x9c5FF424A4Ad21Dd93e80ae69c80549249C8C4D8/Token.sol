pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Strings.sol";

import "./IUriProvider.sol";

contract IntergalacticToken is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => address) private uriProviders;
    address public defaultUriProvider;

    address private feeRecipient;

    bytes constant METADATA_START = "data:application/json;charset=UTF-8,%7B%22name%22%3A%20%22Intergalactic%20Tokens%22%2C%20%22description%22%3A%20%22A%20collection%20of%20dynamically%20generated%20intergalactic%20token%20logos%20that%20cruise%20space%20based%20on%20their%20price%20fluctuations.%22%2C%20%22seller_fee_basis_points%22%3A%20250%2C%20%22fee_recipient%22%3A%20%22";
    bytes constant METADATA_END = "%22%7D";

    constructor(address _defaultUriProvider) ERC721("Intergalactic Tokens", "IGT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        feeRecipient = msg.sender;
        defaultUriProvider = _defaultUriProvider;
    }

    function safeMint(address to, uint256 tokenId, address uriProvider) public onlyRole(MINTER_ROLE) {
        if (uriProvider != defaultUriProvider) {
            uriProviders[tokenId] = uriProvider;
        }
        _safeMint(to, tokenId);
    }

    function safeMintWithData(address to, uint256 tokenId, address uriProvider, string memory data) external onlyRole(MINTER_ROLE) {
        IUriProvider(uriProvider).writeLogo(tokenId, data);
        safeMint(to, tokenId, uriProvider);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
            METADATA_START,
            Strings.toHexString(uint160(feeRecipient), 20),
            METADATA_END
        ));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address provider = uriProviders[tokenId];
        if (provider == address(0)) provider = defaultUriProvider;
        return IUriProvider(provider).tokenURI(tokenId);
    }

    function setUriProvider(uint256 tokenId, address uriProvider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uriProviders[tokenId] = uriProvider;
    }

    function setDefaultUriProvider(address uriProvider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultUriProvider = uriProvider;
    }

    function setFeeRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRecipient = recipient;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
