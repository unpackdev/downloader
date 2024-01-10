// SPDX-License-Identifier: MIT
// NEKOCORE Reserve Minter
//
//                       @@@@@@@@@                                               (@@@@@*
//                      @@@/,,,,,%@@@@*                                      %@@@@&*/@@@@
//                     &@@*,,,,,,,,,,&@@@@                               (@@@@(,,,,,,,*@@@
//                     @@@,,,,,,,,,,,,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,%@@*
//                    @@@,,,,,,,,,,,,,,,,,,,*(/****,,,******,,,**/#@@@@(,,,,,,,,,,,,,,,,@@@
//                    @@@,,,,,,,,,,,,,,,,,,,******,,,******,,,******,,,,,,,,,,,,,,,,,,,,&@@,
//                   #@@(,,,,,,,,,,,,,,,,,,,******,,,******,,,,******,,,,,,,,,,,,,,,,,,,,@@@
//                   @@@*,,,,,,,,,,,,,,,,,,,,******,,,******,,,,******,,,,,,,,,,,,,,,,,,,@@@
//                   @@@,,,,,,,,,,,,,,,,,,,,,******,,,,******,,,,******,,,,,,,,,,,,,,,,,,#@@#
//                   @@@,,,,,,,,,,,,,,,,,,,,,*****,,,,,******,,,******,,,,,,,,,,,,,,,,,,,,@@@
//                  @@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,******,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@
//                &@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@
//               @@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%@@@
//              @@@#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@@
//             @@@&,,,,,,,,,,,,,,,,,,,,,%&&&&&#*,,,,,,,,,,,,,,,,,,,*#&&&&&%,,,,,,,,,,,,,,,,,,%@@@
//            ,@@@,,*********,,,,,,,,@&,,/@@@/,,@@&&*,,,,,,,,,*&@@,,*&@@(,,#@*,,,,,,*******,,,@@@,
//            @@@%************,,,,&%,@#,,,,,,,*%@@,&@,,,,,,,,/@,@@&%*,,,,,,/@*/@,,************@@@@
//            @@@/****,,,,,**,,,,@,@*,,,,,,,,,,,,,/@,@,,,,,,@*%%,,,,,,,,,,,,,,@,@,,***,,,,****&@@@
//            @@@/,,,,,,,,,,,,,,@,&*,,,,,,,,,,,,,,,/%,*,(#,,,/%,,,,,,,,,,,,,,,,@,@,,,,,,,,,,,,@@@%
//            %@@@*********,,,,,@,@,,,,,@,,,,,&#,,,,@*@@&#%@*#&,,,,@,,,,,(@,,,,@,@,,,*********@@@
//             @@@/*********,,,,,@,@,,,,,,(&%*,,,@@@,@,(@@@@@,@#@@,,,(&%*,,,,,@,&*,,,********@@@%
//              @@@*,,,,,,,,,,,,,,@,&@,,,,,,,,/@@@#,@((((((((@**@ %@&,,,,,,,%@,@,,,,,,,,,,,,@@@@
//               @@@(,,,,,,,,,,,,,,,@%,/@@@@@@@*,&@(((((%&%((((@@,*@@@@@@@(,(@,,,,,,,,,,,,,@@@%
//                @@@@,,,,,,,,,,,,,,*@@@&@@@@@%%&@((((@,    @((((@&%@@@@@%&@@@*,,,,,,,,,,@@@@
//                  @@@@*,,,,,,,,,#@#(@@*,,&@((@%%%@((@,@(@ @((@%%%@((@&,,*@@(#@(,,,,,,@@@@/
//                    @@@@@,,,,,,(@(&/ %@@@*  %%(&%%@(@,@(@ @(@%%&(%%  /@@@# /&(@(,,&@@@@
//                       @@@@@%,,@@(@ @(((((@, %(&%%@(@,@(@ @(@%%%#% ,@(((((@ @(@@@@@@(
//                          (@@@@@@(@,@(((((@, &(%%%@(@,@(@ @(@%%%#& ,@(((((@,@(@@@
//                              @@@@#(@,,(/,  @#(@@@(/@@   %@((@@@(#@  ,/(,,@(#@/
//                             &@@@,%@@(((##((#@@@,,,,,,,,,,,,,,,@@@#((##(((@@%
//                            @@@&******(@@@@*,,,,,,,,,,,,,,,,,,,,,,,*@@@@@@@(
//                           @@@@,****,,,,**,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@
//                          ,@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@
//                          @@@/***********,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@*
//                         ,@@@,******,,**,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@/
//                         @@@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@/
//                      @@@@@*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@
//                    @@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@
//                   @@@%,,,,***,,,,,/((((((((/,,,,,,,,,,,,,,,,,,,,,*(((#@@@@,
//                   @@@,,,****,,,,@@@@@@@@@@@@@@,,,,,,,@@@,,,,,,,@@@@@@@@@#
//                   @@@******,,,*****&@@@@&  @@@&,,,,,@@@@@,,,,,@@@@
//                    @@@@**,,,,****,,,,,@@@(  (@@@@@@@@@&@@@@@@@@@
//                      @@@@@@@#***,,,,,#@@@
//                          ,&@@@@@@@@@@@@#
//
//

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./NekoCore.sol";

contract NekoCoreReserve is IERC721Receiver, Ownable {
    enum ClaimStrategy {
        MATCH_BOGO,
        ONLY_ONCE,
        SET_EXPLICITLY
    }
    NekoCore public ORIGINAL_CONTRACT =
        NekoCore(0xc1328cf1CF8dB8a5fC407CD56759007C7d20e398);
    uint256 public ORIGINAL_PRICE = 0.09 ether;
    uint256 public PRICE = 0.045 ether;
    mapping(uint256 => uint256) public TIMES_CLAIMED;

    uint256 public BUY_ONE_GET_X = 1; // used for buy-one-get-X
    ClaimStrategy public CLAIM_STRATEGY_FOR_PAID_MINTS =
        ClaimStrategy.MATCH_BOGO;
    ClaimStrategy public CLAIM_STRATEGY_FOR_FREE_MINTS =
        ClaimStrategy.MATCH_BOGO;
    uint256 public EXPLICITLY_SET_CLAIMS_FOR_PAID_MINTS = 1;
    uint256 public EXPLICITLY_SET_CLAIMS_FOR_FREE_MINTS = 1;
    // ^^^ these are a little strange and we don't plan on using them, but it allows
    // for better flexibility with the giveaway limits of new mints
    uint256 public constant BATCH_CLAIM_SIZE = 1 << 6;
    bool public MINTABLE = false;

    // modifiers
    // ---------------------------------------------------------
    modifier refuelIfNeeded(uint256 count) {
        if (address(this).balance < (ORIGINAL_PRICE * count)) {
            _refuel();
        }
        _;
    }

    modifier onlyIfMintable() {
        require(MINTABLE, "NekoCore Reserve is not currently mintable");
        _;
    }

    // required overrides
    // ---------------------------------------------------------
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // public functions
    // ---------------------------------------------------------
    function mint(uint256 count)
        external
        payable
        onlyIfMintable
        refuelIfNeeded(count)
    {
        require(msg.value >= PRICE * count, "Minting fee not met");

        // mint some new tokens
        uint256 token_id_start = ORIGINAL_CONTRACT.MINTED();
        ORIGINAL_CONTRACT.mint{value: ORIGINAL_PRICE * count}(count);

        // transfer all the tokens that were just minted
        for (uint256 i = 1; i <= count; i++) {
            uint256 token_id = token_id_start + i;
            // any token minted through this contract has its claim count
            // set by the current claim strategy
            if (CLAIM_STRATEGY_FOR_PAID_MINTS == ClaimStrategy.MATCH_BOGO) {
                TIMES_CLAIMED[token_id] = BUY_ONE_GET_X;
            } else if (
                CLAIM_STRATEGY_FOR_PAID_MINTS == ClaimStrategy.ONLY_ONCE
            ) {
                TIMES_CLAIMED[token_id] = type(uint256).max;
            } else {
                TIMES_CLAIMED[token_id] = EXPLICITLY_SET_CLAIMS_FOR_PAID_MINTS;
            }
            ORIGINAL_CONTRACT.safeTransferFrom(
                address(this),
                msg.sender,
                token_id
            );
        }
    }

    function claim(uint256 token_id) public onlyIfMintable refuelIfNeeded(1) {
        require(claimable(token_id), "Token is not eligible for claims");
        require(
            _msgSender() == ORIGINAL_CONTRACT.ownerOf(token_id),
            "Caller is not the token owner"
        );

        ORIGINAL_CONTRACT.mint{value: ORIGINAL_PRICE}(1);
        uint256 newTokenID = ORIGINAL_CONTRACT.MINTED();

        TIMES_CLAIMED[token_id] += 1; // increment the claim count on the original token
        if (CLAIM_STRATEGY_FOR_FREE_MINTS == ClaimStrategy.MATCH_BOGO) {
            TIMES_CLAIMED[newTokenID] = BUY_ONE_GET_X;
        } else if (CLAIM_STRATEGY_FOR_FREE_MINTS == ClaimStrategy.ONLY_ONCE) {
            TIMES_CLAIMED[newTokenID] = type(uint256).max;
        } else {
            TIMES_CLAIMED[newTokenID] = EXPLICITLY_SET_CLAIMS_FOR_FREE_MINTS;
        }

        ORIGINAL_CONTRACT.safeTransferFrom(
            address(this),
            msg.sender,
            newTokenID
        );
    }

    function claimAll(uint256[] calldata claims)
        public
        onlyIfMintable
        refuelIfNeeded(claims.length)
    {
        for (uint256 i = 0; i < claims.length; i++) {
            claim(claims[i]);
        }
    }

    // public views
    // ---------------------------------------------------------
    function claimable(uint256 token_id) public view returns (bool) {
        // token must exist, not be a trophy, and must not have been claimed already
        return
            token_id <= ORIGINAL_CONTRACT.MINTED() &&
            token_id > ORIGINAL_CONTRACT.TROPHY_COUNT() &&
            TIMES_CLAIMED[token_id] < BUY_ONE_GET_X;
    }

    function claimsAvailable(address test)
        public
        view
        returns (uint256[BATCH_CLAIM_SIZE] memory)
    {
        uint256[BATCH_CLAIM_SIZE] memory result;
        uint256 next;
        for (uint256 i = 1; i <= ORIGINAL_CONTRACT.MINTED(); i++) {
            if (claimable(i) && test == ORIGINAL_CONTRACT.ownerOf(i)) {
                for (
                    uint256 j = 0;
                    j < (BUY_ONE_GET_X - TIMES_CLAIMED[i]);
                    j++
                ) {
                    // it's possible for a token to have multiple claims on it
                    // if so, we add the id multiple times
                    result[next++] = i;
                    if (next == BATCH_CLAIM_SIZE) {
                        return result;
                    }
                }
            }
        }
        return result;
    }

    // onlyOwner
    // ---------------------------------------------------------
    function setMintable(bool mintable) external onlyOwner {
        MINTABLE = mintable;
    }

    function setMintPrice(uint256 amtWei) external onlyOwner {
        // this amount is in wei, super important
        PRICE = amtWei;
    }

    function setRedemptionAmount(uint256 amt) external onlyOwner {
        // set to 0 to turn off freebies
        BUY_ONE_GET_X = amt;
    }

    function setTokenClaimCountManually(uint token_id, uint256 claims) external onlyOwner {
        TIMES_CLAIMED[token_id] = claims;
    }

    function setClaimStrategyAndLimits(
        ClaimStrategy free,
        uint256 freeExplicitlySet,
        ClaimStrategy paid,
        uint256 paidExplicitlySet
    ) external onlyOwner {
        CLAIM_STRATEGY_FOR_FREE_MINTS = free;
        EXPLICITLY_SET_CLAIMS_FOR_FREE_MINTS = freeExplicitlySet;

        CLAIM_STRATEGY_FOR_PAID_MINTS = paid;
        EXPLICITLY_SET_CLAIMS_FOR_PAID_MINTS = paidExplicitlySet;
    }

    function setTargetContract(address nkc) external onlyOwner {
        ORIGINAL_CONTRACT = NekoCore(nkc);
        ORIGINAL_PRICE = ORIGINAL_CONTRACT.PRICE_PER_TOKEN();
    }

    function airdrop(uint256 count, address to)
        external
        onlyOwner
        refuelIfNeeded(count)
    {
        uint256 token_id_start = ORIGINAL_CONTRACT.MINTED();
        ORIGINAL_CONTRACT.mint{value: ORIGINAL_PRICE * count}(count);
        for (uint256 i = 1; i <= count; i++) {
            uint256 token_id = token_id_start + i;
            if (CLAIM_STRATEGY_FOR_PAID_MINTS == ClaimStrategy.MATCH_BOGO) {
                TIMES_CLAIMED[token_id] = BUY_ONE_GET_X;
            } else if (
                CLAIM_STRATEGY_FOR_PAID_MINTS == ClaimStrategy.ONLY_ONCE
            ) {
                TIMES_CLAIMED[token_id] = type(uint256).max;
            } else {
                TIMES_CLAIMED[token_id] = EXPLICITLY_SET_CLAIMS_FOR_PAID_MINTS;
            }
            ORIGINAL_CONTRACT.safeTransferFrom(address(this), to, token_id);
        }
    }

    function reclaimOwnership() external onlyOwner {
        // to avoid out-of-fuel errors, we allow this contract to temporarily be
        // the owner of the target contract.
        //
        // This function allows the owner of THIS contract to reclaim
        // ownership of the ORIGINAL contract
        ORIGINAL_CONTRACT.transferOwnership(_msgSender());
    }

    function withdraw(uint256 amtWei) external onlyOwner {
        // special case for '0' withdraw, transfer full balance
        if (amtWei == 0) {
            amtWei = address(this).balance;
        }
        payable(_msgSender()).transfer(amtWei);
    }

    // internal
    // ---------------------------------------------------------
    function _refuel() internal {
        ORIGINAL_CONTRACT.withdraw();
    }

    // fallbacks (ability to fund this contract)
    // ---------------------------------------------------------
    receive() external payable {}
}
