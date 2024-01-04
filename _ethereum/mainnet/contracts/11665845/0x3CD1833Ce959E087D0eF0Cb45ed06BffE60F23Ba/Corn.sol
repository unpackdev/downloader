// SPDX-License-Identifier: MIT

pragma solidity 0.6.9;

import "./IERC777.sol";
import "./IERC777Recipient.sol";
import "./SafeMath.sol";
import "./IERC1820Registry.sol";
import "./ERC777.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Address.sol";
import "./IERC777Sender.sol";
import "./IERC20.sol";

/**
 * @dev Details of a farm at an address
 */
struct Farm {
    uint256 amount;
    uint256 compostedAmount;
    uint256 blockNumber;
    uint256 lastHarvestedBlockNumber;
    address harvesterAddress;
}

/**
 * @dev Farmland - Crop Smart Contract
 */
contract Corn is ERC777, IERC777Recipient, ReentrancyGuard {
    /**
     * @dev Protect against overflows by using safe math operations (these are .add,.sub functions)
     */
    using SafeMath for uint256;

    /**
     * @dev To limit one action per block per address
     */
    modifier preventSameBlock(address targetAddress) {
        require(
            farms[targetAddress].blockNumber != block.number &&
                farms[targetAddress].lastHarvestedBlockNumber != block.number,
            "You can not allocate/release or harvest in the same block"
        );
        _; // Call the actual code
    }

    /**
     * @dev There must be a farm on this LAND to execute this function
     */
    modifier requireFarm(address targetAddress, bool requiredState) {
        if (requiredState) {
            require(
                farms[targetAddress].amount != 0,
                "You must have allocated land to grow crops on your farm"
            );
        } else {
            require(
                farms[targetAddress].amount == 0,
                "You must have released your land"
            );
        }
        _; // Call the actual code
    }

    /**
     * @dev This will be LAND token smart contract address
     */
    IERC777 private immutable _token;
    IERC1820Registry private _erc1820 =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    /**
     * @dev Decline some incoming transactions (Only allow crop smart contract to send/receive LAND)
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external override {
        require(amount > 0, "You must receive a positive number of tokens");
        require(
            _msgSender() == address(_token),
            "You can only build farms on LAND"
        );

        // Ensure someone doesn't send in some LAND to this contract by mistake (Only the contract itself can send itself LAND)
        require(
            operator == address(this),
            "Only CORN contract can send itself LAND tokens"
        );
        require(to == address(this), "Funds must be coming into a CORN token");
        require(from != to, "Why would CORN contract send tokens to itself?");
    }

    /**
     * @dev How many blocks before the farm maturity boost starts ( Set to 6400 on mainnet - around 1 day )
     */
    uint256 private immutable _startMaturityBoost;

    /**
     * @dev How many blocks before the maximum 3x farm maturity boost is reached ( Set to 179200 on mainnet - around 28 days)
     */
    uint256 private immutable _endMaturityBoost;

    /**
     * @dev How many blocks until the fail safe limit is lifted and you are able to allocate any amount of LAND to growing crops (Set to 161280 on mainnet for 28 day failsafe period)
     */
    uint256 private immutable _failsafeTargetBlock;

    constructor(
        address token,
        uint256 startMaturityBoost,
        uint256 endMaturityBoost,
        uint256 failsafeBlockDuration
    ) public ERC777("Corn", "CORN", new address[](0)) {
        require(
            endMaturityBoost > 0,
            "endMaturityBoost must be at least 1 block (min 24 hours before time farm maturation starts)"
        ); // to avoid division by 0

        _token = IERC777(token);
        _startMaturityBoost = startMaturityBoost;
        _endMaturityBoost = endMaturityBoost;
        _failsafeTargetBlock = block.number.add(failsafeBlockDuration);

        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
    }

    /**
     * @dev 0.00000001 crops grown per block for each LAND allocated to a farm ... 10^18 / 10^8 = 10^10
     */
    uint256 private constant _harvestPerBlockDivisor = 10**8;

    /**
     * @dev To avoid small burn ratios we multiply the ratios by this number.
     */
    uint256 private constant _ratioMultiplier = 10**10;

    /**
     * @dev To get 4 decimals on our multipliers, we multiply all ratios & divide ratios by this number.
     * @dev This is done because we're using integers without any decimals.
     */
    uint256 private constant _percentMultiplier = 10000;

    /**
     * @dev The maximum LAND that can be allocated to a farm during fail safe period.
     */
    uint256 public constant failsafeMaxAmount = 1000 * (10**18);

    /**
     * @dev This is the farm's maximum 10x compost productivity boost. It's multiplicative with the maturity boost.
     */
    uint256 public constant maxCompostBoost = 100000;

    /**
     * @dev This is the farm's maximum 3x maturity productivity boost. It's multiplicative with the compost boost.
     */
    uint256 public constant maxMaturityBoost = 30000;

    /**
     * @dev This is the maximum number of blocks in each growth cycle ( around 42 days) before a harvest is required. After this many blocks crop will stop growing.
     */
    uint256 public constant maxGrowthCycle = 268800;

    /**
     * @dev This is the maximum the maturity boost extends beyond the base level of 1x. This is the "2x" in the "1x base + (0x to 2x bonus) with a maximum of 3x"
     */
    uint256 public constant maturityBoostExtension = 20000;

    /**
     * @dev PUBLIC: By making farms public we can access elements through the contract view (vs having to create methods)
     */
    mapping(address => Farm) public farms;

    /**
     * @dev PUBLIC: Store how much LAND is allocated to growing crops in farms globally
     */
    uint256 public globalAllocatedAmount;

    /**
     * @dev PUBLIC: Store how much is crop has been composted globally (only from active farms on LAND addresses)
     */
    uint256 public globalCompostedAmount;

    /**
     * @dev PUBLIC: Store how many addresses currently have an active farm
     */
    uint256 public globalTotalFarms;

    // Events
    event Allocated(
        address sender,
        uint256 blockNumber,
        address farmerAddress,
        uint256 amount,
        uint256 burnedAmountIncrease
    );
    event Released(
        address sender,
        uint256 amount,
        uint256 burnedAmountDecrease
    );
    event Composted(
        address sender,
        address targetAddress,
        uint256 amount
    );
    event Harvested(
        address sender,
        uint256 blockNumber,
        address sourceAddress,
        address targetAddress,
        uint256 targetBlock,
        uint256 amount
    );

    //////////////////// END HEADER //////////////////////

    /**
     * @dev PUBLIC: Allocate LAND to growing crops on a farm with the specified address as the harvester.
     */
    function allocate(address farmerAddress, uint256 amount)
        public
        nonReentrant()
        preventSameBlock(_msgSender())
        requireFarm(_msgSender(), false) // Ensure LAND is not already in a farm
    {
        require(
            amount > 0,
            "You must provide a positive amount of LAND to build a farm"
        );

        // Ensure you can only lock up to a limited amount of LAND during failsafe period
        if (block.number < _failsafeTargetBlock) {
            require(
                amount <= failsafeMaxAmount,
                "You can only allocate a maximum of 1000 LAND during failsafe."
            );
        }

        Farm storage senderFarm = farms[_msgSender()]; // Shortcut accessor

        senderFarm.amount = amount;
        senderFarm.blockNumber = block.number;
        senderFarm.lastHarvestedBlockNumber = block.number; // Reset the last harvest height to the new LAND allocation height
        senderFarm.harvesterAddress = farmerAddress;

        globalAllocatedAmount = globalAllocatedAmount.add(amount);
        globalCompostedAmount = globalCompostedAmount.add(
            senderFarm.compostedAmount
        );
        globalTotalFarms += 1;

        emit Allocated(
            _msgSender(),
            block.number,
            farmerAddress,
            amount,
            senderFarm.compostedAmount
        );

        // Send [amount] of LAND token from the address that is calling this function to crop smart contract.
        IERC777(_token).operatorSend(
            _msgSender(),
            address(this),
            amount,
            "",
            ""
        ); // [RE-ENTRANCY WARNING] external call, must be at the end
    }

    /**
     * @dev PUBLIC: Releasing a farm returns LAND to the owners
     */
    function release()
        public
        nonReentrant()
        preventSameBlock(_msgSender())
        requireFarm(_msgSender(), true) // Ensure the address you are releasing has a farm on the LAND
    {
        Farm storage senderFarm = farms[_msgSender()]; // Shortcut accessor

        uint256 amount = senderFarm.amount;
        senderFarm.amount = 0;

        globalAllocatedAmount = globalAllocatedAmount.sub(amount);
        globalCompostedAmount = globalCompostedAmount.sub(
            senderFarm.compostedAmount
        );
        globalTotalFarms = globalTotalFarms.sub(1);

        emit Released(_msgSender(), amount, senderFarm.compostedAmount);

        // Send back the LAND amount to person calling the method
        IERC777(_token).send(_msgSender(), amount, ""); // [RE-ENTRANCY WARNING] external call, must be at the end
    }

    /**
     * @dev PUBLIC: Composting a crop fertilizes a farm at specific address
     */
    function compost(address targetAddress, uint256 amount)
        public
        nonReentrant()
        requireFarm(targetAddress, true) // Ensure the address you are composting to has a farm on the LAND
    {
        require(amount > 0, "Nothing to compost");

        Farm storage targetFarm = farms[targetAddress]; // Shortcut accessor, pay attention to targetAddress here

        targetFarm.compostedAmount = targetFarm.compostedAmount.add(amount);

        globalCompostedAmount = globalCompostedAmount.add(amount);

        emit Composted(_msgSender(), targetAddress, amount);

        // Call the normal ERC-777 burn (this will destroy a crop token). We don't check address balance for amount because the internal burn does this check for us.
        _burn(_msgSender(), amount, "", ""); // [RE-ENTRANCY WARNING] external call, must be at the end
    }

    /**
     * @dev PUBLIC: Harvests crops from a specific address to a specified address UP TO the target block
     */
    function harvest(
        address sourceAddress,
        address targetAddress,
        uint256 targetBlock
    )
        public
        nonReentrant()
        preventSameBlock(sourceAddress)
        requireFarm(sourceAddress, true) // Ensure the adress that is being harvested has a farm on the LAND
    {
        require(
            targetBlock <= block.number,
            "You can only harvest up to current block"
        );

        Farm storage sourceFarm = farms[sourceAddress]; // Shortcut accessor, pay attention to sourceAddress here

        require(
            sourceFarm.lastHarvestedBlockNumber < targetBlock,
            "You can only harvest ahead of last harvested block"
        );
        require(
            sourceFarm.harvesterAddress == _msgSender(),
            "You must be the delegated harvester of the sourceAddress"
        );

        uint256 mintAmount = getHarvestAmount(sourceAddress, targetBlock);
        require(mintAmount > 0, "Nothing to harvest");

        sourceFarm.lastHarvestedBlockNumber = targetBlock; // Reset the last harvested height

        emit Harvested(
            _msgSender(),
            block.number,
            sourceAddress,
            targetAddress,
            targetBlock,
            mintAmount
        );

        // Call the normal ERC-777 mint (this will harvest crop tokens to targetAddress)
        _mint(targetAddress, mintAmount, "", ""); // [RE-ENTRANCY WARNING] external call, must be at the end
    }

    //////////////////// VIEW ONLY //////////////////////

    /**
     * @dev PUBLIC: Get the harvested amount of a specific address up to a target block
     */
    function getHarvestAmount(address targetAddress, uint256 targetBlock)
        public
        view
        returns (uint256)
    {
        Farm storage targetFarm = farms[targetAddress]; // Shortcut accessor

        // Ensure this address has a farm on the LAND
        if (targetFarm.amount == 0) {
            return 0;
        }

        require(
            targetBlock <= block.number,
            "You can only calculate up to current block"
        );
        require(
            targetFarm.lastHarvestedBlockNumber <= targetBlock,
            "You can only specify blocks at or ahead of last harvested block"
        );

        uint256 lastBlockInGrowthCycle =
            targetFarm.lastHarvestedBlockNumber.add(maxGrowthCycle); // end of growth cycle last allowed block
        uint256 blocksMinted = maxGrowthCycle;

        if (targetBlock < lastBlockInGrowthCycle) {
            blocksMinted = targetBlock.sub(targetFarm.lastHarvestedBlockNumber);
        }

        uint256 amount = targetFarm.amount; // Total of size of the farm in LAND for this address
        uint256 blocksMintedByAmount = amount.mul(blocksMinted);

        // Adjust by multipliers
        uint256 compostMultiplier = getAddressCompostMultiplier(targetAddress);
        uint256 maturityMultipler = getAddressMaturityMultiplier(targetAddress);
        uint256 afterMultiplier =
            blocksMintedByAmount
                .mul(compostMultiplier)
                .div(_percentMultiplier)
                .mul(maturityMultipler)
                .div(_percentMultiplier);

        uint256 actualMinted = afterMultiplier.div(_harvestPerBlockDivisor);

        return actualMinted;
    }

    /**
     * @dev PUBLIC: Find out a farms maturity boost for the current LAND address (Using 1 block = 13.5 sec formula)
     */
    function getAddressMaturityMultiplier(address targetAddress)
        public
        view
        returns (uint256)
    {
        Farm storage targetFarm = farms[targetAddress]; // Shortcut accessor

        // Ensure this address has a farm on the LAND
        if (targetFarm.amount == 0) {
            return _percentMultiplier;
        }

        // You don't get a boost until minimum blocks passed
        uint256 targetBlockNumber =
            targetFarm.blockNumber.add(_startMaturityBoost);
        if (block.number < targetBlockNumber) {
            return _percentMultiplier;
        }

        // 24 hours - min before starting to receive rewards
        // 28 days - max for waiting 28 days (The function returns PERCENT (10000x) the multiplier for 4 decimal accuracy
        uint256 blockDiff =
            block.number
            .sub(targetBlockNumber)
            .mul(maturityBoostExtension)
            .div(_endMaturityBoost)
            .add(_percentMultiplier);

        uint256 timeMultiplier = Math.min(maxMaturityBoost, blockDiff); // Min 1x, Max 3x
        return timeMultiplier;
    }

    /**
     * @dev PUBLIC: Find out a farms compost productivity boost for a specific address. This will be returned as PERCENT (10000x)
     */
    function getAddressCompostMultiplier(address targetAddress)
        public
        view
        returns (uint256)
    {
        uint256 myRatio = getAddressRatio(targetAddress);
        uint256 globalRatio = getGlobalRatio();

        // Avoid division by 0 & ensure 1x boost if nothing is locked
        if (globalRatio == 0 || myRatio == 0) {
            return _percentMultiplier;
        }

        // The final multiplier is return with 10000x multiplication and will need to be divided by 10000 for final number
        uint256 compostMultiplier =
            Math.min(
                maxCompostBoost,
                myRatio.mul(_percentMultiplier).div(globalRatio).add(
                    _percentMultiplier
                )
            ); // Min 1x, Max 10x
        return compostMultiplier;
    }

    /**
     * @dev PUBLIC: Get LAND/CROP burn ratio for a specific address
     */
    function getAddressRatio(address targetAddress)
        public
        view
        returns (uint256)
    {
        Farm storage targetFarm = farms[targetAddress]; // Shortcut accessor

        uint256 addressLockedAmount = targetFarm.amount;
        uint256 addressBurnedAmount = targetFarm.compostedAmount;

        // If you haven't harvested or composted anything then you get the default 1x boost
        if (addressLockedAmount == 0) {
            return 0;
        }

        // Compost/Maturity ratios for both address & network
        // Note that we multiply both ratios by the ratio multiplier before dividing. For tiny CROP/LAND burn ratios.
        uint256 myRatio =
            addressBurnedAmount.mul(_ratioMultiplier).div(addressLockedAmount);
        return myRatio;
    }

    /**
     * @dev PUBLIC: Get LAND/CROP compost ratio for global (entire network)
     */
    function getGlobalRatio() public view returns (uint256) {
        // If you haven't harvested or composted anything then you get the default 1x multiplier
        if (globalAllocatedAmount == 0) {
            return 0;
        }

        // Compost/Maturity for both address & network
        // Note that we multiply both ratios by the ratio multiplier before dividing. For tiny CROP/LAND burn ratios.
        uint256 globalRatio =
            globalCompostedAmount.mul(_ratioMultiplier).div(globalAllocatedAmount);
        return globalRatio;
    }

    /**
     * @dev PUBLIC: Get Average LAND/CROP compost ratio for global (entire network)
     */
    function getGlobalAverageRatio() public view returns (uint256) {
        // If you haven't harvested or composted anything then you get the default 1x multiplier
        if (globalAllocatedAmount == 0) {
            return 0;
        }

        // Compost/Maturity for both address & network
        // Note that we multiply both ratios by the ratio multiplier before dividing. For tiny CROP/LAND burn ratios.
        uint256 globalAverageRatio =
            globalCompostedAmount
                .mul(_ratioMultiplier)
                .div(globalAllocatedAmount)
                .div(globalTotalFarms);
        return globalAverageRatio;
    }

    /**
     * @dev PUBLIC: Grab a collection of data associated with an address
     */
    function getAddressDetails(address targetAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 cropBalance = balanceOf(targetAddress);
        uint256 harvestAmount = getHarvestAmount(targetAddress, block.number);

        uint256 addressMaturityMultiplier = getAddressMaturityMultiplier(targetAddress);
        uint256 addressCompostMultiplier = getAddressCompostMultiplier(targetAddress);

        return (
            block.number,
            cropBalance,
            harvestAmount,
            addressMaturityMultiplier,
            addressCompostMultiplier
        );
    }

    /**
     * @dev PUBLIC: Get additional token details
     */
    function getAddressTokenDetails(address targetAddress)
        public
        view
        returns (
            uint256,
            bool,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        bool isOperator =
            IERC777(_token).isOperatorFor(address(this), targetAddress);
        uint256 landBalance = IERC777(_token).balanceOf(targetAddress);
        uint256 myRatio = getAddressRatio(targetAddress);
        uint256 globalRatio = getGlobalRatio();
        uint256 globalAverageRatio = getGlobalAverageRatio();

        return (
            block.number,
            isOperator,
            landBalance,
            myRatio,
            globalRatio,
            globalAverageRatio
        );
    }

    /**
     * @dev PUBLIC: Get some global details
     */
    function getGlobalDetails()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 globalRatio = getGlobalRatio();
        uint256 globalAverageRatio = getGlobalAverageRatio();

        return (
            globalTotalFarms,
            globalRatio,
            globalAverageRatio,
            globalAllocatedAmount,
            globalCompostedAmount
        );
    }

    /**
     * @dev PUBLIC: Get some contracts constants
     */
    function getConstantDetails()
        public
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            maxCompostBoost,
            maxMaturityBoost,
            maxGrowthCycle,
            maturityBoostExtension
        );
    }
}
