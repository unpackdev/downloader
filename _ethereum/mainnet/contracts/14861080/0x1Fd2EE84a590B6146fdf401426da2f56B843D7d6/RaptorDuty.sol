//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract RaptorDuty is ERC721, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 2500;

    uint256 public whitelistCost = 0.05 ether;
    uint256 public publicCost = 0.1 ether;
    uint256 public maxPerAddress = 20;
    uint256 public totalSupply = 0;

    bool public paused = false;
    bool public onlyWhitelisted = true;

    string public baseUri;
    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public claimedWhitelist;

    constructor() payable ERC721("Raptor Duty", "NFTASRD") {}

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist!");
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }

    function mint(bytes32[] calldata _merkleProof, uint256 _tokenId) public payable nonReentrant {
        _checkPaused();
        require(_tokenId < MAX_SUPPLY + 1 && _tokenId > 0, "Invalid token ID");

        if (onlyWhitelisted) {
            require(
                _isWhitelisted(msg.sender, _merkleProof),
                "Not a whitelisted user!"
            );
            require(
                claimedWhitelist[msg.sender] < maxPerAddress,
                "Max NFTs per address is claimed!"
            );
            require(msg.value >= whitelistCost, "Insufficient funds!");
            claimedWhitelist[msg.sender] += 1;
        } else {
            require(msg.value >= publicCost, "Insufficient funds!");
        }
        _safeMint(msg.sender, _tokenId);
        totalSupply += 1;
    }

    function giftToken(address _to, uint256 _tokenId) public onlyOwner {
        require(_tokenId < MAX_SUPPLY + 1 && _tokenId > 0, "Invalid token ID");
        _safeMint(_to, _tokenId);
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setWhitelistMerkleRoot(bytes32 _root) public onlyOwner {
        whitelistMerkleRoot = _root;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWhitelistCost(uint256 _price) public onlyOwner {
        whitelistCost = _price;
    }

    function setPublicCost(uint256 _price) public onlyOwner {
        publicCost = _price;
    }

    function setMaxPerAddress(uint256 _val) public onlyOwner {
        maxPerAddress = _val;
    }

    function withdraw() public {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed!");
    }

    function renounceOwnership() public pure override {
        return; // disable renounce ownership ...
    }

    // utils ---
    function _isWhitelisted(address _user, bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_user));

        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid proof!"
        );
        return true;
    }

    function _checkPaused() internal view {
        require(!paused, "Contract is paused!");
    }
}
