// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Burn Ghost Bounty Box
/// @notice This is Burn Ghost's Bounty Box ERC721 NFT contract 
/// @dev This contract uses OpenZeppelin's library and includes OpenSea's on-chain enforcement tool for royalties   
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract BurnGhostBountyBox is ERC721, Ownable {
 
    /// @notice The base uri of the project
    string public baseURI; 

    /// @notice The collection's max supply
    uint256 public maxSupply = 1000; 

    /// @notice Total reserved by the Burn Ghost team
    uint256 public reserved; 

    /// @notice Total guaranteed mint count 
    uint256 public guaranteed; 

    /// @dev Merkle tree root hash for guaranteed list
    bytes32 private rootForGuaranteed;

    /// @dev Merkle tree root hash for allowed list
    bytes32 private rootForOversubscribed;

    /// @dev Mapping to check if an address has already minted to avoid double mints on allow list mints
    mapping(address => bool) mintedOnGuaranteed; 
    mapping(address => bool) mintedOnOversubscribed; 

    /// @dev Counters library to track token id and counts
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    Counters.Counter private _guaranteedAllowListMintedCounter;
    Counters.Counter private _oversubscribedAllowListMintedCounter;

    /// @dev Different states of minting 
    enum MintState {
        PAUSED, // Minting is paused
        GUARANTEED, // Guaranteed allow list 
        OVERSUBSCRIBED, // General allow list 
        PUBLIC, // Open to public
        REVEALED 
    }

    MintState public mintState; 

    /// @notice Event emitted when a bounty box is burnt/redeemed
    event BountyBoxRedeemed(address indexed ownerAddress, uint256 indexed tokenId); 

    /// @notice Event emitted when a bounty box is burnt/redeemed
    event BountyBoxBatchRedeemed(address indexed ownerAddress, uint256 indexed redeemedCount, uint256[] tokenId); 

    constructor(string memory uri) ERC721("Burn Ghost Bounty Box", "BGBB") {
        baseURI = uri;
    }

    /// Base uri functions
    ///@notice Returns the base uri 
    ///@return Base uri
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    ///@notice Sets a new base uri
    ///@dev Only callable by owner
    ///@param newBaseURI The new base uri 
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    ///@notice Returns the token uri
    ///@dev Updated to include json 
    ///@param tokenId Token id
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId <= _tokenIdCounter.current(), "BGBB: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string.concat(baseURI, Strings.toString(tokenId + 1), ".json") : "";
    }

    /// Minting functions
    ///@notice Mints box token for allowed list addresses
    ///@dev Uses Merkle tree proof
    ///@param proof The Merkle tree proof of the allow list address 
    function mintBox(bytes32[] calldata proof) external {
        /// Check if the sale is paused
        require(mintState == MintState.GUARANTEED || mintState == MintState.OVERSUBSCRIBED, "BGBB: Not in allowlist minting states");

        require(_tokenIdCounter.current() < maxSupply, "BGBB: Max supply minted"); 

        /// Check if user is on the allow list
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender()))));
        
        /// Update the root based on the state
        bytes32 root;

        // If current state is for guaranteed mints, set to the guaranteed hash
        if (mintState == MintState.GUARANTEED) {

            /// Set the correct root hash
            root = rootForGuaranteed; 

            /// Check that user has not minted on guaranteed list
            require(mintedOnGuaranteed[_msgSender()] == false, "BGBB: User already minted on guaranteed list");
            
            // Check there is sufficient guaranteed mint supply left 
            require(totalGuaranteedAllowListMinted() < guaranteed, "BGBB: Max guaranteed supply minted"); 
            
            /// Increase the allow list minted count
            _guaranteedAllowListMintedCounter.increment();

            /// Set that address has minted
            mintedOnGuaranteed[_msgSender()] = true;
        } 

        // If current state is for oversubscribed, set to the oversubscribed hash
        if (mintState == MintState.OVERSUBSCRIBED) {

            /// Set the correct root hash
            root = rootForOversubscribed; 

            /// Check that user has not minted on oversubscribed list
            require(mintedOnOversubscribed[_msgSender()] == false, "BGBB: User already minted on oversubscribed list");

            /// Check there is sufficient oversubscribed supply left
            /// Balance for oversubscribed mint = max supply minus reserved and guaranteed count
            require(totalOversubscribedAllowListMinted() < maxSupply - reserved - guaranteed, "BGBB: Max allow list supply minted"); 

            _oversubscribedAllowListMintedCounter.increment();

            /// Set that address has minted
            mintedOnOversubscribed[_msgSender()] = true;
        }

        // Check the merkle proof
        require(MerkleProof.verify(proof, root, leaf), "BGBB: Invalid proof");

        /// Get current token id then increase it
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        /// Mint the token
        _safeMint(_msgSender(), tokenId);
    }

    ///@notice Mints a token to caller addresses 
    function publicMintBox() external {

        require(mintState == MintState.PUBLIC || mintState == MintState.REVEALED, "BGBB: Public mint inactive"); 

        /// Check balance of supply 
        /// Total supply minus reserved
        require(_tokenIdCounter.current() < maxSupply - reserved, "BGBB: Max available public supply minted"); 

        /// Get current token id then increase it
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        /// Mint the token
        _safeMint(_msgSender(), tokenId);
    }

    ///@notice Redeem a bounty box
    ///@param tokenId Token id of bounty box to redeem
    function redeem(uint256 tokenId) external virtual {

        require(mintState == MintState.REVEALED, "BGBB: Boxes not revealed yet");

        address tokenOwner;

        // If the caller is the contract owner, burn the token on user's behalf
        if(_msgSender() == owner()) {
            tokenOwner = ownerOf(tokenId);
        } else {
            tokenOwner = _msgSender();
        }

        require(tokenOwner == ownerOf(tokenId), "BGBB: Not token owner");

        // Burn the token
        _burn(tokenId);

        // Emit event that box redeemed
        emit BountyBoxRedeemed(tokenOwner, tokenId);
    }

    ///@notice Redeem a batch of bounty boxes
    ///@param tokenIds Token ids of bounty box to redeem
    function batchRedeem(uint256[] memory tokenIds) external virtual {

        require(mintState == MintState.REVEALED, "BGBB: Boxes not revealed yet");

        address tokenOwner = ownerOf(tokenIds[0]); 

        for(uint256 i; i < tokenIds.length;) {

            // If the caller is the contract owner, bypass the owner check
            if (_msgSender() != owner()) {
                // Ensure that all token ids belong to the same owner
                require(ownerOf(tokenIds[i]) == _msgSender(), "BGBB: Token owner and id mismatch found in list"); 
            }

            // Burn the token
            _burn(tokenIds[i]);

            unchecked {
                i++;
            }
        }

        // Emit event that boxes have been redeemed
        emit BountyBoxBatchRedeemed(tokenOwner, tokenIds.length, tokenIds);
    }

    ///@notice Mint from reserve supply
    ///@dev Only callable by owner
    ///@param to Array of addresses to receive airdrop 
    function mintFromReserve(address[] calldata to) external onlyOwner {
        /// Check balance of supply
        require(to.length <= reserved, "BGBB: Amount exceeds reserved supply"); 
        
        for(uint i; i < to.length;) {
            /// Get current token id then increase it
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            /// Mint the token
            _safeMint(to[i], tokenId);

            /// Unchecked i to save gas
            unchecked {
                i++;
            }
        }

        /// Reduce the reserved amount after minting
        reserved -= to.length; 
    }

    ///@notice Airdrops a token to users from the remaining supply (without reserved supply)
    ///@dev Only callable by owner
    ///@param to Array of addresses to receive airdrop 
    function airdrop(address[] calldata to) external onlyOwner {
        /// Check balance of supply
        require(_tokenIdCounter.current() + to.length <= maxSupply - reserved, "BGBB: Airdrop amount exceeds maximum supply"); 
        
        for(uint i; i < to.length;) {
            /// Get current token id then increase it
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            /// Mint the token
            _safeMint(to[i], tokenId);

            /// Unchecked i to save gas
            unchecked {
                i++;
            }
        }
    }

    /// Other view and admin functions

    /// Verification functions
    ///@notice Returns the current Merkle tree root hash based on a given state
    ///@dev Only callable by owner
    ///@param _mintState The state of the mint to query the root hash for
    function getRootHash(MintState _mintState) external view onlyOwner returns(bytes32) {
        
        require(_mintState == MintState.GUARANTEED || _mintState == MintState.OVERSUBSCRIBED, "BGBB: Invalid mint state");
        
        if(_mintState == MintState.GUARANTEED) {
            return rootForGuaranteed;
        }

        return rootForOversubscribed;
    }

    ///@notice Sets a new Merkle tree root hash
    ///@dev Only callable by owner
    ///@param _root The new merkle tree root hash 
    ///@param _mintState The state of the mint to set the root hash for
    function setRootHash(bytes32 _root, MintState _mintState) external onlyOwner {

        if(_mintState == MintState.GUARANTEED) {
            rootForGuaranteed = _root;
        }

        if(_mintState == MintState.OVERSUBSCRIBED) {
            rootForOversubscribed = _root;
        }
    }

    ///@notice Returns the total number of boxes minted
    function totalMinted() public view returns(uint256) {
        /// Token id starts from index 0 and counter is always incremented after mint, representing the total minted count
       return _tokenIdCounter.current(); 
    }

    ///@notice Returns the current number of guaranteed allow list minted
    function totalGuaranteedAllowListMinted() public view returns(uint256) {
        /// Token id starts from index 0 and counter is always incremented after mint, representing the total minted count
       return _guaranteedAllowListMintedCounter.current(); 
    }

    ///@notice Returns the current number of oversubscribed allow list minted
    function totalOversubscribedAllowListMinted() public view returns(uint256) {
        /// Token id starts from index 0 and counter is always incremented after mint, representing the total minted count
       return _oversubscribedAllowListMintedCounter.current(); 
    }

    ///@notice Returns the total allow list minted 
    function totalAllowListMinted() public view returns(uint256) {
        /// Token id starts from index 0 and counter is always incremented after mint, representing the total minted count
       return _guaranteedAllowListMintedCounter.current() + _oversubscribedAllowListMintedCounter.current(); 
    }

    ///@notice Function to update the reveal flag 
    ///@param newState The new mint state to set
    function setMintState(MintState newState) external onlyOwner{
       require(mintState != MintState.REVEALED, "BGBB: Boxes already revealed");

       mintState = newState; 
    }

    ///@notice Function to update guaranteed mint count 
    ///@param count New guaranteed mint count
    function setGuaranteedCount(uint256 count) external onlyOwner {
        guaranteed = count; 
    }

    ///@notice Function to update reserved mint count 
    ///@param count New reserved mint count
    function setReservedCount(uint256 count) external onlyOwner {
        reserved = count; 
    }

    ///@dev Overrides for DefaultOperatorRegistry
    function setApprovalForAll(address operator, bool approved) public override(ERC721) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
