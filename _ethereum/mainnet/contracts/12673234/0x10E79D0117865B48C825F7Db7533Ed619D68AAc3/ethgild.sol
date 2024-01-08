// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

// Chainlink imports.
import "./AggregatorV3Interface.sol";

// Open Zeppelin imports.
import "./SafeCast.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC1155.sol";

/// @title EthGild
/// @author thedavidmeister
///
/// ## Purpose
///
/// Gild: to cover with gold.
///
/// A wrapped token that wraps/unwraps according to the reference price of gold in ETH.
///
/// Similar to wrapped eth (WETH).
/// WETH "wraps" ETH 1:1 with an erc20 token that can be unwrapped to get the original ETH back.
/// GildEth (ETHg) wraps (gilds) ETH with an erc20 token at the current reference gold price that can be unwrapped to get the original ETH back.
/// The gilding is represented as an NFT (erc1155) owned by the gilder.
/// The NFT owner can ungild ETHg back to ETH at the same rate the ETHg was minted at for that NFT.
/// 0.1% additional ETHg must be burned when it is ungilded (overburn).
/// The overburn locks a tiny sliver of ETH in each gilding to help support growth of an organic ETHg community.
/// Anyone who wants to ungild all their ETH must first acquire a small amount of additional ETHg from a fellow gilder.
/// The heaviest stress on ETHg will likely occur during rapid ETH market price spike and crash cycles.
/// We should expect large amounts of ETHg to be minted by skittish ETH hodlers each time ETH nears an ATH or similar.
/// As the market price of ETH crashes with large new ETHg supply, there will be a lot of pressure on ETHg, likely short term chaos.
/// As (un)gild cycles continue the overburn will soak up some ETHg glut in the medium term.
/// The overburn means that a "bank run" on ETHg will force the market price upward towards the current reference gold price, incentivising new gildings.
/// Long term the steady cumulative increase of locked ETH in the system will cushion future shocks to the ETHg market price.
/// 0.1% is somewhat arbitrary but is intended to be competetive with typical onchain DEX trades that include fee % + slippage + gas.
/// The goal is for the target audience to find it more compelling to wrap ETH to ETHg than trade their ETH away for stablecoins.
///
/// ## Comparison to stablecoins
///
/// EthGild is NOT a stablecoin.
///
/// The primary goal of a stablecoin is to mimic the price of some external "stable" asset.
/// The primary goal of ETHg is to mitigate some of the short-mid term risks associated with holding ETH while maintaining the long term "owner" relationship to the gilded ETH.
///
/// The (un)gild process is designed to constrain gold denominated price movements on ETHg through market forces but there is no explicit peg.
///
/// There are a few key issues that ETH holders face when interacting with stablecoins:
/// - Stablecoins typically denominated in fiat, which inevitably introduces counterparty risk from the fiat issuer
/// - Stablecoins with a fixed peg are either "algorithmic" (undercollateralised) or heavily overcollateralized
///   - The former is a severe case of "works until it doesn't" where a single catastrophic bank run can instantly wipe out the system (e.g. $2 billion wiped out overnight by Titan/Iron)
///   - The latter requires complex mechanisms such as liquidations, custody, DAOs etc. to eternally manage the collateral against the peg (e.g. DAI, USDC)
/// - Moving from ETH to a stablecoin typically means risk of losing ETH, whether you trade it in or borrow against it
///   - If you trade away your ETH then you trigger a taxable event in many jurisdictions, and risk the market moving against you while you use the stablecoin for short term costs, such that you can never buy your ETH back later
///   - If you borrow against your ETH then you face constant liquidation threat, if the market drops sharply for even one hour you can have your ETH taken from you forever
///   - Trades can be front-run and suffer slippage, loan liquidations can cascade and need to be defended even during periods of super-high (500+ gwei) network fees
///
/// EthGild aims to address these concerns in a few ways:
/// - There is no explicit peg and ETHg ranging anywhere from 0-1x the current gold price should be considered normal
///   - Removing rigid expectations from the system should mitigate certain psychological factors that manifest as sudden price shocks and panics
///   - There is no need to actively manage the system if there is no peg to maintain and every ETHg gilded is overcollateralised by design
/// - Gilding/ungilding ETH maintains the gilder's control on their ETH for as long as they hold the erc1155 and can acquire sufficient ETHg to ungild
/// - Gilding/ungilding based on the gold price denominated in ETH decouples the system from counterparty risk as much as possible
///   - Physical gold and by extension the gold price does not derive its value from any specific authority and has well established, global liquid markets
///   - Of course we now rely on the chain link oracle, this is a tradeoff users will have to decide for themselves to accept
/// - The overburn mechanism ensures that bank runs on the underlying asset bring the ETHg price _closer_ to the reference gold price
/// - ETH collateral is never liquidated, the worst case scenario for the erc1155 holder is that they ungild the underlying ETH at the current reference gold price
/// - Gilding/ungilding itself cannot be front-run and there is no slippage because the only inputs are the reference price and your own ETH
/// - EthGild is very simple, the whole system runs off 2x unmodified Open Zeppelin contracts, 1x oracle and 2x functions, `gild` and `ungild`
///
/// ## Implementation
///
/// EthGild is both an erc1155 and erc20.
/// All token behaviour is default Open Zeppelin.
/// This works because none of the function names collide, or if they do the signature overloads cleanly (e.g. `_mint`).
///
/// ## Gilding
///
/// Call the payable `gild` function with an ETH `value` to be gilded.
/// The "reference price" is source from Chainlink oracle for internal calculations, nothing is actually bought/sold/traded in a gild.
/// The erc1155 is minted as the current reference price in ETH as its id, and the reference price multiplied by ETH locked as amount (18 decimals).
/// The ETHg erc20 is minted as the reference price multiplied by ETH locked as amount (18 decimals).
/// The ETH amount is calculated as the `msg.value` sent to the EthGild contract (excludes gas).
///
/// ## Ungilding
///
/// The erc1155 id (reference price) and amount of ETH to ungild must be specified to the `ungild` function.
/// The erc1155 under the reference price id is burned as ETH being ungild multiplied by the reference price.
/// The ETHg erc20 is burned as 1001/1000 times the erc1155 burn.
/// The ETH amount is sent to `msg.sender` (excludes gas).
///
/// ## Reentrancy
///
/// The erc20 minting and all burning is not reentrant but the erc1155 mint _is_ reentrant.
/// Both `gild` and `ungild` end with reentrant calls to the `msg.sender`.
/// `gild` will attempt to treat the `msg.sender` as an `IERC1155Receiver`.
/// `ungild` will call the sender's `receive` function when it sends the ungilded ETH.
/// This is safe for the EthGild contract state as the reentrant calls are last and allowed to facilitate creative use-cases.
///
/// ## Tokenomics
///
/// - Market price pressure above reference price of 1 ounce of gold.
///   - Exceeding this allows anyone to gild 1 ETH, sell minted ETHg, buy more than 1 ETH, repeat infinitely.
/// - Market price pressure below max recent ETH drawdown.
///   - Exceeding this allows all gilded eth to be ungilded on a market buy of ETHg cheaper than the gilded ETH backing it.
/// - Ranging between two (dynamic) limits.
///   - Gild when market is high to leverage ETH without liquidation threat.
///   - Buy low to anticipate upward "bank runs".
///   - Use in range as less-volatile proxy to underlying ETH value.
///   - Use in range for LP on AMM with low IL.
///     - Pair with other gold tokens knowing that ETHg is bounded by gold reference price.
///     - IL is credibly impermanent, or at least mitigated.
///     - All liquidity on AMM is locking ETH in the bonding curve so more liquidity implies tighter market (virtuous cycle).
///     - Should always be baseline supply/demand from leveraging use-case.
///     - Overburn should always tighten the price range as cumulative (un)gild volume builds over time.
///     - The more ETHg is used outside of the (un)gild process, the more underyling ETH is locked
///
/// ## Administration
///
/// - Contract has NO owner or other administrative functions.
/// - Contract has NO upgrades.
/// - There is NO peg.
/// - There is NO DAO.
/// - There are NO liquidations.
/// - There is NO collateralisation ratio.
/// - ETHg is increasingly overcollateralised due to overburn.
/// - There is NO WARRANTY and the code is PUBLIC DOMAIN (read the UNLICENSE).
/// - The tokenomics are hypothetical, have zero empirical evidence (yet) and are certainly NOT FINANCIAL ADVICE.
/// - If this contract is EXPLOITED or contains BUGS
///   - There is NO support or compensation.
///   - There MAY be a NEW contract deployed without the exploit/bug but I am not obligated to engineer or deploy any specific fix.
/// - Please feel welcome to build on top of this as a primitive (read the UNLICENSE).
///
/// ## Smart contract risk
///
/// Every smart contract has significant "unknown risks".
/// This contract may suffer unforeseen bugs or exploits.
/// These bugs or exploits may result in partial or complete loss of your funds if you choose to use it.
/// These bugs or exploits may only manifest when combined with onchain factors that do not exist and cannot be predicted today.
/// For example, consider the innovation of flash loans and the implications to all existing contracts.
/// Audits and other professional reviews will be conducted over time if and when TVL justifies it.
/// Ultimately, the only useful measure of risk is `total value locked x time` which cannot be measured in advance.
///
/// ## Oracle risk
///
/// The Chainlink oracles could cease to function or report incorrect data.
/// As EthGild is not targetting a strict peg or actively liquidating participants, there is some tolerance for temporarily incorrect data.
/// However, if the reference price is significantly wrong for an extended period of time this does harm the system, up to and including existential risk.
/// As there are no administrative functions for EthGild, there is no ability to change the oracle data source after deployment.
/// Changing the oracle means deploying an entirely new contract with NO MIGRATION PATH.
/// You should NOT use this contract unless you have confidence in the Chainlink oracle to maintain price feeds for as long as you hold either the erc20 or erc1155.
/// The Chainlink oracle contracts themselves are proxy contracts, which means that the owner (Chainlink) can modify the data source over time.
/// This is great as it means that data should be available even as they iterate on their contracts, as long as they support backwards compatibility for `AggregatorV3Interface`.
/// This also means that EthGild can never be more secure than Chainlink itself, if their oracles are damaged somehow then EthGild suffers too.
contract EthGild is ERC1155, ERC20 {
    // Chainlink oracles are signed integers so we need to handle them as unsigned.
    using SafeCast for int256;
    using SafeMath for uint256;

    /// @param caller the address gilding ETH.
    /// @param xauReferencePrice the reference XAU price the ETH was gilded at.
    /// @param ethAmount the amount of ETH gilded.
    event Gild(
        address indexed caller,
        uint256 indexed xauReferencePrice,
        uint256 indexed ethAmount
    );
    /// @param caller the address ungilding ETH.
    /// @param xauReferencePrice the reference XAU price the ETH is ungilded at.
    /// @param ethAmount the amount of ETH ungilded.
    event Ungild(
        address indexed caller,
        uint256 indexed xauReferencePrice,
        uint256 indexed ethAmount
    );

    /// erc20 name.
    string public constant NAME = "EthGild";
    /// erc20 symbol.
    string public constant SYMBOL = "ETHg";
    /// erc1155 uri.
    /// Note the erc1155 id is simply the reference XAU price at which ETHg tokens can burn against to unlock ETH.
    string public constant GILD_URI = "https://ethgild.crypto/#/id/{id}";

    /// erc20 is burned 0.1% faster than erc1155.
    /// This is the numerator for that.
    uint256 public constant ERC20_OVERBURN_NUMERATOR = 1001;
    /// erc20 is burned 0.1% faster than erc1155.
    /// This is the denominator for that.
    uint256 public constant ERC20_OVERBURN_DENOMINATOR = 1000;

    // Chainlink oracles.
    // https://docs.chain.link/docs/ethereum-addresses/
    uint256 public constant XAU_DECIMALS = 8;
    AggregatorV3Interface public constant CHAINLINK_XAUUSD =
        AggregatorV3Interface(0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6);
    AggregatorV3Interface public constant CHAINLINK_ETHUSD =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    constructor() ERC20(NAME, SYMBOL) ERC1155(GILD_URI) {} //solhint-disable no-empty-blocks

    /// Returns a reference XAU price in ETH or reverts.
    /// Calls two separate Chainlink oracles to factor out the USD price.
    /// Ideally we'd avoid referencing USD even for internal math but Chainlink doesn't support that yet.
    /// Having two calls costs extra gas and deriving a reference price from some arbitrary fiat adds no value.
    function referencePrice() public view returns (uint256) {
        (, int256 _xauUsd, , , ) = CHAINLINK_XAUUSD.latestRoundData();
        (, int256 _ethUsd, , , ) = CHAINLINK_ETHUSD.latestRoundData();
        return
            _ethUsd.toUint256().mul(10**XAU_DECIMALS).div(_xauUsd.toUint256());
    }

    /// Overburn ETHg at 1001:1000 ratio to receive initial ETH refund.
    /// If the `msg.sender` does not have _both_ the erc1155 and erc20 balances for a given reference price the ETH will not ungild.
    /// The erc20 and erc1155 amounts as `xauReferencePrice * ethAmount` (+0.1% for erc20) will be burned.
    /// @param xauReferencePrice XAU reference price in ETH. MUST correspond to an erc1155 balance held by `msg.sender`.
    /// @param ethAmount the amount of ETH to ungild.
    function ungild(uint256 xauReferencePrice, uint256 ethAmount) external {
        // Amount of ETHg to burn.
        uint256 _ethgAmount = ethAmount.mul(xauReferencePrice);
        emit Ungild(msg.sender, xauReferencePrice, ethAmount);

        // ETHg erc20 burn.
        // 0.1% more than erc1155 burn.
        // NOT reentrant.
        _burn(
            msg.sender,
            _ethgAmount
                // Overburn ETHg.
                .mul(ERC20_OVERBURN_NUMERATOR)
                .div(ERC20_OVERBURN_DENOMINATOR)
                // Compensate multiplication of xauReferencePrice.
                .div(10**XAU_DECIMALS)
        );

        // erc1155 burn.
        // NOT reentrant.
        _burn(
            msg.sender,
            // Reference price is the erc1155 id.
            xauReferencePrice,
            // Compensate multiplication of xauReferencePrice.
            _ethgAmount.div(10**XAU_DECIMALS)
        );

        // ETH ungild.
        // Reentrant via. sender's `receive` or `fallback` function.
        (bool _refundSuccess, ) = msg.sender.call{value: ethAmount}(""); // solhint-disable avoid-low-level-calls
        require(_refundSuccess, "UNGILD_ETH");
    }

    /// Gilds received ETH for equal parts ETHg erc20 and erc1155 tokens.
    /// Set the ETH value in the transaction as the sender to gild that ETH.
    function gild() external payable {
        require(msg.value > 0, "GILD_ZERO");

        uint256 _referencePrice = referencePrice();

        // Amount of ETHg to mint.
        uint256 _ethgAmount = msg.value.mul(_referencePrice).div(10**XAU_DECIMALS);
        emit Gild(msg.sender, _referencePrice, msg.value);

        // erc20 mint.
        // NOT reentrant.
        _mint(msg.sender, _ethgAmount);

        // erc1155 mint.
        // Reentrant via. `IERC1155Receiver`.
        _mint(msg.sender, _referencePrice, _ethgAmount, "");
    }
}
