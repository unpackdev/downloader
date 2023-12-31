// File: Swivel-v4/src/interfaces/ICreator.sol
pragma solidity ^0.8.13;

interface ICreator {
    function create(
        uint8,
        address,
        uint256,
        address,
        address,
        address,
        string calldata,
        string calldata,
        uint8
    ) external returns (address, address);

    function setAdmin(address) external returns (bool);

    function setMarketPlace(address) external returns (bool);
}

// File: Swivel-v4/src/interfaces/IRedeemer.sol



pragma solidity ^0.8.0;

interface IRedeemer {
    function authRedeem(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (uint256);

    function rates(
        uint8,
        address,
        uint256
    ) external view returns (uint256, uint256);
}

// File: Swivel-v4/src/interfaces/IERC5095.sol



pragma solidity ^0.8.0;

interface IERC5095 {
    event Redeem(address indexed from, address indexed to, uint256 amount);

    function maturity() external view returns (uint256);

    function underlying() external view returns (address);

    function convertToUnderlying(uint256) external view returns (uint256);

    function convertToPrincipal(uint256) external view returns (uint256);

    function maxRedeem(address) external view returns (uint256);

    function previewRedeem(uint256) external view returns (uint256);

    function maxWithdraw(address) external view returns (uint256);

    function previewWithdraw(uint256) external view returns (uint256);

    function withdraw(uint256, address, address) external returns (uint256);

    function redeem(uint256, address, address) external returns (uint256);
}

// File: Swivel-v4/src/tokens/ERC20.sol


// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity 0.8.16;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error Invalid(address signer, address owner);

    error Deadline(uint256 deadline, uint256 timestamp);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (deadline < block.timestamp) {
            revert Deadline(deadline, block.timestamp);
        }
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        '\x19\x01',
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner) {
                revert Invalid(msg.sender, owner);
            }

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                    ),
                    keccak256(bytes(name)),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// File: Swivel-v4/src/tokens/ZcToken.sol



pragma solidity 0.8.16;




contract ZcToken is ERC20, IERC5095 {
    /// @dev unix timestamp when the ERC5095 token can be redeemed
    uint256 public immutable override maturity;
    /// @dev address of the ERC20 token that is returned on ERC5095 redemption
    address public immutable override underlying;
    /// @dev uint8 associated with a given protocol in Swivel
    uint8 public immutable protocol;

    /////////////OPTIONAL///////////////// (Allows the calculation and distribution of yield post maturity)
    /// @dev address of a cToken
    address public immutable cToken;
    /// @dev address and interface for an external custody contract (necessary for some project's backwards compatability)
    address public immutable redeemer;

    error Maturity(uint256 timestamp);

    error Approvals(uint256 approved, uint256 amount);

    error Authorized(address owner);

    constructor(
        uint8 _protocol,
        address _underlying,
        uint256 _maturity,
        address _cToken,
        address _redeemer,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        protocol = _protocol;
        underlying = _underlying;
        maturity = _maturity;
        cToken = _cToken;
        redeemer = _redeemer;
    }

    /// @notice Post maturity converts an amount of principal tokens to an amount of underlying that would be returned. Returns 0 pre-maturity.
    /// @param principalAmount The amount of principal tokens to convert
    /// @return The amount of underlying tokens returned by the conversion
    function convertToUnderlying(
        uint256 principalAmount
    ) external view override returns (uint256) {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (principalAmount * xRate) / mRate;
    }

    /// @notice Post maturity converts a desired amount of underlying tokens returned to principal tokens needed. Returns 0 pre-maturity.
    /// @param underlyingAmount The amount of underlying tokens to convert
    /// @return The amount of principal tokens returned by the conversion
    function convertToPrincipal(
        uint256 underlyingAmount
    ) external view override returns (uint256) {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (underlyingAmount * mRate) / xRate;
    }

    /// @notice Post maturity calculates the amount of principal tokens that `owner` can redeem. Returns 0 pre-maturity.
    /// @param owner The address of the owner for which redemption is calculated
    /// @return The maximum amount of principal tokens that `owner` can redeem.
    function maxRedeem(address owner) external view override returns (uint256) {
        if (block.timestamp < maturity) {
            return 0;
        }
        return balanceOf[owner];
    }

    /// @notice Post maturity simulates the effects of redeemption at the current block. Returns 0 pre-maturity.
    /// @param principalAmount the amount of principal tokens redeemed in the simulation
    /// @return The maximum amount of underlying returned by `principalAmount` of PT redemption
    function previewRedeem(
        uint256 principalAmount
    ) external view override returns (uint256) {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (principalAmount * xRate) / mRate;
    }

    /// @notice Post maturity calculates the amount of underlying tokens that `owner` can withdraw. Returns 0 pre-maturity.
    /// @param  owner The address of the owner for which withdrawal is calculated
    /// @return The maximum amount of underlying tokens that `owner` can withdraw.
    function maxWithdraw(
        address owner
    ) external view override returns (uint256) {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (balanceOf[owner] * xRate) / mRate;
    }

    /// @notice Post maturity simulates the effects of withdrawal at the current block. Returns 0 pre-maturity.
    /// @param underlyingAmount the amount of underlying tokens withdrawn in the simulation
    /// @return The amount of principal tokens required for the withdrawal of `underlyingAmount`
    function previewWithdraw(
        uint256 underlyingAmount
    ) public view override returns (uint256) {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (underlyingAmount * mRate) / xRate;
    }

    /// @notice At or after maturity, Burns principalAmount from `owner` and sends exactly `underlyingAmount` of underlying tokens to `receiver`.
    /// @param underlyingAmount The amount of underlying tokens withdrawn
    /// @param receiver The receiver of the underlying tokens being withdrawn
    /// @return The amount of principal tokens burnt by the withdrawal
    function withdraw(
        uint256 underlyingAmount,
        address receiver,
        address holder
    ) external override returns (uint256) {
        // If maturity is not yet reached. TODO this is moved from underneath the previewAmount call - should have been here before? Discuss.
        if (block.timestamp < maturity) {
            revert Maturity(maturity);
        }

        // TODO removing both the `this.foo` and `external` bits of this pattern as it's simply an unnecessary misdirection. Discuss.
        uint256 previewAmount = previewWithdraw(underlyingAmount);

        // Transfer logic: If holder is msg.sender, skip approval check
        if (holder == msg.sender) {
            IRedeemer(redeemer).authRedeem(
                protocol,
                underlying,
                maturity,
                msg.sender,
                receiver,
                previewAmount
            );
        } else {
            uint256 allowed = allowance[holder][msg.sender];
            if (allowed < previewAmount) {
                revert Approvals(allowed, previewAmount);
            }
            allowance[holder][msg.sender] =
                allowance[holder][msg.sender] -
                previewAmount;
            IRedeemer(redeemer).authRedeem(
                protocol,
                underlying,
                maturity,
                holder,
                receiver,
                previewAmount
            );
        }

        return previewAmount;
    }

    /// @notice At or after maturity, burns exactly `principalAmount` of Principal Tokens from `owner` and sends underlyingAmount of underlying tokens to `receiver`.
    /// @param principalAmount The amount of principal tokens being redeemed
    /// @param receiver The receiver of the underlying tokens being withdrawn
    /// @return The amount of underlying tokens distributed by the redemption
    function redeem(
        uint256 principalAmount,
        address receiver,
        address holder
    ) external override returns (uint256) {
        // If maturity is not yet reached
        if (block.timestamp < maturity) {
            revert Maturity(maturity);
        }

        // some 5095 tokens may have custody of underlying and can can just burn PTs and transfer underlying out, while others rely on external custody
        if (holder == msg.sender) {
            return
                IRedeemer(redeemer).authRedeem(
                    protocol,
                    underlying,
                    maturity,
                    msg.sender,
                    receiver,
                    principalAmount
                );
        } else {
            uint256 allowed = allowance[holder][msg.sender];

            if (allowed < principalAmount) {
                revert Approvals(allowed, principalAmount);
            }

            allowance[holder][msg.sender] =
                allowance[holder][msg.sender] -
                principalAmount;
            return
                IRedeemer(redeemer).authRedeem(
                    protocol,
                    underlying,
                    maturity,
                    holder,
                    receiver,
                    principalAmount
                );
        }
    }

    /// @param f Address to burn from
    /// @param a Amount to burn
    function burn(
        address f,
        uint256 a
    ) external onlyAdmin(address(redeemer)) returns (bool) {
        _burn(f, a);
        return true;
    }

    /// @param t Address recieving the minted amount
    /// @param a The amount to mint
    function mint(
        address t,
        uint256 a
    ) external onlyAdmin(address(redeemer)) returns (bool) {
        // disallow minting post maturity
        if (block.timestamp > maturity) {
            revert Maturity(maturity);
        }
        _mint(t, a);
        return true;
    }

    modifier onlyAdmin(address a) {
        if (msg.sender != a) {
            revert Authorized(a);
        }
        _;
    }
}

// File: Swivel-v4/src/interfaces/IAdapter.sol



pragma solidity 0.8.16;

interface IAdapter {
    function underlying(address) external view returns (address);

    function exchangeRate(address) external view returns (uint256);

    function deposit(address, uint256) external returns (uint256);

    function withdraw(address, uint256) external returns (uint256);
}

// File: Swivel-v4/src/interfaces/IVaultTracker.sol



pragma solidity ^0.8.13;

interface IVaultTracker {
    function addNotional(address, uint256) external returns (bool);

    function removeNotional(address, uint256) external returns (bool);

    function redeemInterest(address) external returns (uint256);

    function matureVault(uint256) external returns (bool);

    function transferNotionalFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transferNotionalFee(address, uint256) external returns (bool);

    function rates() external view returns (uint256, uint256);

    function balancesOf(address) external view returns (uint256, uint256);

    function setAdapter(address) external;

    function adapter() external view returns (address);
}

// File: Swivel-v4/src/VaultTracker.sol



pragma solidity 0.8.16;



contract VaultTracker is IVaultTracker {
    /// @notice A single custom error capable of indicating a wide range of detected errors by providing
    /// an error code value whose string representation is documented <here>, and any possible other values
    /// that are pertinent to the error.
    error Exception(uint8, uint256, uint256, address, address);

    struct Vault {
        uint256 notional;
        uint256 redeemable;
        uint256 exchangeRate;
        uint256 accrualBlock;
    }

    mapping(address => Vault) public vaults;

    address public immutable cTokenAddr;
    address public immutable marketPlace;
    address public immutable swivel;
    uint256 public immutable maturity;
    address public adapter;
    uint256 public maturityRate;
    uint8 public immutable protocol;

    /// @param p Protocol enum value for this vault
    /// @param m Maturity timestamp associated with this vault
    /// @param a Address of the adapter for this market
    /// @param c Compounding Token address associated with this vault
    /// @param s Address of the deployed swivel contract
    /// @param mp Address of the designated admin, which is the Marketplace addess stored by the Creator contract
    constructor(
        uint8 p,
        uint256 m,
        address a,
        address c,
        address s,
        address mp
    ) {
        protocol = p;
        maturity = m;
        cTokenAddr = c;
        swivel = s;
        marketPlace = mp;
        adapter = a;

        // instantiate swivel's vault (unblocking transferNotionalFee)
        vaults[s] = Vault({
            notional: 0,
            redeemable: 0,
            exchangeRate: IAdapter(a).exchangeRate(cTokenAddr),
            accrualBlock: block.number
        });
    }

    /// @notice Adds notional to a given address
    /// @param o Address that owns a vault
    /// @param a Amount of notional added
    function addNotional(
        address o,
        uint256 a
    ) external authorized(marketPlace) returns (bool) {
        Vault memory vlt = vaults[o];

        if (vlt.notional > 0) {
            // If marginal interest has not been calculated up to the current block, calculate marginal interest and update exchangeRate + accrualBlock
            if (vlt.accrualBlock != block.number) {
                // note that mRate is is maturityRate if > 0, exchangeRate otherwise
                (uint256 mRate, uint256 xRate) = rates();
                // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
                // otherwise, calculate marginal exchange rate between current and previous exchange rate.
                uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
                uint256 interest = (yield * (vlt.notional + vlt.redeemable)) /
                    1e26;
                // add interest and amount to position, reset cToken exchange rate
                vlt.redeemable = vlt.redeemable + interest;
                // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
                vlt.exchangeRate = mRate < xRate ? mRate : xRate;
                // set vault's accrual block to the current block
                vlt.accrualBlock = block.number;
            }
            vlt.notional = vlt.notional + a;
        } else {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // set notional
            vlt.notional = a;
            // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
            vlt.exchangeRate = mRate < xRate ? mRate : xRate;
            // set vault's accrual block to the current block
            vlt.accrualBlock = block.number;
        }

        vaults[o] = vlt;

        return true;
    }

    /// @notice Removes notional from a given address
    /// @param o Address that owns a vault
    /// @param a Amount of notional to remove
    function removeNotional(
        address o,
        uint256 a
    ) external authorized(marketPlace) returns (bool) {
        Vault memory vlt = vaults[o];

        if (a > vlt.notional) {
            revert Exception(31, a, vlt.notional, o, address(0));
        }

        if (vlt.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();

            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
            uint256 interest = (yield * (vlt.notional + vlt.redeemable)) / 1e26;
            // remove amount from position, Add interest to position, reset cToken exchange rate
            vlt.redeemable = vlt.redeemable + interest;
            // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
            vlt.exchangeRate = maturityRate < xRate ? mRate : xRate;
            // set vault's accrual block to the current block
            vlt.accrualBlock = block.number;
        }
        vlt.notional = vlt.notional - a;

        vaults[o] = vlt;

        return true;
    }

    /// @notice Redeem's interest accrued by a given address
    /// @param o Address that owns a vault
    function redeemInterest(
        address o
    ) external authorized(marketPlace) returns (uint256) {
        Vault memory vlt = vaults[o];

        uint256 redeemable = vlt.redeemable;

        if (vlt.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();

            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
            uint256 interest = (yield * (vlt.notional + vlt.redeemable)) / 1e26;

            vlt.exchangeRate = mRate < xRate ? mRate : xRate;
            vlt.accrualBlock = block.number;
            // adds marginal interest to previously accrued redeemable interest
            redeemable += interest;
        }
        vlt.redeemable = 0;

        vaults[o] = vlt;

        // returns current redeemable if already accrued, redeemable + interest if not
        return redeemable;
    }

    /// @notice Matures the vault
    /// @param c The current cToken exchange rate
    function matureVault(
        uint256 c
    ) external authorized(marketPlace) returns (bool) {
        maturityRate = c;
        return true;
    }

    /// @notice Transfers notional from one address to another
    /// @param f Owner of the amount
    /// @param t Recipient of the amount
    /// @param a Amount to transfer
    function transferNotionalFrom(
        address f,
        address t,
        uint256 a
    ) external authorized(marketPlace) returns (bool) {
        if (f == t) {
            revert Exception(32, 0, 0, f, t);
        }

        Vault memory from = vaults[f];

        if (a > from.notional) {
            revert Exception(31, a, from.notional, f, t);
        }

        if (from.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / from.exchangeRate) - 1e26;
            uint256 interest = (yield * (from.notional + from.redeemable)) /
                1e26;
            // remove amount from position, Add interest to position, reset cToken exchange rate
            from.redeemable = from.redeemable + interest;
            from.exchangeRate = mRate < xRate ? mRate : xRate;
            from.accrualBlock = block.number;
        }
        from.notional = from.notional - a;
        vaults[f] = from;

        Vault memory to = vaults[t];

        // transfer notional to address "t", calculate interest if necessary
        if (to.notional > 0) {
            // if interest hasnt been calculated within the block, calculate it
            if (from.accrualBlock != block.number) {
                // note that mRate is is maturityRate if > 0, exchangeRate otherwise
                (uint256 mRate, uint256 xRate) = rates();
                uint256 yield = ((mRate * 1e26) / to.exchangeRate) - 1e26;
                uint256 interest = (yield * (to.notional + to.redeemable)) /
                    1e26;
                // add interest and amount to position, reset cToken exchange rate
                to.redeemable = to.redeemable + interest;
                to.exchangeRate = mRate < xRate ? mRate : xRate;
                to.accrualBlock = block.number;
            }
            to.notional = to.notional + a;
        } else {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            to.notional = a;
            to.exchangeRate = mRate < xRate ? mRate : xRate;
            to.accrualBlock = block.number;
        }

        vaults[t] = to;

        return true;
    }

    /// @notice Transfers, in notional, a fee payment to the Swivel contract without recalculating marginal interest for the owner
    /// @param f Owner of the amount
    /// @param a Amount to transfer
    function transferNotionalFee(
        address f,
        uint256 a
    ) external authorized(marketPlace) returns (bool) {
        Vault memory oVault = vaults[f];

        if (a > oVault.notional) {
            revert Exception(31, a, oVault.notional, f, address(0));
        }
        // remove notional from its owner, marginal interest has been calculated already in the tx
        oVault.notional = oVault.notional - a;

        Vault memory sVault = vaults[swivel];

        // check if exchangeRate has been stored already this block. If not, calculate marginal interest + store exchangeRate
        if (sVault.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / sVault.exchangeRate) - 1e26;
            uint256 interest = (yield * (sVault.notional + sVault.redeemable)) /
                1e26;
            // add interest and amount, reset cToken exchange rate
            sVault.redeemable = sVault.redeemable + interest;
            // set to maturityRate only if both > 0 && < exchangeRate
            sVault.exchangeRate = (mRate < xRate) ? mRate : xRate;
            // set current accrual block
            sVault.accrualBlock = block.number;
        }
        // add notional to swivel's vault
        sVault.notional = sVault.notional + a;
        // store the adjusted vaults
        vaults[swivel] = sVault;
        vaults[f] = oVault;
        return true;
    }

    /// @notice Return both the current maturityRate if it's > 0 (or exchangeRate in its place) and the Compounding exchange rate
    /// @dev While it may seem unnecessarily redundant to return the exchangeRate twice, it prevents many kludges that would otherwise be necessary to guard it
    /// @return maturityRate, exchangeRate if maturityRate > 0, exchangeRate, exchangeRate if not.
    function rates() public view returns (uint256, uint256) {
        uint256 exchangeRate = IAdapter(adapter).exchangeRate(cTokenAddr);
        return ((maturityRate > 0 ? maturityRate : exchangeRate), exchangeRate);
    }

    /// @notice Returns both relevant balances for a given user's vault
    /// @param o Address that owns a vault
    function balancesOf(address o) external view returns (uint256, uint256) {
        Vault memory vault = vaults[o];
        return (vault.notional, vault.redeemable);
    }

    /// @notice Allows the marketplace to set a new adapter for the market
    /// @param a Address of a new adapter contract
    function setAdapter(address a) external authorized(marketPlace) {
        adapter = a;
    }

    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }
}

// File: Swivel-v4/src/Creator.sol



pragma solidity 0.8.16;




contract Creator is ICreator {
    /// @dev A single custom error capable of indicating a wide range of detected errors by providing
    /// an error code value whose string representation is documented <here>, and any possible other values
    /// that are pertinent to the error.
    error Exception(uint8, uint256, uint256, address, address);

    address public admin;
    address public marketPlace;

    event SetAdmin(address indexed admin);

    constructor() {
        admin = msg.sender;
    }

    /// @notice Allows the owner to create new markets
    /// @param p Protocol associated with the new market
    /// @param u Underlying token associated with the new market
    /// @param m Maturity timestamp of the new market
    /// @param a Adapter address of the new market
    /// @param c Compounding Token address associated with the new market
    /// @param sw Address of the deployed swivel contract
    /// @param n Name of the new market zcToken
    /// @param s Symbol of the new market zcToken
    /// @param d Decimals of the new market zcToken
    function create(
        uint8 p,
        address u,
        uint256 m,
        address a,
        address c,
        address sw,
        string calldata n,
        string calldata s,
        uint8 d
    ) external authorized(marketPlace) returns (address, address) {
        if (marketPlace == address(0)) {
            revert Exception(34, 0, 0, marketPlace, address(0));
        }

        address zct = address(new ZcToken(p, u, m, c, marketPlace, n, s, d));
        address tracker = address(
            new VaultTracker(p, m, a, c, sw, marketPlace)
        );

        return (zct, tracker);
    }

    /// @param a Address of a new admin
    function setAdmin(address a) external authorized(admin) returns (bool) {
        admin = a;

        emit SetAdmin(a);

        return true;
    }

    /// @param m Address of the deployed marketPlace contract
    /// @notice We only allow this to be set once
    /// @dev there is no emit here as it's only done once post deploy by the deploying admin
    function setMarketPlace(
        address m
    ) external authorized(admin) returns (bool) {
        if (marketPlace != address(0)) {
            revert Exception(33, 0, 0, marketPlace, address(0));
        }

        marketPlace = m;
        return true;
    }

    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }
}