// SPDX-License-Identifier: UNLICENSED
/*
* TENDY, LLC (TENDY) is seeking to create a new, regulated NFT marketplace for US
* creators and traders and wishes to engage the DeFi community in its growth.
* 
* Furthermore, TENDY has already acquired 3,300 internet domain names in the NFT space,
* which it intends to sell to the industry as the NFT market expands, e.g., punksnfts.com.
* The list of TENDY domain names can be viewed at https://tendynft.com/.
* Valuations based on public offer prices of the TENDY NFT domain names are, on average, 
* $40,000 each, giving this TNDY token an initial US Dollar net-asset-value (NAV) of $132m.
* 
* TENDY will mint 3,300,000 ERC20 TNDY tokens as its DeFi asset. Each 1,000 tokens will
* be backed by one, $40k value, NFT domain name, giving an average TNDY token value of $40.
* 
* Whenever TENDY sells an NFT domain name it will use this income to buyback and burn TNDY
* tokens on the Uniswap DeFi platform, positively influencing the TNDY token value.
* 
* And, 10% of the TENDY regulated NFT marketplace revenues will be used to buyback and
* burn TNDY tokens on the Uniswap DeFi platform, positively influencing the TNDY token value.
* 
* TENDY intends to buyback TNDY tokens with such revenues when the token price is below 
* NAV, this action is intended to support the established NAV.
* 
* Once the NAV of the TNDY token is aligned with the actual NFT asset value, then TENDY 
* will deposit the balance of its sales revenue along with a pro rata number of its TNDY 
* treasury tokens into the Uniswap DeFi liquidity pool, causing the TNDY price to stabilize.
* 
* Periodically, TENDY will update the NAV of the assets backing the TNDY token as market
* conditions change and the average value of its NFT domain names rises, or when TENDY purchases
* new NFT domains for its portfolio. 
* 
* When the TNDY price is higher than the established NAV, then TENDY may sell treasury tokens 
* into Uniswap, causing the TNDY price to decrease until it reaches equilibrium with the NAV.
* Future domain name sales will drive the token price back to NAV and|or be used to stabilize NAV.
* 
*
* https://tendy.com/ -- TENDY, LLC
*
* Address: 221 34th St. #1000, Manhattan Beach, CA 90266, USA
* Email: info@tendy.com
*
* As at 2-September-2021, TENDY, LLC is a US limited liability company registered in Wyoming.
*
* This is an ERC-20 smart contract for the TNDY token that will be used as one side
* of a Uniswap liquidity pool trading pair. This TNDY token has the following properties:
*
* 1. The number of TNDY tokens from this contract that will be initially added to the 
*    Uniswap liquidity pool shall be 16,500. The amount of ETH added to the other side of
*    the initial Uniswap liquidity pool shall be approximately 4.4, representing $1/TNDY.
*    A further 16,500 TNDY shall be deposited on PancakeSwap as part of the initial release.
* 2. TENDY hereby commits to swap an amount of ETH currency with the Uniswap TNDY<>ETH 
*    trading pair upon receipt of 10% of tendy.com income or 100% of the sale of any of 
*    the NFT domain names that it owns.
* 3. The value of the ETH currency swapped by TENDY shall be equal to 100% of TENDYs actual
*    domain name sales revenue, as disclosed on its website from time to time. Each ETH
*    swap shall be performed no later than 30 working days after a TENDY domain name sale.
* 4. TNDY tokens returned by Uniswap from the buyback/swap of ETH by TENDY shall be burned 
*    by this smart contract.
* 5. This contract shall not be allowed mint any new TNDY tokens, i.e., no dilution.
* 6. TENDY, the company, shall initially hold 3,267,000 TNDY tokens on its balance sheet,
*    i.e., the TNDY treasury tokens. These tokens may be only be sold by TENDY into Uniswap
*    as part of TNDY price stabilization or transferred to the treasury Uniswap liquidity pool, 
*    along with ETH, for price stability.
* 7. TENDYs treasury tokens may only ever be transferred after a notice period has elapsed,
*    where every such notice period will be have been disclosed by this smart contract 
*    on the public blockchain, i.e., no rug-pulls.
*
*
* https://abbey.ch/         -- Abbey Technology GmbH, Zug, Switzerland
* 
* ABBEY DEFI
* ========== 
* 1. Decentralized Finance (DeFi) is designed to be globally inclusive. 
* 2. Centralized finance is based around private share sales to wealthy individuals or
*    the trading of shares on national stock markets, both have high barriers to entry. 
* 3. The Abbey DeFi methodology offers public and private companies exposure to DeFi.
*
* Abbey is a Uniswap-based DeFi service provider that allows companies to offer people a 
* novel way to speculate on the success of their business in a decentralized manner.
* 
* The premise is both elegant and simple, the company commits to a token buyback based on 
* its sales revenue and commits to stabilize a tokens price by adding to the liquidity pool.
* 
* Using Abbey as a Uniswap DeFi management agency, the company spends sales revenue, as ETH, 
* buying one side of a bespoke Uniswap trading pair. The other side of the Uniswap pair 
* is the TNDY token.
* 
* DeFi traders wishing to speculate on the revenue growth of the company deposit ETH in return 
* for TNDY Uniswap tokens. The Uniswap Automated Market Maker ensures DeFi market 
* liquidity and legitimate price discovery. The more ETH that the company deposits over time, 
* the higher the value of the TNDY token, as held by DeFi speculators.
*
*/

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./IERC721.sol";

/**
 * @title Tendy (TNDY) contract for Uniswap.
 * @author Abbey Technology GmbH
 * @notice Token contract for use with Uniswap.  Enforces restrictions outlined in the prospectus.
 */
contract TNDYToken is ERC20 {

    /**
     * @notice The details of a future company cashout.
     */
    struct Notice {
        // The maximum number of tokens proposed for sale.
        uint256 amount;

        // The date after which company tokens can be swapped.
        uint256 releaseDate;
    }

    // Event fired when a restricted wallet gives notice of a potential future trade.
    event NoticeGiven(address indexed who, uint256 amount, uint256 releaseDate);

    // Event fired when a the Net Asset Value changes on this contract.
    event NAVUpdated(address indexed who, uint256 newNAV);

    /**
     * @notice Notice must be given to the public before treasury tokens can be swapped.
     */
    Notice public noticeTreasury;

    /**
     * @notice Notice must be given to the public before Liquidity Tokens can be removed from the pool.
     */
    Notice public noticeLiquidity;

    /**
    * @notice The account that created this contract, also functions as the liquidity provider.
    */
    address public owner;

    /**
     * @notice Holder of the company's tokens.  Must give notice before tokens are moved.
     */
    address public treasury;

    /**
     * @notice The account that performs the buyback of tokens, all bought tokens are burned.
     * @dev They cannot be autoburned during transfer as the Uniswap client prevents the transaction.
     */
    address public buyback;

    /**
     * @notice The account that facilitates moving tokens between Uniswap and PancakeSwap.
     * @dev This account is not used in this contract, it's purely here for verification.
     */
    address public flip;    

    /**
     * @notice The address of the Uniswap Pool ERC20 contract holding the Liquidity Pool tokens.
     */
    address public poolAddress;

    /**
     * @notice The address of the Uniswap NFT ERC721 Positions contract that tracks ownership of liquidity pools.
     */
    address public positionsAddress;

    /**
     * @notice The NFT id of the Liquidity Pool in the Uniswap Positions contract.
     */
    uint256 public nftId;    

    /**
     * @notice The current NAV of the underlying assets.
     */
    uint256 public netAssetValue;

    /**
     * @notice The address of the Binance Contract that can be used with this contract for arbitrage.
     */
    address public binanceContract;

    /**
     * @notice Restrict functionaly to the contract owner.
     */
    modifier onlyOwner {
        require(_msgSender() == owner, "You are not Owner.");
        _;
    }

    /**
     * @notice Restrict functionaly to the buyback account.
     */
    modifier onlyBuyback {
        require(_msgSender() == buyback, "You are not Buyback.");
        _;
    }

    /**
     * @notice Create the contract setting already known values that are unlikely to change.
     * 
     * @param initialSupply The total supply at creation, no more tokens can be minted but they can be burned.
     * @param name          The name of the token.
     * @param symbol        The short symbol for this token.
     * @param treasuryAddr  The address of the treasury wallet.
     * @param buybackAddr   The wallet that performs buybacks and optional burns of tokens.
     * @param flipAddr      The wallet used to move tokens between Ethereum and Binance.
     */
    constructor(uint256 initialSupply, string memory name, string memory symbol, address treasuryAddr, address buybackAddr, address flipAddr, address positionsAddr) ERC20(name, symbol) {
        owner = _msgSender();
        _mint(_msgSender(), initialSupply);

        treasury = treasuryAddr;
        buyback = buybackAddr;
        flip = flipAddr;
        positionsAddress = positionsAddr; 
        netAssetValue = 132000000 ether;

        // Of the 3.3m total supply 33,000 are split between Uniswap and PancakeSwap; treasury keeps the
        // remaining tokens.  Sending 16500 tokens to Flip means they are allocated to owner in the
        // Binance contract (see the binanceContract property), this happens in the constructor on
        // contract creation.
        transfer(treasury, 3267000 ether);
        transfer(flip, 16500 ether);
    }

    /**
     * @notice Set the address of the account holding TNDY tokens on behalf of the company.
     */
    function setTreasury(address who) public onlyOwner {
        treasury = who;
    }

    /**
     * @notice Set the address of the account that buys tokens to burn them.
     */
    function setBuyback(address who) public onlyOwner {
        buyback = who;
    }

    /**
     * @notice Set the address of the account that allows moving tokens between Uniswap and PancakeSwap.
     */
    function setFlip(address who) public onlyOwner {
        flip = who;
    }

    /**
     * @notice Set the address of the Uniswap Pool contract.
     */
    function setPoolAddress(address who) public onlyOwner {
        poolAddress = who;
    }

    /**
     * @notice Set the address of the Uniswap NFT contract that tracks Liquidity Pool ownership.
     */
    function setPositionsAddress(address who) public onlyOwner {
        positionsAddress = who;
    }

    /**
     * @notice Set the id of the position token that determines ownership of the Liquidity Pool.
     */
    function setNftId(uint256 id) public onlyOwner {
        nftId = id;
    }

     /**
     * @notice The total net asset value of the tendynft.com domain portfolio.
     * This will be updated as new domains are purchased, exisiting domains
     * are sold or when the portfolio of domain names is marked-to-market.
     *
     * @param nav    The US dollar value of the portfilio, in wei.
     */
    function setNetAssetValue(uint256 nav) public onlyOwner {
        netAssetValue = nav;

        emit NAVUpdated(_msgSender(), nav);
    }

    /**
     * @notice Set the address of the contract on the Binance Smart Chain where tokens
     *         can be flipped to and flopped from.
     */
    function setBinanceContract(address contractAddress) public onlyOwner {
        binanceContract = contractAddress;
    }

    /**
     * @notice Treasury tokens must give advanced notice to the public before they can be used.
     * A public announcement will be made at the same time this notice is set in the contract.
     *
     * @param who The treasury address.
     * @param amount The maximum number of tokens (in wei).
     * @param numSeconds The number of seconds the tokens are held before being acted on.
     */
    function treasuryTransferNotice(address who, uint256 amount, uint256 numSeconds) public onlyOwner {
        require(who == treasury, "Specified address is not Treasury.");

        uint256 when = block.timestamp + (numSeconds * 1 seconds);

        require(noticeTreasury.releaseDate == 0 || block.timestamp >= noticeTreasury.releaseDate, "Cannot overwrite an active existing notice.");
        require(amount <= balanceOf(who), "Can't give notice for more TNDY tokens than owned.");
        noticeTreasury = Notice(amount, when);
        emit NoticeGiven(who, amount, when);
    }

    /**
     * @notice Liquidity Pool tokens must give advanced notice to the public before they can be used.
     * A public announcement will be made at the same time this notice is set in the contract.     
     *
     * @param who The owner of the Uniswap Positions NFT token.
     * @param amount The maximum number of tokens (in wei).
     * @param numSeconds The number of seconds the tokens are held before being acted on.
     */
    function liquidityRedemptionNotice(address who, uint256 amount, uint256 numSeconds) public onlyOwner {
        require(positionsAddress != address(0), "Uniswap Position Manager must be set.");
        require(nftId != 0, "Uniswap Position NFT Id must be set.");
        require(poolAddress != address(0), "The Uniswap Pool contract address must be set.");

        IERC721 positions = IERC721(positionsAddress);
        address lpOwner = positions.ownerOf(nftId);
        require(who == lpOwner, "The specified address does not own the Positions NFT Token.");

        uint256 when = block.timestamp + (numSeconds * 1 seconds);

        require(noticeLiquidity.releaseDate == 0 || block.timestamp >= noticeLiquidity.releaseDate, "Cannot overwrite an active existing notice.");
        require(amount <= balanceOf(poolAddress), "Can't give notice for more Liquidity Tokens than owned.");
        noticeLiquidity = Notice(amount, when);
        emit NoticeGiven(who, amount, when);
    }

    /**
     * @notice Enforce rules around the company accounts:
     * - Once buyback buys tokens they can never be moved, the only real option is to burn.
     * - Two key accounts: treasury and the owner of the liquidity pool are restricted.
     * - A public announcement of the company's intent along with a time locked  notice set in this contract before any token movement.
     * - Only after the deadline can these restricted tokens move.
     * - No restrictions are in place for any other wallet.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != buyback, "Buyback cannot transfer tokens, it can only burn.");
        if(sender == treasury) {
            require(noticeTreasury.releaseDate != 0 && block.timestamp >= noticeTreasury.releaseDate, "Notice period has not been set or has not expired.");
            require(amount <= noticeTreasury.amount, "Treasury can't transfer more tokens than given notice for.");

            // Clear the remaining notice balance, this prevents giving notice on all tokens and
            // trickling them out.
            noticeTreasury = Notice(0, 0);
        }
        else if(nftId != 0) { // Check if the receiver is the Liquidity Pool owner.
            IERC721 positions = IERC721(positionsAddress);
            address lpOwner = positions.ownerOf(nftId);
            if(recipient == lpOwner) {
                require(noticeLiquidity.releaseDate != 0 && block.timestamp >= noticeLiquidity.releaseDate, "LP notice period has not been set or has not expired.");
                require(amount <= noticeLiquidity.amount, "LP can't transfer more tokens than given notice for.");

                // Clear the remaining notice balance, this prevents giving notice on all tokens and
                // trickling them out.
                noticeLiquidity = Notice(0, 0);
            }
        }

        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice The buyback account can periodically buy tokens and burn them to reduce the
     * total supply pushing up the price of the remaining tokens.
     */
    function burn() public onlyBuyback {
        _burn(buyback, balanceOf(buyback));
    }
}