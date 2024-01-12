// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :5@@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          P@@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? P@@@@@@    .
.   @@@@@G          5@@@@@:     :B@@@@@BJG@@@@@@@@@&B5?~:^7YG#@@@@@@@@BJP@@@ @@&!!     #@@@@@@@@@@@@@? P@@@@@@    .
.   @@@@@G          5@@@@@:    .B@@@@#!!J@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^G@@@@@~.   ^~~~~~^J@ @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. 5@@@@@:   J@@@@&^   G@7?@@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   .B@@@@P           !@@@@@?            .
.   @@@@@@@@@@@@@@! 5@@@@@:   5@@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     Y@@@@#.           !@@@@@?            .
.   @@@@@@@@@@@@@@! P@@@@@:   ?@@@@&^    !YPGPY!  !@@@@@Y&@@@@Y  ~YPGP57.    .B@@@@P           !@@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   .B@@@@&7           ?&@@@@P ?@@@@@5.          ~B@@@@&^            !@@@@@?            .
.   @@@@@G          ^~~~~~.    :G@@@@@BY7~^^~75#@@@@@5.    J@@@@@&P?~^^^!JG@@@@@#~             !@@@@@?            .
.   @@@@@G          5@@@@@:      ?B@@@@@@@@@@@@@@@@B!!      ^P@@@@@@@@@@@@@@@@&Y               !@@@@@?            .
.   @@@@@G.         P@@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                !@@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      ?@@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          ~@@@@@~    :&@@@@7           ~@@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@G?JJJJJJJJ?5@@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   G@@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ !@@@@@~    :&@@@@7            ~@@@&.                         !@@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          !@@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          !@@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          !@@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "./HootERC721.sol";
import "./HootProvenance.sol";
import "./HootBaseERC721Raising.sol";
import "./HootBaseERC721Refund.sol";
import "./HootBaseERC721URIStorageWithLevel.sol";
import "./HootRandTokenID.sol";

abstract contract YINGBlind {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function isFreeMintYINGToken(uint256 tokenId)
        public
        view
        virtual
        returns (bool);
}

/**
 * @title HootAirdropBox
 * @author HootLabs
 */
contract YING is
    HootRandTokenID,
    HootBaseERC721Provenance,
    HootBaseERC721Raising,
    HootBaseERC721Refund,
    HootBaseERC721URIStorageWithLevel,
    HootERC721
{
    event YINGConfigChanged(YINGConfig cfg);
    event YINGBlindContractChanged(address blindAddress);
    event YINGRevealed(
        uint256 indexed blindTokenId,
        uint256 indexed yingTokenId
    );
    /**
     * used to mark the contract, each contract have to make a different CONTRACT_SHIELD
     */
    uint256 public constant CONTRACT_SHIELD = 1942123432145421;

    struct YINGConfig {
        uint256 maxSupply;
        bool rejectFreeMintRefund;
    }

    YINGConfig public yingCfg;

    address _yingBlindAddress;

    constructor(YINGConfig memory yingCfg_)
        HootERC721("YING", "YING")
    {
        yingCfg = yingCfg_;
    }

    /***********************************|
    |               Config              |
    |__________________________________*/
    function setYINGConfig(YINGConfig calldata cfg_) external onlyOwner {
        yingCfg = cfg_;
        emit YINGConfigChanged(cfg_);
    }

    // Set authorized contract address for minting the ERC-721 token
    function setYINGBlindContract(address contractAddress_) external onlyOwner {
        _yingBlindAddress = contractAddress_;
        emit YINGBlindContractChanged(contractAddress_);
    }

    /***********************************|
    |               Core                |
    |__________________________________*/
    function mintTransfer(address address_, uint256 blindTokenId_)
        public
        virtual
        returns (uint256)
    {
        require(_msgSender() == _yingBlindAddress, "not authorized");
        unchecked {
            require(
                totalMinted() + 1 <= yingCfg.maxSupply,
                "mint would exceed max supply"
            );
        }
        uint256 tokenId = _genTokenId();
        _safeMint(address_, tokenId);
        emit YINGRevealed(blindTokenId_, tokenId);
        return tokenId;
    }

    function mintTransferBatch(
        address address_,
        uint256[] calldata blindTokenIds_
    ) public virtual returns (uint256[] memory) {
        require(_msgSender() == _yingBlindAddress, "not authorized");
        require(
            blindTokenIds_.length <= yingCfg.maxSupply,
            "mint would exceed max supply"
        );
        unchecked {
            require(
                totalMinted() + blindTokenIds_.length <= yingCfg.maxSupply,
                "mint would exceed max supply"
            );

            uint256[] memory tokenIds = new uint256[](blindTokenIds_.length);
            for (uint256 i = 0; i < blindTokenIds_.length; i++) {
                uint256 tokenId = _genTokenId();
                _safeMint(address_, tokenId);
                tokenIds[i] = tokenId;

                emit YINGRevealed(blindTokenIds_[i], tokenId);
            }
            return tokenIds;
        }
    }

    /***********************************|
    |      HootBaseERC721Owners         |
    |__________________________________*/
    function exists(uint256 tokenId_)
        public
        view
        virtual
        override(HootBaseERC721Owners, HootERC721)
        returns (bool)
    {
        return HootERC721.exists(tokenId_);
    }

    /***********************************|
    |         HootRandTokenID           |
    |__________________________________*/
    function _remainSupply() internal view virtual override returns (uint256) {
        return yingCfg.maxSupply - totalMinted();
    }

    /***********************************|
    |        HootBaseERC721Refund       |
    |__________________________________*/
    function _refundPrice(uint256 tokenId_)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (yingCfg.rejectFreeMintRefund) {
            YINGBlind yingBlind = YINGBlind(_yingBlindAddress);
            if (yingBlind.isFreeMintYINGToken(tokenId_)) {
                return 0;
            }
        }
        return super._refundPrice(tokenId_);
    }

    /***********************************|
    | HootBaseERC721URIStorageWithLevel |
    |__________________________________*/
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override(ERC721, HootBaseERC721URIStorage)
        returns (string memory)
    {
        return HootBaseERC721URIStorage.tokenURI(tokenId_);
    }

    /***********************************|
    |          HootERC721               |
    |__________________________________*/
    function tokenByIndex(uint256 index)
        external
        view
        virtual
        override
        returns (uint256)
    {
        require(index < totalMinted(), "out of range");
        return _unsafeGetTokenIdByIndex(index);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        override
        returns (uint256)
    {
        require(balanceOf(owner) > index, "there are not enough tokens");
        uint256 totalMinted = totalMinted();
        uint256 scanIndex = 0;
        uint256 tokenId = 0;
        for (uint256 i = 0; i < totalMinted; i++) {
            tokenId = _unsafeGetTokenIdByIndex(i);
            require(tokenId >= _startTokenId(), "token not minted");
            if (_unsafeOwnerOf(tokenId) != owner) {
                continue;
            }
            if (scanIndex == index) {
                return tokenId;
            }
            ++scanIndex;
        }
        revert("not found token");
    }

    function tokensOfOwner(address owner_)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner_);
        if (balance == 0) {
            return new uint256[](0);
        }
        uint256[] memory tokens = new uint256[](balance);
        uint256 totalMinted = totalMinted();
        uint256 scanIndex = 0;
        uint256 tokenId = 0;
        for (uint256 i = 0; i < totalMinted; i++) {
            tokenId = _unsafeGetTokenIdByIndex(i);
            require(tokenId >= _startTokenId(), "token not minted");
            if (_unsafeOwnerOf(tokenId) != owner_) {
                continue;
            }
            tokens[scanIndex] = tokenId;
            ++scanIndex;
            if(scanIndex == balance){
                break;
            }
        }
        require(scanIndex == balance, "not enough tokens were found");
        return tokens;
    }

    /***********************************|
    |               ERC721A             |
    |__________________________________*/
    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(HootBaseERC721Raising, HootERC721) {
        HootBaseERC721Raising._beforeTokenTransfer(from, to, tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
