// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author Colton Brown (@colt_xyz, coltonbrown.com)
/// @title Manifold Extension for XYZ.CHURCH

import "./AdminControl.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC165.sol";

contract XYZManifoldExtension is ICreatorExtensionTokenURI, AdminControl  {

    address private _creator;
    uint256 private NUM_MINTED = 0;
    uint256 private constant PRICE = 0.2 ether;
    uint256 private constant MAX_MINTABLE = 50;
    uint8 private constant TOKEN_ID = 1;
    bool private isEnabled = true;

    event Minted(address owner);

    constructor(address creator) {
        _creator = creator;
        NUM_MINTED = IERC1155CreatorCore(_creator).totalSupply(TOKEN_ID);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AdminControl, IERC165)
        returns (bool)
    {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId 
        || AdminControl.supportsInterface(interfaceId) 
        || super.supportsInterface(interfaceId);
    }
    

    /// Supplies the metadata URL; a manifold feature.
    /// @dev can be configured to change based on caller
    /// @return metadata URL containing a json schema
    function tokenURI(address /*creator*/, uint256 /*tokenId*/)
        external
        pure
        override
        returns (string memory)
    {
        return 'https://arweave.net/Xsn4nYTe7tvUKlaRVvTUQC9KBHYUCvE7EsuHtNGQAwo';
    }

    /// Withdraw proceeds of the mint to XYZ DAO
    function withdrawAll() external adminRequired {
        payable(0xb01Ba49F1B04A87D75BC268F9f3B5D1276A588f6).transfer(address(this).balance);
    }

    /// Expose state variables for use in xyz.church frontend
    /// @return price NFT mint price
    /// @return maxMint the maximum allowed number of Tokens
    /// @return numMinted the number of tokens already minted
    function getContractState() external view returns (uint256 price, uint256 maxMint, uint256 numMinted) {
        return (PRICE, MAX_MINTABLE, NUM_MINTED);
    }

    // Safety valves for pausing and unpausing the contract
    function pauseMint() external adminRequired {
        isEnabled = false;
    }

    function resumeMint() external adminRequired {
        isEnabled = true;
    }

    // Initialize the minting session by creating the first token as an admin; this is a manifold pattern
    // @dev see manifold's documentation https://www.dropbox.com/s/x9t53qf3werqxru/Manifold%20Creator%20Architecture.pdf
    function mintNew() external adminRequired {

        require(
            NUM_MINTED == 0,
            'TokenID has already been minted'
        );

        address[] memory _callerAddress = new address[](1);
        uint256[] memory _amountsForMint = new uint256[](1);
        string[] memory _urisForMint = new string[](1);

        _callerAddress[0] = msg.sender;
        _amountsForMint[0] = 1;

        uint256[] memory minted = IERC1155CreatorCore(_creator).mintExtensionNew(_callerAddress, _amountsForMint, _urisForMint);
        NUM_MINTED = minted.length;
        emit Minted(msg.sender);
    }

    // Mint a token that has already been initialized with a call to the above method
    // @dev see manifold's documentation https://www.dropbox.com/s/x9t53qf3werqxru/Manifold%20Creator%20Architecture.pdf
    function mintExisting() external payable {

        require (
            isEnabled,
            "Minting has been paused."
        );
        require(
            msg.value >= PRICE,
            "Not enough ether to purchase token."
        );
        require(
            NUM_MINTED > 0,
            "This token has not yet been initialized by an administrator."
        );
        require(
            NUM_MINTED < MAX_MINTABLE,
            "Token is sold out."
        );

        address[] memory _callerAddress = new address[](1);
        uint256[] memory _tokenIdsForMint = new uint256[](1);
        uint256[] memory _amountsForMint = new uint256[](1);

        _callerAddress[0] = msg.sender;
        _tokenIdsForMint[0] = TOKEN_ID;
        _amountsForMint[0] = 1;
        
        IERC1155CreatorCore(_creator).mintExtensionExisting(_callerAddress, _tokenIdsForMint, _amountsForMint);
        NUM_MINTED ++;
        emit Minted(msg.sender);
    }
}
