///////////////////////////////////////////////////////////////////////////////////////
//  _____ _            _____                  _          _____            _       _  //
// |_   _| |          /  __ \                | |        /  __ \          | |     | | //
//   | | | |__   ___  | /  \/_ __ _   _ _ __ | |_ ___   | /  \/ __ _ _ __| |_ ___| | //
//   | | | '_ \ / _ \ | |   | '__| | | | '_ \| __/ _ \  | |    / _` | '__| __/ _ \ | //
//   | | | | | |  __/ | \__/\ |  | |_| | |_) | || (_) | | \__/\ (_| | |  | ||  __/ | //
//   \_/ |_| |_|\___|  \____/_|   \__, | .__/ \__\___/   \____/\__,_|_|   \__\___|_| //
//                                 __/ | |                                           //
//                                |___/|_|                                           //
///////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract TheCryptoCartel is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _giveawayCounter;

    bytes32 private GIVEAWAY_ROLE = 0x3f17b04901401c5c4cea5f2257556ad05de1da2e2de6282fa9c925cabe359a5c;
    string private BASE_URI = "https://gateway.pinata.cloud/ipfs/QmUuca2AqgctKV3W9ShPUHDndCCZk7xGPUoVxtgRnfCdW6/";
    
    bool private whitelistEnabled = true;
    bool private saleEnabled = true;

    uint8 MINT_LIMIT = 11;

    uint16 SUPPLY_LIMIT = 3501;

    uint256 public constant PRICE_PER_TOKEN = 0.069 ether;

    address t87 = 0xA665Af5AF9e485B6b496D43844e018fBE24DBe6d;
    address t10 = 0xC6521BAfD305FCa9205bC7c046634AA9f5B45303;
    address t3 = 0x7Bf4209cF7C38Bad15C3531A9291A6345F1a7b3b;

    constructor() ERC721("The Crypto Cartel", "TCC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GIVEAWAY_ROLE, msg.sender);
        _grantRole(GIVEAWAY_ROLE, t87);
    }

    function toggleWhitelistStatus(bool whitelistStatus) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistEnabled = whitelistStatus;
    }

    function toggleSaleStatus(bool saleStatus) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleEnabled = saleStatus;
    }

    // Implemented to change base URI in scenarios like revealing whitelisted tokens
    function setBaseUri(string memory _baseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BASE_URI = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function mint(uint256 numberOfTokens, bytes32[] calldata proof, bytes32 merkleRoot) public payable {
        uint256 ts = totalSupply();

        require(ts + numberOfTokens < SUPPLY_LIMIT, "Reached max limit. No more minting possible!");
        require(saleEnabled, "Sale is not enabled");
        if(whitelistEnabled) {
            require(balanceOf(msg.sender) + numberOfTokens < 11, "You have reached the limit for whitelist" );
            require(_verify(_leaf(msg.sender), proof, merkleRoot), "Not a whitelisted member!");
        } else {
            require(numberOfTokens < MINT_LIMIT, "Cannot mint more than 5 cartels per transaction!");
            require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether amount sent is not correct");
        }
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function giveAwayMint(uint256 numberOfTokens, address mintAddress)  public onlyRole(DEFAULT_ADMIN_ROLE) onlyRole(GIVEAWAY_ROLE) {
        uint256 ts = totalSupply();
        require(ts + numberOfTokens < SUPPLY_LIMIT, "Reached max limit. No more minting possible!");
        require(_giveawayCounter.current() + numberOfTokens < 121, "max limit for giveaway reached");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _giveawayCounter.increment();
            _safeMint(mintAddress, tokenId);
        }
    }

    receive() external payable {}

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        uint256 t_87 = balance * 87 /100;
        uint256 t_10 = balance * 10 /100;
        uint256 t_3 = balance * 3 /100;
        payable(t87).transfer(t_87);
        payable(t10).transfer(t_10);
        payable(t3).transfer(t_3);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token URI query for nonexistent token!");
        // We can return BASE_URI + tokenId.json here but that would mean tokenId 1 should have
        // return super.tokenURI(tokenId);
        return string(abi.encodePacked(BASE_URI, Strings.toString(tokenId), ".json"));
        
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** ---------------- Merkle tree whitelisting ---------------- */
    // Generate the leaf node (just the hash of tokenID concatenated with the account address)
    function _leaf(address account) internal pure returns (bytes32) {
            return keccak256(abi.encodePacked(account));
    }
    // Verify that a given leaf is in the tree.
    function _verify(bytes32 _leafNode, bytes32[] memory proof, bytes32 merkleRoot) internal view returns (bool) {
            return MerkleProof.verify(proof, merkleRoot, _leafNode);
    }
}