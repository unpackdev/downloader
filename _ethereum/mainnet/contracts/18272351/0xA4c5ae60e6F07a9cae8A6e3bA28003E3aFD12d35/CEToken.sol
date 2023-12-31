// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./BitMaps.sol";

import "./ERC721A.sol";

import "./IERC1155.sol";

/**
 * @dev Implementation of the ERC721A token
 */
contract CEToken is ERC721A, ERC2981, Ownable {
    using BitMaps for BitMaps.BitMap;

    /// @notice Sets when can redeem copy
    bool public canRedeem;

    /// @notice Wallet that will receive values from redeem() function
    address public trustedWallet;

    /// @dev Price for redeemptions. Set after deploy.
    uint256 public redeemPrice;

    /// @notice address that can mint tokens
    address public minter;

    /// @notice Uri of metadata. Set after deployment.
    string private uri;

    /// @notice Access Pass Token
    IERC1155 public accessPassToken;

    /**
     * @dev It uses a Bitmap to store 1) if a token has a FREE or PAID claim 2) if it was already redeemed or not.
     * It reuses OpenZeppelin implementation of a Bitmap. The first bit stores if it was claimed already or not. If first
     * bit is true, it was claimed, if it is false, it wasn't claimed. hasClaimed() function returns if a tokenId were claimed
     * or not.
     *
     * The second bit store if it is a Paid or Free claim. If it is true, it is a paid claim/redeem.
     * If it is false, it is a free claim/redeem. Functions isPaid() and isFree() returns the claim information of a tokenId.
     *
     */
    mapping(uint256 => BitMaps.BitMap) private redeemBitmapValues;

    /// @notice Event OpenSea uses to update a metadata from a token range.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /// @notice Event to store which collection were burned for a cetain token id.
    event CEMinted(
        address owner,
        uint256 tokenId_Issue1,
        uint256 tokenId_Issue2,
        uint256 tokenId_Issue3,
        uint256 tokenId_Issue4,
        uint256 tokenId_Issue5,
        uint256 tokenId_Issue6,
        uint256 tokenId
    );

    /// @notice Event to register token was redeemed
    event CERedeemed(address owner, uint256 tokenId);

    /**
     * Constructor. Sets royalty receiver and Access Pass token address
     * @param _royaltyReceiver Royalty receiver address
     * @param _accessPass ERC-1155 Access Pass token address
     */
    constructor(
        address _royaltyReceiver,
        address _accessPass
    ) ERC721A("Huxley C.E.", "C.E.") {
        _setDefaultRoyalty(_royaltyReceiver, 500);

        accessPassToken = IERC1155(_accessPass);
    }

    /**
     * @dev Mints <b>_amount</b> tokens. Sender must be the minter address.
     * @param _account Address that will receive the tokens
     * @param _amountToMint Amount of CE tokens that will be minted
     * @param _freeClaimAmount Amount of free Claim CE tokens. Paid Claim is equal to _amountToMint - _freeClaimAmount
     * @param _tokenIdsBurned Array of tokenIDs that were burned. It is used inside CEMinted event.
     */
    function mint(
        address _account,
        uint256 _amountToMint,
        uint256 _freeClaimAmount,
        uint256[][] calldata _tokenIdsBurned
    ) external {
        require(msg.sender == minter, "CE: Not minter");

        // If _freeClaimAmount is greater than _amountToMint, it reverts
        _mintToken(
            _account,
            _amountToMint,
            _freeClaimAmount,
            _amountToMint - _freeClaimAmount,
            _tokenIdsBurned
        );
    }

    /**
     * It sets the claim info (if it is free or paid claim), mints CE tokens, mints Access Pass tokens and emit
     * an event that has all tokenIds burned (a complete Huxley Saga comics collection) and the new CE tokenId
     * @param _account Account that will get the CE tokens and AccessPass tokens
     * @param _amountToMint Amountof CE tokens to be minted
     * @param _freeClaimAmount Amount of free claim tokens
     * @param _paidClaimAmount  Amount of paid claim tokens
     * @param _tokenIdsBurned Array with the tokens ids from Huxley Saga that were burned
     */
    function _mintToken(
        address _account,
        uint256 _amountToMint,
        uint256 _freeClaimAmount,
        uint256 _paidClaimAmount,
        uint256[][] calldata _tokenIdsBurned
    ) internal {
        // InitialToken Id is the 1st CE token Id that will be minted in this tx
        // Since it is known the amount of tokens that will be minted,
        // it is possible to know the tokenIds range. It is used to emit CEMinted event
        uint256 initialTokenId = _nextTokenId();

        // After setting claim info using a bitmap, it returns the last token id that
        // had a claim info set to compare after minting all CE tokens. Because
        // this number must be equal to the _nextTokenId() value
        uint256 lastTokenIdSet = setClaimInfo(
            _freeClaimAmount,
            _paidClaimAmount
        );

        // Mints CE tokens ERC721A
        _safeMint(_account, _amountToMint);

        // Minst AccessPass tokens ERC1155
        accessPassToken.privateMint(_account, _amountToMint);

        // Emit event of collections burned and tokenIds
        for (uint256 i = 0; i < _amountToMint; ) {
            emit CEMinted(
                _account,
                _tokenIdsBurned[i][0],
                _tokenIdsBurned[i][1],
                _tokenIdsBurned[i][2],
                _tokenIdsBurned[i][3],
                _tokenIdsBurned[i][4],
                _tokenIdsBurned[i][5],
                initialTokenId++
            );
            unchecked {
                ++i;
            }
        }

        // making sure all tokens were corrected set for Free or Paid Claim
        assert(lastTokenIdSet == _nextTokenId());
        assert(initialTokenId == _nextTokenId());
    }

    /**
     * Sets if it is paid or free claim. First it sets the Paid Claim tokens and then sets the Free Claim tokens.
     *
     * @notice Bitmap Index 0 is if it was claimed. Index 1 is if it is paid or free claim.
     *
     * @param _freeClaimAmount Amount of free claim tokens. It can be 0
     * @param _paidClaimAmount Amount of paid claim tokens It can be 0
     */
    function setClaimInfo(
        uint256 _freeClaimAmount,
        uint256 _paidClaimAmount
    ) internal returns (uint256 currentTokenId) {
        currentTokenId = _nextTokenId();

        // set Paid first
        for (uint256 i; i < _paidClaimAmount; ) {
            redeemBitmapValues[currentTokenId].setTo(1, true);
            unchecked {
                ++i;
                ++currentTokenId;
            }
        }

        unchecked {
            currentTokenId = currentTokenId + _freeClaimAmount;
        }
    }

    /**
     * @notice It isn't necessary to redeem paid and then free claims or vice versa. Wallet has to pay only for the amount
     * of paid claim tokens multiplied by the redeem price value.
     * @param _tokenIds Array with tokenIds. It can contaim paid or free tokens.
     */
    function redeem(uint256[] calldata _tokenIds) external payable {
        require(canRedeem, "CE: Cannot redeem.");

        uint256 tokenIdsLength = _tokenIds.length;
        uint256 amountToPay; // total amount of paid claim tokens
        for (uint256 i = 0; i < tokenIdsLength; ) {
            uint256 _tokenId = _tokenIds[i];
            require(hasClaimed(_tokenId) == false, "CE: Token claimed");

            // only token id owner can call redeem()
            require(ownerOf(_tokenId) == msg.sender, "CE: Not owner to redeem");

            // sets to true that it was claimed
            redeemBitmapValues[_tokenId].setTo(0, true);

            // if it is a paid claim token, increment by 1 amountToPay value
            if (this.isPaid(_tokenId)) {
                ++amountToPay;
            }

            emit CERedeemed(msg.sender, _tokenId);

            unchecked {
                ++i;
            }
        }

        uint256 totalPaid = redeemPrice * amountToPay;
        require(msg.value >= totalPaid, "CE: Low value");

        unchecked {
            (bool success, ) = trustedWallet.call{value: msg.value}("");
            require(success, "CE: Redeem failed");
        }
    }

    /**
     * Returns if _tokenId were already claimed or not
     * @dev Index 0 is if it was claimed.
     * @param _tokenId Token ID to check if it was claimed
     */
    function hasClaimed(uint256 _tokenId) public view returns (bool) {
        return redeemBitmapValues[_tokenId].get(0);
    }

    /**
     * Returns if it is a Paid Claim _tokenId
     * @dev Index 1 is if it is paid or free claim.
     * @param _tokenId token id to check if it is a paid claim
     */
    function isPaid(uint256 _tokenId) external view returns (bool) {
        return redeemBitmapValues[_tokenId].get(1);
    }

    /**
     * Returns if it is a Free Claim _tokenId.
     * @dev Index 1 is if it is paid or free claim.
     * @param _tokenId token id to check if it is a free claim
     */
    function isFree(uint256 _tokenId) public view returns (bool) {
        return !redeemBitmapValues[_tokenId].get(1);
    }

    /// @notice Set base uri. OnlyOwner can call it.
    function setBaseURI(string memory _value) external onlyOwner {
        uri = _value;
    }

    /// @notice Returns base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    /// @notice Set address of Minter
    function setMinter(address _addr) external onlyOwner {
        minter = _addr;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * Sets a new royalty value
     * @param receiver Address of new royalty receiver
     * @param numerator New royalty value
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 numerator
    ) external onlyOwner {
        ERC2981._setDefaultRoyalty(receiver, numerator);
    }

    /**
     * Emits and event to update metadata
     *
     * @param _fromTokenId initial token id to be updated
     * @param _toTokenId last token id to be updated
     */
    function updateMetadata(
        uint256 _fromTokenId,
        uint256 _toTokenId
    ) external onlyOwner {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

    /**
     * @dev Updates value of 'redeemPrice'. Only Owner can update it.
     * @param _price  New value of 'redeemPrice'
     */
    function setRedeemPrice(uint256 _price) external onlyOwner {
        redeemPrice = _price;
    }

    /**
     * @dev Updates value of 'canRedeem'. Only Owner can update it.
     * @param _value  New value of 'canRedeem'
     */
    function setCanRedeem(bool _value) external onlyOwner {
        canRedeem = _value;
    }

    /**
     * @dev Updates address of 'trustedWallet'. Only Owner can update it.
     * @param _trustedWallet  New address for 'trustedWallet
     */
    function setTrustedWallet(address _trustedWallet) external onlyOwner {
        trustedWallet = _trustedWallet;
    }

    /// @notice Override _startTokenId to start token id equal to 1. Default was 0.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev IP Licenses
    function IPLicensesIncluded() external pure returns (string memory) {
        return "Personal Use, Commercial Display, Merchandising";
    }
}
