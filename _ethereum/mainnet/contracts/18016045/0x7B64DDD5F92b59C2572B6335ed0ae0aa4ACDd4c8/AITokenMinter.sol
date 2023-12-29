// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./Pausable.sol";

import "./SignatureChecker.sol";

import "./IBurnable.sol";
import "./IGenesisToken.sol";
import "./IAIToken.sol";
import "./IERC721.sol";

/**
 * @dev Minter of AI Token
 *
 *   Huxley Token Id details:
 * - token id until 10110, Issue 1.
 * - token id from 10111 until 20220, Issue 2
 * - token id from 20221 until 30330, Issue 3
 * - token id from 30331 until 38775, Issue 4
 * - token id from 40441 until 49414, Issue 5+6 - If tokenId is even, it is Issue 6. If it is an odd tokenId, it is Issue 5
 *
 */
contract AITokenMinter is Pausable, Ownable {
    using SignatureChecker for address;

    /**
     * @dev Burn methods to mint AI Tokens
     * GTS: burns Genesis Tokens
     * MainBurn: Burns 2x tokens from Issue 4, 5 and 6
     * NormalBurn: Burns token from any issue (1, 2, 3, 4, 5 or 6) - 2 of any Comic
     */
    enum MintMethods {
        GTSBurn,
        MainBurn,
        NormalBurn
    }

    /// @notice Interface to burn GenesisToken
    IGenesisToken public immutable genesisToken;

    /// @notice Interface to burn HuxleyComics Issues 1, 2 or 3
    IERC721 public immutable huxleyComics;

    /// @notice Interface to burn HuxleyComics Issue 4
    IBurnable public immutable huxleyComics4;

    /// @notice Interface to burn HuxleyComics Issue 5/6
    IBurnable public immutable huxleyComics56;

    /// @notice Interface to mint AI Token
    IAIToken public aiToken;

    /// @notice Address of the wallet that signs the holder type
    address public signer;

    constructor(
        address _huxley123,
        address _huxley4,
        address _huxley56,
        address _genesis
    ) {
        huxleyComics = IERC721(_huxley123);
        huxleyComics4 = IBurnable(_huxley4);
        huxleyComics56 = IBurnable(_huxley56);

        genesisToken = IGenesisToken(_genesis);

        _pause();
    }

    /**
     * User burns 1 or more GTS token and gets a certain amount of AI
     * burnBatch() from GTS is called.
     * It reverts if wallet that is trying to burn is not the owner of the token
     * It reverts if array size are different
     * It reverts if array is empty
     * It reverts if amount is over token balance
     *
     * If _categories = [1,2] it will burn categories 1 and 2
     * If _amounts = [10,5] it will burn 10 tokens from category 1 and 5 tokens from category 2.
     *
     * @param _categories Genesis token categories. It is from 1 to 10.
     * @param _amounts Genesis token amount to burn. It can't be over the wallet token balance
     * @param _type It is type of holder. If it has a complete set that is redeemed or unredeemed, if it has Avatar/Robots token
     * @param _typeSignature Signature created by the signer confirming the wallet type
     */
    function burnGenesis(
        uint256[] calldata _categories,
        uint256[] calldata _amounts,
        uint256 _type,
        bytes calldata _typeSignature
    ) external whenNotPaused {
        uint256 size = _amounts.length;

        // burn batch checks if msg.sender is the token owners
        // if arrays are empty or mismatched, it reverts
        genesisToken.burnBatch(msg.sender, _categories, _amounts);

        uint256 totalBurned;

        for (uint256 i; i < size; ) {
            totalBurned += _amounts[i];
            unchecked {
                i++;
            }
        }

        _mintAI(MintMethods.GTSBurn, totalBurned, _type, _typeSignature);
    }

    /**
     * Wallet burns 2 Comics 4, 2 Comics 5 and 2 Comics 6 token and gets a certain amount of AI
     * _tokenIds array should follow the correct order: token id from 4, 5 and 6
     *
     * @param _tokenIds4 List of token ids from Issue 4. It cannot be empty.
     * @param _tokenIds5 List of token ids from Issue 5. It cannot be empty.
     * @param _tokenIds6 List of token ids from Issue 5. It cannot be empty.
     * @param _type It is type of holder. If it has a complete set that is redeemed or unredeemed, if it has Avatar/Robots token
     * @param _typeSignature Signature created by the signer confirming the wallet type
     */
    function mainBurn(
        uint256[] calldata _tokenIds4,
        uint256[] calldata _tokenIds5,
        uint256[] calldata _tokenIds6,
        uint256 _type,
        bytes calldata _typeSignature
    ) external whenNotPaused {
        uint256 size4 = _tokenIds4.length;
        uint256 size5 = _tokenIds5.length;
        uint256 size6 = _tokenIds6.length;

        //check if they have same size
        require(size4 == size5, "AI: Different size 4 and 5");
        require(size4 == size6, "AI: Different size 4 and 6");

        // It must have at least 2 tokens ids
        require(size4 >= 2, "AI: Array 4 has less than 2 tokens");

        // it must be an even size. At least 2 tokens to get AI. User can send 2, 4, 6, etc tokens
        require(isEven(size4), "AI: Size must be even"); // since 4, 5 and 6 has same size, we just need to check one array

        // If token id doesn't exist, it reverts
        // It also checks ownership
        _burn4(_tokenIds4);
        _burn5(_tokenIds5);
        _burn6(_tokenIds6);

        // each 2 tokens gives a certain amount of AI. Divide by 2 to have the amount wallet is going
        // to receive when minting using this method
        _mintAI(MintMethods.MainBurn, size4 / 2, _type, _typeSignature);
    }

    /**
     * I burns at least 2 tokens from any comic and then mint AI token
     * Issue 1, 2 and 3 needs an approvalForAkk() to be able to burn because AI Minter needs to transfer
     * it first to itself and then bur.
     * @param _tokenIds123 List of token ids from Issue 1, 2 and 3. It can be empty.
     * @param _tokenIds4 List of token ids from Issue 4. It can be empty.
     * @param _tokenIds56 List of token ids from Issue 5/6. It can be empty.
     * @param _type It is type of holder. If it has a complete set that is redeemed or unredeemed, if it has Avatar/Robots token
     * @param _typeSignature Signature created by the signer confirming the wallet type
     */
    function burnNormalComics123456(
        uint256[] calldata _tokenIds123,
        uint256[] calldata _tokenIds4,
        uint256[] calldata _tokenIds56,
        uint256 _type,
        bytes calldata _typeSignature
    ) external whenNotPaused {
        // burns tokens and return the amount of tokens burned
        // It should burn in pairs
        uint256 totalBurned = _executeBurnNormal(
            _tokenIds123,
            _tokenIds4,
            _tokenIds56
        );

        // mint AI token
        _mintAI(
            MintMethods.NormalBurn,
            (totalBurned) / 2, // for each 2 tokens burned, 1 AI
            _type,
            _typeSignature
        );
    }

    /**
     * Burns tokens
     * @param _tokenIds123 List of token ids from Issue 1, 2 and 3. It can be empty.
     * @param _tokenIds4 List of token ids from Issue 4. It can be empty.
     * @param _tokenIds56 List of token ids from Issue 5/6. It can be empty.
     */
    function _executeBurnNormal(
        uint256[] calldata _tokenIds123,
        uint256[] calldata _tokenIds4,
        uint256[] calldata _tokenIds56
    ) internal returns (uint256 totalBurned) {
        totalBurned =
            _tokenIds123.length +
            _tokenIds4.length +
            _tokenIds56.length;

        require(isEven(totalBurned), "AI: Should be in pairs");

        _burn123(_tokenIds123);
        _burn4(_tokenIds4);
        // it doesn't need to check if tokens are from 5 or 6. It could be all from 5 or 6 or both
        _burn56(_tokenIds56, false, false);
    }

    /**
     * Burns tokens from Issue 1, 2 or 3.
     * It first transfer the token to AITokenMinter and then burns. Owner should approval
     * the transfer before.
     * @param _tokenIds123 List of token ids from Issue 1, 2 and 3. It can be empty.
     */
    function _burn123(uint256[] calldata _tokenIds123) internal {
        uint256 size = _tokenIds123.length;

        for (uint256 i; i < size; ) {
            // 1) transfer token so it can be burned - setApprovalForAll was called before
            // Since it is using msg.sender, we don't need to check ownerOf
            huxleyComics.transferFrom(
                msg.sender,
                address(this),
                _tokenIds123[i]
            );

            huxleyComics.burn(_tokenIds123[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * Burn tokens from Issue 4
     * It reverts if msg.sender is not the token Owner
     * It won't call the burn function from Issue 4 it the token list is empty.
     * @param _tokenIds4 List of token ids from 4. It can be empty.
     */
    function _burn4(uint256[] calldata _tokenIds4) internal {
        uint256 size = _tokenIds4.length;

        for (uint256 i; i < size; ) {
            require(
                huxleyComics4.ownerOf(_tokenIds4[i]) == msg.sender,
                "AI: Not owner 4"
            );
            unchecked {
                i++;
            }
        }

        if (size > 0) {
            huxleyComics4.burnBatch(_tokenIds4);
        }
    }

    /**
     * Burn tokens from Issue 5.
     * @param _tokenIds5 List of token ids from Issue 5. It can be empty.
     */
    function _burn5(uint256[] calldata _tokenIds5) internal {
        // checkIssue and if it is Five
        _burn56(_tokenIds5, true, true);
    }

    /**
     * Burn tokens from Issue 6
     * @param _tokenIds6 List of token ids from Issue 6. It can be empty.
     */
    function _burn6(uint256[] calldata _tokenIds6) internal {
        // checkIssue and is not Five
        _burn56(_tokenIds6, true, false);
    }

    /**
     * Burn tokens from Issue 5/6.
     * It checks the token owner before burning it. It token ids list is empty, it doesn't
     * call the burn function from the Issue 5/6 contract and returns 0 tokens burned.
     * @param _tokenIds56 List of token ids from Issue 5 or Issue 6. It can be empty.
     * @param _isMainBurn If it is main burn, it is necessary to check if token is from Issue 5 or 6.
     * @param _isFive True if it is from Issue 5 (is odd)
     */
    function _burn56(
        uint256[] calldata _tokenIds56,
        bool _isMainBurn,
        bool _isFive
    ) internal {
        uint256 size = _tokenIds56.length;

        // Before burning Issues 56, it needs to check Ownership and if it is Issue 5 and 6 token ids range
        // If it is even, it is from Issue 6
        for (uint256 i; i < size; ) {
            require(
                huxleyComics56.ownerOf(_tokenIds56[i]) == msg.sender,
                "AI: Not owner 56"
            );

            if (_isMainBurn) {
                if (_isFive) {
                    require(!isEven(_tokenIds56[i]), "AI: Not Issue 5"); // odd tokenId is Issue 5
                } else {
                    require(isEven(_tokenIds56[i]), "AI: Not Issue 6"); // even tokenId is Issue 6
                }
            }

            unchecked {
                i++;
            }
        }

        if (size > 0) {
            huxleyComics56.burnBatch(_tokenIds56);
        }
    }

    /**
     * Before minting, it needs to get the Type
     * For GenesisToken, amount is the total GenesisToken burned * typeAmount
     * For MainBurn (2x Issue 4, 5 and6), is total burned / 2 (it is 2 tokens per Issue) * typeAmount
     * For NormalBurn (Burn of any Comic Issue), it is total burned / 2 (it is 2 tokens per Issue) * typeAmount
     *
     * @param _mintMethod Burn method. It can be GTSBurn, MainBurn or NormalBurn
     * @param _burnMethodQuantity Quantity of tokens for the burn method. I reverts if it is 0 (zero)
     * @param _type Wallet type to determine total amount of AI tokens to mint
     * @param _typeSignature Signature confirming the type
     */
    function _mintAI(
        MintMethods _mintMethod,
        uint256 _burnMethodQuantity,
        uint256 _type,
        bytes calldata _typeSignature
    ) internal {
        // is type correct signed?
        require(hasValidType(_type, _typeSignature));

        // Gets amount of AI tokens to be minted
        uint256 typeAmount = _getTypeAmount(_mintMethod, _type);

        // Mint AI ERC721A Tokens
        aiToken.mint(msg.sender, _burnMethodQuantity * typeAmount);
    }

    /**
     * Return amount of tokens to be minted depending of the type and Burn method.
     * @param _mintMethod It can be GTSBurn, MainBurn or NormalBurn
     * @param _type Type can be 1, 2 or 3
     */
    function _getTypeAmount(
        MintMethods _mintMethod,
        uint256 _type
    ) internal pure returns (uint256 typeAmount) {
        if (_mintMethod == MintMethods.GTSBurn) {
            if (_type == 3) {
                typeAmount = 11;
            } else if (_type == 2) {
                typeAmount = 9;
            } else {
                typeAmount = 5;
            }
        } else if (_mintMethod == MintMethods.MainBurn) {
            if (_type == 3) {
                typeAmount = 10;
            } else if (_type == 2) {
                typeAmount = 8;
            } else {
                typeAmount = 4;
            }
        } else {
            if (_type == 3) {
                typeAmount = 3;
            } else if (_type == 2) {
                typeAmount = 2;
            } else {
                typeAmount = 1;
            }
        }
    }

    /**
     * Verify type signature.
     * @param _type Type can be 1, 2 or 3
     * @param _typeSignature Signature to confirm wallet type
     */
    function hasValidType(
        uint256 _type,
        bytes calldata _typeSignature
    ) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(_type, msg.sender));

        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", result)
        );
        return signer.isValidSignatureNow(hash, _typeSignature);
    }

    /**
     * Set AI Token contract. OnlyOwner can call it
     * @param _addr  AI Token address
     */
    function setAIToken(address _addr) external onlyOwner {
        aiToken = IAIToken(_addr);
    }

    /**
     * @dev Updates address of 'signer'. OnlyOwner can call it
     * @param _signer  New address for 'signer'
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
