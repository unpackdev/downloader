// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./AccessControl.sol";

    error TotalAmountExceeded();
    error OnlyMinterRoleCanMint();

contract NFT is ERC721A, AccessControl, Ownable {
    string private _baseURIAddress;
    uint256 public immutable totalNFTSupply;
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory _name, string memory _symbol, string memory _initialBaseURI, uint256 _totalNFTSupply) ERC721A(_name, _symbol)  {
        _baseURIAddress = _initialBaseURI;
        totalNFTSupply = _totalNFTSupply;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        addMinter(_msgSender());
    }

    function addMinter(address _minter) public onlyOwner {
        // Grant the minter role to a specified account
        _setupRole(MINTER_ROLE, _minter);
    }

    function changeBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURIAddress = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIAddress;
    }

    function mintOwner(address addr, uint256 amount) public payable onlyOwner {
        _safeMint(addr, amount);
    }

    function mintTo(address addr, uint256 amount) public validateAmount(amount) {
        if (!hasRole(MINTER_ROLE, _msgSender())) {
            revert OnlyMinterRoleCanMint();
        }
        _safeMint(addr, amount);
    }

    modifier validateAmount(uint256 amount) {
        if ((totalSupply() + amount) > totalNFTSupply) {
            revert TotalAmountExceeded();
        }
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}