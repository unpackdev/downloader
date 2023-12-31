// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./Pausable.sol";
import "./SignatureChecker.sol";

import "./IBurnable.sol";
import "./IERC721.sol";

/**
 * @dev Minter of CE Token
 *
 *   Huxley Token Id details:
 * - token id until 10110, Issue 1.
 * - token id from 10111 until 20220, Issue 2
 * - token id from 20221 until 30330, Issue 3
 * - token id from 30331 until 38775, Issue 4
 * - token id from 40441 until 49414, Issue 5+6 - If tokenId is even, it is Issue 6. If it is an odd tokenId, it is Issue 5
 *
 */
contract CETokenMinter is Pausable, Ownable {
    using SignatureChecker for address;

    /// @notice Interface to burn HuxleyComics Issues 1, 2 or 3
    IERC721 public immutable huxleyComics;

    /// @notice Interface to burn HuxleyComics Issue 4
    IBurnable public immutable huxleyComics4;

    /// @notice Interface to burn HuxleyComics Issue 5/6
    IBurnable public immutable huxleyComics56;

    /// @notice Interface to mint CE Token
    IERC721 public ceToken;

    /// @notice token id until 10110, Issue 1.
    uint256 immutable lastTokenIssue1 = 10110;

    /// @notice token id from 10111 until 20220, Issue 2
    uint256 immutable lastTokenIssue2 = 20220;

    /// @notice token id from 20221 until 30330, Issue 3
    uint256 immutable lastTokenIssue3 = 30330;

    /// @notice Address of the wallet that signs claim type (free or paid)
    address public signer;

    /**
     * Sets Huxley Comics addresses, CE address and pause the minting
     * @param _huxley123 Huxley Comics address for Issue 1, 2 and 3
     * @param _huxley4 Huxley Comics address for Issue 4
     * @param _huxley56 Huxley Comics address for Issue 5/6
     * @param _ceToken Huxley Collection Edittion address
     */
    constructor(
        address _huxley123,
        address _huxley4,
        address _huxley56,
        address _ceToken
    ) {
        huxleyComics = IERC721(_huxley123);
        huxleyComics4 = IBurnable(_huxley4);
        huxleyComics56 = IBurnable(_huxley56);

        ceToken = IERC721(_ceToken);

        _pause();
    }

    /**
     * Burn 1 or more complete collection. A wallet has a complete collection when it
     * has at least one token from each Issue (1 until 6).
     *
     * It will burn Huxley Comics token and mint 1 Collection Edition (CE) and 1 Access Pass (AP)
     *
     * It needs a signature that will confirm the amount of Free Claim CE. i.e.: Wallet is burning
     * 3 collections. And it will have 2 Free Claim and 1 Paid Claim CE. So, <b>_freeClaimAmount</b>
     * will be equal to 2. And the contract logic will set 2 CE tokens as Free claim and 1 CE Token as Paid Claim.
     *
     * _tokenIds123: If wallet is burning more than one collection, it should follow a specific order.
     * For example, if it is burning 2 collection, it should be:
     * [tokenId_Issue1b, tokenId_Issue2b, tokeId_Issue3b, tokenId_Issue1a, tokenId_Issue2a, tokeId_Issue3a ]
     * [tokenId_Issue4b, tokenId_Issue4a ]
     * [tokenId_Issue5a, tokenId_Issue6a, tokenId_Issue5b, tokenId_Issue6b]
     *
     * So it would burn 1st:
     * [tokenId_Issue1a, tokenId_Issue2a, tokeId_Issue3a, tokenId_Issue4a, tokenId_Issue5a, tokenId_Issue6a]
     *
     * 2nd burn:
     * [tokenId_Issue1b, tokenId_Issue2b, tokeId_Issue3b, tokenId_Issue4b, tokenId_Issue5b, tokenId_Issue6b]
     *
     * It uses tokenId numbers to know if it is from Issue1, Issue2 or Issue 3.
     *
     * It also checks Issue4, Issue 5 and Issue 6 ownership before burning.
     *
     * @param _tokenIds123 Token ids from Issue 1, 2 and 3. The order of the tokens matter
     * @param _tokenIds4 Token ids from Issue 4. The order of the tokens matter
     * @param _tokenIds56 Token ids from Issue 5/6. The order of the token ids matter.
     * @param _freeClaimAmount Amount of free claim
     * @param _signature Signature created by signer to confirm amount of free claim
     */
    function burnCollections(
        uint256[] calldata _tokenIds123,
        uint256[] calldata _tokenIds4,
        uint256[] calldata _tokenIds56,
        uint256 _freeClaimAmount,
        bytes calldata _signature
    ) external whenNotPaused {
        require(
            hasValidSignature(
                _signature,
                _freeClaimAmount,
                _tokenIds123,
                _tokenIds4,
                _tokenIds56
            ),
            "CE: Wrong signature"
        );

        // _tokenIds123.length wasn't added in a local variable because
        // it was getting stack too deep error
        // they all should have the same amount of a complete collection.
        require(
            _tokenIds123.length / 3 == _tokenIds4.length,
            "CEM: Wrong size 4"
        );
        require(
            _tokenIds56.length / 2 == _tokenIds4.length,
            "CEM: Wrong size 56"
        );

        // Loop does the actions below:
        // - Burns 123,
        // - checks Issue 4 ownership
        // - checks 5 and 6 ownership and if it is from 5 and 6
        // - save in memory token ids that will be used in a an event after minting CE token
        // - emits event of collection burned
        uint256 i; // it controls _tokenIds123 index
        uint256 j; // it controls _tokenIds4 index
        uint256 z; // it controls _tokenIds56 index (it is in pair)
        uint256[][] memory tokenIdsBurned = new uint256[][](_tokenIds4.length);

        while (i < _tokenIds123.length) {
            _burnTokens123(
                _tokenIds123[i],
                _tokenIds123[i + 1],
                _tokenIds123[i + 2]
            );

            _checkOwner4Token(_tokenIds4[j]);

            // check 56 ownership and if it is 5 and 6 (it checks if they are even/odd)
            _checkOwner56Tokens(_tokenIds56[z], _tokenIds56[z + 1]);

            uint256[] memory burnedIds = new uint256[](6);
            burnedIds[0] = _tokenIds123[i];
            burnedIds[1] = _tokenIds123[i + 1];
            burnedIds[2] = _tokenIds123[i + 2];
            burnedIds[3] = _tokenIds4[j];
            burnedIds[4] = _tokenIds56[z];
            burnedIds[5] = _tokenIds56[z + 1];

            // it uses j index because it is equal to the amount of CE that will be minted
            tokenIdsBurned[j] = burnedIds;

            unchecked {
                i = i + 3; // issue 123
                ++j; // issue 4
                z = z + 2; // issue 56
            }
        }

        // while loop has already checked tokenids ownership for Issue 4 and Issue 5 and 6
        _burn4(_tokenIds4);
        _burn56(_tokenIds56);

        // mint a certain amount of CE token and the same amount of AP
        _mintCE(_tokenIds4.length, _freeClaimAmount, tokenIdsBurned);
    }

    /**
     * Burns 1 collection set. It is in a different function to save gas since it doesn't loop.
     *
     * Check burnCollections() comments to see how to setup _tokenIds123, _tokenIds4 and _tokenIds56
     * arrays
     *
     * @param _tokenIds123 Token ids from Issue 1, 2 and 3. The order of the tokens matter
     * @param _tokenIds4 Token ids from Issue 4. The order of the tokens matter
     * @param _tokenIds56 Token ids from Issue 5/6. The order of the token ids matter.
     * @param _freeClaimAmount Amount of free claim
     * @param _signature Signature created by signer to confirm amount of free claim
     */
    function burn1Set(
        uint256[] calldata _tokenIds123,
        uint256[] calldata _tokenIds4,
        uint256[] calldata _tokenIds56,
        uint256 _freeClaimAmount,
        bytes calldata _signature
    ) external whenNotPaused {
        require(
            hasValidSignature(
                _signature,
                _freeClaimAmount,
                _tokenIds123,
                _tokenIds4,
                _tokenIds56
            ),
            "CE: Wrong signature"
        );

        // It isn't necessary to check size of _tokenIds1, _tokenIds2 and _tokenIds3
        // because it won't burn more than 1 token from each array.
        // It is different for _tokenIds4 and _tokenIds56 since it is sending the arrays to the burn function.
        require(_tokenIds4.length == 1, "CEM: Wrong size 4");
        require(_tokenIds56.length == 2, "CEM: Wrong size 56");
        require(_freeClaimAmount <= 1, "CEM: Claim Not 0 or 1");

        // transfer tokens to Minter contract and burn them
        _burnTokens123(_tokenIds123[0], _tokenIds123[1], _tokenIds123[2]);

        // check ownership and burn it
        _checkOwner4Token(_tokenIds4[0]);
        _burn4(_tokenIds4);

        _checkOwner56Tokens(_tokenIds56[0], _tokenIds56[1]);
        _burn56(_tokenIds56);

        // since it is just one collection, create the array with size 1
        uint256[][] memory tokenIdsBurned = new uint256[][](1);
        uint256[] memory burnedIds = new uint256[](6);
        burnedIds[0] = _tokenIds123[0];
        burnedIds[1] = _tokenIds123[1];
        burnedIds[2] = _tokenIds123[2];
        burnedIds[3] = _tokenIds4[0];
        burnedIds[4] = _tokenIds56[0];
        burnedIds[5] = _tokenIds56[1];

        tokenIdsBurned[0] = burnedIds;

        // mint 1 CE token. CE Token contract mints also 1 AP token
        _mintCE(1, _freeClaimAmount, tokenIdsBurned);
    }

    /**
     * Burn Tokens from Issue 1, 2 and 3. First it transfer to Minter contract and then burn it.
     * If wallet is not the owner, it will fail and revert.
     * It checks tokenId range to make sure it is from the correct Issue (1, 2 or 3)
     * @param _tokenId1 TokenId from Issue 1
     * @param _tokenId2 TokenId from Issue 2
     * @param _tokenId3 TokenId from Issue 3
     */
    function _burnTokens123(
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint256 _tokenId3
    ) internal {
        require(_tokenId1 <= lastTokenIssue1, "CE: Not Issue 1");

        require(_tokenId2 > lastTokenIssue1, "CE: Not Issue 2");
        require(_tokenId2 <= lastTokenIssue2, "CE: Not Issue 2");

        require(_tokenId3 > lastTokenIssue2, "CE: Not Issue 3");
        require(_tokenId3 <= lastTokenIssue3, "CE: Not Issue 3");

        // 1) transfer token so it can be burned - setApprovalForAll was called before
        // Since it is using msg.sender, we don't need to check ownerOf
        huxleyComics.transferFrom(msg.sender, address(this), _tokenId1);
        huxleyComics.transferFrom(msg.sender, address(this), _tokenId2);
        huxleyComics.transferFrom(msg.sender, address(this), _tokenId3);

        huxleyComics.burn(_tokenId1);
        huxleyComics.burn(_tokenId2);
        huxleyComics.burn(_tokenId3);
    }

    /**
     * Check Issue 4 ownership
     * @param _tokenId4 Token id from Issue 4.
     */
    function _checkOwner4Token(uint256 _tokenId4) internal view {
        require(
            huxleyComics4.ownerOf(_tokenId4) == msg.sender,
            "CE: Not owner 4"
        );
    }

    /**
     * Before burning Issues 56, it needs to check Ownership. It also checks if is from Issue 5 or from Issue 6
     * by verifying if it is even (6) or odd (5)
     * @param _tokenId5 Token Id from Issue 5
     * @param _tokenId6 Token Id from Issue 6
     */
    function _checkOwner56Tokens(
        uint256 _tokenId5,
        uint256 _tokenId6
    ) internal view {
        require(
            huxleyComics56.ownerOf(_tokenId5) == msg.sender,
            "CE: Not owner 56"
        );

        require(
            huxleyComics56.ownerOf(_tokenId6) == msg.sender,
            "CE: Not owner 56"
        );

        require(!isEven(_tokenId5), "CE: Not Issue 5"); // odd tokenId is Issue 5
        require(isEven(_tokenId6), "CE: Not Issue 6"); //  even tokenId is Issue 6
    }

    /**
     * It isn't necessary to check if it is token id from Issue 4 because if it doesn't exist,
     * it fails.
     * @param _tokenIds4 Token id list from Issue 4.
     */
    function _burn4(uint256[] calldata _tokenIds4) internal {
        huxleyComics4.burnBatch(_tokenIds4);
    }

    /**
     * It isn't necessary to check if it is from Issue 5 or 6 because if it isn't
     * it fails when trying to burn or checking ownership. But it is necessary
     * to check if one is Issue 5 and another one is from Issue 6.
     * @param _tokenId56 Token if from Issue 5 and 6.
     */
    function _burn56(uint256[] calldata _tokenId56) internal {
        huxleyComics56.burnBatch(_tokenId56);
    }

    /**
     * Calls CE contract and mint CE Token
     * @param _amountToMint Amount of CE Tokens that will be minted
     * @param _freeClaimAmount Amount of tokens that are free claim
     * @param _tokenIdsBurned Array that has token ids burned. It will be used in an event.
     */
    function _mintCE(
        uint256 _amountToMint,
        uint256 _freeClaimAmount,
        uint256[][] memory _tokenIdsBurned
    ) internal {
        ceToken.mint(
            msg.sender,
            _amountToMint,
            _freeClaimAmount,
            _tokenIdsBurned
        );
    }

    /**
     * If the same tokenId is used to burn another set, it will fail because it was already burned and signature won't
     * be able to be reused.
     *
     * Signature is the hash of tokensIds from Issue 1, 2, 3, 4, 5 and 6 + the freeClaimAmount value + the address of the token
     * ids owner.
     *
     * @param _signature Signature to be verified
     * @param _freeClaimAmount Amount of free claims
     * @param _tokenIds123 List of token ids from Issue 1, 2 and 3
     * @param _tokenIds4 List of token ids from Issue 4
     * @param _tokenIds56 List of token ids from Issue 5 and 6
     */
    function hasValidSignature(
        bytes calldata _signature,
        uint256 _freeClaimAmount,
        uint256[] calldata _tokenIds123,
        uint256[] calldata _tokenIds4,
        uint256[] calldata _tokenIds56
    ) internal view returns (bool) {
        bytes32 result = keccak256(
            abi.encodePacked(
                _tokenIds123,
                _tokenIds4,
                _tokenIds56,
                _freeClaimAmount,
                msg.sender
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", result)
        );
        return signer.isValidSignatureNow(hash, _signature);
    }

    /**
     * Set CE Token contract. OnlyOwner can call it
     * @param _addr CE ERC721A Token address
     */
    function setCEToken(address _addr) external onlyOwner {
        ceToken = IERC721(_addr);
    }

    /**
     * Set Signer
     * @param _signer Signer address
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @dev check if a number is even - it is used to check if token id is from Issue 5 or Issue 6
    function isEven(uint256 _num) internal pure returns (bool) {
        return _num % 2 == 0;
    }

    /// @dev Pause burn functions
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause burn functions
    function unpause() external onlyOwner {
        _unpause();
    }
}
