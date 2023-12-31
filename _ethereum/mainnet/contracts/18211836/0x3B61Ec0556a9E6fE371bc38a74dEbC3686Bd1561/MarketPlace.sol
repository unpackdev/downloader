// File: Swivel-v4/src/interfaces/IERC20.sol



pragma solidity ^0.8.13;

// methods requried on other contracts which are expected to, at least, implement the following:
interface IERC20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function transferFrom(address, address, uint256) external returns (bool);

    function decimals() external returns (uint8);
}

// File: Swivel-v4/src/interfaces/IAdapter.sol



pragma solidity 0.8.16;

interface IAdapter {
    function underlying(address) external view returns (address);

    function exchangeRate(address) external view returns (uint256);

    function deposit(address, uint256) external returns (uint256);

    function withdraw(address, uint256) external returns (uint256);
}

// File: Swivel-v4/src/interfaces/IZcToken.sol



pragma solidity ^0.8.13;

interface IZcToken {
    function mint(address, uint256) external returns (bool);

    function burn(address, uint256) external returns (bool);
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

// File: Swivel-v4/src/lib/Sig.sol



pragma solidity ^0.8.13;

library Sig {
    /// @dev ECDSA V,R and S components encapsulated here as we may not always be able to accept a bytes signature
    struct Components {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    error S();
    error V();
    error Length();
    error ZeroAddress();

    /// @param h Hashed data which was originally signed
    /// @param c signature struct containing V,R and S
    /// @return The recovered address
    function recover(
        bytes32 h,
        Components calldata c
    ) internal pure returns (address) {
        // EIP-2 and malleable signatures...
        // see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
        if (
            uint256(c.s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert S();
        }

        if (c.v != 27 && c.v != 28) {
            revert V();
        }

        address recovered = ecrecover(h, c.v, c.r, c.s);

        if (recovered == address(0)) {
            revert ZeroAddress();
        }

        return recovered;
    }

    /// @param sig Valid ECDSA signature
    /// @return v The verification bit
    /// @return r First 32 bytes
    /// @return s Next 32 bytes
    function split(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        if (sig.length != 65) {
            revert Length();
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}

// File: Swivel-v4/src/lib/Hash.sol



pragma solidity ^0.8.13;

/**
  @notice Encapsulation of the logic to produce EIP712 hashed domain and messages.
  Also to produce / verify hashed and signed Orders.
  See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
  See/attribute https://github.com/0xProject/0x-monorepo/blob/development/contracts/utils/contracts/src/LibEIP712.sol
*/

library Hash {
    /// @dev struct represents the attributes of an offchain Swivel.Order
    struct Order {
        bytes32 key;
        uint8 protocol;
        address maker;
        address underlying;
        bool vault;
        bool exit;
        uint256 principal;
        uint256 premium;
        uint256 maturity;
        uint256 expiry;
    }

    // EIP712 Domain Separator typeHash
    // keccak256(abi.encodePacked(
    //     'EIP712Domain(',
    //     'string name,',
    //     'string version,',
    //     'uint256 chainId,',
    //     'address verifyingContract',
    //     ')'
    // ));
    bytes32 internal constant DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // EIP712 typeHash of an Order
    // keccak256(abi.encodePacked(
    //     'Order(',
    //     'bytes32 key,',
    //     'uint8 protocol,',
    //     'address maker,',
    //     'address underlying,',
    //     'bool vault,',
    //     'bool exit,',
    //     'uint256 principal,',
    //     'uint256 premium,',
    //     'uint256 maturity,',
    //     'uint256 expiry',
    //     ')'
    // ));
    bytes32 internal constant ORDER_TYPEHASH =
        0xbc200cfe92556575f801f821f26e6d54f6421fa132e4b2d65319cac1c687d8e6;

    /// @param n EIP712 domain name
    /// @param version EIP712 semantic version string
    /// @param i Chain ID
    /// @param verifier address of the verifying contract
    function domain(
        string memory n,
        string memory version,
        uint256 i,
        address verifier
    ) internal pure returns (bytes32) {
        bytes32 hash;

        assembly {
            let nameHash := keccak256(add(n, 32), mload(n))
            let versionHash := keccak256(add(version, 32), mload(version))
            let pointer := mload(64)
            mstore(pointer, DOMAIN_TYPEHASH)
            mstore(add(pointer, 32), nameHash)
            mstore(add(pointer, 64), versionHash)
            mstore(add(pointer, 96), i)
            mstore(add(pointer, 128), verifier)
            hash := keccak256(pointer, 160)
        }

        return hash;
    }

    /// @param d Type hash of the domain separator (see Hash.domain)
    /// @param h EIP712 hash struct (order for example)
    function message(bytes32 d, bytes32 h) internal pure returns (bytes32) {
        bytes32 hash;

        assembly {
            let pointer := mload(64)
            mstore(
                pointer,
                0x1901000000000000000000000000000000000000000000000000000000000000
            )
            mstore(add(pointer, 2), d)
            mstore(add(pointer, 34), h)
            hash := keccak256(pointer, 66)
        }

        return hash;
    }

    /// @param o A Swivel Order
    function order(Order calldata o) internal pure returns (bytes32) {
        // TODO assembly
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    o.key,
                    o.protocol,
                    o.maker,
                    o.underlying,
                    o.vault,
                    o.exit,
                    o.principal,
                    o.premium,
                    o.maturity,
                    o.expiry
                )
            );
    }
}

// File: Swivel-v4/src/interfaces/ISwivel.sol



pragma solidity ^0.8.13;



// the behavioral Swivel Interface, Implemented by Swivel.sol
interface ISwivel {
    function initiate(
        Hash.Order[] calldata,
        uint256[] calldata,
        Sig.Components[] calldata
    ) external returns (bool);

    function exit(
        Hash.Order[] calldata,
        uint256[] calldata,
        Sig.Components[] calldata
    ) external returns (bool);

    function cancel(Hash.Order[] calldata) external returns (bool);

    function setAdmin(address) external returns (bool);

    function scheduleWithdrawal(address) external returns (bool);

    function scheduleFeeChange(uint16[4] calldata) external returns (bool);

    function blockWithdrawal(address) external returns (bool);

    function blockFeeChange() external returns (bool);

    function withdrawFunds(address) external returns (bool);

    function changeFee(uint16[4] calldata) external returns (bool);

    function approveUnderlying(
        address[] calldata,
        address[] calldata
    ) external returns (bool);

    function splitUnderlying(
        uint8,
        address,
        uint256,
        uint256
    ) external returns (bool);

    function combineTokens(
        uint8,
        address,
        uint256,
        uint256
    ) external returns (bool);

    function authRedeem(
        address,
        address,
        address,
        address,
        uint256
    ) external returns (bool);

    function authApprove(
        address,
        address
    ) external returns (uint256);

    function redeemZcToken(
        uint8,
        address,
        uint256,
        uint256
    ) external returns (bool);

    function redeemVaultInterest(
        uint8,
        address,
        uint256
    ) external returns (bool);

    function redeemSwivelVaultInterest(
        uint8,
        address,
        uint256
    ) external returns (bool);
}

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

// File: Swivel-v4/src/interfaces/IMarketPlace.sol



pragma solidity ^0.8.13;

interface IMarketPlace {
    function setSwivel(address) external returns (bool);

    function setAdmin(address) external returns (bool);

    function createMarket(
        uint8,
        uint256,
        address,
        address,
        string memory,
        string memory
    ) external returns (bool);

    function matureMarket(uint8, address, uint256) external returns (bool);

    function authRedeem(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (uint256);

    function rates(uint8, address, uint256) external returns (uint256, uint256);

    function transferVaultNotional(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (bool);

    // adds notional and mints zctokens
    function mintZcTokenAddingNotional(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (bool);

    // removes notional and burns zctokens
    function burnZcTokenRemovingNotional(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (bool);

    // returns the amount of underlying principal to send
    function redeemZcToken(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (uint256);

    // returns the amount of underlying interest to send
    function redeemVaultInterest(
        uint8,
        address,
        uint256,
        address
    ) external returns (uint256);

    // returns the cToken address for a given market
    function cTokenAddress(uint8, address, uint256) external returns (address);

    // returns the adapter address for a given market
    function adapterAddress(uint8, address, uint256) external returns (address);

    // EVFZE FF EZFVE call this which would then burn zctoken and remove notional
    function custodialExit(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (bool);

    // IVFZI && IZFVI call this which would then mint zctoken and add notional
    function custodialInitiate(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (bool);

    // IZFZE && EZFZI call this, tranferring zctoken from one party to another
    function p2pZcTokenExchange(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (bool);

    // IVFVE && EVFVI call this, removing notional from one party and adding to the other
    function p2pVaultExchange(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (bool);

    // IVFZI && IVFVE call this which then transfers notional from msg.sender (taker) to swivel
    function transferVaultNotionalFee(
        uint8,
        address,
        uint256,
        address,
        uint256
    ) external returns (bool);
}

// File: Swivel-v4/src/MarketPlace.sol



pragma solidity 0.8.16;








contract MarketPlace is IMarketPlace {
    /// @dev A single custom error capable of indicating a wide range of detected errors by providing
    /// an error code value whose string representation is documented <here>, and any possible other values
    /// that are pertinent to the error.
    error Exception(uint8, uint256, uint256, address, address);

    struct Market {
        address adapter;
        address cTokenAddr;
        address zcToken;
        address vaultTracker;
        uint256 maturityRate;
    }

    mapping(uint8 => mapping(address => mapping(uint256 => Market)))
        public markets;
    mapping(uint8 => bool) public paused;

    address public admin;
    address public swivel;
    address public immutable creator;

    event Create(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address cToken,
        address zcToken,
        address vaultTracker
    );
    event Mature(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        uint256 maturityRate,
        uint256 matured
    );
    event RedeemZcToken(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address sender,
        uint256 amount
    );
    event RedeemVaultInterest(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address sender
    );
    event CustodialInitiate(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address zcTarget,
        address nTarget,
        uint256 amount
    );
    event CustodialExit(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address zcTarget,
        address nTarget,
        uint256 amount
    );
    event P2pZcTokenExchange(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address from,
        address to,
        uint256 amount
    );
    event P2pVaultExchange(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address from,
        address to,
        uint256 amount
    );
    event TransferVaultNotional(
        uint8 indexed protocol,
        address indexed underlying,
        uint256 indexed maturity,
        address from,
        address to,
        uint256 amount
    );
    event SetAdmin(address indexed admin);
    event SetAdapter(
        address indexed underlying,
        uint256 indexed maturity,
        address indexed adapter
    );

    /// @param c Address of the deployed creator contract
    constructor(address c) {
        admin = msg.sender;
        creator = c;
    }

    /// @param s Address of the deployed swivel contract
    /// @notice We only allow this to be set once
    /// @dev there is no emit here as it's only done once post deploy by the deploying admin
    function setSwivel(address s) external authorized(admin) returns (bool) {
        if (swivel != address(0)) {
            revert Exception(20, 0, 0, swivel, address(0));
        }

        swivel = s;
        return true;
    }

    /// @param a Address of a new admin
    function setAdmin(address a) external authorized(admin) returns (bool) {
        admin = a;

        emit SetAdmin(a);

        return true;
    }

    /// Should execute after the creation of a market to ensure the vaultTracker exists first
    /// @param u Underlying address of a given market
    /// @param m Maturity of a given market
    /// @param p Protocol enum value of a given market
    /// @param a Address of a new adapter
    function setAdapter(
        address u,
        uint256 m,
        uint8 p,
        address a
    ) external authorized(admin) returns (bool) {
        // Update the market
        markets[p][u][m].adapter = a;

        // Update the adapter in the vault tracker
        IVaultTracker(markets[p][u][m].vaultTracker).setAdapter(a);

        emit SetAdapter(u, m, a);
        return true;
    }

    /// @notice Allows the owner to create new markets
    /// @param p Protocol associated with the new market
    /// @param m Maturity timestamp of the new market
    /// @param c Compounding Token address associated with the new market
    /// @param a Satallite contract responsible for executing protocol specific transactions
    /// @param n Name of the new market zcToken
    /// @dev the memory allocation of `s` is for alleviating STD err, there's no clearly superior scoping or abstracting alternative.
    /// @param s Symbol of the new market zcToken
    function createMarket(
        uint8 p,
        uint256 m,
        address c,
        address a,
        string memory n,
        string memory s
    ) external authorized(admin) unpaused(p) returns (bool) {
        if (swivel == address(0)) {
            revert Exception(21, 0, 0, address(0), address(0));
        }

        address underlying = IAdapter(a).underlying(c);

        if (markets[p][underlying][m].vaultTracker != address(0)) {
            // NOTE: not saving and publishing that found tracker addr as stack limitations...
            revert Exception(22, 0, 0, address(0), address(0));
        }

        (address zct, address tracker) = ICreator(creator).create(
            p,
            underlying,
            m,
            a,
            c,
            swivel,
            n,
            s,
            IERC20(underlying).decimals()
        );

        ISwivel(swivel).authApprove(underlying, c);

        markets[p][underlying][m] = Market(a, c, zct, tracker, 0);

        emit Create(p, underlying, m, c, zct, tracker);

        return true;
    }

    /// @notice Can be called after maturity, allowing all of the zcTokens to earn floating interest on Compound until they release their funds
    /// @param p Protocol Enum value associated with the market being matured
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    function matureMarket(
        uint8 p,
        address u,
        uint256 m
    ) public unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];

        if (market.maturityRate != 0) {
            revert Exception(
                23,
                market.maturityRate,
                0,
                address(0),
                address(0)
            );
        }

        if (block.timestamp < m) {
            revert Exception(24, block.timestamp, m, address(0), address(0));
        }

        // set the base maturity cToken exchange rate at maturity to the current cToken exchange rate
        uint256 xRate = IAdapter(market.adapter).exchangeRate(
            market.cTokenAddr
        );
        markets[p][u][m].maturityRate = xRate;

        // NOTE we don't check the return of this simple operation
        IVaultTracker(market.vaultTracker).matureVault(xRate);

        emit Mature(p, u, m, xRate, block.timestamp);

        return true;
    }

    /// @notice Allows Swivel caller to deposit their underlying, in the process splitting it - minting both zcTokens and vault notional.
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Address of the depositing user
    /// @param a Amount of notional being added
    function mintZcTokenAddingNotional(
        uint8 p,
        address u,
        uint256 m,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];

        if (!IZcToken(market.zcToken).mint(t, a)) {
            revert Exception(28, 0, 0, address(0), address(0));
        }

        if (!IVaultTracker(market.vaultTracker).addNotional(t, a)) {
            revert Exception(25, 0, 0, address(0), address(0));
        }

        return true;
    }

    /// @notice Allows Swivel caller to deposit/burn both zcTokens + vault notional. This process is "combining" the two and redeeming underlying.
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Address of the combining/redeeming user
    /// @param a Amount of zcTokens being burned
    function burnZcTokenRemovingNotional(
        uint8 p,
        address u,
        uint256 m,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];

        if (!IZcToken(market.zcToken).burn(t, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        if (!IVaultTracker(market.vaultTracker).removeNotional(t, a)) {
            revert Exception(26, 0, 0, address(0), address(0));
        }

        return true;
    }

    /// @notice Implementation of authRedeem to fulfill the IRedeemer interface for ERC5095
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param f Address of the user having their zcTokens burned
    /// @param t Address of the user receiving underlying
    /// @param a Amount of zcTokens being redeemed
    /// @return Amount of underlying being withdrawn (needed for 5095 return)
    function authRedeem(
        uint8 p,
        address u,
        uint256 m,
        address f,
        address t,
        uint256 a
    )
        external
        authorized(markets[p][u][m].zcToken)
        unpaused(p)
        returns (uint256)
    {
        /// @dev swiv needs to be set or the call to authRedeem there will be faulty
        if (swivel == address(0)) {
            revert Exception(21, 0, 0, address(0), address(0));
        }

        Market memory market = markets[p][u][m];
        // if the market has not matured, mature it...
        if (market.maturityRate == 0) {
            if (!matureMarket(p, u, m)) {
                revert Exception(30, 0, 0, address(0), address(0));
            }
        }

        if (!IZcToken(market.zcToken).burn(f, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        // depending on initial market maturity status adjust (or don't) the amount to be redemmed/returned
        uint256 amount = market.maturityRate == 0
            ? a
            : calculateReturn(p, u, m, a);

        if (
            !ISwivel(swivel).authRedeem(
                u,
                market.cTokenAddr,
                market.adapter,
                t,
                amount
            )
        ) {
            revert Exception(37, amount, 0, market.cTokenAddr, t);
        }

        emit RedeemZcToken(p, u, m, t, amount);

        return amount;
    }

    /// @notice Allows (via swivel) zcToken holders to redeem their tokens for underlying tokens after maturity has been reached.
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Address of the redeeming user
    /// @param a Amount of zcTokens being redeemed
    function redeemZcToken(
        uint8 p,
        address u,
        uint256 m,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (uint256) {
        Market memory market = markets[p][u][m];

        // if the market has not matured, mature it and redeem exactly the amount
        if (market.maturityRate == 0) {
            if (!matureMarket(p, u, m)) {
                revert Exception(30, 0, 0, address(0), address(0));
            }
        }

        if (!IZcToken(market.zcToken).burn(t, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        emit RedeemZcToken(p, u, m, t, a);

        if (market.maturityRate == 0) {
            return a;
        } else {
            // if the market was already mature the return should include the amount + marginal floating interest generated on Compound since maturity
            return calculateReturn(p, u, m, a);
        }
    }

    /// @notice Allows Vault owners (via Swivel) to redeem any currently accrued interest
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Address of the redeeming user
    function redeemVaultInterest(
        uint8 p,
        address u,
        uint256 m,
        address t
    ) external authorized(swivel) unpaused(p) returns (uint256) {
        // call to the floating market contract to release the position and calculate the interest generated
        uint256 interest = IVaultTracker(markets[p][u][m].vaultTracker)
            .redeemInterest(t);

        // if the market has not matured, mature it and redeem exactly the amount
        if (block.timestamp > m && markets[p][u][m].maturityRate == 0) {
            if (!matureMarket(p, u, m)) {
                revert Exception(30, 0, 0, address(0), address(0));
            }
        }

        emit RedeemVaultInterest(p, u, m, t);

        return interest;
    }

    /// @notice Calculates the total amount of underlying returned including interest generated since the `matureMarket` function has been called
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param a Amount of zcTokens being redeemed
    function calculateReturn(
        uint8 p,
        address u,
        uint256 m,
        uint256 a
    ) internal returns (uint256) {
        Market memory market = markets[p][u][m];

        uint256 xRate = IAdapter(market.adapter).exchangeRate(
            market.cTokenAddr
        );

        return (a * xRate) / market.maturityRate;
    }

    /// @notice Return the compounding token address for a given market
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    function cTokenAddress(
        uint8 p,
        address u,
        uint256 m
    ) external view returns (address) {
        return markets[p][u][m].cTokenAddr;
    }

    /// @notice Return the adapter address for a given market
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    function adapterAddress(
        uint8 p,
        address u,
        uint256 m
    ) external view returns (address) {
        return markets[p][u][m].adapter;
    }

    /// @notice Return current rates (maturity, exchange) for a given vault. See VaultTracker.rates for details
    /// @dev While it's true that Compounding exchange rate is not strictly affiliated with a vault, the 2 data points are usually needed together.
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @return maturityRate, exchangeRate*
    function rates(
        uint8 p,
        address u,
        uint256 m
    ) external view returns (uint256, uint256) {
        return IVaultTracker(markets[p][u][m].vaultTracker).rates();
    }

    /// @notice Called by swivel IVFZI && IZFVI
    /// @dev Call with protocol, underlying, maturity, mint-target, add-notional-target and an amount
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param z Recipient of the minted zcToken
    /// @param n Recipient of the added notional
    /// @param a Amount of zcToken minted and notional added
    function custodialInitiate(
        uint8 p,
        address u,
        uint256 m,
        address z,
        address n,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];
        if (!IZcToken(market.zcToken).mint(z, a)) {
            revert Exception(28, 0, 0, address(0), address(0));
        }

        if (!IVaultTracker(market.vaultTracker).addNotional(n, a)) {
            revert Exception(25, 0, 0, address(0), address(0));
        }

        emit CustodialInitiate(p, u, m, z, n, a);
        return true;
    }

    /// @notice Called by swivel EVFZE FF EZFVE
    /// @dev Call with protocol, underlying, maturity, burn-target, remove-notional-target and an amount
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param z Owner of the zcToken to be burned
    /// @param n Target to remove notional from
    /// @param a Amount of zcToken burned and notional removed
    function custodialExit(
        uint8 p,
        address u,
        uint256 m,
        address z,
        address n,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        Market memory market = markets[p][u][m];
        if (!IZcToken(market.zcToken).burn(z, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        if (!IVaultTracker(market.vaultTracker).removeNotional(n, a)) {
            revert Exception(26, 0, 0, address(0), address(0));
        }

        emit CustodialExit(p, u, m, z, n, a);
        return true;
    }

    /// @notice Called by swivel IZFZE, EZFZI
    /// @dev Call with underlying, maturity, transfer-from, transfer-to, amount
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param f Owner of the zcToken to be burned
    /// @param t Target to be minted to
    /// @param a Amount of zcToken transfer
    function p2pZcTokenExchange(
        uint8 p,
        address u,
        uint256 m,
        address f,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        address zct = markets[p][u][m].zcToken;

        if (!IZcToken(zct).burn(f, a)) {
            revert Exception(29, 0, 0, address(0), address(0));
        }

        if (!IZcToken(zct).mint(t, a)) {
            revert Exception(28, 0, 0, address(0), address(0));
        }

        emit P2pZcTokenExchange(p, u, m, f, t, a);
        return true;
    }

    /// @notice Called by swivel IVFVE, EVFVI
    /// @dev Call with protocol, underlying, maturity, remove-from, add-to, amount
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param f Owner of the notional to be transferred
    /// @param t Target to be transferred to
    /// @param a Amount of notional transfer
    function p2pVaultExchange(
        uint8 p,
        address u,
        uint256 m,
        address f,
        address t,
        uint256 a
    ) external authorized(swivel) unpaused(p) returns (bool) {
        if (
            !IVaultTracker(markets[p][u][m].vaultTracker).transferNotionalFrom(
                f,
                t,
                a
            )
        ) {
            revert Exception(27, 0, 0, address(0), address(0));
        }

        emit P2pVaultExchange(p, u, m, f, t, a);
        return true;
    }

    /// @notice External method giving access to this functionality within a given vault
    /// @dev Note that this method calculates yield and interest as well
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param t Target to be transferred to
    /// @param a Amount of notional to be transferred
    function transferVaultNotional(
        uint8 p,
        address u,
        uint256 m,
        address t,
        uint256 a
    ) external unpaused(p) returns (bool) {
        if (
            !IVaultTracker(markets[p][u][m].vaultTracker).transferNotionalFrom(
                msg.sender,
                t,
                a
            )
        ) {
            revert Exception(27, 0, 0, address(0), address(0));
        }

        emit TransferVaultNotional(p, u, m, msg.sender, t, a);
        return true;
    }

    /// @notice Transfers notional fee to the Swivel contract without recalculating marginal interest for from
    /// @param p Protocol Enum value associated with this market
    /// @param u Underlying token address associated with the market
    /// @param m Maturity timestamp of the market
    /// @param f Owner of the amount
    /// @param a Amount to transfer
    function transferVaultNotionalFee(
        uint8 p,
        address u,
        uint256 m,
        address f,
        uint256 a
    ) external authorized(swivel) returns (bool) {
        return
            IVaultTracker(markets[p][u][m].vaultTracker).transferNotionalFee(
                f,
                a
            );
    }

    /// @notice Called by admin at any point to pause / unpause market transactions in a specified protocol
    /// @param p Protocol Enum value of the protocol to be paused
    /// @param b Boolean which indicates the (protocol) markets paused status
    function pause(uint8 p, bool b) external authorized(admin) returns (bool) {
        paused[p] = b;
        return true;
    }

    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }

    modifier unpaused(uint8 p) {
        if (paused[p]) {
            revert Exception(1, 0, 0, address(0), address(0));
        }
        _;
    }
}