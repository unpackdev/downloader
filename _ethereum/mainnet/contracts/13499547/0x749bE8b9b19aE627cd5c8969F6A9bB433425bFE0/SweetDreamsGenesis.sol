//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract SweetDreamsGenesis is ERC721Enumerable, Ownable, VRFConsumerBase {

    uint16 public constant MAX_DREAMS_RESERVED = 11;
    uint16 public constant MAX_DREAMS_FOR_MINT = 101;
    uint16 public constant MAX_SUPPLY = MAX_DREAMS_RESERVED + MAX_DREAMS_FOR_MINT;

    bytes32 public immutable VRF_KEY_HASH;
    uint256 public immutable VRF_FEE;

    bytes32 public randomnessRequestId1;
    bytes32 public randomnessRequestId2;
    uint256 public rng1;
    uint256 public rng2;
    string public provenanceHash;
    string public baseURI;
    address payable public treasury;
    uint256 public tokenPrice;
    bool public isMintingOpen = false;
    bool public isMintingWhitelistOnly = false;
    mapping(address => bool) public isWhitelisted;

    event MintingStateChanged(bool isOpen, bool isWhitelistOnly);
    event Minted(address minter, uint256 id);
    event BaseURIChanged(string baseURI);
    event ProvenanceHashChanged(string provenanceHash);
    event TreasuryChanged(address treasury);
    event TokenPriceChanged(uint256 tokenPrice);
    event RandomnessRequested(bytes32 randomnessRequestId);

    constructor(
        bytes32 VRF_KEY_HASH_,
        uint256 VRF_FEE_,
        address VRF_COORDINATOR_,
        address LINK_TOKEN_
    )
        ERC721("SDG", "Sweet Dreams: Genesis")
        VRFConsumerBase(VRF_COORDINATOR_, LINK_TOKEN_)
    {
        VRF_KEY_HASH = VRF_KEY_HASH_;
        VRF_FEE = VRF_FEE_;
    }

    function setMintingState(bool isOpen, bool isWhitelistOnly) external onlyOwner {
        isMintingOpen = isOpen;
        isMintingWhitelistOnly = isWhitelistOnly;
        emit MintingStateChanged(isOpen, isWhitelistOnly);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setTreasury(address payable treasury_) external onlyOwner {
        treasury = treasury_;
        emit TreasuryChanged(treasury);
    }

    function setTokenPrice(uint256 tokenPrice_) external onlyOwner {
        tokenPrice = tokenPrice_;
        emit TokenPriceChanged(tokenPrice);
    }

    function setProvenanceHash(string calldata provenanceHash_) external onlyOwner {
        provenanceHash = provenanceHash_;
        emit ProvenanceHashChanged(provenanceHash);
    }

    function addToWhitelist(address[] calldata toWhitelist) external onlyOwner {
        for (uint256 i = 0; i < toWhitelist.length; i++) {
            isWhitelisted[toWhitelist[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata toRemove) external onlyOwner {
        for (uint256 i = 0; i < toRemove.length; i++) {
            isWhitelisted[toRemove[i]] = false;
        }
    }

    function reserveBeforeMint() external onlyOwner {
        uint256 nextTokenId = totalSupply();
        require(treasury != address(0), "Treasury not set");
        require(nextTokenId == 0, "Cannot reserve tokens after minting started");

        for (uint i = 0; i < MAX_DREAMS_RESERVED; i++) {
            _safeMint(treasury, nextTokenId + i);
            emit Minted(msg.sender, nextTokenId + i);
        }
    }

    function mint() external payable {
        uint256 nextTokenId = totalSupply();
        require(tx.origin == msg.sender, "Minter must be EOA");
        require(nextTokenId < MAX_SUPPLY, "Max supply reached");
        require(bytes(provenanceHash).length != 0, "Provenance hash must be set");
        require(treasury != address(0), "Treasury must be set");
        require(tokenPrice > 0, "Token price must be set");
        require(tokenPrice == msg.value, "Incorrect Ether value sent");
        require(isMintingOpen, "Minting is closed");

        if (isMintingWhitelistOnly) {
            require(isWhitelisted[msg.sender], "Minter must be whitelisted");
        }

        _safeMint(msg.sender, nextTokenId);
        emit Minted(msg.sender, nextTokenId);
        nextTokenId++;

        treasury.transfer(msg.value);
    }

    function revealMetadata() external onlyOwner {
        require(LINK.balanceOf(address(this)) >= VRF_FEE, "Not enough LINK");

        if (randomnessRequestId1 == "") {
            randomnessRequestId1 = requestRandomness(VRF_KEY_HASH, VRF_FEE);
            emit RandomnessRequested(randomnessRequestId1);
        } else if (randomnessRequestId2 == "") {
            randomnessRequestId2 = requestRandomness(VRF_KEY_HASH, VRF_FEE);
            emit RandomnessRequested(randomnessRequestId2);
        } else {
            revert("Already revealed");
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (requestId == randomnessRequestId1) {
            rng1 = randomness % MAX_DREAMS_RESERVED + 1;
        } else if (requestId == randomnessRequestId2) {
            rng2 = randomness % MAX_DREAMS_RESERVED + 1;
        } else {
            revert("Bad Request");
        }

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // [0;4[ -> revealed from the beginning for bids
        if (tokenId < 4) {
            return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
        }
        // [4;MAX_SUPPLY[ -> hidden until reveal
        if (rng1 == 0 || rng2 == 0) {
            return string(abi.encodePacked(_baseURI(), "placeholder"));
        }
        // [4;MAX_DREAMS_RESERVED[ -> reserved tokens
        if (tokenId < MAX_DREAMS_RESERVED) {
            return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
        }

        // [MAX_DREAMS_RESERVED;MAX_SUPPLY-1] -> minted tokens
        uint256 rawIndex = ((tokenId - MAX_DREAMS_RESERVED) * rng1 + rng2) % MAX_DREAMS_FOR_MINT + MAX_DREAMS_RESERVED;

        return string(abi.encodePacked(_baseURI(), Strings.toString(rawIndex)));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}
