// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Metadata.sol";
import "./ERC721Receiver.sol";
import "./ERC173.sol";
import "./ERC165.sol";
import "./utils.sol";

/**
 * @dev Feathered Frens package
 */
contract Package is ERC721, ERC721Metadata, ERC173, ERC165 {
    mapping(uint256 => address) private _tokenOwner;
    mapping(address => uint256) private _ownerBalance;
    mapping(uint256 => address) private _tokenApproval;
    mapping(address => mapping(address => bool)) private _operatorApproval;

    bool private _reveal = false;
    bool private _baseSet = false;
    bool private _baseLock = false;
    bool _jsonExtension = false;

    string private _name;
    string private _symbol;
    string private _extendedBaseUri;

    uint256 private _currentId = 0;
    uint256 private _totalSupply = 0;

    address private _ownership;

    bytes32 private root;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function transferOwnership(address _newOwner) public override ownership {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        address previousOwner = _ownership;
        _ownership = _newOwner;
    
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    modifier ownership() {
        require(owner() == msg.sender, "ERC173: caller is not the owner");
        _;
    }

    function owner() public view override returns (address) {
        return _ownership;
    }
    
    function _setMerkleRoot(bytes32 _root) internal {
        root = _root;
    }
    
    function merkleRoot() internal view returns (bytes32) {
        return root;
    }

    function _whitelistMint(address _to, bytes32[] calldata _merkleProof, bytes32 _merkleRoot) internal {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(utils.verify(_merkleProof, _merkleRoot, leaf), "FF: invalid merkle proof.");
        require(_currentId < 5555, "ERC721: maximum tokens minted");
        require(_to != address(0), "ERC721: cannot mint to zero address");

        _currentId += 1;
        _totalSupply += 1;
        _tokenOwner[_currentId] = _to;
        _ownerBalance[_to] += 1;

        emit Transfer(address(0), _to, _currentId);
    }

    function _mint(address _to) internal {
        require(_currentId < 5555, "ERC721: maximum tokens minted");
        require(_to != address(0), "ERC721: cannot mint to zero address");

        _currentId += 1;
        _totalSupply += 1;
        _tokenOwner[_currentId] = _to;
        _ownerBalance[_to] += 1;

        emit Transfer(address(0), _to, _currentId);
    }

    function reveal() public ownership {
        require(_baseLock == true, "FF: reveal base not locked");
        _reveal = true;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_tokenId != 0, "FF: token ID out of range");
        require(_currentId >= _tokenId, "FF: token ID out of range");
        if (_reveal == true) {
            if (_jsonExtension == true) {
                return string(abi.encodePacked(_ipfs(), _extendedBaseUri, "/", utils.toString(_tokenId), ".json"));
            } else {
                return string(abi.encodePacked(_ipfs(), _extendedBaseUri, "/", utils.toString(_tokenId)));
            }
        } else {
            return string(abi.encodePacked(_ipfs(), "bafybeidvzxfejqzlftewxphrrqvee3r6sxf7mf6etdajcoawpz4sf5hve4/prereveal.json"));
        }
    }

    function checkURI(uint256 _tokenId) public view returns (string memory) {
        require(_baseSet == true, "FF: CID has not been set");
        require(_baseLock == false, "FF: URI has been set");
        if (_jsonExtension == true) {
            return string(abi.encodePacked(_ipfs(), _extendedBaseUri, "/", utils.toString(_tokenId), ".json"));
        } else {
            return string(abi.encodePacked(_ipfs(), _extendedBaseUri, "/", utils.toString(_tokenId)));
        }
    }

    function _ipfs() internal pure returns (string memory) {
        return "ipfs://";
    }

    function revealBaseLocked() public view returns (bool) {
        return _baseLock;
    }

    function lockRevealBase(bool _lockStatus) public ownership {
        require(_reveal == false, "FF: reveal has already occured");
        require(_baseSet == true, "FF: reveal base not set");
        _baseLock = _lockStatus;
    }

    function setRevealBase(string memory _cid, bool _isExtension) public ownership {
        require(_baseLock == false, "FF: already revealed");
        _extendedBaseUri = _cid;
        _jsonExtension = _isExtension;
        _baseSet = true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view override returns (uint256) {
        return _ownerBalance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        return _tokenOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
        _transfer(_from, _to, _tokenId);
    
        _onERC721Received(_from, _to, _tokenId, _data);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public override {
        require(_tokenOwner[_tokenId] == msg.sender);
        _tokenApproval[_tokenId] = _approved;

        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public override {
        require(msg.sender != _operator, "ERC721: cannot approve the owner");
        _operatorApproval[msg.sender][_operator] = _approved;
    
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        return _tokenApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return _operatorApproval[_owner][_operator];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from, "ERC721: from address is not owner of token");
        require(_tokenOwner[_tokenId] == msg.sender || _tokenApproval[_tokenId] == msg.sender || _operatorApproval[_from][msg.sender] == true, "ERC721: unauthorized transfer");
        require(_to != address(0), "ERC721: cannot transfer to the zero address");
        _ownerBalance[_from] -= 1;
        _tokenOwner[_tokenId] = _to;
        _tokenApproval[_tokenId] = address(0);
        _ownerBalance[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
    }

    function _onERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            try ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 response) {
                if (response != ERC721Receiver.onERC721Received.selector) {
                    revert("ERC721: ERC721Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC165) returns (bool) {
        return
            interfaceId == type(ERC165).interfaceId ||
            interfaceId == type(ERC173).interfaceId ||
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC721Metadata).interfaceId ||
            interfaceId == type(ERC721Receiver).interfaceId;
    }
}
