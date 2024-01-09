pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";

contract SmileToken is Ownable, ERC721Enumerable, AccessControlEnumerable {

    // An address who has permissions to mint NFT
    address public minter;

    mapping(uint256 => string) public tokenUri;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); 

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    constructor() ERC721("TheSmileOf", "TheSmileOf") {
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
        _setupRole(DEFAULT_ADMIN_ROLE, minter);
        _grantRole(DEFAULT_ADMIN_ROLE, minter);
    }

    function mint(address minterAddress) public onlyMinter returns (uint256) {
        _safeMint(minterAddress, totalSupply());
        return (totalSupply() - 1);
    }

    // Set every token URI by owner 
    function setTokenUri(uint256 _tokenID, string memory _tokenUri) public onlyMinter{
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");
        tokenUri[_tokenID] = _tokenUri;
    }

    function tokenURI(uint256 _tokenID) public view override returns(string memory){
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");
        return tokenUri[_tokenID];
    }
}