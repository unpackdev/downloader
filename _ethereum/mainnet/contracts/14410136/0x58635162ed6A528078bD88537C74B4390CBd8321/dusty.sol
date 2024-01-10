pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "./IERC1820Registry.sol";
import "./ReentrancyGuard.sol";
import "./IERC777Recipient.sol";
import "./IERC777.sol";

// import "./console.sol";

abstract contract dusty is IERC777Recipient, ReentrancyGuard {
    // struct community_data {
    //     uint256 start;
    //     uint256 end;
    //     uint256 price;
    //     bool    isDust;
    //     uint256 max_purchase;
    //     address purchaser;
    // }

    address DUST_TOKEN;
    address signer;
    address[] wallets;
    uint16[] shares;
    uint256 fullDustPrice;
    uint256 discountDustPrice;
    uint256 maxPerSaleMint;

    mapping(address => uint256) presold;

    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    event DustPresale(address from, uint256 number_of_items, uint256 price);
    event DustSale(address buyer, uint256 number_to_buy, uint256 dustAmount);

    constructor(
        address dust,
        address _signer,
        uint256 _fullDustPrice,
        uint256 _discountDustPrice,
        uint256 _maxPerSaleMint,
        address[] memory _wallets,
        uint16[] memory _shares
    ) {
        DUST_TOKEN = dust;/*
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );*/
        wallets = _wallets;
        shares = _shares;
        signer = _signer;
        fullDustPrice = _fullDustPrice;
        discountDustPrice = _discountDustPrice;
        maxPerSaleMint = _maxPerSaleMint;
    }

    // https://twitter.com/nicksdjohnson/status/1485769228481605639?s=20&t=22PZlf-8awaea2bubNw72A
    // ```
    // bytes4 selector = bytes4(data[:4]);
    // uint256 id = uint256(bytes32(data[4:36]));
    // ```

    struct vData {
        bool mint_free;
        uint256 max_mint;
        address from;
        uint256 start;
        uint256 end;
        uint256 eth_price;
        uint256 dust_price;
        bytes signature;
    }

    function tokensReceived(
        address,
        address from,
        address,
        uint256 amount,
        bytes calldata userData,
        bytes calldata
    ) external override nonReentrant {
 
    }

    function checkSaleIsActive() public view virtual returns (bool);

    function checkPresaleIsActive() public view virtual returns (bool);

    function bumpDiscount(address msgSender, uint256 numberOfCards)
        internal
        virtual;

    function checkBuyerHasEthercards(address buyer) internal view virtual;

    function dustPreSaleWithEC(
        address buyer,
        uint256 dustAmount,
        uint256 number_to_buy
    ) internal {
        // nonReEntrant by calling
        ///   console.log(block.timestamp);
        require(checkPresaleIsActive(), "Presale is not active");
        require(
            dustAmount == discountDustPrice * number_to_buy,
            "incorrect amount of dust supplied"
        );
        require(number_to_buy < maxPerSaleMint, "too many tokens requested");
        checkBuyerHasEthercards(buyer);

        bumpDiscount(buyer, number_to_buy);

        _mintCards(number_to_buy, buyer);
        _split777(dustAmount);
        emit DustSale(buyer, number_to_buy, dustAmount);
    }

    function dustMainSale(
        address buyer,
        uint256 dustAmount,
        uint256 number_to_buy
    ) internal {
        // nonReEntrant by calling
        // console.log(block.timestamp);
        require(checkSaleIsActive(), "Sale is not active");
        require(
            dustAmount == fullDustPrice * number_to_buy,
            "incorrect amount of dust supplied"
        );
        require(number_to_buy < maxPerSaleMint, "too many tokens requested");
        _mintCards(number_to_buy, buyer);
        _split777(dustAmount);
        emit DustSale(buyer, number_to_buy, dustAmount);
    }

    function _mintCards(uint256 numberOfCards, address recipient)
        internal
        virtual;

    function _mintDiscountCards(uint256 numberOfCards, address recipient)
        internal
        virtual;

    function _split777(uint256 amount) internal {
        uint256 _total;
        for (uint256 j = 0; j < wallets.length; j++) {
            uint256 _amount = (amount * shares[j]) / 1000;
            if (j == wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            IERC777(DUST_TOKEN).send(wallets[j], _amount, "");
        }
    }

    function verify(vData memory info) public view returns (bool) {
        require(info.from != address(0), "INVALID_SIGNER");
        bytes memory cat =
            abi.encode(
                info.from,
                info.start,
                info.end,
                info.eth_price,
                info.dust_price,
                info.max_mint,
                info.mint_free
            );
        // console.log("data-->");
        // console.logBytes(cat);
        bytes32 hash = keccak256(cat);
        // console.log("hash ->");
        //    console.logBytes32(hash);
        require(info.signature.length == 65, "Invalid signature length");
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        bytes memory signature = info.signature;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data =
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
        address recovered = ecrecover(data, sigV, sigR, sigS);
        return signer == recovered;
    }
}
