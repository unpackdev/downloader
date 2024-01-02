// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "./ERC721.sol";
import "./IEIP2981.sol";
import "./Strings.sol";

contract KillingTime is ERC721 {
    address payable private _royalties_recipient;

    uint256 private _royaltyAmount; //in %
    uint256 public _tokenId;
    uint256 private _nonce;
    uint256 private _unique;
    uint256 private _numberOfFrames;
    uint256 public _breakingOdds;
    uint256 public _uniqueOdds;

    string[] private _uriComponents;
    string private _frames;

    bool _uniqueActivated = false;

    mapping(uint256 => string) public _imagesURIs;
    mapping(uint256 => string) public _animationsURIs;
    mapping(address => bool) public _isAdmin;
    mapping(uint256 => bool) public _isFramed;
    mapping(uint256 => bool) public _isInsured;
    mapping(uint256 => bool) public _isBroken;

    constructor() ERC721("Killing Time", "Killing Time") {
        _tokenId = 0;
        _uriComponents = [
            'data:application/json;utf8,{"name":"',
            '", "description":"',
            '", "created_by":"Smokestacks", "image":"',
            '", "image_url":"',
            '", "animation":"',
            '", "animation_url":"',
            '", "attributes":[',
            "]}"
        ];
        _isAdmin[msg.sender] = true;
        _royalties_recipient = payable(msg.sender);
        _royaltyAmount = 10;
        _nonce = 0;
        _tokenId = 1;
        _breakingOdds = 2;
        _uniqueOdds = 100;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            interfaceId == type(IEIP2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    modifier adminRequired() {
        require(_isAdmin[msg.sender], "Only admins can perfom this action");
        _;
    }

    function mint(address to, bool isInsured) external adminRequired {
        _isInsured[_tokenId] = isInsured;
        _mint(to, _tokenId);
        _tokenId++;
    }

    function toggleAdmin(address admin) external adminRequired {
        _isAdmin[admin] = !_isAdmin[admin];
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(msg.sender == owner, "Owner only");
        _burn(tokenId);
    }

    function repair(uint256 tokenId) external {
        require(
            msg.sender == ERC721.ownerOf(tokenId),
            "You can only repair your own Clock"
        );
        require(_isBroken[tokenId], "This clock is not broken");
        _isBroken[tokenId] = false;
        if (tokenId == _unique) {
            _uniqueActivated = true;
        }
    }

    function breaks(bool unique) public returns (bool) {
        uint256 mod = unique ? _uniqueOdds : _breakingOdds;
        uint256 rnd = uint256(keccak256(abi.encodePacked(msg.sender, _nonce))) %
            mod;
        _nonce++;
        return rnd == 0 ? true : false;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        if (!_isInsured[firstTokenId]) {
            if (!_isBroken[firstTokenId]) {
                _isBroken[firstTokenId] = breaks(false);
            }
        } else {
            if (_unique == 0) {
                bool tokenBreaks = breaks(true);
                if (tokenBreaks) {
                    _isBroken[firstTokenId] = tokenBreaks;
                    _unique = firstTokenId;
                }
            }
        }
    }

    function toggleFrameClock(uint256 tokenId) external {
        address owner = ERC721.ownerOf(tokenId);
        require(msg.sender == owner, "Owner only");
        require(
            _isInsured[tokenId],
            "Only inusured clocks can enter frame mode"
        );
        _isFramed[tokenId] = !_isFramed[tokenId];
    }

    function setOdds(bool unique, uint256 odds) external adminRequired {
        if (unique) {
            _uniqueOdds = odds;
        } else {
            _breakingOdds = odds;
        }
    }

    function setURIs(
        string[3] calldata updatedImageURI,
        string[3] calldata updatedAnimationURI
    ) external adminRequired {
        require(updatedImageURI.length == updatedAnimationURI.length);
        for (uint8 i = 0; i < updatedImageURI.length; i++) {
            _imagesURIs[i] = updatedImageURI[i];
            _animationsURIs[i] = updatedAnimationURI[i];
        }
    }

    function setFrames(
        uint256 numberOfFrames,
        string calldata updatedFrames
    ) external adminRequired {
        _numberOfFrames = numberOfFrames;
        _frames = updatedFrames;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory name;
        string memory description;
        string memory image;
        string memory animation;
        string memory attributes;

        if (tokenId == _unique && _uniqueActivated) {
            image = _imagesURIs[0];
            animation = _animationsURIs[0];
        } else if (_isBroken[tokenId]) {
            image = _imagesURIs[1];
            animation = _animationsURIs[1];
        } else if (_isFramed[tokenId]) {
            image = string(
                abi.encodePacked(
                    _frames,
                    Strings.toString(block.number % _numberOfFrames),
                    ".jpg"
                )
            );
        } else {
            image = _imagesURIs[2];
            animation = _animationsURIs[2];
        }

        name = "Killing Time";
        description = "";
        attributes = string(
            abi.encodePacked(
                '{"trait_type": "Insured", "value": "',
                _isInsured[tokenId] ? "true" : "false",
                '"}'
            )
        );
        bytes memory byteString = abi.encodePacked(
            abi.encodePacked(_uriComponents[0], name),
            abi.encodePacked(_uriComponents[1], description),
            abi.encodePacked(_uriComponents[2], image),
            abi.encodePacked(_uriComponents[3], image),
            abi.encodePacked(_uriComponents[4], animation),
            abi.encodePacked(_uriComponents[5], animation),
            abi.encodePacked(_uriComponents[6], attributes),
            abi.encodePacked(_uriComponents[7])
        );
        return string(byteString);
    }

    // Royalites mgmt

    function setRoyalties(
        address payable _recipient,
        uint256 _royaltyPerCent
    ) external adminRequired {
        _royalties_recipient = _recipient;
        _royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(
        uint256 salePrice
    ) external view returns (address, uint256) {
        if (_royalties_recipient != address(0)) {
            return (_royalties_recipient, (salePrice * _royaltyAmount) / 100);
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }
}
