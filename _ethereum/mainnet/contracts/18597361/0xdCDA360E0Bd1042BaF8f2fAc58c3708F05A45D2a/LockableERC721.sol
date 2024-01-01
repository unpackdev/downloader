// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IContractLocker.sol";
import "./IERC4906.sol";
import "./IERC5192.sol";

contract LockableERC721 is ERC721, AccessControl, Ownable, IERC4906, IERC5192, ERC2981 {
    using Strings for uint256;

    // Role
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant EMITTER = "EMITTER";
    bytes32 public constant MINTER = "MINTER";

    // Metadata
    string public baseURI;
    string public baseExtension;

    // Mint
    uint256 public totalSupply = 0;
    address public withdrawAddress;

    // Locker
    IContractLocker public contractLocker;

    // Constructor
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _contractLockerAddress,
        uint96 _royaltyFee,
        address _withdrawAddress,
        address[] memory _admins,
        string memory _baseURI,
        string memory _baseExtension
    ) ERC721(_name, _symbol) Ownable(_owner) {
        // GrantRole
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(ADMIN, _owner);
        for (uint256 i = 0; i < _admins.length; i++) {
            _grantRole(ADMIN, _admins[i]);
            _grantRole(EMITTER, _admins[i]);
        }

        // WithdrawAddress
        _setDefaultRoyalty(_withdrawAddress, _royaltyFee);
        withdrawAddress = _withdrawAddress;

        // Metadata
        baseURI = _baseURI;
        baseExtension = _baseExtension;

        // Locker
        contractLocker = IContractLocker(_contractLockerAddress);
        _grantRole(EMITTER, _contractLockerAddress);
    }

    // Mint
    function mintCommon(address _address, uint256 _tokenId) private {
        _mint(_address, _tokenId);
        totalSupply++;
        if (contractLocker.ownerHasLocked(_address)) {
            emit Locked(_tokenId);
        }
    }
    function airdrop(address[] calldata _addresses, uint256[] calldata _tokenIds) external onlyRole(ADMIN) {
        require(_addresses.length == _tokenIds.length, "Invalid Length");
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintCommon(_addresses[i], _tokenIds[i]);
        }
    }
    function mint(address _address, uint256 _tokenId) external payable onlyRole(MINTER) {
        mintCommon(_address, _tokenId);
    }
    function withdraw() public onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Getter
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension));
    }
    function getOwnTokenIds(address _owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 tokenId = 0;
        uint256 index = 0;
        while (index < tokenIds.length) {
            if (_ownerOf(tokenId) == _owner) {
                tokenIds[index] = tokenId;
                index++;
            }
            tokenId++;
        }
        return tokenIds;
    }
    function locked(uint256 _tokenId) override public view returns (bool){
        address owner = _ownerOf(_tokenId);
        return contractLocker.ownerHasLocked(owner) || contractLocker.tokenIsLocked(_tokenId);
    }

    // Setter
    function setWithdrawAddress(address _value) public onlyRole(ADMIN) {
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
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyRole(ADMIN){
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
    function setContractLocker (address _address) external onlyRole(ADMIN) {
        contractLocker = IContractLocker(_address);
    }

    // Emit
    function emitLockState(uint256 _tokenId, bool _locked) external onlyRole(EMITTER) {
        if (_locked) {
            emit Locked(_tokenId);
        } else {
            emit Unlocked(_tokenId);
        }
    }
    function emitMetadataUpdated(uint256 _tokenId) external onlyRole(EMITTER) {
        emit MetadataUpdate(_tokenId);
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Transfer
    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        require (
            !_approved ||
            !contractLocker.operatorIsLocked(_operator),
            "Locked"
        );
        super.setApprovalForAll(_operator, _approved);
    }
    function approve(address _to, uint256 _tokenId) public virtual override {
        require (
            !contractLocker.operatorIsLocked(_to) &&
            !locked(_tokenId),
            "Locked"
        );
        super.approve(_to, _tokenId);
    }
    function _update(address _to, uint256 _tokenId, address _auth) internal virtual override returns (address) {
        require(
            !locked(_tokenId),
            "Locked"
        );
        return super._update(_to, _tokenId, _auth);
    }
}