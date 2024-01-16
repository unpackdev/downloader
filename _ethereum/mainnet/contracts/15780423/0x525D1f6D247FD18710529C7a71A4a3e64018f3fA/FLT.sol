// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";

/**

                                 ▄▄▄▓▓▓▓█▓▓▓▓▓▓██▓▓▓▄▄▄
                           ▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▄▄
                       ▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▄
                    ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▄
                 ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▄
               ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▀   ▀▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
             ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀    █▓▌   ▄▄▓▓▓▌  ▐▓▓▓▀▀▀▀█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
           ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ▄   █▌   ▀▀▀▓▓   ▓▓▌   ▄   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
          ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▀▓█   ▀█   ▓▓▄   ▄▓▓▄ ▄▓▓   ▄▄  ▄▓▓▀ ▀█▓▓▓▓▓▓▓▓▓▓▓▓
         ▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀▓▄   ▀█   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▄    ▓▓▓      ▓▓▓▓▓▓▓▓▓▓▓█
        ▓▓▓▓▓▓▓▀▀▓▓▓▓█   ▀▀    ▓▓▓▓▓▓▓█▀▀       ▀▀▀▓▓▓▓█▓▓▌  ▀  ▐▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▄
       ▓▓▓▓▓▓▓▌  ▀▀▀▀▓▓▄    ▄▓▓▓▓▓█▀                 ▀▀▓▓▓▓▄     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
      ▓▓▓▓▓▓▓▓▓▄     ▀█▓▓▓█▓▓▓▓▓▀                       ▀▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
     ▐▓▓▓▓▓▓▓▓▓▓▓▄ ▄     ▓▓▓▓▓▓                           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌
     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▄▓▓▓▓▓█                             ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌
    ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌           ▄▀▀▀▀▀▄       ▄▄▄▄  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀                  ▄▄          ▄▄ ▀   ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                  ▓▓▓▌        ▓▓▓▓    ▐▓▓▓▓▓▓▓      ▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                   ▀▀   ▄   ▄  ▀▀     ▓▓▓▓▓▓▓▓    ▀▀▓▓▓▓▓▓▓▓
    ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█                     ▄▄▓▓▓▓▓█▄      ▓▓▓▓▓▓▓▓▓▓▓▄▄▄▓▓▓▓▓▓▓▓▌
     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄             ▐▄ ▄▓▓▓▓▀ ▀▓▓▓▓▓▄▄▓▐▓▓▓▓▓▓▓▓   ▐▀▀▓▓▓▓▓▓▓▓
     ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀  ▓▓▓▓▓▓▓            ▀▀▀▀              ▓▓▓▓▓▓▓▓▌     ▐▓▓▓▓▓▓▓▓
      ▓▓▓▓▓▓▓▓▓█▀    ▄▓▓▓▓▓▓▓▓█                            ▓▓▓▓▓▓▓▓▀▀█▄▄▄▓▓▓▓▓▓▓▓▓
      ▐▓▓▓▓▓▓▓▓▌  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▄                         ▓▓▓▓▓   ▀  ▀ ▀▓▓▓▓▓▓▓▓▓▌
       ▐▓▓▓▓▓▓▓▓█▄▓▓█▀ ▀▓▓▓▓▓▓▓▓▓█▄                     ▄▓▓▓▓▓▓▓▓▄    ▄▓▓▓▓▓▓▓▓▓▌
        ▐▓▓▓▓▓▓▓▓▓▓▌     ▐▓▓▓▓▓▓▓▓▓▓█▄▄             ▄▄▓▓▓▓█▓▓█    ▓█▓▄▓▓▓▓▓▓▓▓▓▀
          █▓▓▓▓▓▓▓▓█  ▐▄▓█▀▀▀▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▀    ▓▓  ▐▌  ▓▓▓▓▓▓▓▓▓▓▓
           ▀▓▓▓▓▓▓▓▓▓▓▓▓▌  ▄   ▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄▄  ▓▓▓▄   ▄▓▓▓▓▓▓▓▓▓█
             ▓▓▓▓▓▓▓▓▓█▀▌    ▄▓▓▄   ▓▓▓▓▓▓▓▓▓▓▓█▀▓▓▓▓▓▓▓▓▄  ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓
               ▓▓▓▓▓▓▓█▄    ▓▓▌     ▓▓    ▐▓  ▓  ▐▓▓▓▓▓▓▓▓▌ ▄▓▓▓▓▓▓▓▓▓▓▓▓▀
                 ▀▓▓▓▓▓▓▓█▓▓▓▓▓▓▄▄ ▓▓▌  ▀▀█▓      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
                   ▀█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▄▄▄▓▓█▄▄  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
                      ▀▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▀
                          ▀▀█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀
                                ▀▀█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▀▀▀
 */


// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);
    constructor() { owner = msg.sender; }
    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);    
    }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

abstract contract Security {
    // Prevent Smart Contracts
    modifier onlySender {
        require(msg.sender == tx.origin, "No Smart Contracts!"); _; }
}

abstract contract PublicClaim {
    bool public _publicClaimEnabled;
    uint256 public _publicClaimTime;

    mapping(address => uint256) internal _addressToClaims;

    function addressToClaims(address _addr) external view returns (uint256) {
        return _addressToClaims[_addr];
    }

    function _setPublicClaim(bool isClaimEnabled_, uint256 claimTime_) internal {
        _publicClaimEnabled = isClaimEnabled_;
        _publicClaimTime = claimTime_;
    }

    modifier publicClaimEnabled {
        require(_publicClaimEnabled && _publicClaimTime <= block.timestamp,
            "Public Claim is not enabled yet!"); 
            _;
    }

    function publicMintStatus() external view returns (bool) {
        return _publicClaimEnabled && _publicClaimTime <= block.timestamp; 
    }
}

abstract contract MultiMerkleRoots {
    mapping(uint => bytes32) internal _merkleRoots;

    function merkleRoots(uint _allocation) public view returns (bytes32) {
        return _merkleRoots[_allocation];
    }

    function _setMerkleRoots(uint[] calldata _allocations, bytes32[] calldata _newRoots) internal {
        uint _len = _allocations.length;
        for(uint i = 0; i < _len; i++) {
            _merkleRoots[_allocations[i]] = _newRoots[i];
        } 
    }

    function isAllowlisted(address _user, bytes32 [] calldata _merkleProof, uint _allocation) public view returns(bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_user));
        bytes32 _merkle_root = _merkleRoots[_allocation];
        for (uint256 i = 0; i < _merkleProof.length; i++) {
            _leaf = _leaf < _merkleProof[i]
                ? keccak256(abi.encodePacked(_leaf, _merkleProof[i]))
                : keccak256(abi.encodePacked(_merkleProof[i], _leaf));
        }
        return _leaf == _merkle_root;
    }
}

abstract contract ERC721AExtension is ERC721A {
    string internal baseTokenURI; string internal baseTokenURI_EXT;

    function multiTransferFrom(address from_, address to_, 
    uint256[] memory tokenIds_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }

    function multiSafeTransferFrom(address from_, address to_, 
    uint256[] memory tokenIds_, bytes memory data_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    // // Internal View Functions
    // Embedded Libraries
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(
            baseTokenURI, _toString(tokenId), baseTokenURI_EXT));
    }

    // token uri
    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_;
    }
}

contract FLT is ERC721AExtension, Ownable, Security, MultiMerkleRoots, PublicClaim {
    // Constructor
    constructor() payable ERC721A("Funcles Legacy Token", "FLT") {}

    uint256 public maxSupply = 3333;

    function withdraw() public onlyOwner {
        payable(owner).transfer(payable(address(this)).balance);
    }

    // Token URI
    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    // Public Claim
    function setPublicClaim(bool bool_, uint256 time_) external onlyOwner {
        _setPublicClaim(bool_, time_);
    }

    function setMerkleRoots(uint[] calldata _allocations, bytes32[] calldata _newRoots) external onlyOwner {
        require(_allocations.length == _newRoots.length, "setMerkleRoots: Array length mismatch");
        _setMerkleRoots(_allocations, _newRoots);
    }

    function ownerMint(address[] calldata tos_, uint256[] calldata amounts_) external onlyOwner {
        require(tos_.length == amounts_.length,
            "Array lengths mismatch!");
        for (uint256 i = 0; i < tos_.length; i++) {
            _safeMint(tos_[i], amounts_[i]);
        }
    }

    function claim(uint256 _quantity, bytes32[] calldata _merkleProof, uint _allocation) external onlySender publicClaimEnabled {
        require(isAllowlisted(msg.sender, _merkleProof, _allocation), "Not allowlisted");
        require(_addressToClaims[msg.sender] + _quantity <= _allocation, "Not enough claims remaining");
        _addressToClaims[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }
}