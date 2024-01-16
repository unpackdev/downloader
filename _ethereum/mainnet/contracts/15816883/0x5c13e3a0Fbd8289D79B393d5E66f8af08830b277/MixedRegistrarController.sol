// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./IRegistrarController.sol";
import "./IRegistrar.sol";
import "./IVoucher.sol";
import "./Registration.sol";
import "./SignatureChecker.sol";
import "./StringUtils.sol";

contract MixedRegistrarController is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable,
    IRegistrarController
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringUtils for *;
    using Registration for Registration.RegisterOrder;

    struct ERC20Detail {
        address token;
        uint256 amount;
    }

    struct VoucherDetail {
        address token;
        uint256 id;
        uint256 amount;
    }

    address public constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // 365.2425 days
    uint256 public constant MIN_REGISTRATION_DURATION = 31556952;

    // A commitment can only be revealed after the minimum commitment age.
    uint256 public minCommitmentAge;
    // A commitment expires after the maximum commitment age.
    uint256 public maxCommitmentAge;

    mapping(address => mapping(uint256 => bool)) private _vouchers;

    function initialize(uint256 _minCommitmentAge, uint256 _maxCommitmentAge)
        public
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712_init("RegistrarController", "1");

        require(_maxCommitmentAge > _minCommitmentAge);
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function rentPrice(
        address registrar,
        string memory name,
        uint256 duration
    ) public view override returns (IPriceOracle.Price memory price) {
        bytes32 label = keccak256(bytes(name));

        IRegistrar r = IRegistrar(registrar);
        price = IPriceOracle(r.priceOracle()).price(
            name,
            r.nameExpires(uint256(label)),
            duration
        );
    }

    function valid(string memory name) public pure returns (bool) {
        bytes memory bname = bytes(name);
        // zero width for /u200b /u200c /u200d and U+FEFF
        for (uint256 i; i < bname.length - 2; i++) {
            if (bytes1(bname[i]) == 0xe2 && bytes1(bname[i + 1]) == 0x80) {
                if (
                    bytes1(bname[i + 2]) == 0x8b ||
                    bytes1(bname[i + 2]) == 0x8c ||
                    bytes1(bname[i + 2]) == 0x8d
                ) {
                    return false;
                }
            } else if (bytes1(bname[i]) == 0xef) {
                if (
                    bytes1(bname[i + 1]) == 0xbb && bytes1(bname[i + 2]) == 0xbf
                ) return false;
            }
        }
        return true;
    }

    function available(address registrar, string memory name)
        public
        view
        override
        returns (bool)
    {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && IRegistrar(registrar).available(uint256(label));
    }

    function nameExpires(address registrar, string memory name)
        public
        view
        override
        returns (uint256)
    {
        bytes32 label = keccak256(bytes(name));
        return IRegistrar(registrar).nameExpires(uint256(label));
    }

    function register(Registration.RegisterOrder calldata order)
        public
        payable
        nonReentrant
    {
        IPriceOracle.Price memory price = _checkRegister(order);
        uint256 cost = price.base + price.premium;
        string memory name = string(order.name);

        if (order.params.length > 0) {
            (address voucher, uint256 voucherId) = abi.decode(
                order.params,
                (address, uint256)
            );
            require(
                isVoucher(voucher, voucherId),
                "RegistrarController: invalid voucher"
            );

            IVoucher v = IVoucher(voucher);
            cost = v.checkout(
                voucherId,
                IVoucher.VoucherEffect.Register,
                order.registrar,
                name,
                price.currency,
                cost
            );
            v.burn(msg.sender, voucherId, 1);
        }

        IRegistrar registrar = IRegistrar(order.registrar);
        if (cost > 0) {
            if (msg.sender != address(this)) {
                IERC20Upgradeable(price.currency).safeTransferFrom(
                    msg.sender,
                    address(this),
                    cost
                );
            }
            IERC20Upgradeable(price.currency).safeTransfer(
                registrar.feeRecipient(),
                cost
            );
        }

        (uint256 tokenId, uint256 expires) = registrar.register(
            name,
            order.owner,
            order.duration,
            order.resolver
        );

        emit NameRegistered(
            order.registrar,
            keccak256(order.name),
            name,
            order.owner,
            tokenId,
            price.base + price.premium,
            expires
        );
    }

    function renew(
        address registrar,
        string calldata name,
        uint256 duration,
        bytes memory data
    ) public payable nonReentrant {
        bytes32 label = keccak256(bytes(name));
        IPriceOracle.Price memory price = rentPrice(registrar, name, duration);
        uint256 cost = price.base + price.premium;
        IRegistrar r = IRegistrar(registrar);

        if (data.length > 0) {
            (address voucher, uint256 voucherId) = abi.decode(
                data,
                (address, uint256)
            );
            require(
                isVoucher(voucher, voucherId),
                "RegistrarController: invalid voucher"
            );

            IVoucher v = IVoucher(voucher);
            cost = v.checkout(
                voucherId,
                IVoucher.VoucherEffect.Renewal,
                registrar,
                name,
                price.currency,
                cost
            );
            v.burn(msg.sender, voucherId, 1);
        }

        if (cost > 0) {
            if (msg.sender != address(this)) {
                IERC20Upgradeable(price.currency).safeTransferFrom(
                    msg.sender,
                    address(this),
                    cost
                );
            }
            IERC20Upgradeable(price.currency).safeTransfer(
                r.feeRecipient(),
                cost
            );
        }

        (uint256 tokenId, uint256 expires) = r.renew(uint256(label), duration);

        emit NameRenewed(
            registrar,
            label,
            name,
            tokenId,
            price.base + price.premium,
            expires
        );
    }

    function renew(
        address registrar,
        string calldata name,
        uint256 duration
    ) public payable override nonReentrant {
        renew(registrar, name, duration, "");
    }

    function bulkRegister(
        Registration.RegisterOrder[] calldata orders,
        ERC20Detail[] calldata erc20Details,
        VoucherDetail[] calldata voucherDetails
    ) external payable {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.length; i++) {
            erc20Details[i].token.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    msg.sender,
                    address(this),
                    erc20Details[i].amount
                )
            );
        }
        // transfer vouchers from the sender to this contract
        for (uint256 i = 0; i < voucherDetails.length; i++) {
            voucherDetails[i].token.call(
                abi.encodeWithSelector(
                    IERC1155Upgradeable.safeTransferFrom.selector,
                    msg.sender,
                    address(this),
                    voucherDetails[i].id,
                    voucherDetails[i].amount,
                    ""
                )
            );
        }

        for (uint256 i = 0; i < orders.length; i++) {
            address(this).call(
                abi.encodeWithSelector(this.register.selector, orders[i])
            );
        }

        // return remaining tokens (if any)
        for (uint256 i = 0; i < erc20Details.length; i++) {
            if (
                IERC20Upgradeable(erc20Details[i].token).balanceOf(
                    address(this)
                ) > 0
            ) {
                erc20Details[i].token.call(
                    abi.encodeWithSignature(
                        "transfer(address,uint256)",
                        msg.sender,
                        IERC20Upgradeable(erc20Details[i].token).balanceOf(
                            address(this)
                        )
                    )
                );
            }
        }
        for (uint256 i = 0; i < voucherDetails.length; i++) {
            if (
                IERC1155Upgradeable(voucherDetails[i].token).balanceOf(
                    address(this),
                    voucherDetails[i].id
                ) > 0
            ) {
                voucherDetails[i].token.call(
                    abi.encodeWithSelector(
                        IERC1155Upgradeable.safeTransferFrom.selector,
                        address(this),
                        msg.sender,
                        voucherDetails[i].id,
                        IERC1155Upgradeable(voucherDetails[i].token).balanceOf(
                            address(this),
                            voucherDetails[i].id
                        ),
                        ""
                    )
                );
            }
        }
    }

    function changeCommitmentAge(uint256 min, uint256 max) external onlyOwner {
        minCommitmentAge = min;
        maxCommitmentAge = max;
    }

    function isVoucher(address voucher, uint256 id) public view returns (bool) {
        return _vouchers[voucher][id];
    }

    function setVoucher(
        address voucher,
        uint256 id,
        bool enable
    ) external onlyOwner {
        _vouchers[voucher][id] = enable;
    }

    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165Upgradeable).interfaceId ||
            interfaceId == type(IRegistrarController).interfaceId;
    }

    /* Internal functions */

    function _checkRegister(Registration.RegisterOrder calldata order)
        internal
        view
        returns (IPriceOracle.Price memory)
    {
        IRegistrar registrar = IRegistrar(order.registrar);
        // Check the register order
        bytes32 registerHash = order.hash();
        _validateOrder(order, registrar, registerHash);

        IPriceOracle.Price memory price = rentPrice(
            order.registrar,
            string(order.name),
            order.duration
        );
        return price;
    }

    function _validateOrder(
        Registration.RegisterOrder calldata order,
        IRegistrar registrar,
        bytes32 registerHash
    ) internal view {
        // Require a valid registration (is old enough and is committed)
        require(
            order.applyingTime + minCommitmentAge <= block.timestamp,
            "RegistrarController: Registration is not valid"
        );

        // If the registration is too old, or the name is registered, stop
        require(
            order.applyingTime + maxCommitmentAge > block.timestamp,
            "RegistrarController: Registration has expired"
        );
        require(
            available(address(registrar), string(order.name)),
            "RegistrarController: Name is unavailable"
        );

        require(order.duration >= MIN_REGISTRATION_DURATION);

        // Verify the signer is not address(0)
        require(
            order.issuer != address(0) && order.issuer == registrar.issuer(),
            "RegistrarController: Invalid issuer"
        );

        require(
            order.currency == IPriceOracle(registrar.priceOracle()).currency(),
            "RegistrarController: Invalid currency"
        );

        // Verify the validity of the signature
        require(
            SignatureChecker.verify(
                registerHash,
                order.issuer,
                order.v,
                order.r,
                order.s,
                _domainSeparatorV4()
            ),
            "RegistrarController: Invalid signature"
        );
    }
}
