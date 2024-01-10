// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";


/**
 * Used to delegate ownership of a contract to another address,
 * to save on unneeded transactions to approve contract use for users
 */
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BasedVitalik is ERC721A, Ownable {
    using SafeMath for uint256;

    // Keep mapping of proxy accounts for easy listing
    mapping(address => bool) public proxyApproved;

    // Keep mapping of whitelist mints to prevent abuse
    mapping(address => uint256) public earlyAccessMinted;

    // Define starting contract state
    bytes32 public merkleRoot;
    bool public merkleSet = false;
    bool public earlyAccessMode = true;
    bool public mintingIsActive = false;
    bool public reservedVitaliks = false;
    bool public placeholderMeta = true;
    uint256 public salePrice = 0.03 ether;
    uint256 public constant maxSupply = 4962;
    uint256 public constant maxMints = 30;
    address public immutable proxyRegistryAddress;
    string public baseURI;
    string public _contractURI;

    constructor(address _proxyRegistryAddress) ERC721A("Based Vitalik", "BV") {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // Show contract URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Flip the minting from active or pause
    function toggleMinting() external onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    // Flip the early access mode to allow/disallow public minting vs whitelist minting
    function toggleEarlyAccessMode() external onlyOwner {
        earlyAccessMode = !earlyAccessMode;
    }

    // Flip the placeholder metadata URI to global or per token
    function togglePlaceholder() external onlyOwner {
        placeholderMeta = !placeholderMeta;
    }

    // Flip the proxy approval state
    function toggleProxyState(address proxyAddress) external onlyOwner {
        proxyApproved[proxyAddress] = !proxyApproved[proxyAddress];
    }

    // Specify a new IPFS URI for metadata
    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    // Specify a new contract URI
    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    // Update sale price if needed
    function setSalePrice(uint256 _newPrice) external onlyOwner {
        salePrice = _newPrice;
    }

    // Specify a merkle root hash from the gathered k/v dictionary of
    // addresses and their claimable amount of tokens - thanks Kiwi!
    // https://github.com/0xKiwi/go-merkle-distributor
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        merkleSet = true;
    }

    // Reserve some vitaliks for giveaways
    function reserveVitaliks() external onlyOwner {
        // Only allow one-time reservation of 40 tokens
        if (!reservedVitaliks) {
            _mintVitaliks(40);
            reservedVitaliks = true;
        }
    }

    // Internal mint function
    function _mintVitaliks(uint256 numberOfTokens) private {
        require(numberOfTokens > 0, "Must mint at least 1 token");

        // Mint number of tokens requested
        _safeMint(msg.sender, numberOfTokens);

        // Update tally if in early access mode
        if (earlyAccessMode) {
            earlyAccessMinted[msg.sender] = earlyAccessMinted[msg.sender].add(numberOfTokens);
        }

        // Disable minting if max supply of tokens is reached
        if (totalSupply() == maxSupply) {
            mintingIsActive = false;
        }
    }

    // Purchase and mint
    function mintVitaliks(
      uint256 index,
      address account,
      uint256 whitelistedAmount,
      bytes32[] calldata merkleProof,
      uint256 numberOfTokens
    ) external payable {
        require(mintingIsActive, "Minting is not active.");
        require(msg.value == numberOfTokens.mul(salePrice), "Incorrect Ether supplied for the number of tokens requested.");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply.");

        if (earlyAccessMode) {
            require(merkleSet, "Merkle root not set by contract owner.");
            require(msg.sender == account, "Can only be claimed by the whitelisted address.");
            // Verify merkle proof
            bytes32 node = keccak256(abi.encodePacked(index, account, whitelistedAmount));
            require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid merkle proof.");
            require(earlyAccessMinted[msg.sender].add(numberOfTokens) <= whitelistedAmount, "Cannot exceed amount whitelisted during early access mode.");
        } else {
            require(numberOfTokens <= maxMints, "Cannot mint more than 30 per tx during public sale.");
        }

        _mintVitaliks(numberOfTokens);
    }

    /*
     * Override the below functions from parent contracts
     */

    // Always return tokenURI, even if token doesn't exist yet
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (placeholderMeta) {
            return string(abi.encodePacked(baseURI));
        } else {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        }
    }

    // Whitelist proxy contracts for easy trading on platforms (Opensea is default)
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721A)
        returns (bool isOperator)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator || proxyApproved[_operator]) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}
