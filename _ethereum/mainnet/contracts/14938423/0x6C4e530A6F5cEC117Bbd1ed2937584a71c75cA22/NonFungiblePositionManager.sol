//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "NFTDescriptor.sol";
import "utils.sol";
import "ITrueFreezeGovernor.sol";

/// @title NonFungiblePositionManager contract
/// @author chalex.eth - CharlieDAO
/// @notice Represent position as a NFT

contract NonFungiblePositionManager is ERC721, Ownable {
    address public governorAddress;
    bool private isInitialized;

    /* ------------------ Constructor --------------*/

    constructor() ERC721("TrueFreeze NFT positions", "TrueFreeze") {}

    /* ------------------ Modifier --------------*/
    modifier onlyGovernor() {
        require(msg.sender == governorAddress, "Only Factory can call");
        _;
    }

    /* ----------- External functions --------------*/

    /// @notice set the TrueFreezeGovernor address
    /// @param _governorAddress address of the TrueFreezeGovernor contract
    function setOnlyGovernor(address _governorAddress) external onlyOwner {
        require(isInitialized == false, "Governor already set");
        governorAddress = _governorAddress;
        isInitialized = true;
    }

    /// @notice mint NFT when wAsset are locked in TrueFreezeGovernor
    /// @dev mint is only perform by the TrueFreezeGovernor
    function mint(address _to, uint256 _tokenId) external onlyGovernor {
        _mint(_to, _tokenId);
    }

    /// @notice burn NFT when wAsset are withdrawed early in TrueFreezeGovernor
    /// @dev mint is only perform by the TrueFreezeGovernor
    function burn(uint256 _tokenId) external onlyGovernor {
        _burn(_tokenId);
    }

    /* ----------- View functions --------------*/

    /// @dev return SVG code for rendering the NFT
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId));
        (
            uint256 _amountLocked,
            ,
            uint256 _lockingDate,
            uint256 _maturityDate,

        ) = ITrueFreezeGovernor(governorAddress).getPositions(tokenId);

        return
            NFTDescriptor._constructTokenURI(
                _amountLocked,
                _lockingDate,
                _maturityDate
            );
    }
}
