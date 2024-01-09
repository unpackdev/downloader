// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./AdminControl.sol";
import "./StringConvertor.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./ERC20Upgradeable.sol";
import "./IVNFTDescriptor.sol";
import "./IVoucherSVG.sol";
import "./ConvertibleVoucher.sol";
import "./ConvertiblePool.sol";
import "./base64.sol";

contract ConvertibleVoucherDescriptor is IVNFTDescriptor, AdminControl {

    event SetVoucherSVG(
        address indexed voucher,
        address oldVoucherSVG,
        address newVoucherSVG
    );

    using StringConvertor for address;
    using StringConvertor for uint256;
    using StringConvertor for bytes;

    // ConvertibleVoucher address => VoucherSVG address
    // Mapping value of 0x0 is defined as default VoucherSVG
    mapping(address => address) public voucherSVGs;


    function initialize(address defaultVoucherSVG_) external initializer {
        AdminControl.__AdminControl_init(_msgSender());
        setVoucherSVG(address(0), defaultVoucherSVG_);
    }

    function setVoucherSVG(address voucher_, address voucherSVG_) public onlyAdmin {
        emit SetVoucherSVG(voucher_, voucherSVGs[voucher_], voucherSVG_);
        voucherSVGs[voucher_] = voucherSVG_;
    }

    function contractURI() external view override returns (string memory) { 
        ConvertibleVoucher voucher = ConvertibleVoucher(_msgSender());
        return string(
            abi.encodePacked(
                'data:application/json;{"name":"', voucher.name(),
                '","description":"', _contractDescription(voucher),
                '","unitDecimals":"', uint256(voucher.unitDecimals()).toString(),
                '","properties":{}}'
            )
        );
    }

    function slotURI(uint256 slot_) external view override returns (string memory) {
        ConvertibleVoucher voucher = ConvertibleVoucher(_msgSender());
        ConvertiblePool pool = voucher.convertiblePool();
        ConvertiblePool.SlotDetail memory slotDetail = pool.getSlotDetail(slot_);

        return string(
            abi.encodePacked(
                'data:application/json;{"unitsInSlot":"', voucher.unitsInSlot(slot_).toString(),
                '","tokensInSlot":"', voucher.tokensInSlot(slot_).toString(),
                '","properties":', _properties(pool, slotDetail),
                '}'
            )
        );
    }

    function tokenURI(uint256 tokenId_)
        external
        view
        virtual
        override
        returns (string memory)
    {
        ConvertibleVoucher voucher = ConvertibleVoucher(_msgSender());
        ConvertiblePool pool = voucher.convertiblePool();

        uint256 slot = voucher.slotOf(tokenId_);
        ConvertiblePool.SlotDetail memory slotDetail = pool.getSlotDetail(slot);
        
        bytes memory name = abi.encodePacked(voucher.name(), ' #', tokenId_.toString());

        address voucherSVG = voucherSVGs[_msgSender()];
        if (voucherSVG == address(0)) {
            voucherSVG = voucherSVGs[address(0)];
        }
        string memory image = IVoucherSVG(voucherSVG).generateSVG(_msgSender(), tokenId_);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"', name, 
                            '","description":"', _tokenDescription(voucher, tokenId_, slotDetail),
                            '","image":"data:image/svg+xml;base64,', Base64.encode(bytes(image)),
                            '","units":"', voucher.unitsInToken(tokenId_).toString(),
                            '","slot":"', slot.toString(),
                            '","properties":', _properties(pool, slotDetail),
                            '}'
                        )
                    )
                )
            );
    }

    function _contractDescription(ConvertibleVoucher voucher) 
        private 
        view
        returns (bytes memory)
    {
        string memory underlyingSymbol = ERC20Upgradeable(voucher.underlying()).symbol();

        return abi.encodePacked(
            unicode'⚠️ ', _descAlert(), '\\n\\n',
            'Convertible Voucher of ', underlyingSymbol, '. ',
            _descVoucher(), '\\n\\n', 
            _descProtocol()
        );
    }

    function _tokenDescription(
        ConvertibleVoucher voucher, 
        uint256 tokenId, 
        ConvertiblePool.SlotDetail memory slotDetail
    )
        private
        view
        returns (bytes memory)
    {
        string memory underlyingSymbol = ERC20Upgradeable(voucher.underlying()).symbol();

        return abi.encodePacked(
            unicode'⚠️ ', _descAlert(), '\\n\\n',
            'Convertible Voucher #', tokenId.toString(), ' of ', underlyingSymbol, '. ',
            _descVoucher(), '\\n\\n', 
            abi.encodePacked(
                '- Voucher Address: ', address(voucher).addressToString(), '\\n',
                '- Pool Address: ', address(voucher.convertiblePool()).addressToString(), '\\n',
                '- Underlying Address: ', voucher.underlying().addressToString(), '\\n',
                '- Fund Currency Address: ', slotDetail.fundCurrency.addressToString()
            )
        );
    }

    function _descAlert() private pure returns (string memory) {
        return "**Alert**: The price of the NFTs you're seeing on this page may be incorrect due to the failure of several third-party marketplaces to keep the numbers up to date. Please check the Voucher's correct pricing on the Solv dApp before buying or making an offer.";
    }

    function _descVoucher() private pure returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    'Convertible Voucher is a structured product that can be converted into a predetermined number of tokens or stablecoins under certain conditions.',
                    '\\n\\n', 
                    'At maturity, the holders are paid the face value in stablecoins if the settlement price falls into the bond range. Otherwise, the Voucher will convert to an amount of tokens redeemable by the holder.'
                )
            );
    }

    function _descProtocol() private pure returns (string memory) {
        return 'Solv Protocol is the decentralized platform for creating, managing and trading Financial NFTs.';
    }

    function _properties(
        ConvertiblePool pool,
        ConvertiblePool.SlotDetail memory slotDetail
    ) 
        private
        view
        returns (bytes memory data) 
    {
        return 
            abi.encodePacked(
                abi.encodePacked(
                    '{"underlyingToken":"', pool.underlyingToken().addressToString(),
                    '","fundCurrency":"', slotDetail.fundCurrency.addressToString(), 
                    '","issuer":"', slotDetail.issuer.addressToString(),
                    '","totalValue":"', _formatValue(slotDetail.totalValue, pool.valueDecimals())
                ),
                abi.encodePacked(
                    '","highestPrice":"', _formatValue(slotDetail.highestPrice, pool.priceDecimals()),
                    '","lowestPrice":"', _formatValue(slotDetail.lowestPrice, pool.priceDecimals()),
                    '","settlePrice":"', _formatValue(slotDetail.settlePrice, pool.priceDecimals()),
                    '","effectiveTime":"', uint256(slotDetail.effectiveTime).datetimeToString(),
                    '","maturity":"', uint256(slotDetail.maturity).datetimeToString(),
                    '"}'
                )
            );
    }

    function _formatValue(uint256 value, uint8 decimals) private pure returns (bytes memory) {
        return value.uint2decimal(decimals).trim(decimals - 2).addThousandsSeparator();
    }

}
