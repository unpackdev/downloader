// SPDX-License-Identifier: MIT
// Derived from OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

/// @title Creat00r Blacklist NftPaymentSplitter
/// @author Bitstrays Team

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                 ,▄▄                                              //
//                                 ▓███▄▄▓██▄                                       //
//                            ,╔▄██████▌     ║████Γ                                 //
//                         ╔██▀   █████▌     ║████      ╟██▄                        //
//                      ╓█▀╙     ]██████     ║███▌      ╟█████▓,                    //
//                   ,▄█▀        ║██████⌐    ║███▌      ▐████████▄                  //
//                  ▄█╙          ╟██████▒    ║███▌       ██████████▄                //
//                ╓█▀            ║██████▌    ║███▒       ████████████▄              //
//               ▐█              ╫██████▌    ║███▒       ██████████████             //
//              ▄█               ╟██████▌    ║███▒       ███████████████            //
//             ╔█                ╟██████▌    ║███▌       ████████████████           //
//            ,█⌐                ║██████⌐    ║███▌      ▐████████████████▌          //
//            ║▌                 ╙██████     ║███▌      ║█████████████████          //
//            █▌                  █████▌     ║████      ╟█████████████████▌         //
//           ]█     ]▄            ╟████▌     ║████▒    ]████████████╙╟████▌         //
//           ▐█     ▐█             ████      ║█████    ╟███████████▌ ▐████▌         //
//            ▓▒     █▒            └▀▀       ║██████,,▓████████████▌ ╟████▌         //
//            ╟▌     ║█                      ║█████████████████████ ]█████⌐         //
//            ╙█      ╟█                     ║████████████████████╜ ╣████▌          //
//             ╟▌      ╫▌                    ║███████████████████⌐ ▓█████           //
//              ╫▌      ╚█µ                  ║█████████████████▀ ,▓█████`           //
//               ╟█      └▀█                 ║████████████████` ▄██████             //
//                ╚█µ      `▀█▄              ║█████████████▀ ,▄██████▀              //
//                 `██        ╙▀█▄,          ║█████████▀╙ ,▄████████╙               //
//                   ╙█▄         `╙▀██▄▄╦╓╓,╓╚▀▀▀▀▀╙  ,╗▄█████████╙                 //
//                     "▀█╦              ╙╙╙╙╔▄▄▄▓█████████████▀                    //
//                        ╙▀█▄,              ║█████████████▀▀                       //
//                           `╙▀█▄╦╓         ║████████▀▀╙                           //
//                                 ╙▀▀▀█████▓                                       //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./ERC165Checker.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 * @title NftPaymentSplitter
 * @dev This contract allows to split Ether payments among a group of NFT holders. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 * This contract is derived from the openzeppelin payment splitter and modified for NFT payment splitting.
 *
 * The split will be equal parts. The way this is specified is by assigning each
 * NFT to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 * There are only two types of shares the owner shares and the NFT holder share.
 */
contract NftPaymentSplitter is Context, Ownable {
    using ERC165Checker for address;

    event PayeeAdded(uint256 tokenId, uint256 shares);
    event PaymentReleased(uint256 tokenId, address to, uint256 amount);
    event ERC20PaymentReleased(
        uint256 tokenId,
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event UnclaimedPaymentReleased(uint256 tokenId, address to, uint256 amount);
    event UnclaimedERC20PaymentReleased(
        uint256 tokenId,
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    uint256 private _maxSupply;
    uint256 private _sharesPerToken;
    uint256 private _totalSharesOffset; //offset for unitialized tokenids
    address public creat00rWallet;
    address public dev1Wallet;
    address public dev2Wallet;

    uint32 private constant _creat00rId = 0;
    uint32 private constant _dev1Id = 334;
    uint32 private constant _dev2Id = 335;


    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    IERC721 public immutable nftCollection;

    mapping(uint256 => uint256) private _shares;
    mapping(uint256 => uint256) private _released;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(uint256 => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `NftPaymentSplitter` where each tokenId in `nftCollection_`  is assigned
     * the same shared defined in `sharesPerToken_`. The `creat00rShare_` and `creat00rAddress_` are
     * used for the collection owner to define a bigger share propotion. 
     *
     * Note
     * creat00rShare_ is using the tokenId 0 which may not work for collections where the tokenId 0 exists
     * this can be easy modified if required
     */
    constructor(
        uint256 maxSupply_,
        uint256 sharesPerToken_,
        uint256[] memory creat00rsShare_,
        address[] memory creat00rWallets_,
        address nftCollection_
    ) payable {
        require(
            nftCollection_ != address(0),
            "ERC721 collection address can't be zero address"
        );
        require(
            nftCollection_.supportsInterface(IID_IERC721),
            "collection address does not support ERC721"
        );
        require(maxSupply_ > 0, "PaymentSplitter: no payees");

        _maxSupply = maxSupply_;
        _sharesPerToken = sharesPerToken_;

        _totalSharesOffset = maxSupply_ * sharesPerToken_;
        nftCollection = IERC721(nftCollection_);

        _setupCreat00rShares(creat00rsShare_, creat00rWallets_);

    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _calculateTotalShares();
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev calculate the total shares using offset (maxSupply_ * sharesPerToken_)
     * offset will be reduce until 0 once everyone claimed once
     *
     */
    function _calculateTotalShares() internal view returns (uint256) {
        return _totalShares + _totalSharesOffset;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an NFT tokenId.
     */
    function shares(uint256 tokenId) public view returns (uint256) {
        uint256 tokenShares = _shares[tokenId];
        // if shares are unitialized but within range return default allocation
        if (tokenShares == 0 && tokenId <= _maxSupply) {
            tokenShares = _sharesPerToken;
        }
        return tokenShares;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee (NFT tokenId).
     */
    function released(uint256 tokenId) public view returns (uint256) {
        return _released[tokenId];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee (NFT tokenId). `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][tokenId];
    }

    /**
     * @dev Triggers a transfer to `tokenId` holder of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * Initializes payee (NFT tokenId) during first release
     */
    function release(uint256 tokenId) public virtual {
        require(
            tokenId <= _maxSupply || _isCreat00r(tokenId),
            "PaymentSplitter: tokenId is outside range"
        );
        if (_shares[tokenId] == 0) {
            _addPayee(tokenId, _sharesPerToken);
        }
        require(_shares[tokenId] > 0, "PaymentSplitter: tokenId has no shares");

        address payable account;
        if (_isCreat00r(tokenId)) {
            account = payable(_getCreat00r(tokenId));
        } else {
            account = payable(nftCollection.ownerOf(tokenId));
        }

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            tokenId,
            totalReceived,
            released(tokenId)
        );

        require(payment != 0, "PaymentSplitter: tokenId is not due payment");

        _released[tokenId] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(tokenId, account, payment);
    }

    /**
     * @dev Triggers a transfer to `tokenId` holder of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     * Initializes payee (NFT tokenId) during first release.
     */
    function release(IERC20 token, uint256 tokenId) public virtual {
        require(
            tokenId <= _maxSupply || _isCreat00r(tokenId),
            "PaymentSplitter: tokenId is outside range"
        );
        if (_shares[tokenId] == 0) {
            _addPayee(tokenId, _sharesPerToken);
        }
        require(_shares[tokenId] > 0, "PaymentSplitter: tokenId has no shares");

        address account;
        if (_isCreat00r(tokenId)) {
            account = _getCreat00r(tokenId);
        } else {
            account = nftCollection.ownerOf(tokenId);
        }

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            tokenId,
            totalReceived,
            released(token, tokenId)
        );

        require(payment != 0, "PaymentSplitter: tokenId is not due payment");

        _erc20Released[token][tokenId] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(tokenId, token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        uint256 tokenId,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[tokenId]) /
            _calculateTotalShares() -
            alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * reduce _totalSharesOffset for each tokenId until 0.
     * Only called once per tokenId/owner
     * @param tokenId nft tokenId
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(uint256 tokenId, uint256 shares_) private {
        require(
            tokenId <= _maxSupply || _isCreat00r(tokenId),
            "PaymentSplitter: tokenId must be < _maxSupply"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[tokenId] == 0,
            "PaymentSplitter: tokenId already has shares"
        );

        _shares[tokenId] = shares_;
        _totalShares = _totalShares + shares_;
        if (!_isCreat00r(tokenId) && _totalSharesOffset - shares_ >= 0) {
            _totalSharesOffset = _totalSharesOffset - shares_;
        }
        emit PayeeAdded(tokenId, shares_);
    }

    function _isCreat00r(uint256 tokenId) internal pure returns (bool){
        return (tokenId == _creat00rId || tokenId == _dev1Id || tokenId == _dev2Id);
    }


    function _getCreat00r(uint256 tokenId) internal view returns (address){
        if(tokenId == _creat00rId) {
            return creat00rWallet; 
        }
        if(tokenId == _dev1Id) {
            return dev1Wallet; 
        }
        if(tokenId == _dev2Id) {
            return dev2Wallet; 
        }
        revert("Invalid creat00r tokenId");
    }

    function _setupCreat00rShares(uint256[] memory creat00rsShare_, address[] memory creat00rWallets_) internal {
        require(creat00rsShare_.length == creat00rWallets_.length);
        require(creat00rWallets_.length == 3);
 
        require(creat00rsShare_[0]>creat00rsShare_[1] && creat00rsShare_[0]>creat00rsShare_[2]);

        creat00rWallet = creat00rWallets_[0];
        _addPayee(_creat00rId, creat00rsShare_[0]);
        dev1Wallet = creat00rWallets_[1];
        _addPayee(_dev1Id, creat00rsShare_[1]);
        dev2Wallet = creat00rWallets_[2];
        _addPayee(_dev2Id, creat00rsShare_[2]);
    }

    /**
     * @notice
     *  function to update _creat00rAddress
     *  opensea ever shuts down or is compromised
     * @dev Only callable by the owner.
     * @param creat00rWallet_ nft tokenId
     */
    function setCreat00rAddress(address creat00rWallet_) external onlyOwner {
        require(creat00rWallet_ != address(0), "Zero Address not allowed");
        creat00rWallet = creat00rWallet_;
    }

    /**
     * @dev Triggers a transfer for `tokenIds` of the amount of Ether they are owed to creat00r, according to their percentage of the
     * total shares and their previous withdrawals.
     * Only allow payout if list of tokenIds does not exists (NFT's have not been minted)
     * (valid tokenIds's range 1-100)
     */
    function releaseUnlcaimed(uint256[] memory tokenIds) external onlyOwner {
        (bool success, bytes memory result) = address(nftCollection).call(abi.encodeWithSignature("claimExpiration()", msg.sender));
        uint claimExpiration = abi.decode(result, (uint));
        require(success && claimExpiration < block.timestamp, "nftCollection claim window still active");
        uint256 totalPayment = 0;
        bool isValidUnclaimedList = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId <= 100, "Invalid claim id range[1,100]");
            try nftCollection.ownerOf(tokenId) {
                isValidUnclaimedList = false;
            } catch Error(
                string memory /*reason*/
            ) {
                if (_shares[tokenId] == 0) {
                    _addPayee(tokenId, _sharesPerToken);
                }
                require(_shares[tokenId] > 0, "PaymentSplitter: tokenId has no shares");
                uint256 totalReceived = address(this).balance + totalReleased() - totalPayment;
                uint256 payment = _pendingPayment(
                    tokenId,
                    totalReceived,
                    released(tokenId)
                );

                _released[tokenId] += payment;
                _totalReleased += payment;
                totalPayment += payment;
                emit UnclaimedPaymentReleased(
                    tokenId,
                    creat00rWallet,
                    payment
                );
            }
        }
        require(
            totalPayment != 0,
            "PaymentSplitter: tokenId is not due payment"
        );
        require(isValidUnclaimedList, "Invalid list of unclaimed token");
        Address.sendValue(payable(creat00rWallet), totalPayment);
    }


    /**
     * @dev Triggers a transfer for `tokenIds` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     * Only allow payout if list of tokenIds does not exists (NFT's have not been minted).
     * (valid tokenIds's range 1-100)
     */
    function releaseUnlcaimed(IERC20 token, uint256[] memory tokenIds)
        external
        onlyOwner
    {   
        (bool success, bytes memory result) = address(nftCollection).call(abi.encodeWithSignature("claimExpiration()", msg.sender));
        uint claimExpiration = abi.decode(result, (uint));
        require(success && claimExpiration < block.timestamp, "nftCollection claim window still active");
        uint256 totalPayment = 0;
        bool isValidUnclaimedList = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId <= 100, "Invalid claim id range[1,100]");
            try nftCollection.ownerOf(tokenId) {
                isValidUnclaimedList = false;
            } catch Error(
                string memory /*reason*/
            ) {
                if (_shares[tokenId] == 0) {
                    _addPayee(tokenId, _sharesPerToken);
                }
                uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token) - totalPayment;
                uint256 payment = _pendingPayment(
                    tokenId,
                    totalReceived,
                    released(token, tokenId)
                );

                //skip update storage since we have nothing to pay
                _erc20Released[token][tokenId] += payment;
                _erc20TotalReleased[token] += payment;
                totalPayment += payment;
                emit UnclaimedERC20PaymentReleased(
                    tokenId,
                    token,
                    creat00rWallet,
                    payment
                );
            }
        }
        require(
            totalPayment != 0,
            "PaymentSplitter: account is not due payment"
        );
        require(isValidUnclaimedList, "List contains existing tokenIds");
        SafeERC20.safeTransfer(token, creat00rWallet, totalPayment);
    }
}
