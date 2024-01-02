// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Strings.sol";
import "./Ownable2Step.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";
import "./MessageHashUtils.sol";

/**
 * @title TWLMysteryBox
 */
contract TWLMysteryBox is Ownable2Step, ERC721A("TWL Mystery Box", "TWLMB") {
    using Strings for uint256;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // A record of states for signing/validating signatures in the contract.
    mapping(address => bool) public hasClaimed;
    // A record of nonces for signing/validating signatures in the contract.
    mapping(address => uint256) private nonces;
    // Keeps track of the number of tokens minted
    uint256 public currentTokenId = 1;
    // An address for authorizing claims.
    address public trustedSigner;
    // An address for receiving funds.
    address payable public fundsReceiver;
    // If true, then the NFTs can only be transferred to/from the zero address.
    bool public soulbound = true;
    // If true, then the contract is paused.
    bool public paused;

    // Events
    event MysteryBoxClaimed(
        address indexed recipient,
        uint256 tier,
        uint256 startTokenId,
        uint256 endTokenId
    );

    // Custom errors to provide clarity during failure conditions
    error InvalidTokenId();

    // The base URI for the token metadata.
    string private _contractURI = "https://theworldslargest.com/api/nft/sperm-game/metadata";
    // The base URI for the token metadata.
    string private _nftURI = "https://theworldslargest.com/api/nft/sperm-game/";

    constructor() Ownable(msg.sender) {
        trustedSigner = msg.sender;
    }

    function claimMysteryBox(uint256 userNonce, bytes memory signature, uint256 tier) public payable {
        // Check if the contract is paused. If so, revert.
        require(!paused, "Contract is paused");
        // Check if the user sent enough ETH. If not, revert.
        require(msg.value == 0.003 ether, "Invalid ETH amount");
        // Check if user is eligible to claim. If not, revert.
        require(isEligibleToClaim(msg.sender), "Can only claim one mystery box per account");
        // Check if signature is valid. If not, revert.
        require(isValidSignature(msg.sender, userNonce, tier, signature), "Invalid signature");
        // Increment the user's nonce.
        nonces[msg.sender]++;
        // Mark the user as having claimed.
        hasClaimed[msg.sender] = true;
        // Mint 7 NFTs.
        _mint(msg.sender, 7);
        // Assign initial metadata
        emit MysteryBoxClaimed(
            msg.sender,
            // tier, if the user has a TWL Trailer NFT, then they get a rarity boost.
            tier,
            // startTokenId, the first token ID of the 7 NFTs that were minted.
            currentTokenId,
            // endTokenId, the last token ID of the 7 NFTs that were minted.
            currentTokenId + 6
        );
        // Increment the currentTokenId by 7.
        currentTokenId += 7;
        // Transfer
        (bool success,) = fundsReceiver.call{value: msg.value, gas: gasleft()}("");
        require(success, "recipient reverted");
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setSoulbound(bool _soulbound) public onlyOwner {
        soulbound = _soulbound;
    }

    function setTrustedSigner(address _trustedSigner) public onlyOwner {
        require(_trustedSigner != address(0), "Trusted signer cannot be zero address");
        trustedSigner = _trustedSigner;
    }

    function setFundsReceiver(address payable _fundsReceiver) public onlyOwner {
        require(_fundsReceiver != address(0), "Funds receiver address cannot be zero address");
        fundsReceiver = _fundsReceiver;
    }

    // Make the NFTs soulbound; if soulbound is true, then the NFTs can only be transferred to/from the zero address.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (soulbound) {
            require(from == address(0) || to == address(0), "NFTs are soulbound");
        }
    }

    /**
    * @notice Allows the owner to set a new base URI.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _nftURI = newBaseURI;
    }

    function baseURI() external view returns (string memory) {
        return _nftURI;
    }

    function _baseURI() internal override view returns (string memory) {
        return _nftURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId == 0 || tokenId > currentTokenId) {
            revert InvalidTokenId();
        }

        return string(abi.encodePacked(_nftURI, tokenId.toString()));
    }

    // Allows the owner to withdraw funds from the contract.
    function withdraw() public onlyOwner {
        // Require that the fundsReceiver is set.
        require(fundsReceiver != address(0), "Funds receiver address not set");
        // Send the entire balance to the fundsReceiver.
        (bool success,) = fundsReceiver.call{value: address(this).balance, gas: gasleft()}("");
        require(success, "recipient reverted");
    }

    function isEligibleToClaim(address user) public view returns (bool) {
        return !hasClaimed[user];
    }

    function isValidSignature(address user, uint256 userNonce, uint256 tier, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user, userNonce, tier));
        bytes32 signedHash = messageHash.toEthSignedMessageHash();
        return signedHash.recover(signature) == trustedSigner;
    }

    // Allows the contract to receive ether.
    receive() external payable {}
}
