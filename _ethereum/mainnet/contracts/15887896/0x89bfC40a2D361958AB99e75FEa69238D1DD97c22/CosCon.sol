// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./IERC721Metadata.sol";
import "./AccessControlEnumerable.sol";
// import "./Context.sol";
// import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./UriChanger.sol";
import "./ERC5169.sol";
import "./OprimizedEnumNonBurnable.sol"; 

contract CosCon is
    UriChanger,
    ERC5169,
    OprimizedEnumNonBurnable
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    string constant _metadataURI = "https://resources.smarttokenlabs.com/";
    string constant _contractPath = "/coscon2022.json";
    string constant _contractName = "COSCon'22 Collectible";
    string constant _contractSymbol = "COSCON22";

    string private _baseTokenURI = "ipfs://bafybeiasebwgwq3mw4qn75pfmwnnv4d7cnos5capz2gfuebhxdxdqb5vki";

    // Counters.Counter private _tokenIdCounter;

    // tokenId => type
    mapping(uint => uint) private types;

    // attendy is default role, if no other roles then its attendee

    // ticketId -> role
    mapping(uint => uint) private ticketRoles;

    enum RoleNames { SOUVENIR, ATTENDY, VOLUNTEER, SPEAKER, PRODUCER }

    uint private mintEnd;

    function setMintEnd(uint newTime) external onlyOwner {
        mintEnd = newTime;
    }

    function _authorizeSetScripts(string[] memory) internal override onlyOwner {}

    constructor(address uriChanger) OprimizedEnumNonBurnable(_contractName, _contractSymbol) UriChanger(uriChanger){
        mintEnd = block.timestamp + 30 * 24 * 60 * 60;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseTokenURI) external onlyUriChanger {
        _baseTokenURI = newBaseTokenURI;
    }

    modifier whenMintingAllowed() {
        require(block.timestamp < mintEnd, "Minting finished");
        _;
    }

    function mint(address to, uint ticketId, uint _type) public virtual onlyUriChanger whenMintingAllowed {

        require (_type < 32, "Wrong Role");
        require (_type > 0, "No Roles");
        require (ticketRoles[ticketId] == 0, "Already minted");

        ticketRoles[ticketId] = _type;
        uint counter = 0;
        uint bit;
        uint id;
        while (_type > 0) {
            bit = _type & 1;
            if (bit == 1) {
                id = getCurrentId();
                incrementCurrentId();
                if (counter > 0) {
                    types[id] = counter;
                }
                _mint(to, id);
            }
            _type = _type / 2;
            counter++;
        }        
    }

    // get tokenId for ticketId+role, revern if not minted
    function getMinted(uint ticketId) public view returns (uint){
        // console.log();
        uint role = ticketRoles[ticketId];
        require (role != 0, "Not minted");
        return role;
    }

    function getRoleName(uint _role) public pure returns (string memory){
        if (_role == uint( RoleNames.ATTENDY ) ){
            return "attendee";
        } else if (_role == uint( RoleNames.VOLUNTEER) ){
            return "volunteer";
        } else if (_role == uint( RoleNames.SPEAKER) ){
            return "speaker";
        } else if (_role == uint( RoleNames.PRODUCER) ){
            return "producer";
        }else if (_role == uint( RoleNames.SOUVENIR) ){
            return "souvenir";
        } else {
            revert("Unknown Role");
        }
    }

    function getRole(uint tokenId) view public returns (string memory){
        ownerOf(tokenId);
        return getRoleName(types[tokenId]);
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getRoleId(string calldata _roleName) external pure returns (uint){
        if (compareStrings(_roleName, "attendee")){
            return uint(RoleNames.ATTENDY);
        } else if (compareStrings(_roleName, "volunteer") ){
            return uint(RoleNames.VOLUNTEER);
        } else if (compareStrings(_roleName, "speaker") ){
            return uint(RoleNames.SPEAKER);
        } else if (compareStrings(_roleName, "producer") ){
            return uint(RoleNames.PRODUCER);
        } else if (compareStrings(_roleName, "souvenir") ){
            return uint(RoleNames.SOUVENIR);
        } else {
            revert("Unknown Role Name");
        }
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(from == address(0), "Only mint allowed");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override( OprimizedEnumNonBurnable, ERC5169)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || ERC5169.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, "/", getRole(tokenId), ".json"));
        } else {
            return string(abi.encodePacked(_metadataURI, block.chainid.toString(), "/", contractAddress(), "/", tokenId.toString()));
        }
    }

    function contractAddress() internal view returns (string memory) {
        return Strings.toHexString(uint160(address(this)), 20);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, _contractPath));
    }
}