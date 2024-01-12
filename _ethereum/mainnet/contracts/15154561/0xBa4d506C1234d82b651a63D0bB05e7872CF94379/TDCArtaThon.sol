// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// The Dream Conduit -- Art-a-Thon Contract

// Source: https://github.com/chiru-labs/ERC721A
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./AccessControlEnumerable.sol";

contract TDCArtaThon is
    ERC721A,
    Ownable,
    AccessControlEnumerable
{
    using Strings for uint256;

    //Interface for royalties
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseURIPrefix = "";

    mapping(uint => address) public tokenArtists;

    address public royaltyRecipient;
    uint24 public royaltyAmount;

    // Opensea
    string public contractURI = "";

    constructor() ERC721A("TDC Art-a-Thon", "TDCArtaThon") {
        // Initialize owner access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        royaltyRecipient = _msgSender();
        royaltyAmount = 500;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only addresses with admin role can perform this action"
        );
        _;
    }

    modifier onlyOwnerorAdmin() {
        require(
            _msgSender() == owner() ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only addresses with admin role can perform this action"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Only addresses with minter role can perform this action."
        );
        _;
    }

    function setBaseURI(string memory baseURIPrefix) external onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function safeMint(address to) external onlyMinter {
        // Mint 1 token
        _safeMint(to, 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "Art-a-Thon token does not exist");
        return
            bytes(_baseURIPrefix).length > 0
                ? string(
                    abi.encodePacked(
                        _baseURIPrefix,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function mintArt(address artist, address to) external onlyMinter {
        tokenArtists[_nextTokenId()] = artist;
        _safeMint(to, 1);
    }

    function walletOfOwner(address address_) external view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        if (_balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory _tokens = new uint256[](_balance);
            uint256 _index;

            uint256 tokensCount = totalSupply();

            for (uint256 i = 0; i < tokensCount; i++) {
                if (address_ == ownerOf(i)) {
                    _tokens[_index] = i;
                    _index++;
                }
            }

            return _tokens;
        }
    }

    function supportsInterface(bytes4 interfaceID) public view override(ERC721A, AccessControlEnumerable)
        returns (bool)
    {
        //*** return super.supportsInterface(interfaceID);
        // Updated for ERC721A V4.x and ERC2981
        if(interfaceID == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return ERC721A.supportsInterface(interfaceID);
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    // Add a user address as a admin
    function addAdmin(address account) external onlyOwnerorAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function setTokenArtist(uint tokenId, address artist) external onlyOwnerorAdmin {
        require(_exists(tokenId), "Art-a-Thon token does not exist");
        tokenArtists[tokenId] = artist;
    }

    // EIP2981
    // Amount is percentage to two decimal points and should be between 0 and 10000, where 10000 = 100.00 percent
    function setRoyalty(address royaltyAddress, uint24 amount) external onlyOwnerorAdmin {
        royaltyRecipient = royaltyAddress;
        royaltyAmount = amount;
    }

    function royaltyInfo(uint256, uint256 value) external view
        returns (address receiver, uint256 amount)
    {
        receiver = royaltyRecipient;
        amount = (value * royaltyAmount) / 10000;
    }
}
