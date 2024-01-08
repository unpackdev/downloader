//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AbstractLocker_v30.sol";

import "./SafeERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract BalanceLocker_v30 is Initializable, ContextUpgradeable, OwnableUpgradeable,
    ERC20BurnableUpgradeable, AbstractLocker_v30
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    string private constant _LP_NAME = 'BAG Bridge LP';
    string private constant _LP_SYMBOL = 'BBLP';
    uint8 private _decimals;
    uint256 public lpFeeShareBP;
    uint256 public lpLockerTokenBalance;
    uint256 public lpLockerTokenBalanceCap;

    /*
    // EIP-2612 https://eips.ethereum.org/EIPS/eip-2612
    bytes32 public LP_DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant LP_PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => CountersUpgradeable.Counter) private _nonces;
    */

    // Oracle
    bytes32 private constant LIQUIDITY_REFUND_TYPEHASH=keccak256(abi.encodePacked(
        "LiquidityRefund(uint256 claimId,uint256 sourceChainGuid,address sourceLockerAddress,address sourceAddress,uint256 amount,uint256 deadline)"
    ));

    function initialize(
        uint256 _chainGuid,
        address _lockerToken,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP,
        uint16 _lpFeeShareBP,
        uint256 _lpLockerTokenBalanceCap
    ) public initializer {
        __BalanceLocker_init(_chainGuid, _lockerToken, _oracleAddress, _feeAddress, _feeBP,
            _lpFeeShareBP, _lpLockerTokenBalanceCap);
    }

    function __BalanceLocker_init(
        uint256 _chainGuid,
        address _lockerToken,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP,
        uint16 _lpFeeShareBP,
        uint256 _lpLockerTokenBalanceCap
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained(_LP_NAME, _LP_SYMBOL);
        _decimals = 18;
        __ERC20Burnable_init_unchained();
        __AbstractLocker_init_unchained(_chainGuid, _lockerToken, _oracleAddress, _feeAddress, _feeBP);
        __BalanceLocker_init_unchained(_lpFeeShareBP, _lpLockerTokenBalanceCap);
    }

    function __BalanceLocker_init_unchained(
        uint16 _lpFeeShareBP,
        uint256 _lpLockerTokenBalanceCap
    ) internal initializer {
        require(_lpFeeShareBP <= 10000, 'initialize: invalid lpFeeShareBP');

        /*
        LP_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(_LP_NAME)),
                keccak256(bytes('1')),
                evmChainId,
                address(this)
            )
        );
        */
        lpLockerTokenBalance = 0;
        lpFeeShareBP = _lpFeeShareBP;
        lpLockerTokenBalanceCap = _lpLockerTokenBalanceCap;
    }

    function setLpLockerTokenBalanceCap(uint256 _cap) external onlyOwner {
        lpLockerTokenBalanceCap = _cap;
    }

    // AbstractLocker overrides

    function _receiveTokens(
        address _fromAddress,
        uint256 _amount
    ) virtual internal override {
        // transfer in tokens
        IERC20Upgradeable(lockerToken).safeTransferFrom(
            address(_fromAddress),
            address(this),
            _amount
        );
    }

    function _sendTokens(
        address _toAddress,
        uint256 _amount
    ) virtual internal override {
        require(IERC20Upgradeable(lockerToken).balanceOf(address(this)) >= _amount,
            'sendTokens: insufficient funds');
        // transfer out tokens
        IERC20Upgradeable(lockerToken).safeTransfer(
            address(_toAddress),
            _amount
        );
    }

    function _sendFees(
        uint256 _feeAmount
    ) virtual internal override {
        uint256 lpFeeAmount = _feeAmount * lpFeeShareBP / 10000;
        uint256 netFeeAmount = _feeAmount - lpFeeAmount;

        lpLockerTokenBalance = lpLockerTokenBalance + lpFeeAmount;
        // increment LP fee balance
        _sendTokens(feeAddress, netFeeAmount);
    }

    // EIP-2612 functions - https://eips.ethereum.org/EIPS/eip-2612
    /*
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        // Checks
        require(deadline >= block.timestamp, 'permit: expired');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                LP_DOMAIN_SEPARATOR,
                keccak256(abi.encode(LP_PERMIT_TYPEHASH,
                    owner, spender, value, _nonces[owner].current(), deadline))
            )
        );
        address recoveredAddress = ECDSAUpgradeable.recover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner,
            'permit: invalid');

        // Effects
        _nonces[owner].increment();

        // Interactions
        _approve(owner, spender, value);
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return LP_DOMAIN_SEPARATOR;
    }
    */

    // Liquidity management functions

    function calcNewLiquidity(
        uint256 _newAmount
    ) view internal returns (uint liquidity) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            liquidity = _newAmount;
        } else {
            liquidity = _newAmount * totalSupply / lpLockerTokenBalance;
        }
    }

    function liquidityAdd(
        uint256 _amount,
        address _to,
        uint256 _deadline
    ) external {
        // Checks
        require(_deadline >= block.timestamp, 'liquidityAdd: expired');
        require(_amount > 0, 'liquidityAdd: zero amount');
        require(lpLockerTokenBalance + _amount < lpLockerTokenBalanceCap, 'liquidityAdd: cap exceeded');

        // Effects
        uint256 liquidity = calcNewLiquidity(_amount);
        lpLockerTokenBalance = lpLockerTokenBalance + _amount;

        // Interactions
        _receiveTokens(msg.sender, _amount);

        _mint(_to, liquidity);
        emit LiquidityAdd(msg.sender, _to, _amount);
    }

    function liquidityRemove(
        uint256 _targetChainGuid,
        address _targetLockerAddress,
        address _targetAddress,
        uint256 _liquidity,
        bool _payImmediateFee,
        uint256 _deadline
    ) external {
        // Checks
        require(_deadline >= block.timestamp, 'liquidityRemove: expired');
        require(_liquidity > 0, 'liquidityRemove: zero liquidity');
        bool sameLocker = (address(this) == _targetLockerAddress) && (chainGuid == _targetChainGuid);
        require(!(_payImmediateFee && sameLocker), 'liquidityRemove: invalid fee');
        uint256 totalSupply = totalSupply();
        require(_liquidity <= totalSupply, 'liquidityRemove: invalid liquidity');

        // Effects
        uint256 removedAmount = lpLockerTokenBalance * _liquidity / totalSupply;
        require(lpLockerTokenBalance >= removedAmount, 'liquidityRemove: negative balance');
        lpLockerTokenBalance = lpLockerTokenBalance - removedAmount;

        // Interactions
        burn(_liquidity);
        if (sameLocker) {
            // immediate removal is allowed
            _sendTokens(_targetAddress, removedAmount);
        }
        // otherwise wait for oracle to confirm claim time based on fee payment
        emit LiquidityRemove(msg.sender, _targetChainGuid, _targetLockerAddress, _targetAddress, removedAmount);
    }

    function liquidityRefund(
        uint256 _claimId,
        uint256 _sourceChainGuid,
        address _sourceLockerAddress,
        address _sourceAddress,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Checks
        require(_deadline >= block.timestamp, 'liquidityRefund: expired');
        require(chainGuid == _sourceChainGuid, 'liquidityRefund: wrong chain');
        require(address(this) == _sourceLockerAddress, 'liquidityRefund: wrong locker');
        require(claims[_claimId] == false, 'liquidityRefund: claim used');
        require(IERC20Decimals(lockerToken).decimals() == tokenDecimals, 'liquidityRefund: bad decimals');

        // values must cover all non-signature arguments to the external function call
        bytes32 values = keccak256(abi.encode(
            LIQUIDITY_REFUND_TYPEHASH,
            _claimId, _sourceChainGuid, _sourceLockerAddress, _sourceAddress, _amount, _deadline
        ));
        _verify(values, _v, _r, _s);

        // Effects
        claims[_claimId] = true;
        uint256 liquidity = calcNewLiquidity(_amount);
        lpLockerTokenBalance = lpLockerTokenBalance + _amount;

        // Interactions
        _mint(_sourceAddress, liquidity);

        emit LiquidityRefund(msg.sender, _sourceAddress, _amount);
    }

    function setupTokenDecimals() public override onlyOwner {
        super.setupTokenDecimals();
        require(tokenDecimals<=255, 'setupTokenDecimals: invalid decimals');
        _decimals = tokenDecimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    uint256[50] private __gap;
}