// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";

/**
   @title SporesNFT721 contract
   @dev This contract is used to handle Spores NFT Token using ERC-721 (https://eips.ethereum.org/EIPS/eip-721)
*/
contract SporesNFT721 is OwnableUpgradeable, ERC721URIStorageUpgradeable {
    //  Address of Minter
    address private _minter;

    //  SporesNFT721 version
    bytes32 public constant VERSION = keccak256("SPORES_NFT_721_v1");

    event TransferMinter(
        address indexed previousMinter,
        address indexed newMinter
    );

    modifier onlyMinter() {
        require(_minter == _msgSender(), "SporesNFT721: caller is not minter");
        _;
    }

    /**
       @notice Initialize Token Name and Token Symbol
            In upgradeability, this function is used to replace `constructor`
       @dev This function should be called only once - right after SporesNFT721 contract is deployed
       @param _name            Initialized Token name
       @param _symbol          Initialized Token symbol
    */
    function init(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        _minter = _msgSender();
    }

    /**
       @notice Transfer Minter role to a new address
       @dev Caller must have Minter or Owner role
            New Minter should not be address(0)
       @param _newMinter        Address of a new Minter
    */
    function transferMinter(address _newMinter) external {
        require(
            _msgSender() == _minter || _msgSender() == owner(),
            "SporesNFT721: caller is not minter or owner"
        );
        require(_newMinter != address(0), "SporesNFT721: Set zero address");

        emit TransferMinter(_minter, _newMinter);
        _minter = _newMinter;
    }

    /**
       @notice Query an address of current Minter role
       @dev Caller can be ANY
       @return      Address of current Minter
    */
    function minter() external view returns (address) {
        return _minter;
    }

    /**
       @notice Mint NFT Token to a receiver `to`
       @dev Caller must have Minter role
       @param _to           Receiver Address
       @param _tokenId      Token ID number
       @param _uri          Token URI
    */
    function mint(
        address _to,
        uint256 _tokenId,
        string calldata _uri
    ) external onlyMinter {
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }
}
