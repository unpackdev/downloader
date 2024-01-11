// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

// import "./ERC1155Upgradeable.sol";
import "./ERC1155.sol";
import "./console.sol";
import "./Counters.sol";
import "./SafeMath.sol";

/**
 * @title Ettios NFT
 */
// contract Erc1155Token is ERC1155Upgradeable {
contract Erc1155Token is ERC1155 {
    using SafeMath for uint256;


    address payable public _owner;
    address[] _emitters;
    // string public _baseUri = "https://mkt.ettios.io/token/{id}.json";

    struct AssetData {
        uint index;
        address creator;
        string company;
        string assetName;
        string assetSymbol;
        string metadataUrl;
        uint creatorFee; // in percentage (1% = 100)
    }

    mapping(uint => AssetData) public assets;
    uint[] public tokenList;
    mapping(address => uint[]) _assetIndexes;
    mapping(address => int) _investorBalances;
    address[] public _tokenOwners;
    using Counters for Counters.Counter;
    Counters.Counter private maxTokenId;
    mapping(uint256 => mapping(address => uint256)) private salePrice;

    // fee for company (1% = 100)
    uint public orgFee = 100;
    uint public fixedOrgFee = 2e15;

    mapping(uint => AssetData) public lazyAssets;
    //lazyTokenId => amount
    mapping(uint => uint) public lazyBalances;
    Counters.Counter private lazyId;
    mapping(uint256 => uint256) private lazyPrice;

    event NewToken(address tokenOwner, uint tokenId, string tokenUri, uint amount);
    event LazyToken(address creator, uint lazyTokenId, string tokenUri, uint amount);
    event Burned(address tokenOwner, uint tokenId, string tokenUri);

    modifier onlyOwner() {
        require(
            _msgSender() == _owner,
            "only owner can call this function"
        );
        _;
    }

    modifier onlyOwnerOrEmitters() {
        address sender = _msgSender();
        bool doesListContainElement = false;
        for (uint i=0; i < _emitters.length; i++) {
            if (sender == _emitters[i]) {
                doesListContainElement = true;
            }
        }
        require(doesListContainElement ||
            _msgSender() == _owner,
            "only owner or emitters can execute this function"
        );
        _;
    }
    
    modifier onlyHodlerOf(address _hodler, uint256 _tokenId) {
        require(balanceOf(_hodler, _tokenId) > 0, "given wallet does not own this token");
        _;
    }
    
    modifier onlyCreatorOf(address _creator, uint256 _lazyTokenId) {
        require(lazyAssets[_lazyTokenId].creator == _creator, "given wallet is not the creator of this token");
        _;
    }

    modifier onlyOwnerOrEmittersOrHodler(address hodler) {
        address sender = _msgSender();
        bool doesListContainElement = false;
        for (uint i=0; i < _emitters.length; i++) {
            if (sender == _emitters[i]) {
                doesListContainElement = true;
            }
        }
        require(hodler == sender || doesListContainElement ||
            _msgSender() == _owner,
            "Only hodler, owner or emitters can execute this function"
        );
        _;
    }

    constructor(string memory _url) ERC1155(_url) {
        _owner = payable(_msgSender());
        // _baseUri = _url;
    }

    // function initializeNFT(string memory _url)
    //     public
    //     initializer
    // {
    //     _owner = payable(_msgSender());
    //     if(bytes(_url).length > 0 && bytes(_url) != bytes("")) {
    //         _baseUri = _url;
    //     }
    //     __ERC1155_init(_baseUri);
    // }
    
    // function _msgSender() internal view virtual returns (address) {
    //     return msg.sender;
    // }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = payable(newOwner);
    }

    function getOwner() public view onlyOwnerOrEmitters returns (address) {
        return _owner;
    }

    function getEmitters() public view onlyOwnerOrEmitters returns (address[] memory) {
        return _emitters;
    }

    function setOrgFee(uint _fixedOrgFee, uint _fee) external onlyOwner {
        require(_fee < 10000, "fee must be less than 100% (1% = 100)");
        orgFee = _fee;
        fixedOrgFee = _fixedOrgFee;
    }

    function addEmitter(address newEmitter) public onlyOwner {
        _emitters.push(newEmitter);
    }

    fallback() external payable{ }
    receive() external payable {}


    function getBalance() public view onlyOwnerOrEmitters returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No hay nada que retirar");
        payable(_msgSender()).transfer(address(this).balance);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return assets[tokenId].metadataUrl;
    }

    function mintByEmitters(
        address _to,
        string memory company,
        string memory assetName,
        string memory assetSymbol,
        string memory metadataUrl,
        uint creatorFee,
        uint amount
    ) public onlyOwnerOrEmitters {
        uint lazyTokenId = _setAssetData(
            _msgSender(),
            company,
            assetName,
            assetSymbol,
            metadataUrl,
            creatorFee,
            amount
        );
        _finishMinting(_to, lazyTokenId, amount);
    }

    function startLazyMint(
        string memory company,
        string memory assetName,
        string memory assetSymbol,
        string memory metadataUrl,
        uint creatorFee,
        uint amount) payable external{
        require(msg.value >= fixedOrgFee, "You must cover fixed fee");
        _setAssetData(
            _msgSender(),
            company,
            assetName,
            assetSymbol,
            metadataUrl,
            creatorFee,
            amount
        );
    }

    function buyLazyToken(
        uint _lazyTokenId,
        uint amount) payable external{
        require(amount > 0, "You must buy at least 1 token");
        require(lazyAssets[_lazyTokenId].creator != address(0), "assets not found");
        require(lazyBalances[_lazyTokenId] >= amount, "not enough tokens");
        require(lazyPrice[_lazyTokenId] > 0, "price not set yet");
        uint totalPrice = amount * lazyPrice[_lazyTokenId];
        require(msg.value >= totalPrice, "insufficient funds to buy");
        console.log("totalPrice %s", totalPrice);
        uint fees = totalPrice * orgFee / 10000;
        console.log("orgFee %s", orgFee);
        console.log("fees %s", fees);
        uint earnings = totalPrice - fees;
        _finishMinting(_msgSender(), _lazyTokenId, amount);
        payable(lazyAssets[_lazyTokenId].creator).transfer(earnings);
    }

    function _setAssetData(
        address creator,
        string memory company,
        string memory assetName,
        string memory assetSymbol,
        string memory metadataUrl,
        uint creatorFee,
        uint amount
    ) internal returns (uint256) {
        // require(creatorFee > 0, "creator fee must be greater than 0");
        lazyId.increment();
        uint256 tokenId = lazyId.current();

        AssetData memory entry = assets[tokenId];
        console.log("entry %s", entry.creator);
        require(entry.creator == address(0), "token already created");
        entry = AssetData(tokenId, creator, company,
            assetName, assetSymbol, metadataUrl, creatorFee);
        lazyAssets[entry.index] = entry;
        lazyBalances[entry.index] = amount;
        emit LazyToken(creator, tokenId, metadataUrl, amount);
        return tokenId;
    }

    function _finishMinting(
        address _to,
        uint lazyTokenId,
        uint amount
    ) internal {
        maxTokenId.increment();
        AssetData memory prefilled = lazyAssets[lazyTokenId];
        require(prefilled.creator != address(0), "lazy asset doesn't exist");
        require(lazyBalances[prefilled.index] >= amount, "not enough amount");
        uint tokenId = maxTokenId.current();
        lazyBalances[prefilled.index] -= amount;

        if(_investorBalances[_to] > 0){
            _assetIndexes[_to].push(tokenId);
        } else {
            _assetIndexes[_to] = [tokenId];
            _investorBalances[_to] = int(amount);
            _tokenOwners.push(_to);
        }

        prefilled.index = tokenId;
        bool exist = false;
        for(uint i = 0; i < tokenList.length; i++){
            if(tokenList[i] == prefilled.index){
                exist = true;
                break;
            }
        }
        if(!exist){
            tokenList.push(prefilled.index);
        }
        // shareholdings[entry.index] = entry;
        assets[prefilled.index] = prefilled;

        _mint(_to, tokenId, amount, bytes(""));
        emit NewToken(_to, tokenId, prefilled.metadataUrl, amount);
    }

    function burn(uint _tokenId, uint amount) public {
        require(
            balanceOf(_msgSender(), _tokenId) > 0,
            "Only token owner can burn this token"
        );
        string memory tokenUri = uri(_tokenId);
        _burn(_msgSender(), _tokenId, amount);

        AssetData storage entry = assets[_tokenId];
        if(entry.creator != address(0)){
            // Move last element of array into the vacated key slot.
            uint entryIndex = entry.index;
            uint lastItemIndex = tokenList.length - 1;
            assets[tokenList[lastItemIndex]].index = entryIndex;
            tokenList[entryIndex] = tokenList[lastItemIndex];
            delete tokenList[lastItemIndex];
            delete assets[_tokenId];
        }
        _updateBalances(_msgSender(), _tokenId, amount);
        emit Burned(_msgSender(), _tokenId, tokenUri);
    }

    function _updateBalances(address _tokenOwner, uint _tokenId, uint amount) internal{
        if(_investorBalances[_tokenOwner] > 0){
            _investorBalances[_tokenOwner] = int(_investorBalances[_tokenOwner]) - int(amount);
            if(_investorBalances[_tokenOwner] < 0){
                _investorBalances[_tokenOwner] = 0;
            }
            uint assetsCount = _assetIndexes[_tokenOwner].length;
            for(uint i = 0; i < assetsCount; i++){
                if(_assetIndexes[_tokenOwner][i] == _tokenId){
                    uint currentBalance = balanceOf(_tokenOwner, _tokenId);
                    if(currentBalance == 0){
                        _assetIndexes[_tokenOwner][i] = _assetIndexes[_tokenOwner][assetsCount - 1];
                        delete _assetIndexes[_tokenOwner][assetsCount - 1];
                        break;
                    }
                }
            }
            assetsCount = _assetIndexes[_tokenOwner].length;
            if(assetsCount < 1){
                delete _assetIndexes[_tokenOwner];
                _investorBalances[_tokenOwner] = 0;
                uint ownersCount = _tokenOwners.length;
                for(uint i = 0; i < ownersCount; i++){
                    if(_tokenOwners[i] == _tokenOwner){
                        _tokenOwners[i] = _tokenOwners[ownersCount - 1];
                        delete _tokenOwners[ownersCount - 1];
                    }
                }
                if(ownersCount <= 1){
                    delete _tokenOwners;
                }
            }
        }
    }

    // function getFullURI(uint tokenId) public view virtual returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //     string memory baseURI = _baseURI();
    //     return string(abi.encodePacked(baseURI, assets[tokenId].company, "/", shareholdings[tokenId].assetName, "/", tokenId));
    // }

    function getHodlers() public view onlyOwnerOrEmitters returns (address[] memory) {
        return _tokenOwners;
    }

    function getBalanceOf(address hodler) public view onlyOwnerOrEmittersOrHodler(hodler) returns (int) {
        return _investorBalances[hodler];
    }

    function getAssetIndexesOf(address hodler) public view onlyOwnerOrEmittersOrHodler(hodler) returns (uint[] memory) {
        return _assetIndexes[hodler];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
        _updateBalances(_msgSender(), id, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(ids.length == amounts.length, "ERC1155: ids and amounts must be of the same length");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        for(uint i = 0; i < ids.length; i++){
            _updateBalances(_msgSender(), ids[i], amounts[i]);
        }
    }

    function totalLazySupply() public view virtual returns (uint256) {
        return lazyId.current();
    }

    function totalSupply() public view virtual returns (uint256) {
        return maxTokenId.current();
    }

    function setLazyPrice(uint256 _tokenId, uint256 price) public onlyCreatorOf(_msgSender(), _tokenId) {
        require(price > 0, "Price must be greater than 0");
        lazyPrice[_tokenId] = price;
    }

    function updatePrice(uint256 _tokenId, uint256 price) public onlyHodlerOf(_msgSender(), _tokenId) {
        require(price > 0, "Price must be greater than 0");
        require(balanceOf(_msgSender(), _tokenId) > 0, "You can't update price of token that you don't own");
        salePrice[_tokenId][_msgSender()] = price;
    }

    function getLazyPrice(uint256 _tokenId) public view returns (uint256) {
        return lazyPrice[_tokenId];
    }

    function getSalePrice(uint256 _tokenId, address hodler) public view returns (uint256) {
        return salePrice[_tokenId][hodler];
    }
}
