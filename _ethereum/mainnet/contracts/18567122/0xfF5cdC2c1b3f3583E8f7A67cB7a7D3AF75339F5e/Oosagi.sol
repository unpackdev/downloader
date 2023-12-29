// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

//   ___    ___   _____  ____   ____  ____ 
//  /   \  /   \ / ___/ /    | /    ||    |
// |     ||     (   \_ |  o  ||   __| |  | 
// |  O  ||  O  |\__  ||     ||  |  | |  | 
// |     ||     |/  \ ||  _  ||  |_ | |  | 
// |     ||     |\    ||  |  ||     | |  | 
//  \___/  \___/  \___||__|__||___,_||____|
//
// https://twitter.com/oosagiNFT
//
                                                                    
contract Oosagi is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseTokenURI;
    string public defaultTokenURI;
    uint256 public maxSupply;
    uint8 public maxMintsPerAddress;

    bool public isPresaleActive;
    bool public isCompleted;
    bool public isRevealed;
    bool public isSaleActive;

    bytes32 presaleListMerkleRoot;

    uint256 public constant mintPrice = 0.03 ether;

    modifier notCompleted() {
        require(
            !isCompleted,
            'Collection is completed, cannot make changes anymore.'
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller must be a user.');
        _;
    }

    modifier isInStock(uint8 quantity) {
        require(
            _nextTokenId() + quantity <= maxSupply + 1,
            'Oosagi is out of stock.'
        );
        _;
    }

    modifier isWithinMaxMints(uint8 quantity) {
        require(
            _numberMinted(msg.sender) + quantity <= maxMintsPerAddress,
            'This wallet has reached the maximum allowed number of mints.'
        );
        _;
    }

    modifier isWithinMaxMintsPerTxn(uint8 quantity) {
        require(
            quantity <= maxMintsPerAddress,
            'The quantity exceeds the maximum tokens allowed per transaction.'
        );
        _;
    }

    modifier isPaymentAmountValid(uint8 quantity) {
        require(msg.value == quantity * mintPrice, 'Incorrect payment amount.');
        _;
    }

    modifier isValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        require(
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            'Address is not on the mint list.'
        );
        _;
    }

    /**
     * @notice Constructor for Oosagi
     * @param name Token name
     * @param symbol Token symbol
     * @param baseTokenURI_ Base URI for completed tokens
     * @param defaultTokenURI_ URI for tokens that aren't completed, unrevealed if you will
     * @param maxSupply_ Max Supply of tokens
     * @param maxMintsPerAddress_ Max mints an address is allowed
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        string memory defaultTokenURI_,
        uint256 maxSupply_,
        uint8 maxMintsPerAddress_
    ) ERC721A(name, symbol) {
        require(maxSupply_ > 0, 'INVALID_SUPPLY');
        baseTokenURI = baseTokenURI_;
        defaultTokenURI = defaultTokenURI_;
        maxSupply = maxSupply_;
        maxMintsPerAddress = maxMintsPerAddress_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _defaultURI() internal view returns (string memory) {
        return defaultTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokensMintedByAddress(address ad) public view returns (uint256) {
        return _numberMinted(ad);
    }

    function getMerkleRoot() public view returns (bytes32) {
        return presaleListMerkleRoot;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), 'URI query for nonexistent token.');

        if (isRevealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), '.json')
                );
        } else {
            return string(abi.encodePacked(_defaultURI()));
        }
    }

    function isCollectionComplete() public view returns (bool) {
        return isCompleted;
    }

    function mint(uint8 quantity)
        external
        payable
        callerIsUser
        isWithinMaxMintsPerTxn(quantity)
        isPaymentAmountValid(quantity)
        isInStock(quantity)
        nonReentrant
    {
        require(isSaleActive, 'Public sale is not active.');
        _safeMint(msg.sender, quantity);
    }

    function presaleListMint(bytes32[] calldata merkleProof, uint8 quantity)
        external
        payable
        callerIsUser
        isWithinMaxMints(quantity)
        isPaymentAmountValid(quantity)
        isInStock(quantity)
        isValidMerkleProof(presaleListMerkleRoot, merkleProof)
        nonReentrant
    {
        require(isPresaleActive, 'Presale list sale is not active.');
        _safeMint(msg.sender, quantity);
    }


    function ownerMint(uint8 quantity)
        external
        onlyOwner
        callerIsUser
        isInStock(quantity)
        nonReentrant
    {
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setBaseURI(string calldata _newBaseURI)
        external
        notCompleted
        onlyOwner
    {
        baseTokenURI = _newBaseURI;
    }

    function setDefaultURI(string calldata _newDefaultURI)
        external
        notCompleted
        onlyOwner
    {
        defaultTokenURI = _newDefaultURI;
    }

    function setComplete() external notCompleted onlyOwner {
        isCompleted = true;
    }

    function setIsRevealed(bool _isRevealed) external notCompleted onlyOwner {
        isRevealed = _isRevealed;
    }

    function setPresaleState(bool isActive) external notCompleted onlyOwner {
        isPresaleActive = isActive;
    }

    function setPresaleMerkleRoot(bytes32 merkleRoot)
        external
        notCompleted
        onlyOwner
    {
        presaleListMerkleRoot = merkleRoot;
    }

    function setSaleState(bool isActive) external notCompleted onlyOwner {
        isSaleActive = isActive;
    }
}
