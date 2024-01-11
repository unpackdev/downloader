pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

/*

    This unit allows the user to define specific cards with specific rewards

    The sale page has a mapping of token address : saleInfo

    token : 0x97ca7fe0b0288f5eb85f386fed876618fb9b8ab8 {
        start : 1646092800,
        end : 1646265600,
        price : 200000000000000000,
        max : 5,
        total : 1000,
        signature : 0x123456789.....
    }



*/

import "./IERC721.sol";

// import "./console.sol";

abstract contract card_with_card {
    struct saleInfo {
        address token_address;
        uint256 start;
        uint256 end;
        uint256 price;
        uint256 max_per_user;
        uint256 total;
        bool oneForOne;
        bytes signature;
    }

    address cwc_signer;

    mapping(address => mapping(address => uint256)) claimedWithCard; // token => (user => claimed)
    mapping(address => mapping(uint256 => bool)) usedCards; // token => (user => claimed)
    mapping(address => uint256) claimedPerToken;

    constructor(address _signer) {
        cwc_signer = _signer;
    }

    function _mintCards(uint256 numberOfCards, address recipient)
        internal
        virtual;

    function _mintDiscountCards(uint256 numberOfCards, address recipient)
        internal
        virtual;

    function _mintDiscountPayable(
        uint256 numberOfCards,
        address recipient,
        uint256 price
    ) internal virtual;

    function _mintPayable(
        uint256 numberOfCards,
        address recipient,
        uint256 price
    ) internal virtual;

    function canSell(uint256 start, uint256 end) internal view returns (bool) {
        return !((block.timestamp < start) || (block.timestamp > end));
    }

    /*
    function mintFreePresaleWithCards(
        uint256 number_of_cards,
        saleInfo calldata sp,
        uint256[] memory tokenIds
    ) external {
        require(sp.price == 0, "You cannot claim free cards");
        require(canSell(sp.start, sp.end), "card with card claim not open");
        uint256 claimedTokens = claimedPerToken[sp.token_address];
        uint256 tokens_available = sp.total - claimedTokens;
        require(
            tokens_available > 0,
            "This token's free allocation is fully redeemed"
        );
        uint256 claimed = claimedWithCard[sp.token_address][msg.sender];
        require(verify(sp), "Invalid CM info");
        uint256 available = sp.max_per_user - claimed;
        require(available > 0, "you have already claimed the max");
        uint256 number_owned =
            eligibleTokens(sp.token_address, sp.oneForOne, tokenIds);
        require(number_owned > 0, "You do not have any eligible tokens");
        if (sp.oneForOne) {
            available = number_owned > available ? available : number_owned;
            console.log("avaialable in MFC", available);
            available = (available > sp.max_per_user)
                ? sp.max_per_user
                : available;
        }
        uint256 tokens_to_mint =
            (available > tokens_available) ? tokens_available : available;
        tokens_to_mint = (number_of_cards > tokens_to_mint)
            ? tokens_to_mint
            : number_of_cards;
        claimedPerToken[sp.token_address] = claimedTokens + tokens_to_mint;
        claimedWithCard[sp.token_address][msg.sender] =
            claimed +
            tokens_to_mint;
        _mintDiscountCards(tokens_to_mint, msg.sender);
    }
    */
    /*
    function mintDiscountPresaleWithCards(
        uint256 numberOfCards,
        saleInfo calldata sp,
        uint256[] memory tokenIds
    ) external payable {
        require(sp.price > 0, "Please claim free cards");
        require(canSell(sp.start, sp.end), "card with card sale not open");
        uint256 claimedTokens = claimedPerToken[sp.token_address];
        uint256 tokens_available = sp.total - claimedTokens;
        require(
            tokens_available > 0,
            "This token's discount allocation is fully redeemed"
        );
        uint256 claimed = claimedWithCard[sp.token_address][msg.sender];
        require(verify(sp), "Invalid CM info");
        uint256 available = sp.max_per_user - claimed;
        require(available > 0, "you have already claimed the max");
        uint256 number_owned =
            eligibleTokens(sp.token_address, sp.oneForOne, tokenIds);
        require(number_owned > 0, "You do not have any eligible tokens");
        if (sp.oneForOne) {
            available = number_owned > available ? available : number_owned;
            available = (available > sp.max_per_user)
                ? sp.max_per_user
                : available;
        }
        uint256 tokens_to_mint =
            (available > tokens_available) ? tokens_available : available;
        require(tokens_to_mint >= numberOfCards, "Not enough tokens available");
        claimedPerToken[sp.token_address] = claimedTokens + numberOfCards;
        claimedWithCard[sp.token_address][msg.sender] = claimed + numberOfCards;
        _mintDiscountPayable(numberOfCards, msg.sender, sp.price);
    }
*/
    function verify(saleInfo calldata sp) internal view returns (bool) {
        require(sp.token_address != address(0), "INVALID_TOKEN_ADDRESS");
        bytes memory cat =
            abi.encode(
                sp.token_address,
                sp.start,
                sp.end,
                sp.price,
                sp.max_per_user,
                sp.total,
                sp.oneForOne
            );
        // console.log("data-->");
        // console.logBytes(cat);
        bytes32 hash = keccak256(cat);
        // console.log("hash ->");
        //   console.logBytes32(hash);
        require(sp.signature.length == 65, "Invalid signature length");
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        bytes memory signature = sp.signature;
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
        //  console.log(cwc_signer, recovered);
        return cwc_signer == recovered;
    }

    function eligibleTokens(
        address token_address,
        bool oneForOne,
        uint256[] memory tokenIds
    ) internal returns (uint256) {
        uint256 count;
        for (uint256 j = 0; j < tokenIds.length; j++) {
            uint256 tokenId = tokenIds[j];
            require(
                IERC721(token_address).ownerOf(tokenId) == msg.sender,
                "You do not own all the tokens indicated"
            );
            if (oneForOne) {
                if (!usedCards[token_address][tokenId]) {
                    usedCards[token_address][tokenId] = true;
                    count++;
                }
            } else {
                count++;
            }
        }
        return count;
    }
}
