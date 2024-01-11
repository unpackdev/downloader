// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title MixDAO Alpha Pass
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://mixdao.club

import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./Payable.sol";

contract MixDAOAlphaPass is ERC1155, Payable {
    uint256 public totalSupply = 0;
    uint256 public tokenPrice = 0.08 ether;

    // Token values incremented for gas efficiency
    uint256 private maxSalePlusOne = 1501;
    uint256 private maxWalletPlusOne = 4;
    uint256 private constant MAX_TEAM_CLAIM = 200;

    mapping(address => uint256) private publicClaimed;

    // Presale
    mapping(address => uint256) private presaleClaimed;
    bytes32 public merkleRoot = "";

    // State
    enum ContractState {
        OFF,
        PRESALE,
        PUBLIC
    }
    ContractState public contractState = ContractState.OFF;

    constructor() ERC1155("ipfs://QmPKxEqPbVcLvSAoCco8DSeUBJh2PquyimUp8bYxRFaZuG") Payable() {}

    //
    // Modifiers
    //

    /**
     * Do not allow calls from other contracts.
     */
    modifier noBots() {
        require(msg.sender == tx.origin, "MixDAOAlphaPass: No bots");
        _;
    }

    /**
     * Ensure current state is correct for this method.
     */
    modifier isContractState(ContractState contractState_) {
        require(contractState == contractState_, "MixDAOAlphaPass: Invalid state");
        _;
    }

    /**
     * Ensure amount of tokens to mint is within the transaction limit and total supply limit.
     */
    modifier validTokenAmount(uint256 numTokens) {
        require((tokenPrice * numTokens) == msg.value, "MixDAOAlphaPass: Ether value sent is not correct");
        require((totalSupply + numTokens) < maxSalePlusOne, "MixDAOAlphaPass: Exceeds available tokens");
        totalSupply += numTokens;
        _;
    }

    //
    // Minting
    //

    /**
     * Mint tokens during the public sale.
     * @param numTokens Number of tokens to mint
     */
    function mintPublic(uint256 numTokens)
        external
        payable
        noBots
        isContractState(ContractState.PUBLIC)
        validTokenAmount(numTokens)
    {
        require(publicClaimed[msg.sender] + numTokens < maxWalletPlusOne, "MixDAOAlphaPass: Exceeds allowance");
        publicClaimed[msg.sender] += numTokens;
        _mint(msg.sender, 0, numTokens, "");
    }

    /**
     * Mint tokens during the presale.
     * @notice This function is only available to those on the allowlist.
     * @param numTokens The number of tokens to mint.
     * @param allowance The total number of tokens allowed to mint.
     * @param proof The Merkle proof used to validate the leaf is in the root.
     */
    function mintPresale(
        uint256 numTokens,
        uint256 allowance,
        bytes32[] calldata proof
    ) external payable noBots isContractState(ContractState.PRESALE) validTokenAmount(numTokens) {
        require(presaleClaimed[msg.sender] + numTokens <= allowance, "MixDAOAlphaPass: Exceeds allowance");
        bytes32 leaf = keccak256(abi.encode(msg.sender, allowance));
        require(verify(merkleRoot, leaf, proof), "MixDAOAlphaPass: Not a valid proof");

        presaleClaimed[msg.sender] += numTokens;

        _mint(msg.sender, 0, numTokens, "");
    }

    /**
     * Mints remaining team tokens.
     * @notice This will be called after the FWC claim.
     * @param numTokens Number of tokens to claim.
     */
    function mintTeam(uint256 numTokens) external onlyOwner {
        require(numTokens <= MAX_TEAM_CLAIM - totalSupply, "MixDAOAlphaPass: Exceeds allowance");
        _mint(msg.sender, 0, numTokens, "");
        totalSupply += numTokens;
    }

    //
    // Admin
    //

    /**
     * Set the contract state.
     * @param contractState_ The new contract state
     */
    function setContractState(ContractState contractState_) external onlyOwner {
        contractState = contractState_;
    }

    /**
     * Update token price.
     * @param tokenPrice_ The new token price
     */
    function setTokenPrice(uint256 tokenPrice_) external onlyOwner {
        tokenPrice = tokenPrice_;
    }

    /**
     * Update maximum number of tokens for sale.
     * @param maxSale The maximum number of tokens available for sale
     */
    function setMaxSale(uint256 maxSale) external onlyOwner {
        uint256 maxSalePlusOne_ = maxSale + 1;
        require(maxSalePlusOne_ < maxSalePlusOne, "MixDAOAlphaPass: Can only reduce supply");
        maxSalePlusOne = maxSalePlusOne_;
    }

    /**
     * Update maximum number of tokens per wallet during the public sale.
     * @notice This parameter only affects the public sale.
     * @param maxWallet The maximum number of tokens available per wallet for the public sale
     */
    function setMaxWallet(uint256 maxWallet) external onlyOwner {
        maxWalletPlusOne = maxWallet + 1;
    }

    /**
     * Set the presale Merkle root.
     * @dev The Merkle root is calculated from [address, allowance] pairs.
     * @param merkleRoot_ The new merkle roo
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /**
     * Update the URI.
     * @param newuri The new URI for the collection
     */
    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    //
    // Views
    //

    /**
     * Return sale claim info.
     * @param addr The address to return sales data for
     * saleInfo[0]: contractState
     * saleInfo[1]: maxSale (total available tokens)
     * saleInfo[2]: totalSupply (minted)
     * saleInfo[3]: tokenPrice
     * saleInfo[4]: presaleClaimed (by given address)
     * saleInfo[5]: maxPerWallet (for public sale)
     * saleInfo[6]: publicClaimed (by given address)
     */
    function saleInfo(address addr) public view virtual returns (uint256[7] memory) {
        return [
            uint256(contractState),
            maxSalePlusOne - 1,
            totalSupply,
            tokenPrice,
            presaleClaimed[addr],
            maxWalletPlusOne - 1,
            publicClaimed[addr]
        ];
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Verify the Merkle proof is valid.
     * @param root The Merkle root. Use the value stored in the contract
     * @param leaf The leaf. A [address, availableAmt] pair
     * @param proof The Merkle proof used to validate the leaf is in the root
     */
    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}
