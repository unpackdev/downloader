// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./ERC2981.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./IERC5192.sol";

contract NinjaDaoMetaverseHatsumode is ERC1155, AccessControl, Ownable, Pausable, IERC5192, ERC2981 {
    using Strings for uint256;

    // Role
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant MINTER = "MINTER";

    // Metadata
    string public name = "NinjaDao Metaverse Hatsumode";
    string public symbol = "NMH";
    string public baseURI;
    string public baseExtension;

    // Mint
    mapping(uint256 => uint256) public mintCosts;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => bool) public isLocked;

    // Withdraw
    address public withdrawAddress = 0x79c1eDa948Bb6a50E6b88C761CD01133b7350B3A;
    address public royaltyReceiver = 0x79c1eDa948Bb6a50E6b88C761CD01133b7350B3A;
    uint96 public royaltyFee = 1000;

    // Modifier
    modifier withinMaxSupply(uint256 _tokenId, uint256 _amount) {
        require(totalSupply[_tokenId] + _amount <= maxSupply[_tokenId], 'Over Max Supply');
        _;
    }
    modifier enoughEth(uint256 _tokenId, uint256 _amount) {
        require(msg.value >= _amount * mintCosts[_tokenId], 'Not Enough Eth');
        _;
    }

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _setDefaultRoyalty(royaltyReceiver, royaltyFee);
    }

    // Mint
    function airdrop(address[] calldata _addresses, uint256 _tokenId, uint256 _amount) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (totalSupply[_tokenId] + _amount <= maxSupply[_tokenId]) {
                mintCommon(_addresses[i], _tokenId, _amount);
            }
        }
    }
    function mint(address _address, uint256 _tokenId, uint256 _amount) external payable
        whenNotPaused
        withinMaxSupply(_tokenId, _amount)
        enoughEth(_tokenId, _amount)
    {
        mintCommon(_address, _tokenId, _amount);
    }
    function externalMint(address _address, uint256 _tokenId, uint256 _amount) external payable onlyRole(MINTER) {
        mintCommon(_address, _tokenId, _amount);
    }
    function mintCommon(address _address, uint256 _tokenId, uint256 _amount) private {
        _mint(_address, _tokenId, _amount, "");
        totalSupply[_tokenId] += _amount;
    }
    function withdraw() public onlyRole(ADMIN) {
        (bool success, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(success);
    }

    // Getter
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

    // Setter
    function setWithdrawAddress(address _value) public onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setMetadataBase(string memory _baseURI, string memory _baseExtension) external onlyRole(ADMIN) {
        baseURI = _baseURI;
        baseExtension = _baseExtension;
    }
    function setIsLocked(uint256 _tokenId, bool _isLocked) external onlyRole(ADMIN) {
        isLocked[_tokenId] = _isLocked;
    }
    function setTokenInfo(uint256 _tokenId, uint256 _mintCost, uint256 _maxSupply, bool _isLocked) external onlyRole(ADMIN) {
        mintCosts[_tokenId] = _mintCost;
        maxSupply[_tokenId] = _maxSupply;
        isLocked[_tokenId] = _isLocked;
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl, ERC2981) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Locked
    function locked(uint256 _tokenId) override public view returns (bool){
        return isLocked[_tokenId];
    }
    function emitLockState(uint256 _tokenId) external onlyRole(ADMIN) {
        if (isLocked[_tokenId]) {
            emit Locked(_tokenId);
        } else {
            emit Unlocked(_tokenId);
        }
    }
    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        super.setApprovalForAll(_operator, _approved);
    }
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                require (!isLocked[ids[i]], "Locked");
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}