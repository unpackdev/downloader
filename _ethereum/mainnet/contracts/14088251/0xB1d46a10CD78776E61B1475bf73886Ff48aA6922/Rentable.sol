// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "Address.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Security4.sol";
import "ORentable.sol";
import "YRentable.sol";
import "WRentable.sol";
import "RentableHooks.sol";

contract Rentable is
    Security4,
    IERC721Receiver,
    RentableHooks,
    ReentrancyGuard
{
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct LeaseConditions {
        uint256 maxTimeDuration;
        uint256 pricePerBlock;
        address paymentTokenAddress;
        uint256 fixedFee;
        uint256 fee;
    }

    struct Lease {
        address paymentTokenAddress;
        uint256 eta;
        uint256 qtyToPullRemaining;
        uint256 feesToPullRemaining;
        uint256 lastUpdated;
        address tokenAddress;
        uint256 tokenId;
        address from;
        address to;
    }

    address internal _yToken;

    mapping(address => mapping(uint256 => LeaseConditions))
        internal _leasesConditions;

    mapping(uint256 => Lease) internal _leases;

    mapping(address => mapping(uint256 => uint256)) internal _currentLeases;

    mapping(address => address) internal _wrentables;
    mapping(address => ORentable) internal _orentables;

    mapping(address => bool) public paymentTokenAllowlist;

    uint256 public constant BASE_FEE = 10000;
    uint256 internal _fixedFee;
    uint256 internal _fee;

    address payable _feeCollector;

    event Deposit(
        address indexed who,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );
    event UpdateLeaseConditions(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address paymentTokenAddress,
        uint256 maxTimeDuration,
        uint256 pricePerBlock
    );
    event Withdraw(
        address indexed who,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );
    event Rent(
        address from,
        address indexed to,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 yTokenId
    );
    event Claim(
        address indexed who,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address paymentTokenAddress,
        uint256 qty,
        uint256 yTokenId
    );
    event RentEnds(
        address from,
        address indexed to,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 yTokenId
    );

    constructor(
        address _governance,
        address _operator,
        address payable _emergencyImplementation
    ) Security4(_governance, _operator, _emergencyImplementation) {}

    function getORentable(address wrapped_) external view returns (address) {
        return address(_orentables[wrapped_]);
    }

    function setORentable(address wrapped_, address oRentable_)
        external
        onlyGovernance
    {
        _orentables[wrapped_] = ORentable(oRentable_);
    }

    function setYToken(address yToken_) external onlyGovernance {
        _yToken = yToken_;
    }

    function getYToken() external view returns (address) {
        return _yToken;
    }

    function getWRentable(address wrapped_) external view returns (address) {
        return address(_wrentables[wrapped_]);
    }

    function setWRentable(address wrapped_, address rentable_)
        external
        onlyGovernance
    {
        _wrentables[wrapped_] = rentable_;
    }

    function getFixedFee() external view returns (uint256) {
        return _fixedFee;
    }

    function setFixedFee(uint256 fixedFee) external onlyGovernance {
        _fixedFee = fixedFee;
    }

    function getFee() external view returns (uint256) {
        return _fee;
    }

    function setFee(uint256 fee) external onlyGovernance {
        _fee = fee;
    }

    function getFeeCollector() external view returns (address) {
        return _feeCollector;
    }

    function setFeeCollector(address payable feeCollector)
        external
        onlyGovernance
    {
        _feeCollector = feeCollector;
    }

    function enablePaymentToken(address paymentTokenAddress)
        external
        onlyGovernance
    {
        paymentTokenAllowlist[paymentTokenAddress] = true;
    }

    function disablePaymentToken(address paymentTokenAddress)
        external
        onlyGovernance
    {
        paymentTokenAllowlist[paymentTokenAddress] = false;
    }

    function _getExistingORentable(address tokenAddress)
        internal
        view
        virtual
        returns (ORentable oRentable)
    {
        oRentable = _orentables[tokenAddress];
        require(
            address(oRentable) != address(0),
            "Token currently not supported"
        );
    }

    function _getExistingORentableCheckOwnership(
        address tokenAddress,
        uint256 tokenId,
        address user
    ) internal virtual returns (ORentable oRentable) {
        oRentable = _getExistingORentable(tokenAddress);

        require(oRentable.ownerOf(tokenId) == user, "The token must be yours");
    }

    modifier onlyOTokenOwner(address tokenAddress, uint256 tokenId) {
        _getExistingORentableCheckOwnership(
            tokenAddress,
            tokenId,
            _msgSender()
        );
        _;
    }

    function _deposit(
        address tokenAddress,
        uint256 tokenId,
        address to,
        bool skipTransfer
    ) internal returns (uint256 oRentableId) {
        ORentable oRentable = _getExistingORentable(tokenAddress);

        if (!skipTransfer) {
            IERC721(tokenAddress).transferFrom(to, address(this), tokenId);
        } else {
            require(
                IERC721(tokenAddress).ownerOf(tokenId) == address(this),
                "Token not deposited"
            );
        }

        oRentableId = oRentable.mint(to, tokenId);

        _postDeposit(tokenAddress, tokenId, to);

        emit Deposit(to, tokenAddress, tokenId);
    }

    function _depositAndList(
        address tokenAddress,
        uint256 tokenId,
        address to,
        bool skipTransfer,
        address paymentTokenAddress,
        uint256 maxTimeDuration,
        uint256 pricePerBlock
    ) internal returns (uint256 oRentableId) {
        oRentableId = _deposit(tokenAddress, tokenId, to, skipTransfer);

        _createOrUpdateLeaseConditions(
            tokenAddress,
            tokenId,
            paymentTokenAddress,
            maxTimeDuration,
            pricePerBlock
        );
    }

    function deposit(address tokenAddress, uint256 tokenId)
        external
        nonReentrant
        whenPausedthenProxy
        onlyAllowlisted
        returns (uint256)
    {
        return _deposit(tokenAddress, tokenId, _msgSender(), false);
    }

    function depositAndList(
        address tokenAddress,
        uint256 tokenId,
        address paymentTokenAddress,
        uint256 maxTimeDuration,
        uint256 pricePerBlock
    )
        external
        nonReentrant
        whenPausedthenProxy
        onlyAllowlisted
        returns (uint256)
    {
        return
            _depositAndList(
                tokenAddress,
                tokenId,
                _msgSender(),
                false,
                paymentTokenAddress,
                maxTimeDuration,
                pricePerBlock
            );
    }

    function withdraw(address tokenAddress, uint256 tokenId)
        external
        nonReentrant
        whenPausedthenProxy
        onlyAllowlisted
    {
        address user = _msgSender();
        ORentable oRentable = _getExistingORentableCheckOwnership(
            tokenAddress,
            tokenId,
            user
        );

        uint256 leaseId = _currentLeases[tokenAddress][tokenId];
        if (leaseId != 0) {
            Lease memory currentLease = _leases[leaseId];
            require(
                block.number > currentLease.eta,
                "Current lease still pending"
            );
        }

        IERC721(tokenAddress).transferFrom(address(this), user, tokenId);

        delete _leasesConditions[tokenAddress][tokenId];

        oRentable.burn(tokenId);

        emit Withdraw(user, tokenAddress, tokenId);
    }

    function leasesConditions(address tokenAddress, uint256 tokenId)
        external
        view
        returns (LeaseConditions memory)
    {
        return _leasesConditions[tokenAddress][tokenId];
    }

    function currentLeases(address tokenAddress, uint256 tokenId)
        external
        view
        returns (Lease memory)
    {
        return _leases[_currentLeases[tokenAddress][tokenId]];
    }

    function _createOrUpdateLeaseConditions(
        address tokenAddress,
        uint256 tokenId,
        address paymentTokenAddress,
        uint256 maxTimeDuration,
        uint256 pricePerBlock
    ) internal {
        require(
            paymentTokenAllowlist[paymentTokenAddress],
            "Not supported payment token"
        );

        LeaseConditions storage lease = _leasesConditions[tokenAddress][
            tokenId
        ];

        lease.maxTimeDuration = maxTimeDuration;
        lease.pricePerBlock = pricePerBlock;
        lease.paymentTokenAddress = paymentTokenAddress;
        lease.fixedFee = _fixedFee;
        lease.fee = _fee;

        _postList(
            tokenAddress,
            tokenId,
            _msgSender(),
            maxTimeDuration,
            pricePerBlock
        );

        emit UpdateLeaseConditions(
            tokenAddress,
            tokenId,
            paymentTokenAddress,
            maxTimeDuration,
            pricePerBlock
        );
    }

    function _isExpired(Lease memory lease) internal virtual returns (bool) {
        return block.number >= lease.eta;
    }

    function _expireLease(uint256 leaseId) internal virtual {
        Lease memory lease = _leases[leaseId];
        require(_isExpired(lease), "Current lease still pending");
        if (WRentable(_wrentables[lease.tokenAddress]).exists(lease.tokenId)) {
            WRentable(_wrentables[lease.tokenAddress]).burn(lease.tokenId);
            _postExpireRent(
                leaseId,
                lease.tokenAddress,
                lease.tokenId,
                lease.from,
                lease.to
            );
            emit RentEnds(
                lease.from,
                lease.to,
                lease.tokenAddress,
                lease.tokenId,
                leaseId
            );
        }
    }

    function createOrUpdateLeaseConditions(
        address tokenAddress,
        uint256 tokenId,
        address paymentTokenAddress,
        uint256 maxTimeDuration,
        uint256 pricePerBlock
    )
        external
        onlyOTokenOwner(tokenAddress, tokenId)
        whenPausedthenProxy
        onlyAllowlisted
    {
        _createOrUpdateLeaseConditions(
            tokenAddress,
            tokenId,
            paymentTokenAddress,
            maxTimeDuration,
            pricePerBlock
        );
    }

    function deleteLeaseConditions(address tokenAddress, uint256 tokenId)
        external
        onlyOTokenOwner(tokenAddress, tokenId)
        whenPausedthenProxy
        onlyAllowlisted
    {
        delete _leasesConditions[tokenAddress][tokenId];
    }

    function createLease(
        address tokenAddress,
        uint256 tokenId,
        uint256 duration
    ) external payable nonReentrant whenPausedthenProxy {
        ORentable oRentable = _getExistingORentable(tokenAddress);
        address from = oRentable.ownerOf(tokenId);

        LeaseConditions memory leaseCondition = _leasesConditions[tokenAddress][
            tokenId
        ];
        require(leaseCondition.maxTimeDuration > 0, "Not available");

        uint256 leaseId = _currentLeases[tokenAddress][tokenId];

        if (leaseId != 0) {
            _expireLease(leaseId);
        }

        require(
            duration <= leaseCondition.maxTimeDuration,
            "Duration greater than conditions"
        );

        address user = _msgSender();
        uint256 paymentQty = leaseCondition.pricePerBlock.mul(duration);

        // Fee calc
        uint256 qtyToPullRemaining = paymentQty.sub(leaseCondition.fixedFee);
        uint256 feesToPullRemaining = qtyToPullRemaining
            .mul(leaseCondition.fee)
            .div(BASE_FEE);
        qtyToPullRemaining = qtyToPullRemaining.sub(feesToPullRemaining);

        leaseId = YRentable(_yToken).mint(from);

        Lease storage lease = _leases[leaseId];
        lease.eta = block.number.add(duration);
        lease.qtyToPullRemaining = qtyToPullRemaining;
        lease.feesToPullRemaining = feesToPullRemaining;
        lease.lastUpdated = block.number;
        lease.tokenAddress = tokenAddress;
        lease.tokenId = tokenId;
        lease.from = from;
        lease.to = user;
        lease.paymentTokenAddress = leaseCondition.paymentTokenAddress;

        _currentLeases[tokenAddress][tokenId] = leaseId;

        WRentable(_wrentables[tokenAddress]).mint(user, tokenId);

        if (leaseCondition.paymentTokenAddress == address(0)) {
            require(msg.value >= paymentQty, "Not enough funds");
            if (msg.value > paymentQty) {
                Address.sendValue(payable(user), msg.value.sub(paymentQty));
            }

            if (leaseCondition.fixedFee > 0) {
                Address.sendValue(_feeCollector, leaseCondition.fixedFee);
            }
        } else {
            IERC20(leaseCondition.paymentTokenAddress).safeTransferFrom(
                user,
                address(this),
                paymentQty
            );
            if (msg.value > 0) {
                Address.sendValue(payable(user), msg.value);
            }

            if (leaseCondition.fixedFee > 0) {
                IERC20(leaseCondition.paymentTokenAddress).safeTransfer(
                    _feeCollector,
                    leaseCondition.fixedFee
                );
            }
        }

        _postCreateRent(leaseId, tokenAddress, tokenId, duration, from, user);

        emit Rent(from, user, tokenAddress, tokenId, leaseId);
    }

    function redeemLease(uint256 leaseId)
        external
        nonReentrant
        whenPausedthenProxy
        onlyAllowlisted
    {
        address user = _msgSender();
        require(
            IERC721(_yToken).ownerOf(leaseId) == user,
            "You should own respective yRentable"
        );

        Lease storage lease2redeem = _leases[leaseId];

        // Calculate linearly the amount remaining
        require(
            lease2redeem.qtyToPullRemaining > 0,
            "Nothing to redeem for the lease"
        );

        uint256 amount2Redeem = 0;
        uint256 fees2Redeem = 0;
        if (_isExpired(lease2redeem)) {
            amount2Redeem = lease2redeem.qtyToPullRemaining;
            fees2Redeem = lease2redeem.feesToPullRemaining;
            _expireLease(leaseId);
        } else {
            amount2Redeem = lease2redeem
                .qtyToPullRemaining
                .mul(block.number.sub(lease2redeem.lastUpdated))
                .div(lease2redeem.eta.sub(lease2redeem.lastUpdated));

            if (lease2redeem.feesToPullRemaining > 0) {
                fees2Redeem = lease2redeem
                    .feesToPullRemaining
                    .mul(block.number.sub(lease2redeem.lastUpdated))
                    .div(lease2redeem.eta.sub(lease2redeem.lastUpdated));
            }
        }

        // approx safety check
        if (amount2Redeem > lease2redeem.qtyToPullRemaining) {
            amount2Redeem = lease2redeem.qtyToPullRemaining;
        }

        if (fees2Redeem > lease2redeem.feesToPullRemaining) {
            fees2Redeem = lease2redeem.feesToPullRemaining;
        }

        lease2redeem.qtyToPullRemaining = lease2redeem.qtyToPullRemaining.sub(
            amount2Redeem
        );
        if (fees2Redeem > 0) {
            lease2redeem.feesToPullRemaining = lease2redeem
                .feesToPullRemaining
                .sub(fees2Redeem);
        }
        lease2redeem.lastUpdated = block.number;

        if (lease2redeem.paymentTokenAddress == address(0)) {
            Address.sendValue(payable(user), amount2Redeem);
            if (fees2Redeem > 0) {
                Address.sendValue(_feeCollector, fees2Redeem);
            }
        } else {
            IERC20(lease2redeem.paymentTokenAddress).safeTransfer(
                user,
                amount2Redeem
            );
            if (fees2Redeem > 0) {
                IERC20(lease2redeem.paymentTokenAddress).safeTransfer(
                    _feeCollector,
                    fees2Redeem
                );
            }
        }

        emit Claim(
            user,
            lease2redeem.tokenAddress,
            lease2redeem.tokenId,
            lease2redeem.paymentTokenAddress,
            amount2Redeem,
            leaseId
        );
    }

    function expireLease(uint256 leaseId) external whenPausedthenProxy {
        _expireLease(leaseId);
    }

    function expireLeases(uint256[] calldata leaseIds)
        external
        whenPausedthenProxy
    {
        for (uint256 i = 0; i < leaseIds.length; i++) {
            _expireLease(leaseIds[i]);
        }
    }

    function afterWTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external whenPausedthenProxy {
        require(
            _msgSender() == _wrentables[tokenAddress],
            "Only proper WRentables allowed"
        );

        uint256 leaseId = _currentLeases[tokenAddress][tokenId];
        if (leaseId != 0) {
            Lease storage currentLease = _leases[leaseId];
            currentLease.to = to;
        }

        address lib = _libraries[tokenAddress];
        if (lib != address(0)) {
            lib.functionDelegateCall(
                abi.encodeCall(
                    ICollectionLibrary(lib).postWTokenTransfer,
                    (tokenAddress, tokenId, from, to)
                ),
                ""
            );
        }
    }

    function afterOTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external whenPausedthenProxy {
        require(
            _msgSender() == address(_orentables[tokenAddress]),
            "Only proper ORentables allowed"
        );

        uint256 leaseId = _currentLeases[tokenAddress][tokenId];
        bool rented = false;
        if (leaseId != 0) {
            Lease storage currentLease = _leases[leaseId];
            currentLease.from = to;
            rented = !(_isExpired(currentLease));
        }

        address lib = _libraries[tokenAddress];
        if (lib != address(0)) {
            lib.functionDelegateCall(
                abi.encodeCall(
                    ICollectionLibrary(lib).postOTokenTransfer,
                    (tokenAddress, tokenId, from, to, rented)
                ),
                ""
            );
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )
        public
        virtual
        override
        nonReentrant
        whenPausedthenProxy
        returns (bytes4)
    {
        require(
            !allowlistEnabled || _isAllowlisted(operator),
            "User not allowed"
        );

        if (data.length == 0) {
            _deposit(_msgSender(), tokenId, from, true);
        } else {
            (
                address paymentTokenAddress,
                uint256 maxTimeDuration,
                uint256 pricePerBlock
            ) = abi.decode(data, (address, uint256, uint256));

            _depositAndList(
                _msgSender(),
                tokenId,
                from,
                true,
                paymentTokenAddress,
                maxTimeDuration,
                pricePerBlock
            );
        }

        return this.onERC721Received.selector;
    }
}
