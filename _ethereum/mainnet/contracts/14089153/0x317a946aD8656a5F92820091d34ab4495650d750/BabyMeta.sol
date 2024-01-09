// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";

/// @title NFT's collection of BabyMeta
/// @notice smart-contract using for minting BabyMeta NFT's
contract BabyMeta is ERC721, Ownable, PaymentSplitter {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;

    bytes32 immutable merkleRoot;

    uint256 public constant MAX_BABYMETA = 4777;
    uint256 public constant BABYMETA_PER_WALLET = 4;
    uint256 public PRICE = 200000000000000000; 

    bool public whitelist_sale;
    bool public public_sale;

    string private _baseTokenURI;

    address[] private _babyTeam = [0x9713318937d21e655B2e4b2c5fc9cafD88669872, 0x49E8a55AAcfD16E77488878091F0A9b6E53e9B7d, 0xA25A8E2a5813622A48B1a53BBb626135ffcea6f7, 0xaaFE8be4FDfe4bBeC994A0905146f8FE1d785913, 0x5cc9426Bf0D0F2dd65846232Ed228263218F237D] ;
    uint[] private _babyShares = [2450, 2450, 2450, 2450, 200];

    event WelcomeToBabyMeta(address from, uint256 id);

    /// @dev root once you init the root hash you cannot change his value later.
    constructor(bytes32 root)
        ERC721("BABYMETA", "BABYMT") PaymentSplitter(_babyTeam, _babyShares) payable
    {
        merkleRoot = root;
    }

    function setBaseURI(string memory newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function setWhitelist(bool status) external onlyOwner {
        whitelist_sale = status;
    }

    function setPublicSale(bool status) external onlyOwner {
        public_sale = status;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

    function currentSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function bornOnWhitelist(uint256 amount, bytes32[] calldata proof) public payable {
        require(whitelist_sale, "The whitelist sale haven't started yet");
        require(currentSupply() + amount <= MAX_BABYMETA, "SOLD OUT");
        require(amount > 0, "bornWL: Amount cannot be 0."); 
        require(msg.value >= amount * PRICE, "Don't enough ether send");
        require(balanceOf(msg.sender) < BABYMETA_PER_WALLET, "You have exceed the authorized amount per addres");
        require(verify(proof, msg.sender), "You are not listed on the Whitelist");
        for (uint8 i = 0; i < amount; i++) {
            _mintElement(msg.sender);
        }
    }

    function bornOnOpenSale(uint256 amount) public payable {
        require(public_sale, "The open sale haven't started yet");
        require(currentSupply() + amount <= MAX_BABYMETA, "SOLD OUT");
        require(amount > 0, "bornOS: Amount cannot be 0.");
        require(msg.value >= amount * PRICE, "Don't enough ether send"); 
        require(balanceOf(msg.sender) < BABYMETA_PER_WALLET, "You have exceed the authorized amount per addres");
        for (uint8 i = 0; i < amount; i++) {
            _mintElement(msg.sender);
        }
    }

    function bornOwner() public onlyOwner {
        uint8 OWNER_MINT = 20;
        require(currentSupply() + OWNER_MINT <= MAX_BABYMETA, "SOLD OUT");
        for(uint8 i = 0; i < OWNER_MINT; i++) {
            _mintElement(owner());
        }
    }
 
    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function verify(bytes32[] memory proof, address from) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _mintElement(address to) private {
        _tokenIdTracker.increment();

        uint256 id = _tokenIdTracker.current();
        _safeMint(to, id);

        emit WelcomeToBabyMeta(to, id);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _baseURI = baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
    }
}
