// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./IBaseCollection.sol";
import "./INiftyKit.sol";

abstract contract BaseCollection is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    IBaseCollection
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    INiftyKit internal _niftyKit;
    address internal _treasury;
    uint256 internal _totalRevenue;

    function __BaseCollection_init(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ERC2981_init();
        __Ownable_init_unchained();

        _niftyKit = INiftyKit(_msgSender());
        _treasury = treasury_;
        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function withdraw() external {
        require(address(this).balance > 0, "0 balance");

        uint256 balance = address(this).balance;
        uint256 fees = _niftyKit.getFees(address(this));
        _niftyKit.addFeesClaimed(fees);
        AddressUpgradeable.sendValue(payable(address(_niftyKit)), fees);
        AddressUpgradeable.sendValue(payable(_treasury), balance.sub(fees));
    }

    function setTreasury(address newTreasury) external onlyOwner {
        _treasury = newTreasury;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function totalRevenue() external view returns (uint256) {
        return _totalRevenue;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function transferOwnership(address newOwner)
        public
        override(IBaseCollection, OwnableUpgradeable)
    {
        return OwnableUpgradeable.transferOwnership(newOwner);
    }
}
