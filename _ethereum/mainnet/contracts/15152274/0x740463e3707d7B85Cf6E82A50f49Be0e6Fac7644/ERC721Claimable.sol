// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Pausable.sol";
import "./ERC721A.sol";
import "./AccessControl.sol";

contract ERC721Claimable is ERC721A, Pausable, AccessControl {
    using Strings for uint;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public startMintId;
    address public ownerAddress;
    string public contractURI;
    string public baseTokenURIWhiteHoodiesClaimed;
    string public baseTokenURIBlackHoodiesClaimed;
    string public baseTokenURIWhiteHoodies;
    string public baseTokenURIBlackHoodies;
    mapping(uint => bool) public blackHoodies;
    mapping(uint => bool) public whiteHoodies;
    mapping(uint => bool) public claimed;
    address public feeCollectorAddress;

    bool public claimStarted;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role.");
        _;
    }
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
        _;
    }

    /// @notice Constructor for the ONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _contractURI the contract URI
    /// @param _baseTokenURIBlackHoodies the base URI for computing the tokenURI
    /// @param _baseTokenURIBlackHoodiesClaimed the base URI for computing the tokenURI
    /// @param _baseTokenURIWhiteHoodies the base URI for computing the tokenURI
    /// @param _baseTokenURIWhiteHoodiesClaimed the base URI for computing the tokenURI
    /// @param _feeCollectorAddress the address fee collector
    constructor(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURIBlackHoodies, string memory _baseTokenURIBlackHoodiesClaimed, string memory _baseTokenURIWhiteHoodies, string memory _baseTokenURIWhiteHoodiesClaimed, address _feeCollectorAddress)
        ERC721A(_name, _symbol)
    {
        contractURI = _contractURI;
        baseTokenURIBlackHoodies = _baseTokenURIBlackHoodies;
        baseTokenURIWhiteHoodies = _baseTokenURIWhiteHoodies;
        baseTokenURIBlackHoodiesClaimed = _baseTokenURIBlackHoodiesClaimed;
        baseTokenURIWhiteHoodiesClaimed = _baseTokenURIWhiteHoodiesClaimed;
        startMintId = 0;
        feeCollectorAddress = _feeCollectorAddress;
        claimStarted = false;

        ownerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function claim(uint tokenId) external {
        require(claimStarted, "Claim period has not begun");
        require(ownerOf(tokenId) == msg.sender, "Must be owner");
        claimed[tokenId] = true;
    }

    function mint(address to, uint quantity) external onlyMinter {
        _mint(to, quantity);
        startMintId = quantity + startMintId;
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        if (whiteHoodies[tokenId]) {
            if (claimed[tokenId]) {
                return string(abi.encodePacked(baseTokenURIWhiteHoodiesClaimed, tokenId.toString()));
            }
            return string(abi.encodePacked(baseTokenURIWhiteHoodies, tokenId.toString()));
        } else {
            if (claimed[tokenId]) {
                return string(abi.encodePacked(baseTokenURIBlackHoodiesClaimed, tokenId.toString()));
            }
            return string(abi.encodePacked(baseTokenURIBlackHoodies, tokenId.toString()));
        }
    }

    function owner() external view returns (address) {
        return ownerAddress;
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setOwner(address _newOwner) public onlyOwner {
        ownerAddress = _newOwner;
    }

    function setBaseURIWhiteHoodies(string memory _baseTokenURI) public onlyOwner {
        baseTokenURIWhiteHoodies = _baseTokenURI;
    }

    function setBaseURIWhiteHoodiesClaimed(string memory _baseTokenURIClaimed) public onlyOwner {
        baseTokenURIWhiteHoodiesClaimed = _baseTokenURIClaimed;
    }

    function setBaseURIBlackHoodies(string memory _baseTokenURI) public onlyOwner {
        baseTokenURIBlackHoodies = _baseTokenURI;
    }

    function setBaseURIBlackHoodiesClaimed(string memory _baseTokenURIClaimed) public onlyOwner {
        baseTokenURIBlackHoodiesClaimed = _baseTokenURIClaimed;
    }

    function setClaimStart(bool _isStarted) public onlyOwner {
        claimStarted = _isStarted;
    }

    function setBlackHoodieToken(uint _tokenId) public onlyOwner {
        blackHoodies[_tokenId] = true;
    }

    function setBlackHoodieTokens(uint[] memory _tokenIds) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            blackHoodies[_tokenIds[i]] = true;
        }
    }

    function revokeBlackHoodieToken(uint _tokenId) public onlyOwner {
        blackHoodies[_tokenId] = false;
    }

    function revokeBlackHoodieTokens(uint[] memory _tokenIds) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            blackHoodies[_tokenIds[i]] = false;
        }
    }

    function setWhiteHoodieToken(uint _tokenId) public onlyOwner {
        whiteHoodies[_tokenId] = true;
    }

    function setWhiteHoodieTokens(uint[] memory _tokenIds) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            whiteHoodies[_tokenIds[i]] = true;
        }
    }

    function revokeWhiteHoodieToken(uint _tokenId) public onlyOwner {
        whiteHoodies[_tokenId] = false;
    }

    function revokeWhiteHoodieTokens(uint[] memory _tokenIds) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            whiteHoodies[_tokenIds[i]] = false;
        }
    }

    function _beforeTokenTransfers(address from, address to, uint tokenId, uint quantity) internal virtual override {
        super._beforeTokenTransfers(from, to, tokenId, quantity);

        require(!claimed[tokenId], "ERC721Claimable: token has already been claimed");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }
}
