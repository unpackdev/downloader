//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./MerkleProofUpgradeable.sol";


contract PixelBadzNFT is Initializable, OwnableUpgradeable, ERC721URIStorageUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    // Merkle Root for proving whitelist address
    bytes32 public merkleRoot;

    bytes32 internal chainLinkKeyHash;

    // Max number of PixelBadz tokens
    uint256 public constant maxTokens = 3333;

    // Starting index to randomise the distribution of tokens
    uint256 public startingIndex;

    // For PixelBadz, it's a free drop
    uint256 public constant whitelistPrice = 0;
    uint256 public constant tokenPrice = 20000000000000000;

    uint256 internal chainLinkFee;

    // Max number of tokens a user can purchase
    uint public constant maxTokenPurchase = 3;

    // Number of whitelisted tokens
    uint public maxWhitelistTokens;
    uint public maxUserTokens;

    // Period where whitelisted accounts are allowed to redeem their tokens
    bool public isRedemptionActive;
    
    // Period where tokens are available to public
    bool public isSaleActive;

    string private _baseURIextended;

    // Provenance IPFS URL to prove original artwork
    string public provenanceUrl;

    string public version;

    mapping(address => uint) public userTokens;

    function initialize(string memory name, string memory symbol)
        public
        initializer
    {
        __Ownable_init_unchained();
        __ERC721URIStorage_init_unchained();
        __ERC721_init_unchained(name, symbol);

        merkleRoot = 0x415ecf5b623aaabd418485b72f6ea85350937d355772b13963df6bcf54bd5f40;
        startingIndex = 0;
        maxWhitelistTokens = 2;
        maxUserTokens = 3;
        isRedemptionActive = false;
        isSaleActive = false;
        provenanceUrl = "";
        version = "1.0";
    }

    function redeemFromWhitelist(uint256 tokenId, bytes32[] calldata proof, uint numberOfTokens)
    external payable
    {
        require(isRedemptionActive, "Not in the redemption period");
        require(_verify(_leaf(msg.sender, tokenId), proof), "Invalid merkle proof");
        require(userTokens[msg.sender] < maxWhitelistTokens, "User has exceeded redemption of whitelisted tokens");
        require(whitelistPrice == msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            if (_tokenIds.current() < maxTokens) {
                userTokens[msg.sender] =  userTokens[msg.sender] + 1;
                _tokenIds.increment();
                uint256 newItemId = _tokenIds.current();
                _safeMint(msg.sender, newItemId);
            }
        }
    }

    function mintToken(uint numberOfTokens) public payable {
        require(isSaleActive, "Not in the sale period");
        require(numberOfTokens <= maxTokenPurchase, "Can only mint 3 tokens at a time");
        require((_tokenIds.current() + numberOfTokens) <= maxTokens, "Purchase would exceed max supply");
        require(tx.origin == msg.sender, "Only owner of the account can redeem");
        require((tokenPrice * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(userTokens[msg.sender] < maxUserTokens, "User has exceeded max tokens");

        for(uint i = 0; i < numberOfTokens; i++) {
            require(userTokens[msg.sender] < maxUserTokens, "User has exceeded max tokens");
            if (_tokenIds.current() < maxTokens) {
                _tokenIds.increment();
                userTokens[msg.sender] =  userTokens[msg.sender] + 1;
                uint256 newItemId = _tokenIds.current();
                _safeMint(msg.sender, newItemId);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorageUpgradeable) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory sequenceId;

        if (startingIndex >= 0) {
            sequenceId = StringsUpgradeable.toString((tokenId + startingIndex) % (maxTokens));
        } else {
            sequenceId = "-1";
        }
        
        return string(abi.encodePacked(baseURI, sequenceId));
    }

    function _leaf(address account, uint256 tokenId)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProofUpgradeable.verify(proof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceUrl = _provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIextended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function toggleRedemption() public onlyOwner {
        isRedemptionActive = !isRedemptionActive;
    }

    function toggleSale() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    // MARK: This should only be called directly as a last resort
    function setStartingIndex(uint index) public onlyOwner{
        startingIndex = index;
    }

    function burn(uint256 tokenId) public onlyOwner {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");
        _burn(tokenId);
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function airdrop(Airdrop[] calldata airdrops)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < airdrops.length; index++) {
            for (uint256 i = 0; i < airdrops[index].count; i++) {
                if (_tokenIds.current() < maxTokens) {
                    _tokenIds.increment();
                    uint256 newItemId = _tokenIds.current();
                    _safeMint(airdrops[index].to, newItemId);
                }
            }
        }
    }

    struct Airdrop {
        address to;
        uint256 count;
    }
}
