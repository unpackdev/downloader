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

import "./Strings.sol";
import "./IERC721Metadata.sol";
import "./HootBase.sol";
import "./HootCrypto.sol";
import "./HootBaseERC721Owners.sol";

/**
 * @title HootBaseERC721URIStorage
 * @author HootLabs
 */
abstract contract HootBaseERC721URIStorage is
    HootBase,
    HootBaseERC721Owners,
    HootCrypto,
    IERC721,
    IERC721Metadata
{
    using Strings for uint256;

    event BaseURIChanged(string uri);
    event TokenHashSet(uint256 tokenId, bytes32 tokenHash);

    string private _preURI;
    // Optional mapping for token URIs
    mapping(uint256 => bytes32) private _tokenHashes;

    function _baseURI(
        uint256 /* tokenId_*/
    ) internal view virtual returns (string memory) {
        return _preURI;
    }

    /**
     * @notice set base URI
     * This process is under the supervision of the community.
     */
    function setBaseURI(string calldata uri_) external onlyOwner {
        _preURI = uri_;
        emit BaseURIChanged(uri_);
    }

    /**
     * @notice setTokenHash is used to set the ipfs hash of the token
     * This process is under the supervision of the community.
     */
    function setTokenHash(uint256 tokenId_, bytes32 tokenHash_)
        external
        atLeastManager
    {
        require(this.exists(tokenId_), "token is not exist");
        _tokenHashes[tokenId_] = tokenHash_;
        emit TokenHashSet(tokenId_, tokenHash_);
    }
    /**
     * @notice setTokenHashBatch is used to set the ipfs hash of the token
     * This process is under the supervision of the community.
     */
    function setTokenHashBatch(uint256[] calldata tokenIds_, bytes32[] calldata tokenHashes_)
        external
        atLeastManager
    {
        require(tokenIds_.length > 0, "no token id");
        require(tokenIds_.length == tokenHashes_.length, "token id array and token hash array have different lengths");
        unchecked {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                uint256 tokenId = tokenIds_[i];
                require(this.exists(tokenId), "token is not exist");
                _tokenHashes[tokenId] = tokenHashes_[i];
                emit TokenHashSet(tokenId, tokenHashes_[i]);
            }
        }
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(this.exists(tokenId_), "token is not exist");

        bytes32 tokenHash = _tokenHashes[tokenId_];
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (tokenHash == "") {
            string memory baseURI = _baseURI(tokenId_);
            return
                bytes(baseURI).length > 0
                    ? string(abi.encodePacked(baseURI, tokenId_.toString()))
                    : "";
        }
        return string(abi.encodePacked("ipfs://", cidv0(tokenHash)));
    }

    function unsafeTokenURIBatch(uint256[] calldata tokenIds_)
        public
        view
        virtual
        returns (string[] memory)
    {
        string[] memory uris = new string[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            if (!this.exists(tokenId)) {
                uris[i] = "";
                continue;
            }
            bytes32 tokenHash = _tokenHashes[tokenId];
            // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            if (tokenHash == "") {
                string memory baseURI = _baseURI(tokenId);
                uris[i] = bytes(baseURI).length > 0
                    ? string(abi.encodePacked(baseURI, tokenId.toString()))
                    : "";
                continue;
            }
            uris[i] = string(abi.encodePacked("ipfs://", cidv0(tokenHash)));
        }
        return uris;
    }
}
