// SPDX-License-Identifier: MIT

// Import necessary libraries and contracts
pragma solidity ^0.8.21;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";


contract DarwinPunks is ERC721, Pausable, Ownable {
    // Price to mint an NFT
    uint256 public mintPrice = 0.0 ether;

    // Base URI for metadata stored on IPFS. The base URI in this contract can be updated by contract owner, but the contract owner cannot remove the metadata content (that the prior base URI pointed to) from IPFS
    string public metadataBaseURI = "ipfs://bafybeigw5rla7tthisg6bf6fvzvw3ricvjogymi4sjgbrbbnrm6mgfbque/";

    // The Ethereum address of the whitelist signer (derived from private key in lambda function) - can be updated by contract owner
    address private signer = 0xFA72c6B96515e98Eadb9420EE4bedbc54088D30b; // Public Address Signer for whitelist filtering

    // The first NFT is minted with an ID numeral of 0
    uint256 private nextID = 0;

    // Maximum number of NFTs that can be minted in one transaction, and acts to limit the cumulative number of NFTs that can be minted by a single user. Updatable via setMaxMint()
    uint256 public maxMint = 1;

    // The soft limit for the total number of NFTs that can be minted. The softTokenLimit can be increased, but NOT decreased (thus increases are irreversable). This increasable-only soft limit allows community growth to be gradual, while still being constrained by the hardTokenLimit. NB: Do not initialise with a value less than 100
    uint256 public softTokenLimit = 200;

    // The upper limit for the total number of NFTs that can be minted. The hardTokenLimit can be decreased, but NOT increased (thus decreases are irreversable). This decreasable-only upper limit allows the community to, if desired, permanently limit the total number of tokens to less than the initial value of 10,000
    uint256 public hardTokenLimit = 10000;

    // The percentage, relative to the current total limit, of tokens the contract owner can mint. Initial value of 12 results in a limit of 12% (10% owner stake + 2% giveaways). The ownerPercLimit can be decreased (irreversably), but NOT increased. Do not initialise with a value less than 1
    uint256 public ownerPercLimit = 12;

    // How many tokens the contract owner has minted
    uint256 public ownerMintedCount;

    // Mapping to track used nonces to prevent replay attacks
    mapping(string => bool) private usedNonces;

    // Mapping to track how many NFTs each address has minted
    mapping(address => uint256) private mintedAddresses;

    // Constructor function to initialize contract and set the name and symbol for the NFT
    constructor() ERC721("DarwinPunks", "DARP") {}

    // Function to mint new NFTs. Requires a signature from the signer and payment of the minting fee (if the minting fee is > 0). If this contract is paused, then minting is paused
    function buy(bytes32 _hash, bytes memory _signature, string memory _nonce, uint256 _amount) external payable whenNotPaused {
        // Generate a hash from the sender's address, the amount of NFTs to be minted, and the nonce
        bytes32 _checkHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(msg.sender, _amount, _nonce))));

        // Check that the signature is valid, the nonce hasn't been used before, and the hash matches the expected value
        require(ECDSA.recover(_hash, _signature) == signer, "NON_WHITELISTED_ADDRESS");
        require(!usedNonces[_nonce], "HASH_USED");
        require(_hash == _checkHash, "INVALID_HASH");

        // Check that the address hasn't exceeded the max mint limit, the payment is sufficient, and the total supply limits haven't been reached
        require((mintedAddresses[msg.sender] + _amount) <= maxMint, "MAX_MINT_PER_ADDRESS_REACHED");
        require((mintPrice * _amount) <= msg.value, "INSUFFICIENT_ETH");
        require((nextID + _amount) <= softTokenLimit, "SOFT_TOKEN_LIMIT_REACHED");
        require((nextID + _amount) <= hardTokenLimit, "ALL_TOKENS_MINTED");

        // Mint the NFTs and update the next ID and the number of NFTs minted by the address
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, nextID);
            nextID++;
            mintedAddresses[msg.sender]++;
        }

        // Mark the nonce as used
        usedNonces[_nonce] = true;
    }

    // Function to mint NFTs as the owner. Can be used to mint NFTs without a signature or payment
    function ownerBatchMint(uint256 _amount) external onlyOwner {
        // Check that the total supply limits haven't been reached
        require((nextID + _amount) <= softTokenLimit, "SOFT_TOKEN_LIMIT_REACHED");
        require((nextID + _amount) <= hardTokenLimit, "ALL_TOKENS_MINTED");

        // Ensure the contract owner can never mint a greater percentage than ownerPercLimit/100 of the total number of currently mintable tokens. This requirement will always trigger if (softTokenLimit * ownerPercLimit) < 100
        require((ownerMintedCount + _amount) <= (softTokenLimit * ownerPercLimit) / 100, "OWNER_MINT_LIMIT_REACHED");

        // Mint the NFTs and update the next ID and the owner minted count
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, nextID);
            nextID++;
            ownerMintedCount++;
        }
    }

    // Function to withdraw the contract's Ether balance to the owner's address
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Functions to update contract parameters. Can only be called by the owner
    function setSignerAddress(address addr) external onlyOwner {
        signer = addr;
    }
    function setMaxMint(uint256 _newMaxMint) external onlyOwner {
        require(_newMaxMint <= softTokenLimit, "MINT_CANNOT_EXCEED_SOFT_TOKEN_LIMIT");
        maxMint = _newMaxMint;
    }
    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }

    // Function to increase the softTokenLimit. This limit allows community growth to be gradual. The softTokenLimit can only be increased, thus increases to softTokenLimit are non-reversable
    function increaseSoftTokenLimit(uint256 _newSoftTokenLimit) external onlyOwner {
      require(_newSoftTokenLimit > softTokenLimit, "SOFT_LIMIT_INCREASE_ONLY");
      require(_newSoftTokenLimit <= hardTokenLimit, "SOFT_LIMIT_CANNOT_EXCEED_UPPER_LIMIT");
       softTokenLimit = _newSoftTokenLimit;
    }

    // Function to decrease the hardTokenLimit. The hardTokenLimit can only be decreased, thus decreases to hardTokenLimit are non-reversable. This limit allows the community to, if desired, permanently limit the total number of tokens to less than the initial value of 10,000
    function decreaseHardTokenLimit(uint256 _newHardTokenLimit) external onlyOwner {
        require(_newHardTokenLimit < hardTokenLimit, "UPPER_LIMIT_DECREASE_ONLY");
        hardTokenLimit = _newHardTokenLimit;
    }

    // Function to decrease the ownerPercLimit. The ownerPercLimit can only be decreased, thus decreases to ownerPercLimit are non-reversable
    function decreaseOwnerPercLimit(uint256 _newOwnerPercLimit) external onlyOwner {
        require(_newOwnerPercLimit < ownerPercLimit, "OWNER_PERC_LIMIT_DECREASE_ONLY");
        ownerPercLimit = _newOwnerPercLimit;
    }

    // Functions to pause and unpause the contract. Can only be called by the owner. This will pause minting for non-owner users (via the buy function)
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    // Function to update the base URI for metadata. Can only be called by the owner
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        metadataBaseURI = newBaseURI;
    }

    // Function to return the base URI for metadata
    function _baseURI() internal view virtual override returns (string memory) {
     return metadataBaseURI;
    }
}
