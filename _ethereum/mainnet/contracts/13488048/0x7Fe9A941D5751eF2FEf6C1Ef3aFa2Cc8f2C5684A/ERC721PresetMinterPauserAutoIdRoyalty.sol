// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721PresetMinterPauserAutoId.sol";

import "./ERC2981Royalties.sol";

abstract contract ERC721PresetMinterPauserAutoIdRoyalty is ERC2981Royalties, ERC721PresetMinterPauserAutoId {
    modifier mustExist(uint256 _tokenId) {
        require(_exists(_tokenId), 'This token id does not exist.');
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint16 _royalty
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseURI) ERC2981Royalties(_royalty) {}

    /// @dev Override supportsInterface to use ERC2981Royalties
    function supportsInterface(bytes4 _interfaceID)
        public
        view
        virtual
        override(ERC721PresetMinterPauserAutoId, ERC2981Royalties)
        returns (bool)
    {
        return ERC2981Royalties.supportsInterface(_interfaceID) || super.supportsInterface(_interfaceID);
    }

    /// @notice Minting is only allowed through the mintVotersNFT function
    /// @dev only allow minting through safe mint
    function mint(address) public pure virtual override {
        /* istanbul ignore else */
        require(false, 'The mint() function is not allowed.');
    }
}
