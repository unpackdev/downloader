//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC165.sol";

import "./IERC2981Holder.sol";
import "./IERC2981.sol";

///
/// @dev An implementor for the NFT Royalty Standard. Provides interface
/// response to erc2981 as well as a way to modify the royalty fees
/// per token and a way to transfer ownership of a token.
///
abstract contract ERC2981 is ERC165, IERC2981, IERC2981Holder {

    // royalty receivers by token hash
    mapping(uint256 => address) internal royaltyReceiversByHash;

    // royalties for each token hash - expressed as permilliage of total supply
    mapping(uint256 => uint256) internal royaltyFeesByHash;

    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @dev only the royalty owner shall pass
    modifier onlyRoyaltyOwner(uint256 _id) {
        require(royaltyReceiversByHash[_id] == msg.sender,
        "Only the owner can modify the royalty fees");
        _;
    }

    /**
     * @dev ERC2981 - return the receiver and royalty payment given the id and sale price
     * @param _tokenId the id of the token
     * @param _salePrice the price of the token
     * @return receiver the receiver
     * @return royaltyAmount the royalty payment
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        require(_salePrice > 0, "Sale price must be greater than 0");
        require(_tokenId > 0, "Token Id must be valid");

        // get the receiver of the royalty
        receiver = royaltyReceiversByHash[_tokenId];

        // calculate the royalty amount. royalty is expressed as permilliage of total supply
        royaltyAmount = royaltyFeesByHash[_tokenId] / 1000000 * _salePrice;
    }

    /// @notice ERC165 interface responder for this contract
    /// @param interfaceId - the interface id to check
    /// @return supportsIface - whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override returns (bool supportsIface) {
        supportsIface = interfaceId == type(IERC2981).interfaceId
        || super.supportsInterface(interfaceId);
    }

    /// @notice set the fee permilliage for a token hash
    /// @param _id - id of the token hash
    /// @param _fee - the fee permilliage to set
    function setFee(uint256 _id, uint256 _fee) onlyRoyaltyOwner(_id) external override {
        require(_id != 0, "Fee cannot be zero");
        royaltyFeesByHash[_id] = _fee;
    }

    /// @notice get the fee permilliage for a token hash
    /// @param _id - id of the token hash
    /// @return fee - the fee
    function getFee(uint256 _id) external view override returns (uint256 fee) {
        fee = royaltyFeesByHash[_id];
    }

    /// @notice get the royalty receiver for a token hash
    /// @param _id - id of the token hash
    /// @return owner - the royalty owner
    function royaltyOwner(uint256 _id) external view override returns (address owner) {
        owner = royaltyReceiversByHash[_id];
    }

    /// @notice get the royalty receiver for a token hash
    /// @param _id - id of the token hash
    /// @param _newOwner - address of the new owners
    function transferOwnership(uint256 _id, address _newOwner) onlyRoyaltyOwner(_id) external override {
        require(_id != 0 && _newOwner != address(0), "Invalid token id or new owner");
        royaltyReceiversByHash[_id] = _newOwner;
    }
}
