// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IChildToken.sol";

contract CryptoNijigenGirlsUpgradeable is IChildToken, Initializable, ERC721Upgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    uint256[] private _tokenIds;

    uint256 _baseMintPrice;

    uint256 _maxTokenId;

    string private _uri;

    // Optional mapping for token price
    mapping(uint256 => uint256) private _tokenPrice;

    address private _erc20TokenAddress;

    mapping (uint256 => bool) public withdrawnTokens;

    mapping (address => bool) public adminMap;

    mapping(uint256 => uint256) private sellTokenPrice;

    function initialize() initializer public {
        __ERC721_init("Crypto Nijigen Girls", "CNG");
        __Ownable_init();
        setURI("https://ipfs.io/ipns/k51qzi5uqu5dgqtirtxnm0vy6zvtu3enn4vmisee4dd67g0ue9plk8mhm2mwq3/CNG");
        _baseMintPrice = 0.05 ether;
    }

    event NftSell(address _seller, uint256 _price, uint256 _tokenId, uint256 _days);
    event NftBan(address _seller, uint256 _tokenId);
    event NftBought(address _seller, address _buyer, uint256 _price, uint256 _tokenId);
    event NftBatchBought(address _seller, address _buyer, uint256 _price, uint256[] _tokenIds);
    event PaymentReleased(address to, uint256 amount);

    function addAdmin (address newAddress) public onlyOwner {
        adminMap[newAddress] = true;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable)
    returns (string memory)
    {
        return string(abi.encodePacked(_uri,tokenId.toString(),".json")) ;
    }

    function totalSupply()
    public
    view
    virtual
    returns (uint256)
    {
        return _tokenIds.length;
    }

    function setURI(string memory newuri) public virtual onlyOwner{
        _uri = newuri;
    }

    function setErc20TokenAddress(address newErc20TokenAddress) public virtual onlyOwner{
        _erc20TokenAddress = newErc20TokenAddress;
    }

    function setBaseSellPrice(uint256 baseSellPrice) public virtual onlyOwner{
        _baseMintPrice = baseSellPrice;
    }

    function safeMintCNG(uint256 _tokenId) external payable{
        uint256 price = _tokenPrice[_tokenId];
        require(price > 0, 'CNGE002');
        require(msg.value == price, 'CNGE002');
        _safeMint(msg.sender,_tokenId);
        _tokenIds.push(_tokenId);
        emit NftBought(address(0), msg.sender, msg.value, _tokenId);
    }

    function safeBatchMintCNG(uint256[] memory ids) external payable{
        uint256 sumPrice = 0;
        for(uint256 i = 0 ; i<ids.length ; i++){
            uint256 price = _tokenPrice[ids[i]];
            require(price > 0, 'CNGE002');
            sumPrice = sumPrice + price;
        }
        require(msg.value == sumPrice, 'CNGE002');

        for(uint256 j = 0 ; j<ids.length ; j++){
            _safeMint(msg.sender,ids[j]);
            _tokenIds.push(ids[j]);
        }

        emit NftBatchBought(address(0), msg.sender, msg.value, ids);
    }

    function sellCNG(uint256 _tokenId, uint256 _price, uint256 _days) external {
        require(msg.sender == ownerOf(_tokenId), 'CNGE001');
        require(_price > _baseMintPrice, 'CNGE002');
        sellTokenPrice[_tokenId] = _price;

        emit NftSell(msg.sender, _price, _tokenId, _days);
    }

    function banCNG(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), 'CNGE001');
        sellTokenPrice[_tokenId] = 0;

        emit NftBan(msg.sender, _tokenId);
    }

    function buyCNG(uint256 _tokenId) external {
        uint256 price = sellTokenPrice[_tokenId];
        require(price > 0, 'CNGE002');
        uint256 txFee = price / 100 * 2;
        address seller = ownerOf(_tokenId);
        if(_erc20TokenAddress != address(0)){
            IERC20Upgradeable tokenContract = IERC20Upgradeable(_erc20TokenAddress);
            require(tokenContract.transferFrom(msg.sender, seller, price - txFee), "CNGE020");
            require(tokenContract.transferFrom(msg.sender, owner(), txFee), "CNGE021");
        } else {
            payable(seller).transfer(price - txFee); // send the ETH to the seller
        }
        _transfer(seller, msg.sender, _tokenId);
        sellTokenPrice[_tokenId] = 0; // not for sale anymore

        emit NftBought(seller, msg.sender, price, _tokenId);
    }

    function release(address payable account) public virtual onlyOwner{

        uint256 payment = address(this).balance;

        require(payment != 0, "CNGE005");

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    function tokenIdOfIndex(uint256 _index) public view virtual returns (uint256){
        return _tokenIds[_index];
    }

    function ownerTokenIds(address account) public view virtual returns (string memory){
        string memory senderTokenIds = "";
        for(uint256 i=0;i < _tokenIds.length;i++){
            if(_tokenIds[i] == 0){
                continue;
            }
            address ownerAddress = ownerOf(_tokenIds[i]);
            if(ownerAddress == account){
                senderTokenIds = string(abi.encodePacked(senderTokenIds,_tokenIds[i].toString(),"/")) ;
            }
        }
        return senderTokenIds;
    }

    function mint(address user, uint256 _tokenId) external {
        require(adminMap[msg.sender] || msg.sender == owner(), 'CNGE001');
        require(_tokenId > 17777, "CNGE010");
        _safeMint(user, _tokenId);
        _tokenIds.push(_tokenId);
    }

    function mint(address user, uint256 _tokenId, bytes calldata metaData) external {
        require(adminMap[msg.sender] || msg.sender == owner(), 'CNGE001');
        require(_tokenId > 17777, "CNGE010");
        _safeMint(user, _tokenId, metaData);
        _tokenIds.push(_tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // polygon deposit
    function deposit(address user, bytes calldata depositData)
    external
    override
    {
        require(adminMap[msg.sender], "CNGE001");
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            withdrawnTokens[tokenId] = false;
            _mint(user, tokenId);
            _tokenIds.push(tokenId);
            // deposit batch
        } else {
            uint256[] memory tokens = abi.decode(depositData, (uint256[]));
            uint256 length = tokens.length;
            for (uint256 i; i < length; i++) {
                withdrawnTokens[tokens[i]] = false;
                _mint(user, tokens[i]);
                _tokenIds.push(tokens[i]);
            }
        }
    }

    /**
     * @notice called when user wants to withdraw token back to root chain
     * @dev Should handle withraw by burning user's token.
     * Should set `withdrawnTokens` mapping to `true` for the tokenId being withdrawn
     * This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdraw(uint256 tokenId) external {
        require(tokenId < 17778, "CNGE110");
        require(msg.sender == ownerOf(tokenId), "CNGE001");
        withdrawnTokens[tokenId] = true;
        uint256 index = _tokenIds.length;
        for(uint256 i=0;i < _tokenIds.length;i++){
            if(tokenId == _tokenIds[i]){
                index = i;
                break;
            }
        }
        if(index < _tokenIds.length){
            delete _tokenIds[index];
        }
        _burn(tokenId);
    }
}