// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////////////////
//                                                                //
//                       ..................                       //
//         ...-----================================----..         //
//    .--===@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@==-.    //
//   -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-   //
//   -@=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-   //
//    -@===----.......                         .......---===@@@-  //
//    .          .........----------------.......            .    //
//     .. ====@@@@@@@@@@@==--------------===@@@@@@@@=====- .      //
//     .- ====@@====--.....---------------.....--=@@@@@@@@ -      //
//     .- ..........---========================--...-@@@@= -      //
//     .. @========================================-...=@@ -      //
//     .. ============================================-..- -      //
//     .. ==============================================-  -      //
//     .. =================@@@@@@@@@@@==================== -      //
//     .. ===============@@@@@@@@@@@@@@@@================= -      //
//     .. =============@@@@@@@@@@@@@@@@@@@================ -      //
//     .. ===@@@@=====@@@@@@@@@@@@@@@@@@@@@=============== -      //
//     .. =@@@@@@@@===@@@@@@@@@@==@@@@@@@@@@============== -      //
//     .. @@@@  @@@==@@@@@@@@@@    @@@@@@@@@============== -      //
//     .. =@@@@@@@@===@@@@@@@@@=..=@@@@@@@@@============== -      //
//     .. ==@@@@@@====@@@@@@@@@@@@@@@@@@@@@@============== -      //
//     .. =============@@@@@@@@@@@@@@@@@@@@=============== -      //
//     .. =======-.-====@@@@@@@@@@@@@@@@@================= -      //
//     .. @======.  ======@@@@@@@@@@@@@=================== -      //
//     .- --------.---=========@@@@======================= -      //
//     .. ==..===== .-..-================================= -      //
//     ...@@=-@@@@@.@@@=..================================ -      //
//     ...@@--@@@@@.=@@@@ .=============================== -      //
//     ...@@--@@@@@.=@@@@= =============================== -      //
//     ...@@=-@@@@@.=@@@@= ============-================== -      //
//     ...@@@.@@@@@.=@@@@@ -==========- .-================ -      //
//     ...@@@.@@@@@--@@@@@. ==========- =..-============== -      //
//     ...@@@=.@@@@@.=@@@@@ .=========- @@=...--=========- -      //
//     ...@@@@--@@@@@--@@@@@. -=======- @@@@@=--.......... -      //
//     ...@@@@@=.=@@@@=.=@@@@=-..---==- @@@@@@@@@@@@@@@@@@ -      //
//     .- @@@@@@@--=@@@@--=@@@@@==--....@@@@@@@@@@@@@@@@@@ =      //
//      =-.-==@@@@@=-=@@@@--=@@@@@@@@@@@@@@@@@@@@@@@@@==-.--      //
//       .--...---===---=@@@@=-==@@@@@@@@@@@@@@===--.......       //
//            .......... ..----.. ..------...........             //
//                     ....................                       //
//                                                                //
////////////////////////////////////////////////////////////////////

// @title Arkivists Genesis
// @author @tom_hirst

pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract ArkivistsGenesis is ERC721, IERC2981, Ownable, ReentrancyGuard {
    // Addresses
    address private _w1; // Community wallet
    address private immutable _w2; // Founder
    address private immutable _w3; // Design
    address private immutable _w4; // Story
    address private immutable _w5; // Dev

    // Provenance
    string public provenanceHash;
    bool public provenanceHashLocked;

    // Collection values
    uint256 public constant MAX_SUPPLY = 777;
    uint256 public constant MAX_PER_TX = 6;
    uint256 public constant MAX_PER_AL_WALLET = 3;
    uint256 public tokenPrice = 0.07 ether;
    uint256 public royaltyPercentage = 5;

    // Mint phase toggles
    bool public allowListMintActive;
    bool public publicMintActive;

    // Track token count
    uint256 private _nextTokenId = 1;

    // Merkle
    bytes32 public merkleRoot;

    // Track how many tokens addresses have minted
    mapping(address => uint256) public mintBalance;

    // Metadata URIs
    string private _contractURI;
    string public baseURI;

    /**
     * @notice Check functions for supply being available
     * @param _numberOfTokens The number of tokens attempting to be minted
     */
    modifier whenSupplyAvailable(uint256 _numberOfTokens) {
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "Exceeds max supply");
        _;
    }

    /**
     * @notice Check functions for correct token amount per tx
     * @param _numberOfTokens The number of tokens attempting to be minted
     */
    modifier whenUnderMaxPerTx(uint256 _numberOfTokens) {
        require(_numberOfTokens <= MAX_PER_TX, "Exceeds max per tx");
        _;
    }
    /**
     * @notice Check functions for correct amount of ETH being sent
     * @dev We ask for the exact amount to protect minters who accidentally send more
     * @param _numberOfTokens The number of tokens to calculate the value required from
     */
    modifier whenCorrectEtherSent(uint256 _numberOfTokens) {
        require(msg.value == tokenPrice * _numberOfTokens, "Incorrect ether sent");
        _;
    }

    /**
     * @notice Constructor
     * @dev Pass in community and team wallet addresses
     * @dev Pass in the starting contractURI for collection level metadata
     * @dev Pass in the starting baseURI for token placeholder metadata
     */
    constructor(
        address w1,
        address w2,
        address w3,
        address w4,
        address w5,
        string memory _startingContractURI,
        string memory _startingBaseURI
    ) ERC721("Arkivists Genesis", "ARKG") {
        _w1 = w1;
        _w2 = w2;
        _w3 = w3;
        _w4 = w4;
        _w5 = w5;
        _contractURI = _startingContractURI;
        baseURI = _startingBaseURI;
    }

    /**
     * @notice Get total supply
     * @return uint256 Number of tokens minted
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    /**
     * @notice Get contractURI
     * @return contractURI The URI for the collection metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Get baseURI
     * @dev Overrides {ERC721-_baseURI}
     * @return baseURI The base token URI for the collection
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Base token minting function
     * @dev Loop counter incrementation can go unchecked to save gas because we can't overflow
     * @param _to The address to mint tokens to
     * @param _numberOfTokens The number of tokens to be minted
     */
    function _internalMint(address _to, uint256 _numberOfTokens) private {
        for (uint256 i = 0; i < _numberOfTokens;) {
            _safeMint(_to, _nextTokenId++);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allowlist minting function
     * @dev Check that the allowlist mint is active
     * @dev Check that an address is not trying to mint more than its max. allocation
     * @dev Check that a valid merkle proof is sent with the transaction
     * @dev Mint balance incrementation can go unchecked to save gas because we can't overflow
     * @param _numberOfTokens The number of tokens to be minted
     * @param _merkleProof The proof of allowlist presence required to mint
     */
    function allowListMint(uint256 _numberOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
        whenSupplyAvailable(_numberOfTokens)
        whenUnderMaxPerTx(_numberOfTokens)
        whenCorrectEtherSent(_numberOfTokens)
    {
        require(allowListMintActive, "AL mint closed");
        require(mintBalance[msg.sender] + _numberOfTokens <= MAX_PER_AL_WALLET, "Exceeds AL wallet limit");

        bytes32 merkleLeaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, merkleLeaf), "Invalid merkle proof");

        unchecked {
            mintBalance[msg.sender] += _numberOfTokens;
        }

        _internalMint(msg.sender, _numberOfTokens);
    }

    /**
     * @notice Public minting function
     * @dev Check that the public mint is active
     * @dev We could allow contracts to mint, but we want real community members
     * @param _numberOfTokens The number of tokens to be minted
     */
    function publicMint(uint256 _numberOfTokens)
        external
        payable
        whenSupplyAvailable(_numberOfTokens)
        whenUnderMaxPerTx(_numberOfTokens)
        whenCorrectEtherSent(_numberOfTokens)
    {
        require(publicMintActive, "Public mint closed");
        require(msg.sender == tx.origin, "No contracts");

        _internalMint(msg.sender, _numberOfTokens);
    }

    /**
     * @notice Claim allowance (27) set aside for the team
     * @dev Can only be used once before any tokens are minted
     * @dev Tokens will be used for PFPs, marketing and giveaways
     */
    function teamClaim() external onlyOwner {
        require(totalSupply() == 0, "Tokens already claimed");

        _internalMint(_w2, 1); // Founder
        _internalMint(_w3, 1); // Design
        _internalMint(_w4, 1); // Story
        _internalMint(_w5, 1); // Dev

        _internalMint(_w1, 22); // Community wallet

        _internalMint(0x3E7898c5851635D5212B07F0124a15a2d3C547EB, 1); // Audit
    }

    /**
     * @notice Update the community wallet address
     * @param _newCommunityWallet The new community wallet address
     */
    function setCommunityWallet(address _newCommunityWallet) external onlyOwner {
        _w1 = _newCommunityWallet;
    }

    /**
     * @notice Set the collection provenance hash
     * @dev Can't be used after the provenance hash is locked
     * @param _provenanceHash The provenance hash for the collection
     */
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        require(!provenanceHashLocked, "Provenance hash locked");

        provenanceHash = _provenanceHash;
    }

    /**
     * @notice Lock the collection provenenace hash
     * @dev This is a one-time use function
     */
     function lockProvenanceHash() external onlyOwner {
        provenanceHashLocked = true;
    }

    /**
     * @notice Update the price of a single token
     * @param _newTokenPrice The new price of a single token
     */
    function setTokenPrice(uint256 _newTokenPrice) external onlyOwner {
        tokenPrice = _newTokenPrice;
    }

    /**
     * @notice Update royalty percentage for secondary sales
     * @param _royaltyPercentage The new royalty percentage
     */
    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyOwner {
        royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @notice Toggle allow list mint phase
     */
    function toggleAllowListMint() external onlyOwner {
        allowListMintActive = !allowListMintActive;
    }

    /**
     * @notice Toggle public mint phase
     */
    function togglePublicMint() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    /**
     * @notice Update the merkle root used for allowlist management
     * @dev Root string passed must be proceeded by '0x'
     * @param _newMerkleRoot The new root of the merkle tree
     */
    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    /**
     * @notice Update the contractURI
     * @dev This is the collection level metadata URL
     * @param _newContractURI The new contractURI for the collection
     */
    function setContractURI(string memory _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @notice Update the baseURI
     * @dev Must include trailing slash
     * @param _newBaseURI The new baseURI for the collection
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Internal withdraw function
     * @param _balance The balance to be split
     * @param _address The address to send the balance to
     * @param _split The % split of the balance to send to the address
     */
    function _internalWithdraw(
        uint256 _balance,
        address _address,
        uint256 _split
    ) private {
        (bool success, ) = payable(_address).call{ value: (_balance / 10000) * _split }("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Withdraw funds from the contract
     * @dev Community wallet 39.25%, Founder 18.22%, Design 15.19%, Story 15.19%, Dev 12.15%
     * @dev Any balance left is sent to the community wallet
     * @dev Prefer call pattern over transfer to prevent potential out of gas revert for multisigs
     */
    function withdraw() external nonReentrant {
        uint256 balance = address(this).balance;

        _internalWithdraw(balance, _w1, 3925);
        _internalWithdraw(balance, _w2, 1822);
        _internalWithdraw(balance, _w3, 1519);
        _internalWithdraw(balance, _w4, 1519);
        _internalWithdraw(balance, _w5, 1215);

        (bool success, ) = payable(_w1).call{ value: address(this).balance }("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Declare support for interfaces used (IERC2981)
     * @dev Overrides {IERC165-supportsInterface}
     * @return bool Whether a checked interface is supported or not
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Set royalty info according to IERC2981 standard
     * @dev Royalties paid to the community wallet
     * @dev Overrides {IERC2981-royaltyInfo}
     * @return address The royalties reciever
     * @return royaltyAmount The amount to be paid
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Non-existent token");

        royaltyAmount = (_salePrice / 100) * royaltyPercentage;

        return (_w1, royaltyAmount);
    }
}
