//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract NFKeyz is ERC721, Ownable {
    address public minter;

    mapping(uint256 => string) internal _tokenURIs;

    uint256 public totalSupply;

    event ChangeTokenURI(uint256 _tokenId, string _tokenURI);

    /// @param user Address of the user
    /// @param tokenURI URI of the token
    struct MintParams {
        address user; // address of the user
        string tokenURI; // uri of the token
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "NFKeyz:not allowed");
        _;
    }

    /// @param _owner Admin address
    constructor(address _owner) ERC721("NFKeyz", "KEYZ") {
        _transferOwnership(_owner);
    }

    /// @notice Mint the new NFT
    /// @dev only minter can mint new NFT
    /// @param _user Address where the NFT should be minted
    /// @param _tokenURI TokenURI which needs to be attached with NFT
    function mint(address _user, string memory _tokenURI) external onlyMinter {
        totalSupply += 1;
        _tokenURIs[totalSupply] = _tokenURI;
        _mint(_user, totalSupply);
    }

    /// @dev Changes token URI of specific tokenID
    /// @param _tokenId ID for which the URI needs to be updated
    /// @param _tokenURI New token URI
    function changeTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        onlyOwner
    {
        _tokenURIs[_tokenId] = _tokenURI;
    }

    /// @notice Returns tokenURI for specific tokenID
    /// @param _tokenId ID of the token
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _tokenURIs[_tokenId];
    }

    /// @notice Adds the minter
    /// @dev Minter can be added only once
    /// @param _minter Address of the minter
    function changeMinter(address _minter) external onlyOwner {
        minter = _minter;
    }
}
