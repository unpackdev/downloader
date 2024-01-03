// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IUniswapV2Router02.sol";
import "./ILGE.sol";
import "./ILodge.sol";
import "./LGEBase.sol";
import "./IPWDR.sol";
import "./ISlopes.sol";
import "./console.sol";

contract LGE is ILGE, IERC1155Receiver, LGEBase {
    struct UserInfo {
        uint256 contributionAmount;
        uint256 snowboardReserved;
        uint256 lastEvent;
    }

    event LiquidityEventStarted(address indexed _address);
    event LiquidityCapReached(address indexed _address);
    event LiquidityEventCompleted(address indexed _address, uint256 totalContributors, uint256 totalContributed);
    event UserContributed(address indexed _address, uint256 _amount);
    event UserClaimed(address indexed _address, uint256 _amount);

    uint256 public constant MAXIMUM_LGE_DURATION = 5 days; // max of 5 days
    uint256 public constant MAXIMUM_ADDRESS_CONTRIBUTION = 20 * 1e18; // 20 ETH per address
    uint256 public constant NFT_ETH_CONTRIBUTION = 15 * 1e18; // minimum contribution to be eligible for NFT
    uint256 public constant MAXIMUM_ETH_CONTRIBUTION = 2000 * 1e18; // 2000 ETH maximum cap
    uint256 public constant MINIMUM_ETH_CONTRIBUTION = 1 * 1e18; // min contribution amount
    uint256 public constant PWDR_TO_MINT = 5250000 * 1e18; // 5.25M PWDR to mint 
    uint256 public constant PWDR_TO_DISTRIBUTE = 2625000 * 1e18; // 2.625M PWDR, half of minting total

    bool internal started;
    bool public override active; // public variable for LGE event status
    
    uint256 public override eventStartTimestamp; // when the event started
    uint256 public override eventEndTimestamp; // when event will ended, computed at init, computed again if cap is reached
    uint256 public override totalContributors; // total # of unique addresses
    uint256 public override totalEthContributed; // total received
    uint256 public override tokenDistributionRate; // tokens distributed per address (totalContributed / # contributors)
    uint256 public override goldBoardsReserved;
    uint256 public override silverBoardsReserved;
    uint256 internal maxActivationTime;
    uint256[] internal activationTimes;

    mapping (address => UserInfo) public ethContributors;

    // modifier to determine if the LGE 
    modifier TimeLimitHasBeenReached {
        require(
            block.timestamp > eventEndTimestamp,
            "Must have reached contribution cap or exceeded event time window"
        );
        _;
    }

    // for functions thats only happen before the LGE has been completed
    modifier EventNotActive {
        require(!active, "LGE is not active");
        _;
    }

    modifier EventActive {
        require(active, "LGE has been completed");
        _;
    }

    modifier OnlyOnce {
        require(!started, "LGE can only be started once");
        _;
    }

    modifier OnlyContributionAmount(uint256 _amount) {
        require (
            _amount <= getMaximumAddressContribution()
            && totalEthContributed + _amount <= getMaximumTotalContribution(), 
            "Cannot contribute more than event ether caps"
        );
        _;
    }

    modifier OnlyWholeAmount(uint256 _amount) {
        require(
            _amount.mod(getMinimumContribution()) == 0, 
            "Can only contribute in whole ether amounts"
        );
        _;
    }

    modifier OnlyValidClaimer(address _address) {
        require(
            ethContributors[_address].contributionAmount > 0, 
            "No tokens to claim"
        );
        _;
    }

    constructor(address _address) 
        public 
        LGEBase(_address) 
    {}

    function startEvent()
        external
        override
        HasPatrol("ADMIN")
        EventNotActive
        OnlyOnce
    {
        started = true;
        active = true;
        eventStartTimestamp = block.timestamp;
        eventEndTimestamp = eventStartTimestamp + getMaximumDuration();

        activationTimes.push(block.timestamp.add(1 days));
        activationTimes.push(block.timestamp.add(2 days));
        activationTimes.push(block.timestamp.add(3 days));
        activationTimes.push(block.timestamp.add(4 days));
        activationTimes.push(eventStartTimestamp + getMaximumDuration());

        emit LiquidityEventStarted(msg.sender);
    }

    function activate() 
        external
        override
        TimeLimitHasBeenReached 
        EventActive
    {
        address pwdrPoolAddress = pwdrPoolAddress();
        address pwdrAddress = pwdrAddress();

        uint256 initialEthLiquidity = totalEthContributed.div(2);

        tokenDistributionRate = PWDR_TO_DISTRIBUTE.mul(1e18).div(totalEthContributed);
        console.log("Tokens to be distributed at rate of 1 ETH per %s PWDR", tokenDistributionRate);
        
        // Activate the slopes
        ISlopes(slopesAddress()).activate();
        
        // mint the tokens
        IPWDR(pwdrAddress).mint(address(this), PWDR_TO_MINT);
        console.log("Minted PWDR Tokens: %s", IERC20(pwdrAddress).balanceOf(address(this)));

        // add liq to uniswap
        console.log("Adding liquidity on Uniswap");
        uint256 lpTokensReceived = _addLiquidityETH(
            initialEthLiquidity,
            PWDR_TO_DISTRIBUTE,
            pwdrAddress
        );
        console.log("Received PWDR-ETH LP Tokens: %s", IERC20(pwdrPoolAddress).balanceOf(address(this)));


        // Lock the LP tokens in the PWDR contract
        // Move this to vault contract instead
        IERC20(pwdrPoolAddress).safeTransfer(vaultAddress(), lpTokensReceived);

        // transfer dev funds
        address(uint160(treasuryAddress())).transfer(initialEthLiquidity);

        // mark event completed
        active = false;
        emit LiquidityEventCompleted(msg.sender, totalContributors, totalEthContributed);
    }

    function contribute() 
        external 
        override
        payable 
    {
        _contribute(msg.sender, msg.value);
    }

    receive() external payable { }

    function _contribute(address _address, uint256 _amount)
        internal
        EventActive
        NonZeroAmount(_amount)
        OnlyContributionAmount(_amount)
        OnlyWholeAmount(_amount)
    {
        if (ethContributors[_address].lastEvent > 0) {
            require(
                ethContributors[_address].contributionAmount + _amount <= getMaximumAddressContribution(),
                "Cannot contribute more than address limit"
            );
        }

        if (block.timestamp > activationTimes[maxActivationTime]) {
            maxActivationTime++;
        }

        ethContributors[_address].contributionAmount = ethContributors[_address].contributionAmount.add(_amount);
        ethContributors[_address].lastEvent = block.timestamp;
        
        // do nft availability checks

        // if user has previously reserved a snowboard (15+ eth),
        // then maxes and there are still gold boards available,
        // swap the board out
        if (ethContributors[_address].contributionAmount == getMaximumAddressContribution()
            && ethContributors[_address].snowboardReserved == 2
            && ILodge(lodgeAddress()).items(0) > goldBoardsReserved) 
        {
            silverBoardsReserved -= 1;
            goldBoardsReserved += 1;
            ethContributors[_address].snowboardReserved = 1;
        }   // else if gold 
        else if (ILodge(lodgeAddress()).items(0) > goldBoardsReserved 
            && ethContributors[_address].contributionAmount == getMaximumAddressContribution()) 
        {
            ethContributors[_address].snowboardReserved = 1; // golden snowboard id + 1
            goldBoardsReserved += 1;
        } 
        else if (ILodge(lodgeAddress()).items(1) > silverBoardsReserved
            && ethContributors[_address].contributionAmount >= getMinimumNFTContribution()) 
        {
            ethContributors[_address].snowboardReserved = 2; // silver snowboard id + 1
            silverBoardsReserved += 1;
        }

        totalEthContributed = totalEthContributed.add(_amount);

        emit UserContributed(_address, _amount);

        if (totalEthContributed == getMaximumTotalContribution()) {
            //... mark the countdown to LGE activation now, next 1PM EST can launch
            eventEndTimestamp = activationTimes[maxActivationTime];
            emit LiquidityCapReached(_address);
        }
    }

    function getContribution(address _address)
        external
        override
        view
        returns (uint256 amount, uint256 board) 
    {
        UserInfo storage user = ethContributors[_address];
        
        amount = user.contributionAmount;
        board = user.snowboardReserved;
    }

    function claim() 
        external 
        override
    {
        _claim(msg.sender);
    }

    function _claim(address _address) 
        internal
        EventNotActive
        OnlyValidClaimer(_address)
    {
        uint256 claimablePwdr = tokenDistributionRate.mul(ethContributors[_address].contributionAmount).div(1e18);
        if (claimablePwdr > IERC20(pwdrAddress()).balanceOf(address(this))) {
            claimablePwdr = IERC20(pwdrAddress()).balanceOf(address(this));
        }

        ethContributors[_address].contributionAmount = 0;
        ethContributors[_address].lastEvent = block.timestamp;

        // transfer token to address
        IERC20(pwdrAddress()).safeTransfer(_address, claimablePwdr);

        if (ethContributors[_address].snowboardReserved > 0) {
            uint256 id = ethContributors[_address].snowboardReserved - 1;
            ethContributors[_address].snowboardReserved = 0;

            IERC1155(lodgeAddress()).safeTransferFrom(address(this), _address, id, 1, "");
        }

        emit UserClaimed(_address, claimablePwdr);
    }

    function retrieveLeftovers()
        external
        override
        EventNotActive
        HasPatrol("ADMIN")
    {
        if (ILodge(lodgeAddress()).items(0) > goldBoardsReserved) {
            uint256 goldenLeftovers = ILodge(lodgeAddress()).items(0) - goldBoardsReserved;
            IERC1155(lodgeAddress()).safeTransferFrom(address(this), _msgSender(), 0, goldenLeftovers, "");
        }

        if (ILodge(lodgeAddress()).items(1) > silverBoardsReserved) {
            uint256 silverLeftovers = ILodge(lodgeAddress()).items(1) - silverBoardsReserved;
            IERC1155(lodgeAddress()).safeTransferFrom(address(this), _msgSender(), 0, silverLeftovers, "");
        }

        if (address(this).balance > 0) {
            address(uint160(_msgSender())).transfer(address(this).balance);
        }
    }

    function getMaximumDuration() public virtual pure returns (uint256) {
        return MAXIMUM_LGE_DURATION;
    }

    function getMaximumAddressContribution() public virtual pure returns (uint256) {
        return MAXIMUM_ADDRESS_CONTRIBUTION;
    }

    function getMinimumNFTContribution() public virtual pure returns (uint256) {
        return NFT_ETH_CONTRIBUTION;
    }

    function getMinimumContribution() public virtual pure returns (uint256) {
        return MINIMUM_ETH_CONTRIBUTION;
    }

    function getMaximumTotalContribution() public virtual pure returns (uint256) {
        return MAXIMUM_ETH_CONTRIBUTION;
    }

    // https://eips.ethereum.org/EIPS/eip-1155#erc-1155-token-receiver
    function supportsInterface(bytes4 interfaceId) 
        external
        override
        view 
        returns (bool)
    {
        return interfaceId == 0x01ffc9a7 
            || interfaceId == 0x4e2312e0; 
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function getLGEStats(address _user)
        external
        view
        returns (bool _active, uint256[] memory _stats)
    {
        _active = active;

        _stats = new uint256[](10);
        _stats[0] = getMaximumTotalContribution();
        _stats[1] = getMaximumAddressContribution();
        _stats[2] = getMinimumNFTContribution();
        _stats[3] = getMinimumContribution();
        _stats[4] = goldBoardsReserved;
        _stats[5] = silverBoardsReserved;
        _stats[6] = totalEthContributed;
        _stats[7] = eventEndTimestamp;
        _stats[8] = ethContributors[_user].contributionAmount;
        _stats[9] = ethContributors[_user].snowboardReserved;
    }
}