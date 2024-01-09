// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.4;

import "./ERC721Tradable.sol";
import "./VRFConsumerBase.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract CTR10000 is ERC721Tradable, VRFConsumerBase {
    using SafeMath for uint256;

    using Counters for Counters.Counter;
 
    enum Status { Deployed, ProvenanceReceived, StartingIndexReceived, MintingCompleted, MetadataFrozen }

    uint16 public constant maxSupply = 10000;

    string internal tokenMutableMetadataURI;
    string internal tokenPermanentMetadataURI;

    function baseTokenURI() override public view returns (string memory) {
        if (currentStatus() == Status.MetadataFrozen) {
            return tokenPermanentMetadataURI;
        }

        return tokenMutableMetadataURI;
    }

    string public contractMetadataURI;

    function setContractMetadata(string memory _contractMetadataURI) public onlyOwner {
        contractMetadataURI = _contractMetadataURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function currentStatus() public view returns (Status) {
        if (bytes(tokenPermanentMetadataURI).length != 0) {
            return Status.MetadataFrozen;
        }

        if (totalSupply() >= maxSupply) {
            return Status.MintingCompleted;
        }

        if (startingIndex != 0) {
            return Status.StartingIndexReceived;
        }

        if (bytes(provenanceCID).length != 0) {
            return Status.ProvenanceReceived;
        }
        
        return Status.Deployed;
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenMutableMetadataURI,
        address _proxyRegistry,
        address _vrfCoordinator,
        address _linkToken,
        address _ctrSigner,
        uint256 _linkFee,
        bytes32 _linkKeyHash
    )
        ERC721Tradable(_tokenName, _tokenSymbol, _proxyRegistry)
        VRFConsumerBase(
            _vrfCoordinator,
            _linkToken
        )
    {
        ctrSigner = _ctrSigner;
        linkFee = _linkFee;
        linkKeyHash = _linkKeyHash;
        tokenMutableMetadataURI = _tokenMutableMetadataURI;
    }

    string public provenanceCID;

    function setProvenance(string memory _provenanceCID) public onlyOwner {
        require(currentStatus() == Status.Deployed);

        provenanceCID = _provenanceCID;
    }

    function provenanceURI() public view returns (string memory) {
        if (currentStatus() == Status.MintingCompleted || currentStatus() == Status.MetadataFrozen) {
            return string(abi.encodePacked("ipfs://", bytes(provenanceCID)));
        } else {
            return provenanceCID;
        }
    }

    uint256 internal linkFee;
    bytes32 internal linkKeyHash;

    function requestStartingIndex() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= linkFee);

        return requestRandomness(linkKeyHash, linkFee);
    }

    uint256 public startingIndex;

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(currentStatus() == Status.ProvenanceReceived);
        
        startingIndex = randomness % maxSupply;
    }

    mapping (uint256 => address) public creatorOf;

    uint16 public creatorRoyaltyInHundredthPercent;

    function setRoyalty(uint16 royalty) public onlyOwner {
        creatorRoyaltyInHundredthPercent = royalty;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        uint256 creatorRoyalty = salePrice.mul(creatorRoyaltyInHundredthPercent).div(10000);
        
        return (creatorOf[tokenId], creatorRoyalty);
    }

    address internal ctrSigner;

    function mint(bytes memory ctrSignature) public {
        require(currentStatus() == Status.StartingIndexReceived);

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, balanceOf(msg.sender)));

        address recoveredSigner = ECDSA.recover(
            messageHash,
            ctrSignature
        );

        require(recoveredSigner == ctrSigner);

        uint256 currentTokenId = _nextTokenId.current();

        _nextTokenId.increment();

        _safeMint(msg.sender, currentTokenId);

        creatorOf[currentTokenId] = msg.sender;
    }

    function freezeMetadata(string memory _tokenPermanentMetadataURI) public onlyOwner {
        require(currentStatus() == Status.MintingCompleted);

        tokenPermanentMetadataURI = _tokenPermanentMetadataURI;
    }
}