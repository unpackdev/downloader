// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

import "./ERC721Tradable.sol";

/**
 * @title BeaverCrafterClub NFTs
 * Base contract to create and distribute rewards to the BCC community
 */
contract BeaverCrafterClubNFTs is ERC721Tradable {
    using Address for address;
    using Counters for Counters.Counter;

    // ============================== Variables ===================================
    address ownerAddress;

    // Count of tokenID
    Counters.Counter private tokenIdCount;

    /// @notice  Root of the Merkle Tree used for whitelisting addresses
    bytes32 public merkleRoot;

    // ============================== Constants ===================================
    /// @notice Price to mint the NFTs
    uint256 public constant price = 8e16;

    /// @notice Price to mint the NFTs in preSale
    uint256 public constant earlyPrice = 6e16;

    /// @notice Max tokens supply for this contract
    uint256 public constant maxSupply = 1e4;

    /// @notice Max number of tokens allowed to own
    uint256 public constant maxBalance = 10;

    /// @notice Max number of tokens available during early sale
    uint256 public constant earlySaleSupply = 2200;

    /// @notice Start of the early sale period (in Unix second)
    // TODO change the timestamp
    uint256 public constant earlySaleStart = 1633471200;

    /// @notice End of the early sale period (in Unix second)
    // TODO change the timestamp
    uint256 public constant earlySaleEnd = 1633644000;

    // ============================== Constructor ===================================

    /// @notice Constructor of the NFT contract
    /// Takes as argument the OpenSea contract to manage sells and transfers
    /// and the merkle root of the whitelisting merkle tree
    constructor(
        address _proxyRegistryAddress, // OpenSea Smart Contract for trading
        bytes32 _merkleRoot
    ) ERC721Tradable("BeaverCrafterClub NFTs", "BCCNFTs", _proxyRegistryAddress) {
        // Initialize counter for next mints
        tokenIdCount._value = 200;
        merkleRoot = _merkleRoot;
    }

    // ============================== Functions ===================================

    /// @notice Returns the url of the servor handling token metadata
    function baseTokenURI() public pure override returns (string memory) {
        return "https://beavercrafterclub-metadata.herokuapp.com/beavers/";
    }

    // ============================== Public functions ===================================

    /// @notice Checks if a proof is valid and an account is whitelisted
    /// @param index Leaf index in the merkle tree
    /// @param account Account to check
    /// @param merkleProof List of hashes corresponding to the nodes of the tree required
    /// to build the merkle proof
    function isWhitelisted(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    /// @notice Mints `tokenId` and transfers it to `to` during VIP Sale Period
    /// @param to address of the future owner of the token
    /// @param amount Number tokens to mint
    /// @param index Leaf index in the merkle tree
    /// @param merkleProof List of hashes corresponding to the nodes of the tree required
    /// to build the merkle proof
    function vipMint(
        address to,
        uint256 amount,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable {
        require(msg.value >= earlyPrice * amount, "Incorrect amount sent");
        require(block.timestamp > earlySaleStart, "Early Sale not opened yet");
        require(this.totalSupply() + amount <= earlySaleSupply, "No More Early Sale token available");
        require(block.timestamp < earlySaleEnd, "Early Sale is closed");
        require(isWhitelisted(index, to, merkleProof), "Account is not whitelisted");
        for (uint256 i = 0; i < amount; i++) {
            tokenIdCount.increment();
            _mint(to, tokenIdCount.current());
        }
    }

    /// @notice Mints `tokenId` and transfers it to `to` during Public Sale Period
    /// @param to address of the future owner of the token
    /// @param amount Number tokens to mint
    function publicMint(address to, uint256 amount) external payable {
        require(msg.value >= price * amount, "Incorrect amount sent");
        require(block.timestamp > earlySaleEnd, "Public Minting not opened yet");
        require(balanceOf(to) + amount <= maxBalance, "Account owns too many to mint");

        for (uint256 i = 0; i < amount; i++) {
            tokenIdCount.increment();
            _mint(to, tokenIdCount.current());
        }
    }

    // ============================== Governor ===================================

    /// @notice Mints a token to an address
    /// @param to address of the future owner of the token
    function governorMint(address to) public onlyOwner {
        tokenIdCount.increment();
        _mint(to, tokenIdCount.current());
    }

    /// @param to address of the future owner of the token
    /// @param amount Number tokens to mint
    function governorMintMultiple(address to, uint256 amount) external payable onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            tokenIdCount.increment();
            super._mint(to, tokenIdCount.current());
        }
    }

    /// @notice Mints `tokenId` and transfers it to `to`
    /// @param to address of the future owner of the token
    /// @param tokenID Target ID to mint
    function governorMintTokenSpecific(address to, uint256 tokenID) external payable onlyOwner {
        require(tokenID < 201);
        super._mint(to, tokenID);
    }

    /// @notice Mints `tokenId` and transfers it to `to`
    /// @param to Array of addresses of the future owner of the token
    /// @param tokenID Array of target ID to mint
    function governorMintMultipleTokenSpecific(address[] memory to, uint256[] memory tokenID)
        external
        payable
        onlyOwner
    {
        require(to.length == tokenID.length, "Incorrect input data");
        for (uint256 i = 0; i < to.length; i++) {
            require(tokenID[i] < 201);
            super._mint(to[i], tokenID[i]);
        }
    }

    /// @notice Recovers any ERC20 token (wETH, USDC) that could accrue on this contract
    /// @param tokenAddress Address of the token to recover
    /// @param to Address to send the ERC20 to
    /// @param amountToRecover Amount of ERC20 to recover
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(to, amountToRecover);
    }

    /// @notice Recovers any ETH that could accrue on this contract
    /// @param to Address to send the ETH to
    /// @param amountToRecover Amount of ETH to recover
    function recoverETH(address payable to, uint256 amountToRecover) external onlyOwner {
        to.transfer(amountToRecover);
    }

    /// @notice Updates the merkle root
    /// @param _merkleRoot New merkle root
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Makes this contract payable
    receive() external payable {}

    // ============================== Internal Functions ===================================

    /// @notice Mints a new token
    /// @param to address of the future owner of the token
    /// @param tokenId id of the token to mint
    /// @dev Checks that the totalSupply is respected, that
    function _mint(address to, uint256 tokenId) internal override {
        require(tokenId < maxSupply, "Reached minting limit");
        super._mint(to, tokenId);
    }
}
