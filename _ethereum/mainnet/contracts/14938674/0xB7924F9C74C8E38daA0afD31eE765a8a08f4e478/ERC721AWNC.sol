// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
// modified: robbie oh (robbieinertia@gmail.com)

pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract ERC721AWNC is ERC721A, Ownable {
    uint256 internal immutable FOUNDERS_CAP = 204;
    uint256 internal immutable MAXIMUM_PUBLIC_AMOUNT = 10;
    uint256 internal immutable PRICE_PER_TOKEN_TYPEA = 0.07 ether;
    uint256 internal immutable PRICE_PER_TOKEN_TYPEB = 0.08 ether;
    uint256 internal immutable PRICE_PER_TOKEN_PUBLIC = 0.09 ether;

    uint256 public maximumSupply;
    bytes32 internal _merkleRootWhitelistTypeA;
    bytes32 internal _merkleRootWhitelistTypeB;
    uint256 public mintACount;
    uint256 public mintBCount;
    bool internal _isOnSale = false;
    bool internal _isPublic = false;
    bool internal _isPresale = false;
    bool internal _isFinished = false;
    bool internal _isFoundersTokenIssued = false;
    string internal _currentBaseURL = 'https://storage.googleapis.com/weirdnomadclub/metadata/';
    address internal _founderNFTMinter;

    mapping(address => uint256) public claimedAmountTypeA;
    mapping(address => uint256) public claimedAmountTypeB;
    mapping(address => uint256) public claimedAmountPublic;
    mapping(uint256 => string) public ipfsURI;

    event MerkleRootWhitelistTypeAChanged(bytes32 _newMerkleRoot);
    event MerkleRootWhitelistTypeBChanged(bytes32 _newMerkleRoot);

    constructor(
        uint256 _newMaximumSupply,
        bytes32 _newMerkleRootWhitelistTypeA,
        bytes32 _newMerkleRootWhitelistTypeB,
        address _newMinter
    ) Ownable() ERC721A('Weird Nomad Club', 'WNC') {
        maximumSupply = _newMaximumSupply;
        _merkleRootWhitelistTypeA = _newMerkleRootWhitelistTypeA;
        _merkleRootWhitelistTypeB = _newMerkleRootWhitelistTypeB;
        _founderNFTMinter = _newMinter;

        emit MerkleRootWhitelistTypeAChanged(_merkleRootWhitelistTypeA);
        emit MerkleRootWhitelistTypeBChanged(_merkleRootWhitelistTypeB);
    }

    modifier onSales() {
        require(_isOnSale, 'NFTContract: not on sale');
        require(!_isFinished, 'NFT: already finished');
        _;
    }

    modifier notContractCall() {
        require(tx.origin == msg.sender, 'NFT: contract call is prevented');
        _;
    }

    modifier onlyMinter() {
        require(_founderNFTMinter == msg.sender, 'NFT: not a minter');
        _;
    }

    modifier onPresale() {
        require(_isPresale, 'NFT: not on presale');
        _;
    }

    event TypeAMinted(uint256 _amount, address _minter);

    function mintTypeA(
        uint256 _amount,
        uint256 _allowedAmount,
        bytes32[] calldata _merkleProof
    ) public payable onSales onPresale {
        require(msg.value == _amount * PRICE_PER_TOKEN_TYPEA, 'NFT: the price paid is lower than current price');
        require(
            isWhitelist(msg.sender, _allowedAmount, _merkleProof, _merkleRootWhitelistTypeA),
            'NFT: not allowed in the whitelist'
        );
        require(
            (claimedAmountTypeA[msg.sender] + _amount) <= _allowedAmount,
            'NFT: the requested amount is exceeded type A allowance'
        );

        claimedAmountTypeA[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);

        require(totalSupply() <= maximumSupply, 'NFT: Exceeded maximum supply');
        mintACount += _amount;
        emit TypeAMinted(_amount, msg.sender);
    }

    event TypeBMinted(uint256 _amount, address _minter);

    function mintTypeB(
        uint256 _amount,
        uint256 _allowedAmount,
        bytes32[] calldata _merkleProof
    ) public payable onSales onPresale {
        require(msg.value == _amount * PRICE_PER_TOKEN_TYPEB, 'NFT: the price paid is lower than current price');
        require(
            isWhitelist(msg.sender, _allowedAmount, _merkleProof, _merkleRootWhitelistTypeB),
            'NFT: not allowed in the whitelist'
        );
        require(
            (claimedAmountTypeB[msg.sender] + _amount) <= _allowedAmount,
            'NFT: the requested amount is exceeded type B allowance'
        );

        claimedAmountTypeB[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);

        require(totalSupply() <= maximumSupply, 'NFT: Exceeded maximum supply');
        mintBCount += _amount;
        emit TypeBMinted(_amount, msg.sender);
    }

    event PublicMinted(uint256 _amount, address _minter);

    function mintPublic(uint256 _amount) public payable onSales notContractCall {
        require(msg.value == _amount * PRICE_PER_TOKEN_PUBLIC, 'NFT: the price paid is lower than current price');
        require(_isPublic, 'NFT: not on public sales');
        require(
            (claimedAmountPublic[msg.sender] + _amount) <= MAXIMUM_PUBLIC_AMOUNT,
            'NFT: exceeded maximum public quota'
        );

        claimedAmountPublic[msg.sender] += _amount;

        _safeMint(msg.sender, _amount);
        require(totalSupply() <= maximumSupply, 'NFT: total supply is exeeded maximum');
        emit PublicMinted(_amount, msg.sender);
    }

    // admin
    event SaleOpened();
    event PresaleOpened();

    function openSale() public onlyOwner {
        _isOnSale = true;
        _isPresale = true;

        emit SaleOpened();
        emit PresaleOpened();
    }

    event PresaleClosed();

    function closePresale() public onlyOwner {
        _isPresale = false;

        emit PresaleClosed();
    }

    event SaleClosed();

    function closeSale() public onlyOwner {
        _isOnSale = false;

        emit SaleClosed();
    }

    event PublicSale();

    function openPublic() external onlyOwner {
        require(!_isPublic, 'NFT: it is already public');

        _isPublic = true;

        emit PublicSale();
    }

    event PrivateSale();

    function closePublic() external onlyOwner {
        require(_isPublic, 'NFT: it is already private');

        _isPublic = false;

        emit PrivateSale();
    }

    event FoundersTokenIssued();

    function mintFoundersToken(address _foundersWalletAddress) external onlyMinter onSales {
        require(!_isFoundersTokenIssued, 'NFT: founders token already minted');
        _safeMint(_foundersWalletAddress, FOUNDERS_CAP);
        _isFoundersTokenIssued = true;

        emit FoundersTokenIssued();
    }

    event TokenSalesEnded();

    function endSales() external onlyMinter onSales {
        require(!_isFinished, 'NFT: it already finished');
        _isFinished = true;

        emit TokenSalesEnded();
    }

    function sendEthers(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    event MaximumSupplyChanged(uint256 _maximumSupply);

    function setMaximumSupply(uint256 _newMaximumSupply) external onlyOwner {
        require(_newMaximumSupply > maximumSupply, 'NFT: the new one is lower than the current supply');

        maximumSupply = _newMaximumSupply;

        emit MaximumSupplyChanged(_newMaximumSupply);
    }

    function setMerkleWhitelistTypeA(bytes32 _merkleRootWhitelist) external onlyOwner {
        _merkleRootWhitelistTypeA = _merkleRootWhitelist;

        emit MerkleRootWhitelistTypeAChanged(_merkleRootWhitelist);
    }

    function setMerkleWhitelistTypeB(bytes32 _merkleRootWhitelist) external onlyOwner {
        _merkleRootWhitelistTypeB = _merkleRootWhitelist;

        emit MerkleRootWhitelistTypeBChanged(_merkleRootWhitelist);
    }

    function setTotalMintingAmount(uint256 _newMaximumSupply) external onlyOwner {
        maximumSupply = _newMaximumSupply;
    }

    function setBaseURL(string memory _newBaseURL) external onlyOwner {
        _currentBaseURL = _newBaseURL;
    }

    function setMinter(address _newMinter) external onlyOwner {
        _founderNFTMinter = _newMinter;
    }

    event IPFSURLSet(uint256 tokenId, string uri);

    function setIpfsURI(uint256 tokenId, string memory uri) public onlyOwner {
        ipfsURI[tokenId] = uri;
        emit IPFSURLSet(tokenId, uri);
    }

    struct TokenUrl {
        uint256 tokenId;
        string uri;
    }

    function setIpfsURIBatch(TokenUrl[] memory urls) external onlyOwner {
        for (uint256 i = 0; i < urls.length; i++) {
            setIpfsURI(urls[i].tokenId, urls[i].uri);
        }
    }

    // view
    function isWhitelist(
        address _address,
        uint256 _allowedAmount,
        bytes32[] calldata _merkleProof,
        bytes32 _merkleRoot
    ) public pure returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_address, _allowedAmount));
        return MerkleProof.verify(_merkleProof, _merkleRoot, node);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(ipfsURI[tokenId]).length == 0) {
            return _tokenURI(tokenId);
        }
        return ipfsURI[tokenId];
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURL;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}