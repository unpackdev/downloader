// SPDX-License-Identifier: MIT

/*
A whimsical NFT drop to pay tribute to my beginnings as a programmer. Credit to Dr. Bryant Wyatt for showing me the beauty of code.
*/

pragma solidity =0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./OperatorFilterer.sol";
import "./SSTORE2.sol";


contract POINCARE is ERC721AQueryable, Ownable, ReentrancyGuard, OperatorFilterer {

    using Strings for uint256;
    string public uriPrefix = 'ipfs://QmPFCBwHcxsPVjDbRggeArbd2ymgvMoNHZDb9FMnFHYVwF/';
    string public uriSuffix = '.json';
    uint256 public cost;
    bool public paused = true;

    uint256 public mintingStartTime = 1698739891;
    uint256 public mintingDuration = 24 hours;

    address [] public pointer;
    mapping(uint256 => bytes32) public tokenHashes;
    
    string _tokenName = "Kepler Chaos by Higgsbelly";
    string _tokenSymbol = "KC";

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address public defaultRoyaltyReceiver;
    mapping(uint256 => address) royaltyReceivers;
    uint256 public defaultRoyaltyPercentage;
    mapping(uint256 => uint256) royaltyPercentages;
    
    address _defaultRoyaltyReceiver = 0xC9367730EDE93Bb941e0a5F6509618001b001fa4; //Higgs ADDRESS
    uint256 _defaultRoyaltyAmount = 42; // Points out 1000

    bool public operatorFilteringEnabled;

    constructor() ERC721A(_tokenName, _tokenSymbol) {
    setCost(19900000000000000);
    defaultRoyaltyReceiver = _defaultRoyaltyReceiver;
    defaultRoyaltyPercentage = _defaultRoyaltyAmount;
    _registerForOperatorFiltering();
    operatorFilteringEnabled = true;
    
    }

    modifier mintCompliance() {
        require(block.timestamp >= mintingStartTime && block.timestamp <= mintingStartTime + mintingDuration, "Minting is not allowed outside the minting period");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
    }

    function setMintingStartTime(uint256 _newStartTime) external onlyOwner {
    mintingStartTime = _newStartTime;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance() mintPriceCompliance(_mintAmount) {
        require(!paused, 'The contract is paused!');

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_msgSender(), 1);
            bytes32 hash = keccak256(abi.encodePacked(block.timestamp, _msgSender(), (totalSupply() - 1)));
            tokenHashes[(totalSupply() - 1)] = hash;
            emit TokenHashGenerated((totalSupply() - 1), hash);
        }
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance() onlyOwner() {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_receiver, 1);
            bytes32 hash = keccak256(abi.encodePacked(block.timestamp, _receiver, (totalSupply() - 1)));
            tokenHashes[(totalSupply() - 1)] = hash;
            emit TokenHashGenerated(totalSupply() - 1, hash);
        }
    }

    event TokenHashGenerated(uint256 indexed tokenId, bytes32 hash);

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
    }


    function setCost(uint256 _cost) public onlyOwner() {
    cost = _cost;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner() {
    uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner() {
    uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner() {
    paused = _state;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
    }

    function storeScript (string calldata _text) public onlyOwner() {
        pointer.push(SSTORE2.write(bytes(_text)));
    }

    function projectScriptByIndex (uint256 _index) external view returns (string memory) {
        return string(SSTORE2.read(pointer[_index]));
    }

    function editScript(string calldata _text, uint256 _index) external {
    require(_index < pointer.length, "Index out of bounds");
    pointer[_index] = SSTORE2.write(bytes(_text));
    }


    function withdraw() public onlyOwner() nonReentrant {

    (bool es, ) = payable(0x2B0386bbDd314d8356C21f39BE2491F975BD6361).call{value: address(this).balance * 100 / 1000}('');
    require(es);
    
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    
    }

    

    /*//////////////////////////////////////////////////////////////////////////
                        ERC2981 Functions START
    //////////////////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
    {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
        interfaceId == 0x01ffc9a7 ||
        interfaceId == 0x80ac58cd ||
        interfaceId == 0x5b5e139f ||
        interfaceId == 0x2a55205a ||
        super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceivers[_tokenId] != address(0)
            ? royaltyReceivers[_tokenId]
            : defaultRoyaltyReceiver;
        royaltyAmount = royaltyPercentages[_tokenId] != 0 ? (_salePrice * royaltyPercentages[_tokenId]) / 1000 : (_salePrice * defaultRoyaltyPercentage) / 1000;
    }

    function setDefaultRoyaltyReceiver(address _receiver) external onlyOwner() {
        defaultRoyaltyReceiver = _receiver;
    }

    function setRoyaltyReceiver(uint256 _tokenId, address _newReceiver)
        external onlyOwner()
    {
        royaltyReceivers[_tokenId] = _newReceiver;
    }

    function setRoyaltyPercentage(uint256 _tokenId, uint256 _percentage)
        external onlyOwner()
    {
        royaltyPercentages[_tokenId] = _percentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        ERC2981 Functions END
    //////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////
                        OS OPERATOR FILTER START
    //////////////////////////////////////////////////////////////////////////*/
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        OS OPERATOR FILTER END
    //////////////////////////////////////////////////////////////////////////*/
}