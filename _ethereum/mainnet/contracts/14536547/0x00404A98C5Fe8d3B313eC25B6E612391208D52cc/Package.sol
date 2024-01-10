// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Metadata.sol";
import "./ERC721Receiver.sol";
import "./ERC173.sol";
import "./ERC165.sol";
import "./String.sol";

/**
 * @dev Happy Robot Friends package
 */
contract Package is ERC721, ERC721Metadata, ERC173, ERC165, String {
    mapping(uint256 => address) private _tokenOwner;
    mapping(address => uint256) private _ownerBalance;
    mapping(uint256 => address) private _tokenApproval;
    mapping(address => mapping(address => bool)) private _operatorApproval;
    mapping(uint256 => bool) private _baseLevel;
    mapping(uint256 => string) private _level;

    string private _name;
    string private _symbol;
    string private _extendedBaseUri;

    uint256 private _currentId = 0;
    uint256 private _totalSupply = 0;

    address private _ownership;
    address private GameContract = address(0);

    bool private _reveal = false;
    bool private _baseSet = false;
    bool private _baseLock = false;
    bool _jsonExtension = false;

    /**
     * @dev Ownership functions
     */

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

    /**
     * @dev Game functions
     */

    function setGameContract(address _gameContract) public ownership {
        GameContract = _gameContract;
    }

    function levelUp(uint256 _tokenId, string memory _cid) public {
        require(msg.sender == GameContract, "HRF: Caller not game");
        _baseLevel[_tokenId] = false;
        _level[_tokenId] = _cid;
    }

    function resetLevel(uint256 _tokenId) public {
        require(msg.sender == GameContract, "HRF: Caller not game");
        _baseLevel[_tokenId] = true;
    }

    /**
     * @dev Metadata functions
     */

    function _mint(address _to) internal {
        require(_currentId < 3333, "ERC721: maximum tokens minted");
        require(_to != address(0), "ERC721: cannot mint to zero address");

        _currentId += 1;
        _totalSupply += 1;
        _tokenOwner[_currentId] = _to;
        _ownerBalance[_to] += 1;
        _baseLevel[_currentId] = true;

        emit Transfer(address(0), _to, _currentId);
    }

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

    function reveal() public ownership {
        require(_baseLock == true, "HRF: Reveal base not locked");
        _reveal = true;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_tokenId != 0, "HRF: Token ID out of range");
        require(_currentId >= _tokenId, "HRF: Token ID out of range");
        if (_reveal == true) {
            if (_baseLevel[_tokenId] == true) {
                if (_jsonExtension == true) {
                    return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId), ".json"));
                } else {
                    return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId)));
                }
            } else {
                return string(abi.encodePacked(_baseUri(), _level[_tokenId]));
            }
        } else {
            return string(abi.encodePacked(_baseUri(), "bafybeifupt34zaycketp6khwmwusssksupv245g43xl3yriumgeqbjo7n4/prereveal.json"));
        }
    }

    function checkURI(uint256 _tokenId) public view returns (string memory) {
        require(_baseSet == true, "HRF: CID has not been set");
        require(_baseLock == false, "HRF: URI has been set");
        if (_jsonExtension == true) {
            return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId), ".json"));
        } else {
            return string(abi.encodePacked(_baseUri(), _extendedBaseUri, "/", toString(_tokenId)));
        }
    }

    function _baseUri() internal pure returns (string memory) {
        return "ipfs://";
    }

    function revealBaseLocked() public view returns (bool) {
        return _baseLock;
    }

    function lockRevealBase(bool _lockStatus) public ownership {
        require(_reveal == false, "HRF: Reveal has already occured");
        require(_baseSet == true, "HRF: Reveal base not set");
        _baseLock = _lockStatus;
    }

    function setRevealBase(string memory _cid, bool _isExtension) public ownership {
        require(_baseLock == false, "HRF: Already revealed");
        _extendedBaseUri = _cid;
        _jsonExtension = _isExtension;
        _baseSet = true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev ERC721 functions
     */
    
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

    /**
     * @dev ERC721 internal transfer function
     */

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

    /**
     * @dev ERC721Received private function
     */

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

    /**
     * @dev ERC165 function
     */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(ERC165).interfaceId ||
            interfaceId == type(ERC173).interfaceId ||
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC721Metadata).interfaceId ||
            interfaceId == type(ERC721Receiver).interfaceId;
    }
}
