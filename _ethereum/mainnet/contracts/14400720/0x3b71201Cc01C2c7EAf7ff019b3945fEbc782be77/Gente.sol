// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/**

 .d8888b.  888      d8b 888          888                             d8b
d88P  Y88b 888      Y8P 888          888                             Y8P
Y88b. d88P 888          888          888
 "Y88888"  88888b.  888 888888       88888b.   .d88b.  88888b.d88b.  888  .d88b.  .d8888b
.d8P""Y8b. 888 "88b 888 888          888 "88b d88""88b 888 "888 "88b 888 d8P  Y8b 88K
888    888 888  888 888 888          888  888 888  888 888  888  888 888 88888888 "Y8888b.
Y88b  d88P 888 d88P 888 Y88b.        888  888 Y88..88P 888  888  888 888 Y8b.          X88
 "Y8888P"  88888P"  888  "Y888       888  888  "Y88P"88888  888  888 888  "Y8888   88888P'
                                                     888
                                                     888
88888b.  888d888  .d88b.  .d8888b   .d88b.  88888b.  888888
888 "88b 888P"   d8P  Y8b 88K      d8P  Y8b 888 "88b 888
888  888 888     88888888 "Y8888b. 88888888 888  888 888
888 d88P 888     Y8b.          X88 Y8b.     888  888 Y88b.
88888P"  888      "Y8888   88888P'  "Y8888  888  888  "Y888
888
888
8.d8888b.  888      d8b 888           .d8888b.                    888
d88P  Y88b 888      Y8P 888          d88P  Y88b                   888
Y88b. d88P 888          888          888    888                   888
 "Y88888"  88888b.  888 888888       888         .d88b.  88888b.  888888  .d88b.
.d8P""Y8b. 888 "88b 888 888          888  88888 d8P  Y8b 888 "88b 888    d8P  Y8b
888    888 888  888 888 888          888    888 88888888 888  888 888    88888888
Y88b  d88P 888 d88P 888 Y88b.        Y88b  d88P Y8b.     888  888 Y88b.  Y8b.
 "Y8888P"  88888P"  888  "Y888        "Y8888P88  "Y8888  888  888  "Y888  "Y8888
*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC2981.sol";

contract Gente is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public PROVENANCE_HASH;

    uint256 constant MAX_SUPPLY = 10000;
    uint256 private _currentId;

    string public baseURI;
    string private _contractURI;

    bool public isActive = false;

    uint256 public price = 1 ether;

    bytes32 public merkleRoot;
    mapping(address => uint256) private _alreadyMinted;

    address public beneficiary;
    address public royalties;

    constructor(
        address _beneficiary,
        address _royalties,
        string memory _initialBaseURI,
        string memory _initialContractURI
    ) ERC721("8bit Gente Official", "8BITGENTE") {
        beneficiary = _beneficiary;
        royalties = _royalties;
        baseURI = _initialBaseURI;
        _contractURI = _initialContractURI;
    }

    // Accessors

    function setProvenanceHash(string calldata hash) public onlyOwner {
        PROVENANCE_HASH = hash;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    // Metadata

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    // Minting

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _internalMint(to, amount);
    }

    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    // Private

    function _internalMint(address to, uint256 amount) private {
        require(_currentId + amount <= MAX_SUPPLY, "Will exceed maximum supply");

        for (uint256 i = 1; i <= amount; i++) {
            _currentId++;
            _safeMint(to, _currentId);
        }
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // IERC2981

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice/100) * 5;
        return (royalties, royaltyAmount);
    }
}