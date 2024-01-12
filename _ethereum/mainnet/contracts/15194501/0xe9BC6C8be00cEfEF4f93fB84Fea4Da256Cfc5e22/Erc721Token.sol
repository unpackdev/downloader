// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**  
* @title An NFT Marketplace contract for Ethernaal NFTs
* @author Ethernaal
* @notice This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
* @dev Most function calls are currently implemented with access control
* This is the Ethernaal Marketplace contract for Minting NFTs and Direct Sale only.
*/
import "./ERC721.sol";

interface IERC20{
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


struct AssetData {
    uint256 assetId;
    uint256 tokenId;
    address creator;
    string title;
    string artistName;
    string tokenUri;
    bool isForSale;
    string nftType;
    string status;
}

struct SaleData{
    uint256 tokenId;
    uint256 price;
    uint256 naalPrice;
}

struct NftType{
    string nftType;
    bool reqWhitelist;
}

contract EthernaalNFT is ERC721{

    address public owner;
    address[] admins;
    address public blackUniOrg;
    address payable public ethernaalOrg;
    uint256 orgFee;
    uint256 blackUniFee;
    uint256 creatorFee; // in percentage (1% = 100)
    // uint256 sellerFee;
    uint256 orgFeeInitial;
    uint256 blackUniFeeInital;
    IERC20 public naalToken;

    //mapping creator to whitelisted nft types 
    mapping(address => string[]) cWL;
    //mapping creator to asset id
    mapping(address => uint[]) creatorAssetIds;
    mapping(address => uint[]) creatorLazyAssetIds;
    //list of allowed NFT types
    NftType[] public listNftTypes;

    uint public nftSupply;
    uint public assetSupply;
    mapping(uint => AssetData) public assets;
    //mapping tokenId to token id
    mapping(uint => uint) public nfts;

    //mapping address owner to list of tokens
    mapping(address => uint[]) nftsOf;
    //mapping tokenId to sale data
    mapping(uint => SaleData) public _salePrices;
    //mapping lazy tokenId to sale data
    mapping(uint => SaleData) public _lazyPrices;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event WhitelistCreator(address indexed _creator, string[] nftTypes);
    event DelistCreator(address indexed _creator);
    event LazyToken(address indexed creator, uint indexed lazyTokenId, string tokenUri);
    event SalePriceSet(uint256 indexed _tokenId, uint256 _price, uint256 _naalPrice);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed assetId, uint256 _tokenId, bool payWithNaal);
    event Mint(address indexed creator, uint indexed assetId, uint indexed tokenId, string tokenURI);
    event Burned(address indexed tokenOwner, uint indexed assetId, uint indexed tokenId, string tokenUri);
    event StatusSet(uint indexed assetId, string indexed status);
    event OwnerChanged(address tOwner, address indexed newOwner, uint indexed assetId, uint indexed tokenId, uint price, bool payWithNaal);

    error InsufficientFundsToBuy(uint requested, uint paymentIntent);

    uint constant FLOAT_HANDLER_TEN_4 = 10000;

    /**
    * Modifier to allow only minters to mint
    */
    modifier onlyMinter(string memory nftType) virtual {
        require(isWhitelisted(_msgSender(), nftType), "You are not whitelisted");
        _;
    }

    /**
    * Modifier to allow only owners of a token to perform certain actions 
    */
    modifier onlyHodlerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner");
        _;
    }

    /**
    * Modifier to allow only owner of the contract to perform certain actions 
    */
    modifier onlyOwner() {
        require(_msgSender() == owner, "You are not the owner");
        _;
    }
    
    /**
    * Modifier to allow only admin of the organization to perform certain actions 
    */
    modifier onlyAdmins() {
        require(_msgSender() == owner || _isAdmin(_msgSender(), false), "You are not admin");
        _;
    }

    function _isAdmin(address _a, bool rmIfFound) internal returns (bool) {
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == _a) {
                if(rmIfFound){
                    admins[i] = admins[admins.length - 1];
                    admins.pop();
                }
                return true;
            }
        }
        return false;
    }

    constructor(string memory _name, 
        string memory _symbol,
        address payable org,
        address payable blackUnicornOrg,
        address naalAddress
    ) ERC721(_name, _symbol) {
        naalToken = IERC20(naalAddress);

        owner = _msgSender();
        ethernaalOrg = org;
        blackUniOrg = blackUnicornOrg;
        //Creator royalty Fee is fixed to be 1% of sales, org fee to be 1% and black unicorn to 0.5%
        //Multiply all the three % variables by 100, to kepe it uniform
        orgFee = 100;
        creatorFee = 100;
        blackUniFee = 50;
        // sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        //Fees for first sale only
        orgFeeInitial = 200;
        blackUniFeeInital = 50;
    }

    function _valAddr(address addr) internal pure{
        require(addr != address(0), "Invalid addr");
    }

    function transferSCOwnership(address newOwner) public virtual onlyOwner{
        _valAddr(newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
    * @dev Organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function setOrgAddress(address _newOrg) public onlyOwner{
        _valAddr(_newOrg);
        ethernaalOrg = payable(_newOrg);
    }

    /**
    * @dev Black Unicorn organisation address can be updated to another address in case of attack or compromise(`newOrg`)
    * Can be done only by the contract owner.
    */
    function setBlackUniAddress(address _blackUniOrg) public onlyOwner{
        _valAddr(_blackUniOrg);
        blackUniOrg = payable(_blackUniOrg);
    }

    function addAdmin(address _newAdmin) public onlyAdmins{
        _valAddr(_newAdmin);
        require(!_isAdmin(_newAdmin, false), "is already an admin");
        admins.push(_newAdmin);
    }

    function rmAdmin(address _admin) public onlyAdmins returns(bool){
        _valAddr(_admin);
        return _isAdmin(_admin, true);
    }

    function setNaalAddress(address _naalAddress) public onlyAdmins{
        _valAddr(_naalAddress);
        naalToken = IERC20(_naalAddress);
    }
    
    /** @dev Calculate the royalty distribution for organisation/platform and the
    * creator/artist.
    * Each of the organisation, creator royalty and the parent organsation fees
    * are set in this function.
    * The 'sellerFee' indicates the final amount to be sent to the seller.
    * The first iteration of whitepaper has the following stats:
    * orgFee = 2%
    * blackUnicornFee = 0.5%
    * artist royalty/creator fee = 0%
    * The above numbers can be updated later by the DAO
    */
    function setRoyaltyPercentage(uint256 _orgFee, uint _creatorFee, uint _blackUnicornFee, uint256 _orgFeeInitial, uint _blackUnicornFeeInitial) public onlyAdmins {
        //Sum of org fee and creator fee should be 100%
        require(10000 > _orgFee+_creatorFee+_blackUnicornFee, "seller should earn something");
        orgFee = _orgFee;
        creatorFee = _creatorFee;
        blackUniFee = _blackUnicornFee;
        // sellerFee = 10000 - orgFee - creatorFee - blackUniFee;
        orgFeeInitial = _orgFeeInitial;
        _blackUnicornFeeInitial = _blackUnicornFeeInitial;
    }

    /** @dev Return all the royalties including first sale and subsequent sale values
    * orgFee - % of fees that would go to the org from the total royalty
    * blackUniFee - % of fees for Black Unicorn
    * creatorRoyalty - % of fees that would go to the artist/creator
    * orgInitialRoyalty - % of fees that would go to the organisation on first sale
    * blackUniFeeInitial - % of fees that would go to Black Unicorn on first sale
    */
    function getRoyalties() public view returns (uint _orgFee, uint _blackUniFee, uint256 _creatorRoyalty, 
    uint256 _orgInitialRoyalty, uint _blakcUniFeeInitial) {
        return (orgFee, creatorFee, blackUniFee, orgFeeInitial, blackUniFeeInital);
    }

    function getNftTypes() public view returns (NftType[] memory) {
        return listNftTypes;
    }

    function addNftTypes(string[] memory types, bool[] memory reqWhitelist) public onlyAdmins {
        require(types.length == reqWhitelist.length, "both lists should be same length");
        for(uint j = 0; j < types.length; j++) {
            (bool exists,) = existsNftType(types[j]);
            if(!exists) {
                listNftTypes.push(NftType(types[j], reqWhitelist[j]));
            }
        }
    }

    function removeNftTypes(string[] memory types) public onlyAdmins {
        for(uint j = 0; j < types.length; j++) {
            _rmIfExistsNftType(types[j]);
        }
    }

    function existsNftType(string memory nftType) public view returns (bool, bool) {
        for(uint i = 0; i < listNftTypes.length; i++) {
            if(compareStrings(listNftTypes[i].nftType, nftType)) {
                return (true, listNftTypes[i].reqWhitelist);
            }
        }
        return (false, true);
    }

    function _rmIfExistsNftType(string memory nftType) internal {
        for(uint i = 0; i < listNftTypes.length; i++) {
            if(compareStrings(listNftTypes[i].nftType, nftType)) {
                listNftTypes[i] = listNftTypes[listNftTypes.length-1];
                listNftTypes.pop();
                return;
            }
        }
    }

    /**
    * This function is used to set the price of a token
    * @notice Only hodler of token is allowed to set the price of a token
    */
    function setPrice(uint256 tokenId, uint256 price, uint naalPrice) public onlyHodlerOf(tokenId) {
        require(price > 0, "Price should be greater than 0");
        require(naalPrice > 0, "NAAL Price should be greater than 0");
        require(tokenId > 0, "Token ID cannot be zero");
        require(tokenId <= nftSupply, "Token ID cannot be greater than existing token IDs");
        require(assets[tokenId].tokenId == tokenId, "Token ID does not exist");
        // require(_salePrices[tokenId].tokenId == tokenId, "Token ID does not exist");
        _salePrices[tokenId].price = price;
        _salePrices[tokenId].naalPrice = naalPrice;
    }

    function setLazyPrice(uint256 lazyTokenId, uint256 price, uint256 naalPrice) public {
        require(price > 0, "Price should be greater than 0");
        require(naalPrice > 0, "NAAL Price should be greater than 0");
        require(lazyTokenId > 0, "Token ID cannot be zero");
        require(lazyTokenId <= assetSupply, "Token ID cannot be greater than existing lazy token IDs");
        require(assets[lazyTokenId].assetId == lazyTokenId, "Token ID does not exist");
        require(assets[lazyTokenId].tokenId == 0, "Asset is already sold");
        require(assets[lazyTokenId].creator == _msgSender(), "Only creator of the token can set the price");
        SaleData storage lazyPrice = _lazyPrices[lazyTokenId];
        if(lazyPrice.tokenId == 0) {
            _lazyPrices[lazyTokenId].tokenId = lazyTokenId;
            _lazyPrices[lazyTokenId].price = price;
            _lazyPrices[lazyTokenId].naalPrice = naalPrice;
        }
    }

    function mintByCreator(
        address _to,
        string memory title,
        string memory artistName,
        string memory metadataUrl,
        string memory nftType
    ) public virtual onlyMinter(nftType) returns(uint256) {
        uint lazyTokenId = _setAssetData(
            _msgSender(),
            title,
            artistName,
            metadataUrl,
            nftType
        );
        return _finishMinting(_to, lazyTokenId);
    }
    
    function startLazyMint(
        string memory title,
        string memory artistName,
        string memory metadataUrl,
        string memory nftType) payable external returns(uint256) {
        uint lazyTokenId = _setAssetData(
            _msgSender(),
            title,
            artistName,
            metadataUrl,
            nftType
        );
        assets[lazyTokenId].isForSale = true;
        creatorLazyAssetIds[_msgSender()].push(lazyTokenId);
        return lazyTokenId;
    }
    
    function buyLazyTokenWithNaal(uint _lazyTokenId) external{
        uint allowance = naalToken.allowance(msg.sender, address(this));
        _validateBeforeBuy(_lazyTokenId, true, allowance);
        uint totalPrice = _lazyPrices[_lazyTokenId].naalPrice;

        (uint toSeller, uint _toCreator, uint toPlatform, uint toBlackUnicorn) 
            = _calcPaymentDistribution(totalPrice, 0, orgFeeInitial, blackUniFeeInital);
        require(_toCreator == 0, "creator should not be paid for the first sale");
        address tokenCreatorAddress = assets[_lazyTokenId].creator;
        
        uint tokenId = _finishMinting(_msgSender(), _lazyTokenId);
        _sendPayments(true, msg.sender, payable(tokenCreatorAddress), 0, 
            payable(tokenCreatorAddress), toSeller, toPlatform, toBlackUnicorn);
        emit Sold(_msgSender(), tokenCreatorAddress, totalPrice, _lazyTokenId, tokenId, true);
    }

    function buyLazyToken(uint _lazyTokenId) payable external{
        _validateBeforeBuy(_lazyTokenId, false, msg.value);
        uint totalPrice = _lazyPrices[_lazyTokenId].price;
        (uint toSeller, uint _toCreator, uint toPlatform, uint toBlackUnicorn) 
            = _calcPaymentDistribution(totalPrice, 0, orgFeeInitial, blackUniFeeInital);
        require(_toCreator == 0, "creator should not be paid for the first sale");
        address tokenCreatorAddress = assets[_lazyTokenId].creator;
        
        uint tokenId = _finishMinting(_msgSender(), _lazyTokenId);
        _sendPayments(false, msg.sender, payable(tokenCreatorAddress), 0, 
            payable(tokenCreatorAddress), toSeller, toPlatform, toBlackUnicorn);
        emit Sold(_msgSender(), tokenCreatorAddress, totalPrice, _lazyTokenId, tokenId, false);
    }

    function _validateBeforeBuy(uint _lazyTokenId, bool payWithNaal, uint payingValue) internal view {
        require(_lazyTokenId > 0 && _lazyTokenId <= assetSupply, "Token ID is not valid");
        require(assets[_lazyTokenId].tokenId == 0, "Asset is already sold");
        require(assets[_lazyTokenId].assetId == _lazyTokenId, "Invalid ID");
        require(assets[_lazyTokenId].creator != address(0), "assets not found or already minted");
        require(assets[_lazyTokenId].isForSale, "Token is not for sale");
        uint price = payWithNaal ? 
            _lazyPrices[_lazyTokenId].naalPrice
            : _lazyPrices[_lazyTokenId].price;
        require(price > 0, "price not set yet");
        if(payingValue < price){
            revert InsufficientFundsToBuy(price, payingValue);
        }
    }
    
    function _setAssetData(
        address creator,
        string memory title,
        string memory artistName,
        string memory tokenUri,
        string memory nftType
    ) internal returns (uint256) {
        (bool allowed, ) = existsNftType(nftType);
        require(allowed, "NFT type is not allowed");
        uint256 assetId = ++assetSupply;

        AssetData memory entry = assets[assetId];
        require(entry.creator == address(0), "token already created");
        entry = AssetData(assetId, 0, creator, title,
            artistName, tokenUri,
            false, nftType, "");
        assets[entry.assetId] = entry;
        emit LazyToken(creator, entry.assetId, tokenUri);
        return entry.assetId;
    }
    
    function _finishMinting(
        address _to,
        uint lazyTokenId
    ) internal returns (uint256){
        AssetData storage prefilled = assets[lazyTokenId];
        require(prefilled.tokenId == 0, "token already minted");
        require(prefilled.creator != address(0), "lazy asset doesn't exist");
        uint tokenId = ++nftSupply;

        if(nftsOf[_to].length == 0) {
            nftsOf[_to] = [tokenId];
        } else {
            nftsOf[_to].push(tokenId);
        }

        prefilled.tokenId = tokenId;
        prefilled.isForSale = false;
        prefilled.status = "SO";
        nfts[prefilled.tokenId] = prefilled.assetId;
        // assets[prefilled.assetId] = prefilled;
        delete _lazyPrices[lazyTokenId];

        creatorAssetIds[prefilled.creator].push(tokenId);
        _mint(_to, tokenId);
        emit Mint(prefilled.creator, prefilled.assetId, prefilled.tokenId, prefilled.tokenUri);
        return prefilled.tokenId;
    }

    function _calcPaymentDistribution(uint amount, uint creatorRoyalty, 
        uint platformFees, uint blackUnicornFee) 
    internal pure returns (
        uint toSeller, uint toCreator, uint toPlatform, uint toBlackUnicorn
    ){
        //Dividing by 100*100 as all values are multiplied by 100
        // uint256 toSeller = (msg.value * sellerFees) / FLOAT_HANDLER_TEN_4;
        toCreator = (amount * creatorRoyalty) / FLOAT_HANDLER_TEN_4;
        toPlatform = (amount * platformFees) / FLOAT_HANDLER_TEN_4;
        toBlackUnicorn = (amount * blackUnicornFee) / FLOAT_HANDLER_TEN_4;
        toSeller = amount - toCreator - toPlatform - toBlackUnicorn;
        // return (toSeller, toCreator, toPlatform, toBlackUnicorn);
    }

    
    /**
    * This function is used to set an NFT for sale. 
    * @dev The sale price set in this function will be used to perform the sale transaction
    * once the buyer wants to buy an NFT.
    */
    function setForSale(uint256 _tokenId, uint256 price, uint naalPrice) public virtual onlyHodlerOf(_tokenId) {
        require(_tokenId > 0 && _tokenId <= nftSupply, "Token ID is not valid");
        require(price > 0, "Price must be greater than 0");
        require(naalPrice > 0, "NAAL Price should be greater than 0");
        require(assets[nfts[_tokenId]].tokenId == _tokenId, "Token ID does not exist");
        _salePrices[_tokenId].price = price;
        _salePrices[_tokenId].naalPrice = naalPrice;
        assets[nfts[_tokenId]].isForSale = true;
        emit SalePriceSet(_tokenId, price, naalPrice);
    }

    /**
    * This function is used to buy an NFT which is on sale.
    */
    function buyTokenOnSaleWithNaal(uint256 tokenId) external {
        uint totalPrice = _salePrices[tokenId].naalPrice;
        uint allowance = naalToken.allowance(msg.sender, address(this));
        _finishSelling(_msgSender(), true, tokenId, totalPrice, allowance);
    }

    /**
    * This function is used to buy an NFT which is on sale.
    */
    function buyTokenOnSale(uint256 tokenId)
        external
        payable
    {
        uint totalPrice = _salePrices[tokenId].price;
        _finishSelling(_msgSender(), false, tokenId, totalPrice, msg.value);
    }

    function _finishSelling(address buyer, bool payWithNaal,
            uint256 tokenId, uint totalPrice, uint availableToSpend) internal {
        require(totalPrice > 0, "price not set yet");
        require(assets[nfts[tokenId]].isForSale, "token is not for sale");
        if(availableToSpend < totalPrice){
            revert InsufficientFundsToBuy(totalPrice, availableToSpend);
        }

        (uint toSeller, uint toCreator, uint toPlatform, uint toBlackUnicorn) 
            = _calcPaymentDistribution(totalPrice, creatorFee, orgFee, blackUniFee);
        
        address tOwner = _changeOwnerOfNft(tokenId, buyer, totalPrice, payWithNaal);
        _salePrices[tokenId].price = 0;
        _salePrices[tokenId].naalPrice = 0;
        assets[nfts[tokenId]].isForSale = false;
        
        address tokenCreatorAddress = assets[nfts[tokenId]].creator;
        _sendPayments(payWithNaal, buyer, payable(tOwner), toSeller, 
            payable(tokenCreatorAddress), toCreator, 
            toPlatform, toBlackUnicorn);
        emit Sold(buyer, tOwner, totalPrice, assets[nfts[tokenId]].assetId, tokenId, payWithNaal);
    }

    function _changeOwnerOfNft(uint256 tokenId, address newOwner, uint price, bool payWithNaal) internal returns(address){
        require(assets[nfts[tokenId]].tokenId == tokenId, "Token ID does not exist");
        address tOwner = ownerOf(tokenId);

        // remove tokenId from the previous investor/owner list
        for(uint i = 0; i < nftsOf[tOwner].length; i++){
            if(nftsOf[tOwner][i] == tokenId){
                nftsOf[tOwner][i] = nftsOf[tOwner][nftsOf[tOwner].length - 1];
                nftsOf[tOwner].pop();
                break;
            }
        }
        nftsOf[newOwner].push(tokenId);
        _safeTransfer(tOwner, newOwner, tokenId, "");//bytes(price));
        emit OwnerChanged(tOwner, newOwner, assets[nfts[tokenId]].assetId, tokenId, price, payWithNaal);
        return tOwner;
    }

    function _sendPayments(bool payWithNaal, address sender,
            address payable hodler, uint toHodler, 
            address payable creator, uint toCreator, 
            uint toPlatform, uint toBlackUnicorn) internal {
        require(hodler != address(0), "hodler address is not valid");
        require(creator != address(0), "creator address is not valid");
        if(toPlatform > 0) {
            if(payWithNaal){
                naalToken.transferFrom(sender, ethernaalOrg, toPlatform);
            }else{
                payable(ethernaalOrg).transfer(toPlatform);
            }
        }
        if(toBlackUnicorn > 0) {
            if(payWithNaal){
                naalToken.transferFrom(sender, blackUniOrg, toBlackUnicorn);
            }else{
                payable(blackUniOrg).transfer(toBlackUnicorn);
            }
        }
        if(toCreator > 0) {
            if(payWithNaal){
                naalToken.transferFrom(sender, creator, toCreator);
            }else{
                creator.transfer(toCreator);
            }
        }
        if(toHodler > 0) {
            if(payWithNaal){
                naalToken.transferFrom(sender, hodler, toHodler);
            }else{
                hodler.transfer(toHodler);
            }
        }
    }

    function setStatus(uint256 _tokenId, string memory status) public onlyHodlerOf(_tokenId) {
        require(_tokenId > 0 && _tokenId <= nftSupply, "Token ID is not valid");
        require(assets[nfts[_tokenId]].tokenId == _tokenId, "Token ID does not exist");
        assets[nfts[_tokenId]].status = status;
        emit StatusSet(_tokenId, status);
    }

    /**
    * This function is used to whitelist a/an creator/artist on the platform
    */
    function whitelist(address[] memory _creators, string[] memory nftTypes) public onlyAdmins{
        require(listNftTypes.length > 0, "NFT types is not set yet");
        bool exists = true;
        bool[] memory listReqWhitelist = new bool[](nftTypes.length);
        uint numReqWhitelist = 0;
        uint i = 0;
        for(i = 0; i < nftTypes.length; i++){
            (bool existsThisNftType, bool reqWhitelist) = existsNftType(nftTypes[i]);
            listReqWhitelist[i] = reqWhitelist;
            if(reqWhitelist){
                numReqWhitelist++;
            }
            exists = exists && existsThisNftType;
        }
        require(exists, "NFT type is not valid");
        string[] memory nftTypesToAdd = new string[](numReqWhitelist);
        i = 0;
        for(uint j = 0; j < nftTypes.length; j++){
            if(listReqWhitelist[j]){
                nftTypesToAdd[i++] = nftTypes[j];
            }
        }
        for(i = 0; i < _creators.length; i++){
            cWL[_creators[i]] = nftTypesToAdd;
            emit WhitelistCreator(_creators[i], nftTypesToAdd);
        }
        
    }

    /**
    * This function is used to unlist/delist a creator from the platform
    */
    function delist(address[] memory _creators) public onlyAdmins{
        for(uint i = 0; i < _creators.length; i++){
            delete cWL[_creators[i]];
            emit DelistCreator(_creators[i]);
        }
    }

    /**
    * This is a getter function to get the current price of an NFT.
    */
    function getSalePrice(uint256 tokenId, bool isLazy) public view returns (uint256 price, uint256 naalPrice) {
        if(isLazy){
            price = _lazyPrices[tokenId].price;
            naalPrice = _lazyPrices[tokenId].naalPrice;
        }else{
            price = _salePrices[tokenId].price;
            naalPrice = _salePrices[tokenId].naalPrice;
        }
    }

    /**
    * This function returns if a creator is whitelisted on the platform or no
    */
    function isWhitelisted(address _creator, string memory nftType) public view returns (bool) {
        (bool existsThisNftType, bool reqWhitelist) = existsNftType(nftType);
        if(!existsThisNftType) return false;
        if(!reqWhitelist) return true;
        for(uint i = 0; i < cWL[_creator].length; i++){
            if(compareStrings(cWL[_creator][i], nftType)){
                return true;
            }
        }
        return false;
    }

    function getPerm(address _creator) external view returns (string[] memory) {
        return cWL[_creator];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(bytes((a))) == keccak256(bytes((b))));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return assets[nfts[tokenId]].tokenUri;
    }

    function getNTFsOf(address _owner) public view returns (uint256[] memory) {
        return nftsOf[_owner];
    }

    function getAdmins() public view returns (address[] memory) {
        return admins;
    }
    
    function getCreations(address _creator) external view returns(uint[] memory) {
        return creatorAssetIds[_creator];
    }
    function getLazyCreations(address _creator) external view returns(uint[] memory) {
        return creatorLazyAssetIds[_creator];
    }

}