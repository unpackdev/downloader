// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Strings.sol";

contract EmaNinjaDao is ERC721, AccessControl, Ownable, Pausable {
    using Strings for uint256;

    // Role
    bytes32 public constant ADMIN = "ADMIN";

    // Metadata
    string public baseURI;
    string public baseExtension;

    // Mint
    uint256 public totalSupply;
    address public withdrawAddress;

    // Sale
    uint256 public saleTokenIdFrom;
    uint256 public saleTokenIdTo;
    uint256 public mintCost;


    // Modifier
    modifier onSale(uint256 _tokenId) {
        require(saleTokenIdFrom <= _tokenId && saleTokenIdTo >= _tokenId, 'Not On Sale');
        _;
    }
    modifier enoughEth() {
        require(msg.value >= mintCost, 'Not Enough Eth');
        _;
    }

    // Constructor
    constructor(address _withdrawAddress) ERC721("EMA / NinjaDAO", "EMA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        withdrawAddress = _withdrawAddress;
    }

    // Mint
    function mint(uint256 _tokenId, address _to) external payable whenNotPaused {
        require(saleTokenIdFrom <= _tokenId && saleTokenIdTo >= _tokenId, 'Not On Sale');
        require(msg.value >= mintCost, 'Not Enough Eth');
        _mintCommon(_to, _tokenId);
    }
    function airdrop(address[] calldata _addresses, uint256[] calldata _tokenIds) external onlyRole(ADMIN) {
        require(_addresses.length == _tokenIds.length, "Invalid Length");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mintCommon(_addresses[i], _tokenIds[i]);
        }
    }
    function _mintCommon(address _to, uint256 _tokenId) private {
        _mint(_to, _tokenId);
        totalSupply++;
    }
    function withdraw() external onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Getter
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension));
    }

    // Setter
    function setWithdrawAddress(address _value) external onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyRole(ADMIN) {
        baseExtension = "";
    }
    function setSaleInfo(uint256 _tokenIdFrom, uint256 _tokenIdTo, uint256 _mintCost) external onlyRole(ADMIN) {
        saleTokenIdFrom = _tokenIdFrom;
        saleTokenIdTo = _tokenIdTo;
        mintCost = _mintCost;
    }

    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}