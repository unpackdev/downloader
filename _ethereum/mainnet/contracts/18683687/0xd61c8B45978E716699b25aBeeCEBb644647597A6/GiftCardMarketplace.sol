// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: giftcard.sol


pragma solidity ^0.8.0;

interface IABUser {
    function isCreator(address) external view returns (bool);
}

contract GiftCardMarketplace is ConfirmedOwner {
    address public tokenAddress;
    uint256 public giftCardId;
    address public autobetUseraddress;

    mapping(uint256 => string) private giftCardVoucherCodes;
    mapping (uint256 => GiftCard) public giftCards;

    constructor(address _tokenAddress, address _autobetUseraddress)
        ConfirmedOwner(msg.sender)
    {
        tokenAddress = _tokenAddress;
        autobetUseraddress = _autobetUseraddress;
    }

    enum giftCardStatus {
        open,
        bought,
        paid
    }

    struct GiftCard {
        uint256 giftCardId;
        address creator;
        uint256 BETValue;
        uint256 ETHPrice;
        string logoHash;
        string Desc;
        uint256 expDate;
        giftCardStatus status;
        bool isSold;
        address buyer;
        bool isDonation;
        string voucherCode;
    }

    event GiftCardCreated(
        uint256 indexed giftCardId,
        address indexed creator,
        uint256 BETValue,
        uint256 ETHPrice,
        string logoHash,
        string Desc,
        uint256 expDate
    );

    event GiftCardPurchased(
        address giftCardCreator,
        uint256 indexed giftCardId,
        address indexed buyer,
        uint256 BETAmount,
        uint256 ETHAmount
    );

    event withdrawedTokens(
        uint256 giftCardId,
        uint256 amount,
        address creator
    );

    event Received(address sender, uint value);

    function generateRandomVoucherCode(uint256 id)
        internal
        pure
        returns (string memory)
    {
        bytes
            memory characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        bytes memory voucherCode = new bytes(10);

        voucherCode[0] = "B";
        voucherCode[1] = "E";
        voucherCode[2] = "T";
        voucherCode[3] = "-";

        for (uint8 i = 4; i < 9; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(id, i)));
            voucherCode[i] = characters[rand % characters.length];
        }
        return string(voucherCode);
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function depositBetTokens(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        IERC20(tokenAddress).transfer(address(this), _amount);
    }

    function trimCodeCharacter(string memory code)
        internal
        pure
        returns (string memory)
    {
        bytes memory bytesValue = bytes(code);
        uint256 length = bytesValue.length;

        for (uint256 i = 0; i < length; i++) {
            if (bytesValue[i] == "\x00") {
                length = i;
                break;
            }
        }
        string memory result = new string(length);
        bytes memory bytesResult = bytes(result);
        for (uint256 i = 0; i < length; i++) {
            bytesResult[i] = bytesValue[i];
        }

        return result;
    }

    function createGiftCard(
        uint256 _BETValue,
        uint256 _ETHprice,
        string memory _logoHash,
        string memory _Desc,
        uint256 _expDate,
        bool _isDonation
    ) external payable {
        require(
            IABUser(autobetUseraddress).isCreator(msg.sender),
            "Not a registered creator"
        );
        require(_BETValue > 0, "Value must be greater than zero");
        require(_ETHprice >= 0, "Value must be greater than zero");
        require(_expDate >= block.timestamp, "Expiry date is in past");

        uint256 availableToken = IERC20(tokenAddress).balanceOf(msg.sender);
        require(_BETValue < availableToken, "Creator has insufficient balance");

        uint256 allowed = IERC20(tokenAddress).allowance(
            msg.sender,
            address(this)
        );
        require(allowed >= _BETValue, "Allowance low");

        string memory voucherCode;
        if (_isDonation) {
            voucherCode = generateRandomVoucherCode(giftCardId);
            voucherCode = trimCodeCharacter(voucherCode);
            giftCardVoucherCodes[giftCardId] = voucherCode;
        }

         giftCards[giftCardId]= GiftCard({
            giftCardId: giftCardId,
            creator: msg.sender,
            BETValue: _BETValue,
            ETHPrice: _ETHprice,
            logoHash: _logoHash,
            Desc: _Desc,
            expDate: _expDate,
            status: giftCardStatus.open,
            isSold: false,
            buyer: address(0),
            isDonation: _isDonation,
            voucherCode: voucherCode
        });

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _BETValue);

        emit GiftCardCreated(
            giftCardId,
            msg.sender,
            _BETValue,
            _ETHprice,
            _logoHash,
            _Desc,
            _expDate
        );
        giftCardId++;
    }

    function purchaseGiftCard(uint256 _giftCardId, string memory _voucherCode)
        external
        payable
    {
        require(_giftCardId < giftCardId, "Invalid gift card ID");
        GiftCard storage giftCard = giftCards[_giftCardId];
        require(!giftCard.isSold, "Gift card is already sold");
        uint256 ETHAmount = giftCard.ETHPrice;
        uint256 BETAmount = giftCard.BETValue;
        require(
            msg.value == ETHAmount,
            "Sent Ether amount does not match specified ETH price"
        );

        if (giftCard.isDonation) {
            require(
                keccak256(abi.encodePacked(_voucherCode)) ==
                    keccak256(
                        abi.encodePacked(giftCardVoucherCodes[_giftCardId])
                    ),
                "Invalid voucher code"
            );
        }
        payable(giftCard.creator).transfer(ETHAmount);
        IERC20(tokenAddress).transfer(msg.sender, BETAmount);
        address creator = giftCard.creator;
        giftCard.isSold = true;
        giftCard.status = giftCardStatus.bought;
        giftCard.buyer = msg.sender;
        emit GiftCardPurchased(
            creator,
            _giftCardId,
            msg.sender,
            BETAmount,
            ETHAmount
        );
    }


//withdraw each expired giftcard tokens of creator
    function withdrawCreatorTokens(uint256 _giftCardId) external payable {
        require(_giftCardId < giftCardId, "Invalid gift card ID");
        GiftCard storage giftCard = giftCards[_giftCardId];
        require(
            giftCard.status == giftCardStatus.open,
            "Gift card status not open"
        );

        if (giftCard.expDate <= block.timestamp && giftCard.status != giftCardStatus.bought) {
            uint256 amount = giftCard.BETValue;
            IERC20(tokenAddress).transfer(giftCard.creator, amount);
            giftCard.status = giftCardStatus.paid;
            emit withdrawedTokens(_giftCardId,amount,giftCard.creator);
        }
       
    }

    function getGiftCardsByBuyer(address _buyer)
        external
        view
        returns (GiftCard[] memory)
    {
        uint256 buyerCount = 0;
        for (uint256 i = 0; i < giftCardId; i++) {
            if (giftCards[i].buyer == _buyer) {
                buyerCount++;
            }
        }
        GiftCard[] memory buyerGiftCards = new GiftCard[](buyerCount);
        uint256 index = 0;

        for (uint256 i = 0; i < giftCardId; i++) {
            if (giftCards[i].buyer == _buyer) {
                buyerGiftCards[index] = giftCards[i];
                index++;
            }
        }
        return buyerGiftCards;
    }

//BET token balance of user
    function getBetTokenBalance(address _walletAddress)
        public
        view
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(_walletAddress);
    }

    function transferToken(
        uint256 amount,
        address to,
        address tokenAdd
    ) external onlyOwner {
        require(
            amount <= IERC20(tokenAdd).balanceOf(address(this)),
            "low balance"
        );
        IERC20(tokenAddress).transfer(to, amount);
    }

//get contract BET balance
    function getContractTokenBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function withdrawETH() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawContractBetTokens(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        IERC20(tokenAddress).transfer(address(this), _amount);
    }

    function withdrawUserBetTokens(address _userAddress, uint256 _amount)
        external onlyOwner
    {
        require(_amount > 0, "Amount must be greater than zero");
        IERC20(tokenAddress).transfer(_userAddress, _amount);
    }

    function getContractETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}