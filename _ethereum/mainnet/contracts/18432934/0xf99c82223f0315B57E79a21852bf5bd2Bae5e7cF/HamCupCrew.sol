// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./EnumerableSet.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";
import "./ILocker.sol";
import "./IContractAllowListProxy.sol";

contract HamCupCrew is
    ERC721A('HamCup Crew', 'HCC'),
    Ownable,
    ERC2981,
    DefaultOperatorFilterer,
    AccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

    string public constant baseExtension = '.json';

    ILocker public locker;

    string public baseURI = 'https://data.syou-nft.com/hcc/json/';
    IContractAllowListProxy public cal;
    uint256 public calLevel = 1;
    bool public enableRestrict = false;
    EnumerableSet.AddressSet private localAllowedAddresses;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Caller is not a burner');
        _;
    }
    
    modifier whenNotStaking(uint256 tokenId) {
        require(
            isLocked(tokenId) == false,
            "The token is loked now."
        );
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _setDefaultRoyalty(0x83bd713c0a530A5338af150B4D5c27e6Ae5A33Cb, 1000);
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _isAllowed(address transferer) internal view virtual returns (bool) {
        if (!enableRestrict) return true;
        return localAllowedAddresses.contains(transferer) || cal.isAllowed(transferer, calLevel);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function isLocked(uint256 tokenId) public virtual view returns(bool) {
        return address(locker) != address(0) && locker.isLocked(address(this), tokenId) == true;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(
            _isAllowed(operator) || !approved,
            "Can not approve locked token"
         );
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (!_isAllowed(operator)) return false;
        return super.isApprovedForAll(account, operator);
    }

    function approve(address to, uint256 tokenId) public payable virtual override whenNotStaking(tokenId) {
        super.approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) whenNotStaking(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) whenNotStaking(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) whenNotStaking(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    // external (only owner)
    function setEnableRestrict(bool value) external onlyOwner {
        enableRestrict = value;
    }

    function setLocker(address value) external onlyOwner {
        locker = ILocker(value);
    }

    function addLocalContractAllowList(address transferer) external onlyOwner {
        localAllowedAddresses.add(transferer);
    }

    function removeLocalContractAllowList(address transferer) external onlyOwner {
        localAllowedAddresses.remove(transferer);
    }

    function setCAL(address value) external onlyOwner {
        cal = IContractAllowListProxy(value);
    }

    function setCALLevel(uint256 value) external onlyOwner {
        calLevel = value;
    }

    function withdraw(address to) external onlyOwner {
        (bool os, ) = payable(to).call{value: address(this).balance}('');
        require(os);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // external (only minter)
    function minterMint(address _address, uint256 _amount) external onlyMinter {
        _safeMint(_address, _amount);
    }

    // external (only burner)
    function burnerBurn(address _address, uint256[] calldata tokenIds) external onlyBurner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_address == ownerOf(tokenId));

            _burn(tokenId);
        }
    }

    // public (only owner)
    function ownerMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //external
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl, ERC2981) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
