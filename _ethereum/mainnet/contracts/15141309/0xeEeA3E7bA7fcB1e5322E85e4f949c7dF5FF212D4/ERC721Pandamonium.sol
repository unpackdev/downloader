// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Pausable.sol";
import "./ERC721A.sol";
import "./AccessControl.sol";

contract ERC721Pandamonium is ERC721A, Pausable, AccessControl {
    using Strings for uint;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public startMintId;
    string public contractURI;
    string public baseTokenURI;
    address public feeCollectorAddress;

    bool public claimStarted;
    bool public publicMint;
    uint public max;

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
    /// @param _feeCollectorAddress the address fee collector
    constructor(string memory _name, string memory _symbol, string memory _contractURI, address _feeCollectorAddress) ERC721A(_name, _symbol) {
        contractURI = _contractURI;
        baseTokenURI = _contractURI;
        startMintId = 0;
        max = 10000;
        feeCollectorAddress = _feeCollectorAddress;
        claimStarted = false;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint quantity) external onlyMinter {
        require(startMintId < max, "No more left");
        _mint(to, quantity);
        startMintId = quantity + startMintId;
    }

    function mintDirect(address to, uint quantity) external onlyOwner {
        require(startMintId < max, "No more left");
        _mint(to, quantity);
        startMintId = quantity + startMintId;
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        return baseTokenURI;
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setMaxQuantity(uint _quantity) public onlyOwner {
        max = _quantity;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }

    function owner() external view returns (address) {
        return feeCollectorAddress;
    }
}
