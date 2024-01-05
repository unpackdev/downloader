// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract BallerFactory is ERC721, AccessControl {
    using Address for address;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Add minter roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Baller Teams
    string[30] public ballerTeamPool = [         
        "Atlanta",
        "Boston",
        "Brooklyn",
        "Charlotte",
        "Chicago",
        "Cleveland",
        "Dallas",
        "Denver",
        "Detroit",
        "Golden State",
        "Houston",
        "Indiana",
        "LA1",
        "LA2",
        "Memphis",
        "Miami",
        "Milwaukee",
        "Minnesota",
        "New Orleans",
        "New York",
        "Oklahoma City",
        "Orlando",
        "Philadelphia",
        "Phoenix",
        "Portland",
        "Sacramento",
        "San Antonio",
        "Toronto",
        "Utah",
        "Washington"
    ];

    // Maximum ballers that can be minted per team
    uint256 public maxBallers = 100;

    // Keep track of minted ballers
    Counters.Counter private _ballerIds;

    // Keep track of baller URIS
    mapping(uint256 => string) public _ballerURIs;

    // Total ballers in circulation for the given baller team.
    mapping (string => uint256) public ballersInCirculation;

    // Mapping between baller ID and team.
    mapping (uint256 => string) public ballerTeams;

    // Ensure we never mint the same baller
    mapping(string => uint256) hashes;
    
    // Event to track successful Baller purchases
    event BallerPurchaseRequest(address to, string team);

    // Event to track URI changes
    event URIChanged(uint256 ballerId, string uri);
    
    /**
    * Constructor.
    */
    constructor()
    ERC721(
        "8-Bit Baller", "BALR"
    )
    {
        // Set admin/minter roles to deployer address
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }
    
    /**
    * Baller minting function.
    * @param to Address of the beneficiary.
    * @param teamId Integer ID of the team baller plays for.
    * @param mdHash IPFS Hash of the metadata JSON file corresponding to the baller.
    */
    function mintBaller(address to, uint256 teamId, string memory mdHash) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "BallerFactory: Must have minter role to mint.");
        require(to != address(0), "BallerFactory: Cannot mint to the 0 address.");
        require(teamId < 30, "BallerFactory: Invalid team.");
        require(teamId >= 0, "BallerFactory: Invalid team.");
        require(hashes[mdHash] != 1, "BallerFactory: Hash has already been used.");
        
        hashes[mdHash] = 1;

        // Grab team corresponding to the given team ID
        string memory team = ballerTeamPool[teamId];

        require(ballersInCirculation[team] < maxBallers, "BallerFactory: There are no ballers left for this team!");

        // Set the team for the current baller ID
        ballerTeams[_ballerIds.current()] = team;

        // Increase ballers of the given team in circulation by 1
        ballersInCirculation[team] = ballersInCirculation[team].add(1);

        // Mint baller to address
        _safeMint(to, _ballerIds.current());

        // Set URI to IPFS hash for the current baller
        _setTokenURI(_ballerIds.current(), string(abi.encodePacked(_baseURI(), mdHash)));

        // Increment baller ID
        _ballerIds.increment();

        // Emit baller purchase request.
        emit BallerPurchaseRequest(to, team);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * Getter function to see the number of ballers in circulation for a given team.
    * @param teamId Integer ID of the team of interest.
    */
    function getBallersInCirculation(uint256 teamId) public view returns(uint256) {
        string memory team = ballerTeamPool[teamId];
        return ballersInCirculation[team];
    }

    /**
    * Sets the token URI for the given baller.
    * @param ballerId Integer ID of the baller.
    * @param uri The new URI for the baller.
    */
    function setBallerURI(uint256 ballerId, string memory uri) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BallerFactory: Must have admin role to change baller metadata.");

        _setTokenURI(ballerId, string(abi.encodePacked(_baseURI(), uri)));

        emit URIChanged(ballerId, uri);
    }

    /**
    * @dev Base URI for computing {tokenURI}.
    */
    function _baseURI() override internal pure returns (string memory) {
        return "ipfs://";
    }
    
    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _ballerURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _ballerURIs[tokenId];
    }
}