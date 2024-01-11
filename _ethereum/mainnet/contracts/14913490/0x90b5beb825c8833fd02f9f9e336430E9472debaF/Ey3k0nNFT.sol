// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ECDSA.sol";

contract Ey3k0nNFT is Initializable, OwnableUpgradeable, ERC721Upgradeable, ERC2981Upgradeable {
    using ECDSA for bytes32;

    address public signerAddress;
    address public developerAddress;
    uint256 public price;
    uint256 public maxSupply;
    uint256 public teamMaxSupply;
    uint256 public maxTokensPerWallet;
    uint256 public expirationTimestamp;
    uint256 public teamLastTokenId;
    uint256 public lastTokenId;

    mapping(address => uint256) public tokensMinted;

    event SignerUpdated(address oldSignerAddress, address newSignerAddress);
    event DeveloperUpdated(address oldDeveloperAddress, address newDeveloperAddress);
    event MaxSupplyUpdated(uint256 oldMaxSupply, uint256 newMaxSupply);
    event MaxTokensPerWalletUpdated(uint256 oldMaxTokensPerWallet, uint256 newMaxTokensPerWallet);
    event ExpirationTimestampUpdated(
        uint256 oldExpirationTimestamp,
        uint256 newExpirationTimestamp
    );
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    // variable and public getter for the baseURI of this collection
    string public baseURI;
    address public newClaimableOwner;

    /**
     * @dev Throws if called by any account other than the owner or developer.
     */
    modifier onlyOwnerOrDeveloper() {
        require(owner() == _msgSender() || developerAddress == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function initialize(
        address _ownerAddress,
        address _signerAddress,
        address _developerAddress,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _teamMaxSupply,
        uint256 _maxTokensPerWallet
    ) external initializer {
        __ERC721_init("Ey3k0n", "Ey3");
        __Ownable_init();

        // Royalty Standard Interface
        __ERC2981_init();

        signerAddress = _signerAddress;
        developerAddress = _developerAddress;
        price = _price;
        maxSupply = _maxSupply;
        teamMaxSupply = _teamMaxSupply;
        maxTokensPerWallet = _maxTokensPerWallet;

        lastTokenId = teamMaxSupply;

        transferOwnership(_ownerAddress);
    }

    function updateSignerAddress(address _signerAddress) external onlyOwner {
        emit SignerUpdated(signerAddress, _signerAddress);
        signerAddress = _signerAddress;
    }

    function updateDeveloperAddress(address _developerAddress) external onlyOwner {
        emit DeveloperUpdated(developerAddress, _developerAddress);
        developerAddress = _developerAddress;
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        emit MaxSupplyUpdated(maxSupply, _maxSupply);
        maxSupply = _maxSupply;
    }

    function updateMaxTokensPerWallet(uint256 _maxTokensPerWallet) external onlyOwner {
        emit MaxTokensPerWalletUpdated(maxTokensPerWallet, _maxTokensPerWallet);
        maxTokensPerWallet = _maxTokensPerWallet;
    }

    function updateExpirationTimestamp(uint256 _expirationTimestamp) external onlyOwnerOrDeveloper {
        emit ExpirationTimestampUpdated(expirationTimestamp, _expirationTimestamp);
        expirationTimestamp = _expirationTimestamp;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        emit PriceUpdated(price, _price);
        price = _price;
    }

    function mint(
        uint256 _issued,
        uint256 _expiration,
        uint256 _numTokens,
        bytes calldata signature
    ) external payable {
        require(_issued > expirationTimestamp, "Signature too old");
        require(_expiration > block.timestamp, "Signature expired");
        require(msg.value >= price * _numTokens, "Not enough ether to purchase NFTs.");
        require(
            maxSupply >= lastTokenId + _numTokens,
            "Minted tokens would exceed supply."
        );
        require(
            maxTokensPerWallet >= tokensMinted[msg.sender] + _numTokens,
            "Claim limit exceeded."
        );

        bytes32 _messageHash = keccak256(abi.encodePacked(msg.sender, _issued, _expiration));

        require(
            signerAddress == _messageHash.toEthSignedMessageHash().recover(signature),
            "Signer address mismatch."
        );

        tokensMinted[msg.sender] += _numTokens;

        uint256 i;
        for (; i < _numTokens; i++) {
            lastTokenId++;
            _safeMint(msg.sender, lastTokenId);
        }
    }

    function mintTeam(address _receiver, uint256 _numTokens) external onlyOwner {
        require(
            teamMaxSupply >= teamLastTokenId + _numTokens,
            "Minted tokens would exceed team supply."
        );

        uint256 i;
        for (; i < _numTokens; i++) {
            teamLastTokenId++;
            _safeMint(_receiver, teamLastTokenId);
        }
    }

    function mintGiveAway(address _receiver, uint256 _numTokens) external onlyOwner {
        require(
            maxSupply >= lastTokenId + _numTokens,
            "Minted tokens would exceed supply."
        );

        uint256 i;
        for (; i < _numTokens; i++) {
            lastTokenId++;
            _safeMint(_receiver, lastTokenId);
        }
    }

    function withdraw(address _receiver) public payable onlyOwner {
        uint _balance = address(this).balance;
        require(_balance > 0, "No ether left to withdraw");

        (bool _success,) = _receiver.call{value : _balance}("");
        require(_success, "Transfer failed.");
    }

    // Implements the base abstract file that returns an empty string
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // sets the baseURI value to be returned by _baseURI() & tokenURI() methods.
    function setBaseURI(string memory newBaseURI) public virtual onlyOwnerOrDeveloper {
        baseURI = newBaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiverAddress, uint96 feeNumerator) public virtual onlyOwner {
        _setDefaultRoyalty(receiverAddress, feeNumerator);
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public virtual onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) public virtual onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        newClaimableOwner = newOwner;
    }

    function claimOwnership() public virtual {
        require(msg.sender == newClaimableOwner, "Ownable: newClaimableOwner is not msg.sender");
        _transferOwnership(newClaimableOwner);
    }
}
