// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721Pausable.sol";
import "./Base64.sol";
import "./MerkleProof.sol";

contract CollectionTimeline is ERC721, Ownable, Pausable {
    uint256 public nextTokenId = 1;

    // Mint Info
    uint256 public mintLimit = 100;
    uint256 public price = 0.1 * 10**18;

    bytes32 private merkleRoot =
        0xe81e45834024d576989bbc18740bced77c223a4985704e1f186cd615674dc840;
    mapping(address => bool) private privateSaleHolders;

    bool private privateSale = false;

    // Meta Data
    string description =
        "With this membership card, you have access to the Collection Timeline.\\nThe Collection Timeline is a service for collectors that provides a centralized view of NFT's collections in the NFT Marketplace.\\n\\nNFT Design:  RETHELD DESIGN";

    string private baseUri =
        "https://asia-northeast1-collectiontimeline.cloudfunctions.net/MembershipCard?id=";

    // EIP-2981
    uint256 public constant secondarySaleRoyalty = 10_00000; // 10.0%
    uint256 public constant modulo = 100_00000; // precision 100.00000%
    address public royaltyReceiver;

    event Minted(address sender, uint256 tokenId);

    constructor() ERC721("CollectionTimeline", "CTM") {
        royaltyReceiver = msg.sender;
    }

    function setMintLimit(uint256 _newMintLimit) external onlyOwner {
        mintLimit = _newMintLimit;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseUri = _baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
        // emit SetMerkleRoot(merkleRoot);
    }

    function setPrivateSale(bool _privateSale) public onlyOwner {
        privateSale = _privateSale;
        // emit SetMerkleRoot(merkleRoot);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount) {
        _receiver = royaltyReceiver;
        _royaltyAmount = (_value / modulo) * secondarySaleRoyalty;
    }

    function publicMint() external payable {
        require(nextTokenId < mintLimit, "Cannot mint any more.");
        require(balanceOf(_msgSender()) < 1, "It can only be minted once.");
        require(msg.value >= uint256(price), "Need to send more ETH.");
        require(!privateSale, "Public sales have not yet begun.");
        uint256 tokenId = nextTokenId;
        nextTokenId++;
        _safeMint(_msgSender(), tokenId);

        emit Minted(_msgSender(), tokenId);

        // userNameById[tokenId] = _userName;
        // iconImageUrlById[tokenId] = _iconImageUrl;
    }

    function privateMint(bytes32[] calldata _merkleProof) external payable {
        require(nextTokenId < mintLimit, "Cannot mint any more.");
        require(balanceOf(_msgSender()) < 1, "It can only be minted once.");
        require(msg.value >= uint256(price), "Need to send more ETH.");
        require(privateSale, "Private sales have not yet begun.");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof."
        );
        require(!privateSaleHolders[_msgSender()], "Has been minted");
        privateSaleHolders[_msgSender()] = true;

        uint256 tokenId = nextTokenId;
        nextTokenId++;
        _safeMint(_msgSender(), tokenId);

        emit Minted(_msgSender(), tokenId);
    }

    function ownerMint() external onlyOwner {
        require(nextTokenId < mintLimit, "Cannot mint any more.");

        uint256 tokenId = nextTokenId;
        nextTokenId++;
        _safeMint(_msgSender(), tokenId);

        emit Minted(_msgSender(), tokenId);
    }

    function mintable(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        if (privateSale) {
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
                return false;
            if (privateSaleHolders[_msgSender()]) return false;
        }
        return true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        // string memory svg = getSVG(tokenId);
        bytes memory json = abi.encodePacked(
            '{"name": "Collection Timeline Membership #',
            Strings.toString(tokenId),
            '", "description": "',
            description,
            '", "image":"',
            baseUri,
            Strings.toString(tokenId),
            '", "animation_url":"',
            baseUri,
            Strings.toString(tokenId),
            '"}'
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(json)
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
