// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract CryptoNijigenGirlsUpgradeable is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    uint256[] private _tokenIds;

    uint256 _baseMintPrice;

    uint256 _maxTokenId;

    string private _uri;

    // Optional mapping for token price
    mapping(uint256 => uint256) private _tokenPrice;

    function initialize() initializer public {
        __ERC721_init("Crypto Nijigen Girls", "CNG");
        __Ownable_init();
        setURI("https://ipfs.io/ipns/k51qzi5uqu5dgqtirtxnm0vy6zvtu3enn4vmisee4dd67g0ue9plk8mhm2mwq3/CNG");
        _baseMintPrice = 0.05 ether;
    }

    event NftBought(address _seller, address _buyer, uint256 _price, uint256 _tokenId);
    event NftBatchBought(address _seller, address _buyer, uint256 _price, uint256[] _tokenIds);
    event PaymentReleased(address to, uint256 amount);

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable)
    returns (string memory)
    {
        return string(abi.encodePacked(_uri,tokenId.toString(),".json")) ;
    }

    function sellMaxTokenId()
    public
    view
    virtual
    returns (uint256)
    {
        return _maxTokenId;
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

    function uri(uint256 id) public view virtual returns (string memory) {
        return string(abi.encodePacked(_uri,id.toString(),".json")) ;
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

    function sellCNG(uint256 _tokenId, uint256 _price) external {
        require(msg.sender == ownerOf(_tokenId), 'CNGE001');
        require(_price > _baseMintPrice, 'CNGE002');
        _tokenPrice[_tokenId] = _price;
    }

    function banCNG(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), 'CNGE001');
        _tokenPrice[_tokenId] = 0;
    }

    function buyCNG(uint256 _tokenId) external payable {
        uint256 price = _tokenPrice[_tokenId];
        require(price > 0, 'CNGE002');
        require(msg.value == price, 'CNGE002');

        address seller = ownerOf(_tokenId);
        _transfer(seller, msg.sender, _tokenId);
        _tokenPrice[_tokenId] = 0; // not for sale anymore
        payable(seller).transfer(msg.value); // send the ETH to the seller

        emit NftBought(seller, msg.sender, msg.value, _tokenId);
    }

    function release(address payable account) public virtual onlyOwner{

        uint256 payment = address(this).balance;

        require(payment != 0, "CNGE005");

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    function setTokenPrice(uint256[] memory ids, uint256[] memory price) public virtual onlyOwner{
        require(ids[0] > _maxTokenId, "CNGE007");
        require(ids.length == price.length, "CNGE006");
        uint256 id = 0;
        for(uint256 i=0;i<ids.length;i++){
            _tokenPrice[ids[i]] = price[i];
            if(ids[i] > id){
                id = ids[i];
            }
        }
        _maxTokenId = id;
    }

    function setTokenPriceBySection(uint256 minId, uint256 maxId, uint256 price) public virtual onlyOwner{
        require(minId > _maxTokenId, "CNGE007");
        for(uint256 i=minId;i<=maxId;i++){
            _tokenPrice[i] = price;
        }
        _maxTokenId = maxId;
    }

    function tokenIds() public view virtual returns (uint256[] memory){
        return _tokenIds;
    }

    function ownerTokenIds(address account) public view virtual returns (string memory){
        require(msg.sender == account, 'CNGE001');
        string memory senderTokenIds = "";
        for(uint256 i=0;i < _tokenIds.length;i++){
            address ownerAddress = ownerOf(_tokenIds[i]);
            if(ownerAddress == account){
                senderTokenIds = string(abi.encodePacked(senderTokenIds,_tokenIds[i].toString(),"/")) ;
            }
        }
        return senderTokenIds;
    }
}