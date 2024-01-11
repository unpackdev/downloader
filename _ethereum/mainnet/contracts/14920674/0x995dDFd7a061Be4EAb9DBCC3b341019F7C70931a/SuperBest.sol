// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract SuperBest is ERC721A, Ownable, ReentrancyGuard  {
    using Strings for uint256;

    enum Stage { FreeSale, PublicSale, SoldOut }

    uint256 public maxSupply;
    uint256 public freeSupply;

    mapping(address => bool) private freeMinted;
    mapping(address => bool) private publicSaleMinted;

    uint64 public giftedMintCounts;

    uint256 public constant FREE_MINT_MAX_PER_WALLET = 1;
    uint256 public constant PUBLIC_MINT_MIN_PER_WALLET = 1;
    uint256 public constant PUBLIC_MINT_MAX_PER_WALLET = 10;

    uint256 public constant PUBLIC_SALE_PRICE = 0.01 ether;
    bool public isMintedSuspend;
    bool public isTransactionFreezed;

    string private baseTokenURI = "ipfs://QmatwBZ2zN3eJotE7sJZFkiZff16euGeKcsRQFYuadVhUp/";
    
    address public vaultAddress;

    bool private isOpenSeaProxyActive = true;
    address proxyRegistryAddress;

    event KidMinted(address account, uint256 startTokenId,uint256 amount);
    event KidBurned(address account, uint256 tokenId);

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============
    modifier isNotContract() {
        require(tx.origin == msg.sender,"contract is not allowed to operate");
        _;
    }

    modifier notMintSuspend(){
        require(!isMintedSuspend, "Mint best has been suspended!");
        _;
    }

    modifier publicSaleActive() {
        require(totalSupply() >= freeSupply, "Public sale is not open");
        _;
    }

    modifier canMintBestGlobal(uint256 numberOfTokens) {
        require(numberOfTokens > 0,"Mint count must be greater than 0");
        require(
            totalSupply() + numberOfTokens <=
                maxSupply,
            "Not enough bests remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            msg.value >= price * numberOfTokens,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isCorrectAmount(uint256 numberOfTokens){
        require(numberOfTokens >= PUBLIC_MINT_MIN_PER_WALLET && numberOfTokens <= PUBLIC_MINT_MAX_PER_WALLET,
        "Incorrect mint amount sent.");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _openSeaProxyRegistryAddress,
        uint256 _maxSupply,
        uint256 _freeSupply
        ) ERC721A(name, symbol){
        proxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxSupply = _maxSupply;
        freeSupply = _freeSupply;
        vaultAddress = owner();
    }

    function setMintSuspend(bool isSuspend) external onlyOwner{
        isMintedSuspend = isSuspend;
    }

    function freezeTransaction(bool isFreezed) external onlyOwner{
        isTransactionFreezed = isFreezed;
    }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function getCurrentStage() public view returns (Stage){
        Stage curStage;
        if(getLeftBestCount() == 0){
            curStage = Stage.SoldOut;
        }
        else if(totalSupply() >= freeSupply){
            curStage = Stage.PublicSale;
        }else {
            curStage = Stage.FreeSale;
        }
        
        return curStage;
    }

    function getLeftBestCount() public view returns(uint256){
        uint256 numMintedSoFar = totalSupply();
        return maxSupply - numMintedSoFar;
    }

    function freeMint()
    external
    nonReentrant
    isNotContract
    notMintSuspend
    canMintBestGlobal(FREE_MINT_MAX_PER_WALLET)
    {
        require(totalSupply() + FREE_MINT_MAX_PER_WALLET <= freeSupply,"Exceed maximum free mint quantity.");
        require(!freeMinted[msg.sender],"You have mint best by free,please try other mint method.");
        freeMinted[msg.sender] = true;

        _mintNFT(msg.sender,FREE_MINT_MAX_PER_WALLET);
    }

    function mint(uint256 amount)
    external
    payable
    nonReentrant
    isNotContract
    publicSaleActive
    notMintSuspend
    isCorrectAmount(amount)
    isCorrectPayment(PUBLIC_SALE_PRICE, amount)
    canMintBestGlobal(amount)
    {
        require(!publicSaleMinted[msg.sender],"You have minted bests before.");
        publicSaleMinted[msg.sender] = true;

        _mintNFT(msg.sender,amount);
        refundIfOver(PUBLIC_SALE_PRICE * amount);
    }

    function airDrop(address to, uint256 amount) 
    external
    nonReentrant
    isNotContract
    notMintSuspend
    canMintBestGlobal(amount)
    onlyOwner
    {
        giftedMintCounts += uint64(amount);
        _mintNFT(to, amount);
    }

    function _mintNFT(address to, uint256 amount) internal {
        _safeMint(to, amount);
        emit KidMinted(msg.sender, _nextTokenId(), amount);
    }

    function burnNFT(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        require(ownerOf(tokenId) == msg.sender, "not your token");
        _burn(tokenId);
        emit KidBurned(msg.sender,tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "SuperBest: Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() external onlyOwner {
        require(vaultAddress != address(0x0), "vault address is not set");
        payable(vaultAddress).transfer(address(this).balance);
    }

    function setApprovalForAll(address operator, bool approved) 
    public 
    override 
    {
        require(!isTransactionFreezed,"Transaction has been freezed!");
        super.setApprovalForAll(operator,approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if(isTransactionFreezed){
            return false;
        }else{
            // whitelist OpenSea proxy contract for easy trading.
            if (proxyRegistryAddress != address(0x0)) {
                ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
                if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
                    return true;
                }
            }

            return super.isApprovedForAll(owner, operator);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if(isTransactionFreezed){
            revert('Transaction is being Freezed now!');
        }else{
            super.transferFrom(from,to,tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        if(isTransactionFreezed){
            revert('Transaction is being Freezed now!');
        }else{
            super.safeTransferFrom(from,to,tokenId,_data);
        }
    }

    // should never be used inside of transaction because of gas fee
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 i = 0;
            uint256 numMintedSoFar = _nextTokenId();
            while(i < numMintedSoFar){
                if(_exists(i)){
                    TokenOwnership memory ownership = _ownershipOf(i);
                    if (ownership.addr == owner && resultIndex < tokenCount) {
                        result[resultIndex] = i;
                        resultIndex++;
                    }
                }
                i++;
            }

            return result;
        }
    }

    function getTokenIds()
    internal
    view
    returns (uint256[] memory _tokenIds){
        uint256[] memory tokenIdList = new uint256[](totalSupply());
        uint index = 0;
        for(uint i = _startTokenId();i < _nextTokenId();i++){
            if(_exists(i)){
                tokenIdList[index] = i;
                index++;
            }
        }
        return tokenIdList;
    }

    function tokenByIndex(uint256 _index) public view returns (uint256 tokenId){
        if(totalSupply() > 0){
            return getTokenIds()[_index];
        }else{
            revert('No any token has been minted so far.');
        }
    }
}