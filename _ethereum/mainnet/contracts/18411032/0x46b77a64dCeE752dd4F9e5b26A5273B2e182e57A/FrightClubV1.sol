
/**0xecE9d8371fA503Cd1f1cA18202FD447701F0D260dkljfalkfdjl;asjf;lkasjf;lsdkjf;las
 * OolllllllllodllllolllodxKWW0olollkWMMWXOxdllcccco0WXxlllldKNkllolodollloollll
d'''''';;;;:;.'''',,'''',dXx,.'.'oNWKd:''..,:c:''dWKc.''.:0Xl.''.,c;','''''',''d
x,''''oKNXXKl'''';k0c'''.;kx,''''dNO:'''.'lKNWN0okWKc.''.:KXl'''';xKKOc'''';k00X
O;''''o00KNNo'''';dk:'''.:Ox,''''d0c''''.:0MMMMMWNWKc'''',lo;'''';OMMNd'''.cKMMM
0:.'''''',kXo''''',,''',l0Nx,''''dx,''''.lXWKxxxxxKKc'''''''''''';OMMWx,'''lXMMM
Kc''''cxxxKNo'''''''''':0WWx,''''dx,'''..cKWx'.'.'xKc'''';dx:'''';OMMWk;'''dWMMM
No''.;OWMMMNo'''',c;''''lKWx,''''d0c'''..;ONx,''',kKc.'''cKXl.''';OMMM0:..,kWMMM
Wd''.:KMMMMXo'''',xx,''''oXx,''''dN0l'.'.';oc'''',xKc.''.:KXl.''.;OMMMXl..;OWMMM
Wk,''lXMMMMXo,,;,:OXo,,,,;xd;;;;;xWMNOoc:;,''',;:o0Kl,;;,c0Xo,,,,:OWMMNo..:KMMMM
MO;.'xWMMMMWXKK0Okkkxodk0OkxxxxOKNWMMN0OkkdoxO0K00000OxxxkOOkxxxk0NMMMWd'.lXMMMM
M0:.,kMMMMMMWKxl;,''...cKk,''',dNMMMWk;',,,'oNMWd,':0O;',,,''',,;cxXWMWk'.oNMMMM
MXc.;0MMMMMXd;'.';dkkd;c0k,''''dWMMMWk,'''''oNMWx'.:0O;'''':o:'''.'dNMWO;'xWMMMM
MNo.cKMMMMNd'''';OWMMWKOXk,''''dWMMMMk,'''''oNMWx'.;Ok,''''lKd,''''oNMMK:'kMMMMM
MWx'oNMMMWO;.'''lXMMMMMMWk,''''dWMMMMk,'''''oNMWx'.:0k;'''';:,''';dXMMMXl;0MMMMM
MWk;dWMMMWk,'''.cXMMMMMMWk,''''dWMMMWk,'''''oNMWx'.:0k,.''',:,''',l0WMMWdcKMMMMM
MMOcOMMMMMO;.''.;OWMMMMMWk,''''dWMMMWk,'''''oNMWx'.:0k;''''lKx;'''.cKMMWxoXMMMMM
MMKd0MMMMMNx,'''':kKK0xdKx,''''l0000KO:.'''':k0Oc..lKk;''''lOd,'''.:0MMWOkWMMMMM
MMX0XMMMMMMNOc,''.',,'.;do'.'''''''':OO:,''''','.'l0Wk,.''''''.''':kWMMMK0WMMMMM
MMWNWMMMMMMMMN0kdollldkKN0doddddoodoxXWXKOdolllox0NMWKdooddoooddxOXWMMMMWWMMMMMM
MMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/





// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

/**
 * @title FrightClub Contract
 * @dev This contract allows for minting of NFTs with hidden metadata until a reveal.
 * Owners can also adjust various parameters including minting cost and tokenURI structure.
 * Whitelisting for minting is supported via Merkle proof validation.
 */
contract FrightClubV1 is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    /// @dev Possible states for the NFT's face.
    enum FaceState { Joking, Scary, StraightFace }
    FaceState public currentState;

    /// @dev Merkle root for the whitelist.
    bytes32 public merkleRoot;

    /// @dev Tracks addresses that have claimed their whitelist mint.
    mapping(address => bool) public whitelistClaimed;
    mapping(uint256 => FaceState) public tokenFaceState;

    /// @dev Prefixes for the different face states.
    mapping(FaceState => string) public stateBaseURIs;

    string public uriSuffix = '.json';

    /// @dev URI that's returned before the official reveal.
    string public hiddenMetadataUri;

    /// @dev Cost to mint an NFT.
    uint256 public cost;
    /// @dev Maximum supply for the NFTs.
    uint256 public maxSupply;
    /// @dev Maximum NFTs that can be minted in a single transaction.
    uint256 public maxMintAmountPerTx;

    /// @dev Contract's operational status.
    bool public paused = true;
    /// @dev Whether or not the whitelist minting is currently enabled.
    bool public whitelistMintEnabled = false;
    /// @dev Whether the NFT metadata has been revealed or not.
    bool public revealed = false;

    // Events
    event FaceStateChanged(uint256 indexed tokenId, FaceState newState);
    event ContractPaused(bool isPaused);
    event Revealed(bool isRevealed);
    event MintingCostUpdated(uint256 newCost);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event MaxMintAmountPerTxUpdated(uint256 newMaxMintAmount);
    event HiddenMetadataUriUpdated(string newUri);
    event StateBaseURIUpdated(FaceState state, string newBaseURI);
    event UriSuffixUpdated(string newSuffix);
    event WhitelistMintEnabledUpdated(bool isEnabled);

    /**
     * @dev Constructor to initialize the contract with initial parameters.
     * @param _tokenName Name of the NFT token.
     * @param _tokenSymbol Symbol of the NFT token.
     * @param _cost Cost to mint an NFT.
     * @param _maxSupply Maximum supply for the NFTs.
     * @param _maxMintAmountPerTx Maximum NFTs that can be minted in a single transaction.
     * @param _hiddenMetadataUri URI that's returned before the official reveal.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    /**
     * @dev Modifier to ensure minting is compliant with various rules.
     * @param _mintAmount Number of NFTs to mint.
     */
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;
    }

    /**
     * @dev Modifier to restrict certain actions to the owner of a specific token.
     * @param tokenId ID of the NFT token.
     */
    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You must be the owner of the token");
        _;
    }

    /**
     * @dev Modifier to ensure minting price is compliant.
     * @param _mintAmount Number of NFTs to mint.
     */
    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        _;
    }

    /**
     * @dev Mint NFTs for addresses that are whitelisted.
     * @param _mintAmount Number of NFTs to mint.
     * @param _merkleProof Merkle proofs for address validation.
     */
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(!whitelistClaimed[_msgSender()], 'Address already claimed!');

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);

       
    }

    /**
     * @dev Mint NFTs for any address.
     * @param _mintAmount Number of NFTs to mint.
     */
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, 'The contract is paused!');
        _safeMint(_msgSender(), _mintAmount);
    }

    /**
     * @dev Mint NFTs for a specific address.
     * @param _mintAmount Number of NFTs to mint.
     * @param _receiver Address to receive the minted NFTs.
     */
    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);

    }

    /**
     * @dev Returns the starting token ID.
     * @return The starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Set the face state of a specific token.
     * @param _tokenId ID of the NFT token.
     * @param _state New face state for the token.
     */
    function setFaceState(uint256 _tokenId, FaceState _state) public onlyOwnerOf(_tokenId){
        require(_exists(_tokenId), "Token does not exist");

        tokenFaceState[_tokenId] = _state;
        currentState = _state;

        emit FaceStateChanged(_tokenId, _state);
    }

    /**
     * @dev Returns the token URI for a given token ID.
     * @param _tokenId ID of the NFT token.
     * @return The token URI.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721Metadata)
        returns (string memory)
    {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (!revealed) {
            return hiddenMetadataUri;
        }

        FaceState tokenState = tokenFaceState[_tokenId];
        string memory currentBaseURI = stateBaseURIs[tokenState];
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    // Setter functions for base URIs and other contract parameters...

    /**
     * @dev Set the revealed status of the contract.
     * @param _state New revealed status.
     */
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;

        emit Revealed(_state);
    }

    /**
     * @dev Set the cost to mint an NFT.
     * @param _cost New cost value.
     */
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;

        emit MintingCostUpdated(_cost);
    }

    /**
     * @dev Set the maximum NFTs that can be minted in a single transaction.
     * @param _maxMintAmountPerTx New maximum minting amount.
     */
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;

        emit MaxMintAmountPerTxUpdated(_maxMintAmountPerTx);
    }

    /**
     * @dev Set the hidden metadata URI.
     * @param _hiddenMetadataUri New hidden metadata URI.
     */
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;

        emit HiddenMetadataUriUpdated(_hiddenMetadataUri);
    }

    /**
     * @dev Set the base URI for a specific face state.
     * @param _state Face state for which to set the base URI.
     * @param _baseURI New base URI for the face state.
     */
    function setStateBaseURI(FaceState _state, string memory _baseURI) public onlyOwner {
        stateBaseURIs[_state] = _baseURI;

        emit StateBaseURIUpdated(_state, _baseURI);
    }

    /**
     * @dev Set the URI suffix for token URIs.
     * @param _uriSuffix New URI suffix.
     */
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;

        emit UriSuffixUpdated(_uriSuffix);
    }

    /**
     * @dev Set the operational status of the contract.
     * @param _state New operational status.
     */
    function setPaused(bool _state) public onlyOwner {
        paused = _state;

        emit ContractPaused(_state);
    }

    /**
     * @dev Set the Merkle root for whitelist validation.
     * @param _merkleRoot New Merkle root.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Enable or disable whitelist minting.
     * @param _state New whitelist minting status.
     */
    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;

        emit WhitelistMintEnabledUpdated(_state);
    }

    /**
     * @dev Allows the owner to withdraw funds to the specified address from the contract.
     */
    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(0x433054718933E44E1314F4C5763D33DA4C23207e).call{value: address(this).balance}('');
        require(os);
    }
}