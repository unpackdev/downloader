// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
   @title SporesNFT1155 contract
   @dev This contract is used to handle Spores NFT Token using ERC-1155 (https://eips.ethereum.org/EIPS/eip-1155)
*/
contract SporesNFT1155 is ERC1155URIStorageUpgradeable, OwnableUpgradeable {
    //  Address of Minter
    address private _minter;

    //  SporesNFT1155 version
    bytes32 public constant VERSION = keccak256("SPORES_NFT_1155_v1");

    event TransferMinter(
        address indexed previousMinter,
        address indexed newMinter
    );

    modifier onlyMinter() {
        require(_minter == _msgSender(), "SporesNFT1155: caller is not minter");
        _;
    }

    /**
       @notice Initialize ERC1155, Owner, and Minter
            In upgradeability, this function is used to replace `constructor`
       @dev This function should be called only once - right after SporesNFT1155 contract is deployed
    */
    function init() external initializer {
        __ERC1155_init();
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
            "SporesNFT1155: caller is not minter or owner"
        );
        require(_newMinter != address(0), "SporesNFT1155: Set zero address");

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
       @notice Minting new Spores NFT Token (ERC1155)
       @dev Caller must have Minter role
       @param _to           Receiver Address
       @param _tokenId      Token ID
       @param _amount       An amount of Spores NFT Token being minted
       @param _uri          Token URI
       @param _data         Data to be sent to Receiver
    */
    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        string calldata _uri,
        bytes memory _data
    ) external onlyMinter {
        require(!_existed(_tokenId), "SporesNFT1155: Token already minted");
        _mint(_to, _tokenId, _amount, _data);
        _setTokenURI(_tokenId, _uri);
    }

    function _existed(uint256 _tokenId) internal view returns (bool) {
        return bytes(uri(_tokenId)).length > 0;
    }
}
