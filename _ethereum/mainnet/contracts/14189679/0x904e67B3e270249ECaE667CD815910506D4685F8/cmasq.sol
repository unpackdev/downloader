// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

contract CMasq is Ownable, ERC721A, EIP712 {
    using Strings for uint256;
    uint256 public constant MAX_TOKENS = 3333;
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public price = 0.05 ether;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    mapping(address => uint256) private _presaleMints;
    uint256 public presaleMaxPerWallet = 10;
    address public issuer;
    string public baseURI = "";

    bytes32 private immutable _CHAIN_CLAIM_TYPEHASH =
    keccak256("Claim(address chainedAddress,uint tokens)");

    constructor()
    ERC721A("Crypto Masquerade", "c-masq")
    EIP712("c-masq", "1")
    {
        issuer = owner();
    }

    // admin functions
    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (0.01 ether);
    }

    function setIssuer(address _issuer) external onlyOwner {
        issuer = _issuer;
    }

    function setPresaleMaxPerWallet(uint256 _newPresaleMaxPerWallet) external onlyOwner {
        presaleMaxPerWallet = _newPresaleMaxPerWallet;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(_exists(tokenId)) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        } else {
            return string(abi.encodePacked(baseURI, "null.json"));
        }
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "CMasq: Public sale has not started");
        require(tokens <= MAX_PER_MINT, "CMasq: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "CMasq: Minting would exceed max supply");
        require(tokens > 0, "CMasq: Must mint at least one token");
        require(price * tokens == msg.value, "CMasq: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "CMasq: Minting would exceed max supply");
        require(tokens > 0, "CMasq: Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// @notice On chain generation for a valid EIP-712 hash
    /// @param chainedAddress the address that has been signed
    /// @return The typed data hash
    function genDataHash(address chainedAddress, uint256 tokens) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(_CHAIN_CLAIM_TYPEHASH, chainedAddress, tokens)
        );

        return _hashTypedDataV4(structHash);
    }

    /// @notice Signer must match ISSUER
    /// @param issuedAddress the address that has been signed,
    /// this address must match the claim code private key
    /// @param v split signature v
    /// @param r split signature r
    /// @param s split signature s
    /// @return True if signature is valid and signer matches issuer
    function isValidIssuerSig(
        address issuedAddress,
        uint256 tokens,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = genDataHash(issuedAddress, tokens);
        address signer = ECDSA.recover(hash, v, r, s);
        return signer == issuer;
    }

    /// @notice Claim presale with signature by issuer
    /// @param issuedAddress address that has been signed by issuer
    //  @param tokens number to be mint
    /// @param v split signature v
    /// @param r split signature r
    /// @param s split signature s
    function claimPresale(
        address issuedAddress,
        uint256 tokens,
        uint8  v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(presaleStarted, "CMasq: Presale has not started");
        require(_presaleMints[issuedAddress] + tokens <= presaleMaxPerWallet, "CMasq: Cannot claim more for destination address");
        require(totalSupply() + tokens <= MAX_TOKENS, "CMasq: Minting would exceed max supply");
        require(msg.value == price * tokens, "CMasq: ETH amount is incorrect");
        require(isValidIssuerSig(issuedAddress, tokens, v, r, s), "CMasq: Invalid issuer signature");

        _presaleMints[issuedAddress] += tokens;
        _safeMint(issuedAddress, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "CMasq: Insufficent balance");
        payable(owner()).transfer(balance);
    }

}
