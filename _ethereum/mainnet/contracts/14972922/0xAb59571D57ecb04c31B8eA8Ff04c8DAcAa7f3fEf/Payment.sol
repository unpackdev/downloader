// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC165CheckerUpgradeable.sol";

import "./Constants.sol";

error Payment_Royalties_Make_More_Then_85_Precent();

error Payment_Royalties_Payees_Not_Equal_Shares_Lenght();

contract Payment is Constants {
    address internal _dissrupPayout;
    enum SaleType {
        DirectSale,
        AuctionSale
    }
    struct Royalty {
        address payee;
        uint256 share;
    }

    using ERC165CheckerUpgradeable for address;
    event PayToRoyalties(address payable[] payees, uint256[] shares);

    mapping(SaleType => mapping(uint256 => Royalty[]))
        internal _saleToRoyalties;

    function _setDissrupPayment(address dissrupPayout) internal virtual {
        _dissrupPayout = dissrupPayout;
    }

    function _splitPayment(
        address seller,
        uint256 price,
        SaleType saleType,
        uint256 saleId
    )
        internal
        returns (
            uint256 dissrupCut,
            uint256 sellerCut,
            address[] memory royaltiesPayees,
            uint256[] memory royaltiesCuts
        )
    {
        // 15% of price
        dissrupCut = (price * 15) / 100;

        payable(_dissrupPayout).transfer(dissrupCut);
        uint256 royaltiesTotalCut;
        (
            royaltiesTotalCut,
            royaltiesPayees,
            royaltiesCuts
        ) = _payToRoyaltiesIfExist(saleType, saleId, price);

        sellerCut = (price) - (dissrupCut + royaltiesTotalCut);

        payable(seller).transfer(sellerCut);
    }

    function _checkRoyalties(
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) internal pure {
        uint256 totalShares;
        if (royaltiesPayees.length != royaltiesShares.length) {
            revert Payment_Royalties_Payees_Not_Equal_Shares_Lenght();
        }

        for (uint256 i = 0; i < royaltiesPayees.length; i++) {
            totalShares = totalShares + royaltiesShares[i];
        }
        // dissrup cut is 15%
        if (totalShares > 85) {
            revert Payment_Royalties_Make_More_Then_85_Precent();
        }
    }

    function _setRoyalties(
        SaleType saleType,
        uint256 saleId,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) internal {
        for (uint256 i = 0; i < royaltiesPayees.length; i++) {
            Royalty memory royalty = Royalty({
                payee: royaltiesPayees[i],
                share: royaltiesShares[i]
            });

            _saleToRoyalties[saleType][saleId].push(royalty);
        }
    }

    function _payToRoyaltiesIfExist(
        SaleType saleType,
        uint256 saleId,
        uint256 price
    )
        private
        returns (
            uint256 royaltiesTotalCuts,
            address[] memory royaltiesPayees,
            uint256[] memory royaltiesCuts
        )
    {
        Royalty[] storage royalties = _saleToRoyalties[saleType][saleId];

        royaltiesCuts = new uint256[](royalties.length);
        royaltiesPayees = new address[](royalties.length);

        for (uint256 i = 0; i < royalties.length; i++) {
            Royalty memory royalty = royalties[i];

            uint256 cut = (price * royalty.share) / 100;

            royaltiesCuts[i] = cut;
            royaltiesPayees[i] = royalty.payee;
            royaltiesTotalCuts += cut;

            payable(royalty.payee).transfer(cut);
        }
    }
}
