// SPDX-License-Identifier: GPL-3.0
// Author: Pagzi Tech Inc. | 2022
// Pinned Positivity - BELIEVE - Evan Carmichael | 2022
pragma solidity >=0.8.0 <0.9.0;
import "./AccessControl.sol";
import "./ERC721Enumerable.sol";

contract PinnedPositivity is AccessControl, ERC721Enumerable  {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable,AccessControl) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    string public baseURI;
    uint256 public cost = 1 ether;
    address pagzi = 0xF4617b57ad853f4Bc2Ce3f06C0D74958c240633c;
    address evan = 0x4294954a5de745420B71CBd2311F0034fd149681;
    uint256 public totSupply = 1000;

    //date settings
    uint256 public publicDate = 1647128611;
    uint256 public endDate = 1647128611;

    //mint passes/claims
    mapping(address => uint256) public mintPasses;
    address public proxyRegistryAddress;

    constructor(
    string memory _initBaseURI, 
    address _proxyRegistryAddress,
	address[] memory admins
    ) ERC721("Pinned Positivity", "BELIEVE") {
    _setupRole(ADMIN_ROLE, msg.sender);
	for (uint256 i = 0; i < admins.length; ++i) {
        _setupRole(ADMIN_ROLE, admins[i]);
	}
    setBaseURI(_initBaseURI);
    proxyRegistryAddress = _proxyRegistryAddress;
    }

    // external
    function mint(uint256 count) external payable{
    require((publicDate <= block.timestamp) && (endDate >= block.timestamp),"DATE");
    require(msg.value >= cost * count,"LOW");
    uint256 totalSupply = _owners.length;
    require(totalSupply + count -1 < totSupply ,"MANY");
    for(uint i; i < count; i++) {
    _mint(_msgSender(), totalSupply + i + 1);
    }
    }
    function claim() external{
    uint256 totalSupply = _owners.length;
    require((publicDate <= block.timestamp) && (endDate >= block.timestamp));
    uint256 reserve = mintPasses[msg.sender];
    require(reserve > 0, "Low reserve");
    _mint(_msgSender(), totalSupply + 1);
    mintPasses[msg.sender] = reserve - 1;
    delete reserve;
    }
    //only owner
    function gift(uint[] calldata quantity, address[] calldata recipient) external{
	require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
    require(quantity.length == recipient.length, "Provide quantities and recipients" );
    uint256 totalSupply = _owners.length;
    for(uint i; i < recipient.length; ++i){
    for(uint j; j < quantity[i]; ++j){
    unchecked {
    totalSupply++;
    }
    _mint(recipient[i], totalSupply + j);
    }
    }
    }
    function setCost(uint256 _cost) external {
	require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
    cost = _cost;
    }
    function setPublicDate(uint256 _publicDate) external {
	require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
    publicDate = _publicDate;
    }
    function setEndDate(uint256 _endDate) external {
	require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
    endDate = _endDate;
    }
    function setDates(uint256 _publicDate, uint256 _endDate) external {
	require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
    publicDate = _publicDate;
    endDate = _endDate;
    }
    function setMintPass(address _address,uint256 _quantity) external {
	require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
    mintPasses[_address] = _quantity;
    }
    function setMintPasses(address[] calldata _addresses, uint256[] calldata _amounts) external {
	require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
    for(uint256 i; i < _addresses.length; i++){
    mintPasses[_addresses[i]] = _amounts[i];
    }
    }
    function setTotSupply(uint256 _totSupply) public {
	    require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        totSupply = _totSupply;
    }
    function setBaseURI(string memory _baseURI) public {
	    require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        baseURI = _baseURI;
    }
    function setProxyRegistryAddress(address _proxyRegistryAddress) external {
	    require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        proxyRegistryAddress = _proxyRegistryAddress;
    }
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }
    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }
    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }
        return true;
    }
    function isApprovedForAll(address _owner, address operator) public view override(ERC721,IERC721) returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        return super.isApprovedForAll(_owner, operator);
    }
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
    function withdraw() public {
	    require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        uint256 balance = address(this).balance;
        payable(pagzi).transfer((balance * 250) / 1000);
        payable(evan).transfer((balance * 750) / 1000);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}