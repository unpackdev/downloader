// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";

import "./Percent.sol";

contract HelixNFT is ERC721Upgradeable, ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address private _owner;

    // Maximum length of tokens per request
    uint256 public constant MAX_ARRAY_LENGTH_PER_REQUEST = 30;

    /**
     * @dev Stakers who can change attribute `isStaked` of token
     *
     * NOTE : Stakers would be HelixChefNFT contract
     */
    EnumerableSet.AddressSet private _stakers;

    /**
     * @dev Minters who can mint token
     * 
     * NOTE : Minters would be address of Whitelist for Presale Or Launchpad contract address for Sale
     */
    EnumerableSet.AddressSet private _minters;

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    string private _internalBaseURI;

    /**
     * @dev Last NFT token id, it's increasing on mint
     */
    uint256 private _lastTokenId;

    /**
     * @dev Structure for attributes the Helix NFTs
     */
    struct Token {
        // mintTokenIDs on solana.
        string[] mintTokenIDs;
        // label IDs on solana(eg. #345, #8900)
        string[] nftIDs;
        // External token URI to use.
        string tokenURI;
        // Timestamp the token is minted(block's timestamp)
        uint256 createTimestamp;
        // True if staked, false otherwise
        bool isStaked;
        // how many it is wrapped from solana
        uint256 wrappedNfts;
        // by which bridge factory id
        uint256 bridgeFactoryId;
    }

    // map token info by token ID : TokenId => Token
    mapping(uint256 => Token) private _tokens;
   
    event Initialize(string baseURI);
    event TokenMint(address indexed to, uint256 indexed tokenId);

    modifier isNotZeroAddress(address _address) {
        require(_address != address(0), "HelixNFT: zero address");
        _;
    }

    modifier tokenIdExists(uint256 tokenId) {
        require(_exists(tokenId), "HelixNFT: nonexistent token");
        _;
    }

    modifier isNotZero(uint256 amount) {
        require(amount > 0, "HelixNFT: zero amount");
        _;
    }

    modifier onlyValidPercent(uint256 percent) {
        require(Percent.isValidPercent(percent), "HelixNFT: invalid percent");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(
        string memory baseURI
    ) external initializer {
        _owner = msg.sender;

        __ERC721_init("Helix NFT", "HELIX-NFT");
        __ERC721Enumerable_init();
        __ReentrancyGuard_init();

        _internalBaseURI = baseURI;

        emit Initialize(baseURI);
    }
    
    //Public functions --------------------------------------------------------------------------------------------

    /**
     * @dev See {ERC721-tokenURI}.
     */
    function tokenURI(uint256 id) public view override tokenIdExists(id) returns (string memory) {
        return string(abi.encodePacked(_tokens[id].tokenURI));
    }

    function getBridgeFactoryId(uint256 _tokenId) external view tokenIdExists(_tokenId) returns (uint256) {
        return _tokens[_tokenId].bridgeFactoryId;
    }

    /**
     * @dev Override funtion to avoid the approval of the staked token
     */
    function approve(address to, uint256 tokenId) public override {
        if (_tokens[tokenId].isStaked) {
            revert("ERC721: Token is staked");
        }
        super.approve(to, tokenId);
    }

    //Internal functions --------------------------------------------------------------------------------------------

    /**
     * @dev Override function to avoid the transfer of the staked token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        if (_tokens[tokenId].isStaked) {
            revert("ERC721: Token is staked");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Required override function required by solidity
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //External functions --------------------------------------------------------------------------------------------

    /**
     * @dev To mint HelixNFT
     */
    function mint(address to) external onlyMinter nonReentrant isNotZeroAddress(to) {
        _lastTokenId += 1;
        uint256 tokenId = _lastTokenId;
        _tokens[tokenId].createTimestamp = block.timestamp;
        _safeMint(to, tokenId);
    }

    // Mints external NFT
    function mintExternal(address to, string[] calldata mintTokenIDs, string[] calldata nftIDs, string calldata uri, uint256 _bridgeFactoryId) 
        external 
        onlyMinter 
        nonReentrant 
        isNotZeroAddress(to) 
    {
        require(mintTokenIDs.length != 0, "Invalid Mint Token IDs length");
        _lastTokenId += 1;
        uint256 tokenId = _lastTokenId;
        Token storage _newToken = _tokens[tokenId];
        _newToken.createTimestamp = block.timestamp;
        _newToken.tokenURI = uri;
        _newToken.bridgeFactoryId = _bridgeFactoryId;

        uint256 length = mintTokenIDs.length;
        string[] memory _newMintTokenIDs = new string[](length);
        string[] memory _newNftIDs = new string[](length);
        _newMintTokenIDs = mintTokenIDs;
        _newNftIDs = nftIDs;
        _newToken.mintTokenIDs = _newMintTokenIDs;
        _newToken.nftIDs = _newNftIDs;
        _newToken.wrappedNfts = length;
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyMinter nonReentrant {
        _burn(tokenId);
    }
    
    /**
     * @dev To get token IDs of user by address
     */
    function getTokenIdsOfOwner(address user) external view returns (uint[] memory) {
        uint256 balance = ERC721Upgradeable.balanceOf(user);
        require(balance > 0, "HelixNFT: insufficient balance");
        uint[] memory tokenIds = new uint[](balance);
        for (uint256 index = 0; index < balance; index++) {
            tokenIds[index] = tokenOfOwnerByIndex(user, index);
        }
        return tokenIds;
    }

    /**
     * @dev To get the last token Id
     */
    function getLastTokenId() external view returns (uint) {
        return _lastTokenId;
    }

    /**
     * @dev External function to get the information of `tokenId`
     */
    function getToken(uint256 _tokenId) 
        external 
        view
        tokenIdExists(_tokenId)
        returns (
            address,
            string memory,
            uint256,
            Token memory
        )
    {
        address tokenOwner = ownerOf(_tokenId);
        string memory uri = tokenURI(_tokenId);
        uint256 tokenId = _tokenId;
        Token memory token = _tokens[_tokenId];
        return(tokenOwner, uri, tokenId, token);
    }

    function getMintTokenIDs(uint256 _tokenId) external view tokenIdExists(_tokenId) returns (string[] memory) {
        return _tokens[_tokenId].mintTokenIDs;
    }

    /**
     * @dev Returns the owner address and staked status among the token information with the given 'tokenId'.
     * 
     * HelixChefNFT's `stake` function calls it to get token's information by token ID
     */
    function getInfoForStaking(uint256 tokenId) 
        external 
        view 
        tokenIdExists(tokenId) 
        returns (address tokenOwner, bool isStaked, uint256 wrappedNFTs) 
    {
        tokenOwner = ownerOf(tokenId);
        isStaked = _tokens[tokenId].isStaked;
        wrappedNFTs = _tokens[tokenId].wrappedNfts;
    }

    /** 
     * @dev Set to set Base URI
     * @param tokenId uint256 ID of the token to be staked/unstaked
     * @param isStaked bool whether to being staked or not
     *
     * HelixChefNFT's `stake` function calls it to set staked status into token's info by token ID
     * 
     * NOTE: - Staked token can't be transferred to anyone
     *       - Staker would be HelixChefNFT contract
     */
    function setIsStaked(uint256 tokenId, bool isStaked) external onlyStaker tokenIdExists(tokenId) {
        if (isStaked) {
            // Clear approval for not to transfer when staked token 
            _approve(address(0), tokenId);
        }
        _tokens[tokenId].isStaked = isStaked;
    }

    /**
     * @dev External function to set new Base URI
     */
    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        _internalBaseURI = newBaseUri;
    }

    //Role functions for Staker --------------------------------------------------------------------------------------

    /**
     * @dev used by owner to add staker who changes `isStaked` of token
     * @param _addStaker address of staker to be added.
     * @return true if successful.
     */
    function addStaker(address _addStaker) public onlyOwner isNotZeroAddress(_addStaker) returns (bool) {
        return EnumerableSet.add(_stakers, _addStaker);
    }

    /**
     * @dev used by owner to delete staker who changes `isStaked` of token
     * @param _delStaker address of staker to be deleted.
     * @return true if successful.
     */
    function delStaker(address _delStaker) external onlyOwner isNotZeroAddress(_delStaker) returns (bool) {
        return EnumerableSet.remove(_stakers, _delStaker);
    }

    /**
     * @dev See the number of stakers
     * @return number of stakers.
     */
    function getStakerLength() public view returns (uint256) {
        return EnumerableSet.length(_stakers);
    }

    /**
     * @dev Check if an address is a staker
     * @return true or false based on staker status.
     */
    function isStaker(address account) public view returns (bool) {
        return EnumerableSet.contains(_stakers, account);
    }

    /**
     * @dev Get the staker at n location
     * @param _index index of address set
     * @return address of staker at index.
     */
    function getStaker(uint256 _index)
        external
        view
        returns (address)
    {
        require(_index <= getStakerLength() - 1, "HelixNFT: index out of bounds");
        return EnumerableSet.at(_stakers, _index);
    }

    /**
     * @dev Modifier for changing `isStaked` of token
     */
    modifier onlyStaker() {
        require(isStaker(msg.sender), "HelixNFT: not staker");
        _;
    }

    //Role functions for Minter --------------------------------------------------------------------------------------

    /**
     * @dev used by owner to add minter who can mint
     * @param _addMinter address of minter to be added.
     * @return true if successful.
     */
    function addMinter(address _addMinter) public onlyOwner isNotZeroAddress(_addMinter) returns (bool) {
        return EnumerableSet.add(_minters, _addMinter);
    }

    /**
     * @dev used by owner to delete minter
     * @param _delMinter address of minter to be deleted.
     * @return true if successful.
     */
    function delMinter(address _delMinter) external onlyOwner isNotZeroAddress(_delMinter) returns (bool) {
        return EnumerableSet.remove(_minters, _delMinter);
    }

    /**
     * @dev See the number of minters
     * @return number of minters.
     */
    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    /**
     * @dev Check if an address is a minter
     * @return true or false based on minter status.
     */
    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    /**
     * @dev Get the minter at n location
     * @param _index index of address set
     * @return address of minter at index.
     */
    function getMinter(uint256 _index)
        external
        view
        returns (address)
    {
        require(_index <= getMinterLength() - 1, "HelixNFT: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    /**
     * @dev Modifier
     */
    modifier onlyMinter() {
        require(isMinter(msg.sender), "HelixNFT: not minter");
        _;
    }

    // Ownable Class ---------------------------------------------------------------
    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "HelixNFT: not owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner isNotZeroAddress(newOwner) {
        _owner = newOwner;
    }

}
