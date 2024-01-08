//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./draft-EIP712.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./IAvatar.sol";
import "./IDava.sol";
import "./IRandomBox.sol";

interface IPartCollection {
    function unsafeMintBatch(
        address account,
        uint256[] calldata partIds,
        uint256[] calldata amounts
    ) external;
}

contract Sale is EIP712, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant WHITELIST_TYPE_HASH =
        keccak256("Whitelist(uint256 ticketAmount,address beneficiary)");
    bytes32 public constant RESERVED_TYPE_HASH =
        keccak256("Reserved(uint256 amount,address beneficiary)");

    uint16 public constant PARTS_PER_AVATAR = 3;
    uint16 public constant MAX_MINT_PER_TICKET = 3;
    uint16 public constant PRE_ALLOCATED_AMOUNT = 500;

    uint16 public constant MAX_MINT_PER_ACCOUNT = 100;

    // Supply
    uint16 private constant MAX_TOTAL_SUPPLY = 10000;
    uint16 public totalClaimedAmount = 0;
    uint16 public totalPreSaleAmount = 0;
    uint16 public totalPublicSaleAmount = 0;

    uint32 public immutable PRE_SALE_OPENING_TIME;
    uint32 public immutable PRE_SALE_CLOSING_TIME;
    uint32 public immutable PUBLIC_SALE_OPENING_TIME;
    uint32 public publicSaleClosingTime;

    uint56 public constant PRICE = 0.05 ether;
    // Parts
    IDava public dava;
    IPartCollection public davaOfficial;
    IRandomBox private _randomBox;

    mapping(address => uint256) public preSaleMintAmountOf;
    mapping(address => uint256) public mainSaleMintAmountOf;
    mapping(address => uint256) public claimedAmountOf;

    struct Reserved {
        uint256 amount;
        address beneficiary;
    }

    struct ClaimReq {
        uint8 vSig;
        bytes32 rSig;
        bytes32 sSig;
        Reserved reserved;
    }

    struct Whitelist {
        uint256 ticketAmount;
        address beneficiary;
    }

    struct PreSaleReq {
        uint8 vSig;
        bytes32 rSig;
        bytes32 sSig;
        Whitelist whitelist;
    }

    constructor(
        IDava dava_,
        IPartCollection davaOfficial_,
        IRandomBox randomBox_,
        uint32 presaleStart,
        uint32 presaleEnd,
        uint32 publicStart
    ) EIP712("AvatarSale", "V1") {
        dava = dava_;
        davaOfficial = davaOfficial_;
        _randomBox = randomBox_;
        PRE_SALE_OPENING_TIME = presaleStart;
        PRE_SALE_CLOSING_TIME = presaleEnd;
        PUBLIC_SALE_OPENING_TIME = publicStart;
        publicSaleClosingTime = 2**32 - 1;
    }

    modifier onlyDuringPreSale() {
        require(
            block.timestamp >= PRE_SALE_OPENING_TIME,
            "Sale: preSale has not started yet"
        );
        require(
            block.timestamp <= PRE_SALE_CLOSING_TIME,
            "Sale: preSale has ended"
        );
        _;
    }

    modifier onlyDuringPublicSale() {
        require(
            block.timestamp >= PUBLIC_SALE_OPENING_TIME,
            "Sale: publicSale has not started yet"
        );
        require(
            block.timestamp <= publicSaleClosingTime,
            "Sale: publicSale has ended"
        );
        _;
    }

    function setPublicSaleClosingTime(uint32 closingTime_) external onlyOwner {
        publicSaleClosingTime = closingTime_;
    }

    function claim(ClaimReq calldata claimReq, uint16 claimedAmount) external {
        require(
            msg.sender == claimReq.reserved.beneficiary,
            "Sale: not authorized"
        );
        require(
            claimedAmount <=
                claimReq.reserved.amount - claimedAmountOf[msg.sender],
            "Sale: exceeds assigned amount"
        );
        require(
            totalClaimedAmount + claimedAmount <= PRE_ALLOCATED_AMOUNT,
            "Sale: exceeds PRE_ALLOCATED_AMOUNT"
        );
        _verifyClaimSig(claimReq);

        claimedAmountOf[msg.sender] += claimedAmount;

        for (uint16 i = 0; i < claimedAmount; i++) {
            _mintAvatarWithParts(totalClaimedAmount + i);
        }
        totalClaimedAmount += claimedAmount;
    }

    // this is for public sale.
    function mint(uint16 purchaseAmount) external payable onlyDuringPublicSale {
        require(!soldOut(), "Sale: sold out");

        mainSaleMintAmountOf[msg.sender] += purchaseAmount;
        require(
            mainSaleMintAmountOf[msg.sender] <= MAX_MINT_PER_ACCOUNT,
            "Sale: can not purchase more than MAX_MINT_PER_ACCOUNT"
        );
        _checkEthAmount(purchaseAmount, msg.value);

        uint16 davaId = _getMintableId();
        for (uint16 i = 0; i < purchaseAmount; i += 1) {
            _mintAvatarWithParts(davaId + i);
        }
        totalPublicSaleAmount += purchaseAmount;
    }

    // this is for pre sale.
    function mintWithWhitelist(
        PreSaleReq calldata preSaleReq,
        uint16 purchaseAmount
    ) external payable onlyDuringPreSale {
        require(
            msg.sender == preSaleReq.whitelist.beneficiary,
            "Sale: msg.sender is not whitelisted"
        );
        require(
            purchaseAmount <=
                (preSaleReq.whitelist.ticketAmount * MAX_MINT_PER_TICKET) -
                    preSaleMintAmountOf[msg.sender],
            "Sale: exceeds assigned amount"
        );
        _checkEthAmount(purchaseAmount, msg.value);
        _verifyWhitelistSig(preSaleReq);

        preSaleMintAmountOf[msg.sender] += purchaseAmount;

        uint16 davaId = _getMintableId();
        for (uint16 i = 0; i < purchaseAmount; i += 1) {
            _mintAvatarWithParts(davaId + i);
        }
        totalPreSaleAmount += purchaseAmount;
    }

    function withdrawFunds(address payable receiver) external onlyOwner {
        uint256 amount = address(this).balance;
        receiver.transfer(amount);
    }

    function _mintAvatarWithParts(uint16 avatarId) internal {
        address avatar = dava.mint(address(this), uint256(avatarId));

        uint256[] memory partIds = _randomBox.getPartIds(avatarId);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;

        davaOfficial.unsafeMintBatch(avatar, partIds, amounts);
        Part[] memory parts = new Part[](PARTS_PER_AVATAR);
        for (uint16 i = 0; i < PARTS_PER_AVATAR; i += 1) {
            parts[i] = Part(address(davaOfficial), uint96(partIds[i]));
        }
        IAvatar(avatar).dress(parts, new bytes32[](0));
        dava.transferFrom(address(this), msg.sender, avatarId);
    }

    function soldOut() public view returns (bool) {
        return (totalPreSaleAmount +
            totalPublicSaleAmount +
            PRE_ALLOCATED_AMOUNT ==
            MAX_TOTAL_SUPPLY);
    }

    function _verifyClaimSig(ClaimReq calldata claimReq) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    RESERVED_TYPE_HASH,
                    claimReq.reserved.amount,
                    msg.sender
                )
            )
        );

        address signer = ecrecover(
            digest,
            claimReq.vSig,
            claimReq.rSig,
            claimReq.sSig
        );
        require(signer == owner(), "Sale: invalid signature");
    }

    function _verifyWhitelistSig(PreSaleReq calldata preSaleReq) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    WHITELIST_TYPE_HASH,
                    preSaleReq.whitelist.ticketAmount,
                    msg.sender
                )
            )
        );

        address signer = ecrecover(
            digest,
            preSaleReq.vSig,
            preSaleReq.rSig,
            preSaleReq.sSig
        );
        require(signer == owner(), "Sale: invalid signature");
    }

    function _getMintableId() private view returns (uint16) {
        uint16 id = PRE_ALLOCATED_AMOUNT +
            totalPreSaleAmount +
            totalPublicSaleAmount;
        require(id < MAX_TOTAL_SUPPLY, "Sale: exceeds max supply");

        return id;
    }

    function _checkEthAmount(uint16 purchaseAmount, uint256 paidEth)
        private
        pure
    {
        require(
            paidEth >= uint256(purchaseAmount) * uint256(PRICE),
            "Sale: not enough eth"
        );
    }
}
