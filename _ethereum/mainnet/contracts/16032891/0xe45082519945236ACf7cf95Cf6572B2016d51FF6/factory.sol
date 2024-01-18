// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeERC20.sol";
import "./Clones.sol";
import "./IIndex.sol";
import "./Itreasury.sol";
import "./IWETH.sol";

/// @title A Factory Contract
/// @notice This is the main factory contract which deploys and control index contracts
/// @dev This is the admin for the deployed index contracts and can call their functions
contract Factory is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @notice stores the address of weth token
    address public WETH;

    /// @notice stores the addresses of the created index fund contracts
    address[] public indexAddressArray;

    /// @notice stores the address of dex contract
    address private dex;

    /// @notice stores the address of the index implmementation contract
    address private indexImplementation;

    /// @notice stores the address for treasury Implementation contract
    address private treasuryImplementation;

    /// @notice stores the id of index address
    mapping(address => uint256) public indexIdByAddress;

    /// @notice Event foo creating index fund contract
    event CreateIndexFund(
        uint256 id,
        uint16[] _percentages,
        address[] _tokens,
        uint256 _depositendingtime,
        uint256 _indexendingtime,
        address _ptoken,
        address _managementfeeaddress,
        address _performancefeeaddress
    );

    /// @notice Event for updation of  index fund contract
    event UpdateIndexFund(uint256 id, uint16[] _percentages, address[] _tokens);

    /// @notice Event for updation of  index fund
    event Purchased(uint256 id, uint256 amount, uint256[] slippageallowed);

    /// @notice Event for updation of  index fund contract owner
    event UpdateIndexOwner(uint256 id, address newOwner);

    /// @notice Event for updation of  index fund contract owner
    event Sold(uint256 id, uint256[] amounts, uint256[] slippageallowed);

    /// @notice Event for Dposit in the index fund contract
    event Deposit(uint256 id, uint256 amount);

    /// @notice Event for Rebalance Purchase of  index fund contract
    event RebalancePurchase(
        uint256 id,
        uint256 amount,
        uint256[] slippageallowed
    );

    /// @notice Event for Rebalance Sell of the index fund contract
    event RebalanceSell(
        uint256 id,
        uint256[] amounts,
        uint256[] slippageallowed
    );

    /// @notice Event for addition of reward token in the index fund contract
    event AddRewardToken(uint256 id, address token);

    /// @notice Event for setting of management fee treasury  in index fund contract
    event SetManagementFeeAddress(uint256 id, address managementfeeaddress);

    /// @notice Event for setting of Performance fee treasury  in index fund contract
    event SetPerformanceFeeAddress(uint256 id, address performancefeeaddress);

    /// @notice Event for distribution in the index fund contract
    event distributeamountEvent(uint256 id);

    /// @notice Event for staking of token from the index fund contract in the staking contract
    event Stake(uint256 id, address _token, address _stakingcontract);

    /// @notice Event for unstaking of token from the stakingcontract to the index contract
    event UnStake(uint256 id, address _token, address _stakingcontract);

    /// @notice Event for approve of token   index fund contract owner
    event ApproveToken(uint256 id, address _token, address _stakingcontract);

    /// @notice Event for execution of funciton by the index fund contract
    event Execute(uint256 id, address target, string _func);

    /// @notice Error for Zero address
    error ZeroAddress();

    /// @notice Error for Wrong Id
    error WrongId();

    /// @notice Error for different or zero array length of tokens and percentages
    error ArrayLength(uint256);

    /// @notice Error when sum of the percentage values is not 1000
    error WrongSum(uint256);

    /// @notice Error for Zero address
    error ZeroAmount(uint256);

    /// @notice modifier for checking if the id is within the created ids
    modifier idcheck(uint256 id) {
        if (id >= indexAddressArray.length) revert WrongId();

        _;
    }

    /// @notice modifier to check if the amount is greater than 0 or not
    modifier amountcheck(uint256 amount) {
        if (!(amount > 0)) revert ZeroAmount(amount);
        _;
    }

    /// @notice modifier to check if the array is not of zero length
    modifier slippagearraycheck(uint256[] calldata arr) {
        if (arr.length == 0) revert ArrayLength(arr.length);
        _;
    }
    /// @notice mmodifier to check the zero address
    modifier zeroaddresscheck(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    /// @notice function to initialze the factory contract.
    /// @param _indeximplementation the implementation address of the index contract.
    /// @param _dex the  address of the dex contract.
    /// @param _treasury the implementation address of the treasury contract.
    function initialize(
        address _indeximplementation,
        address _dex,
        address _treasury
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        indexImplementation = _indeximplementation;
        dex = _dex;
        treasuryImplementation = _treasury;
    }

    /// @notice function to pause the functions
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice function to unpause the functions
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice function to set the implementation contract address for the minimal proxy index contract
    /// @param _implementation The address for the implementation address
    function setImplementation(address _implementation)
        public
        onlyOwner
        whenNotPaused
    {
        indexImplementation = _implementation;
    }

    /// @notice This function will check the supplied inputs, creates a new index fund contract
    ///inside the indexInstanceArray
    /// @param _percentages The percentage array for the tokens
    /// @param _tokens The address array of the tokens
    /// @param _thresholdamount The minimum amount allowed for deposit in index contract
    /// @param _indexendingtime The time after the purchase till which we can't sell the tokens
    /// @param _ptoken The base token of the index contract
    function createIndexFund(
        uint16[] calldata _percentages,
        address[] calldata _tokens,
        uint256 _thresholdamount,
        uint256 _depositendingtime,
        uint256 _indexendingtime,
        address _ptoken
    ) external onlyOwner whenNotPaused {
        if (_percentages.length != _tokens.length || _tokens.length == 0)
            revert ArrayLength(_percentages.length);

        address index_imp = indexImplementation;
        address treasury_imp = treasuryImplementation;

        if (
            dex == address(0) ||
            index_imp == address(0) ||
            treasury_imp == address(0)
        ) revert ZeroAddress();

        // Index index = new Index(_name, _percentages, _tokens,_blocks,_dex);
        uint256 id = indexAddressArray.length;

        address manfeeaddr = Clones.cloneDeterministic(
            treasury_imp,
            keccak256(abi.encodePacked(id, "management"))
        );
        Itreasury(manfeeaddr).initialize(msg.sender);

        address perfeeaddr = Clones.cloneDeterministic(
            treasury_imp,
            keccak256(abi.encodePacked(id, "performance"))
        );
        Itreasury(perfeeaddr).initialize(msg.sender);

        address indexAddress = Clones.cloneDeterministic(
            index_imp,
            keccak256(abi.encodePacked(id, "imp"))
        );
        IndexInterface(indexAddress).initialize(
            _percentages,
            _tokens,
            _thresholdamount,
            _depositendingtime,
            _indexendingtime,
            _ptoken,
            dex,
            manfeeaddr,
            perfeeaddr
        );

        indexAddressArray.push(indexAddress);
        emit CreateIndexFund(
            id,
            _percentages,
            _tokens,
            _depositendingtime,
            _indexendingtime,
            _ptoken,
            manfeeaddr,
            perfeeaddr
        );
    }

    /// @notice This function will check the supplied inputs, creates a new index fund contract
    ///inside the indexInstanceArray
    /// @param id The id of the index contract
    /// @param _percentages The percentage array for the tokens
    /// @param _tokens The address array of the tokens
    function updateIndexFund(
        uint256 id,
        uint16[] calldata _percentages,
        address[] calldata _tokens
    ) external onlyOwner whenNotPaused idcheck(id) {
        if (_percentages.length != _tokens.length || _tokens.length == 0)
            revert ArrayLength(_percentages.length);

        IndexInterface(indexAddressArray[id]).udpateindex(
            _percentages,
            _tokens
        );
        emit UpdateIndexFund(id, _percentages, _tokens);
    }

    /// @notice Returns the current index configuration i.e. tokens and their percentages
    /// @param id The id of the index contract
    function getIndexInfo(uint256 id)
        external
        view
        idcheck(id)
        returns (address[] memory, uint16[] memory)
    {
        return IndexInterface(indexAddressArray[id]).getCurrentTokensInfo();
    }

    /// @notice Returns the previous index configuration
    /// @param id The id of the index contract
    function getPreviousIndexInfo(uint256 id)
        external
        view
        idcheck(id)
        returns (address[] memory, uint16[] memory)
    {
        return IndexInterface(indexAddressArray[id]).getPreviousTokensInfo();
    }

    /// @notice Returns the number of index contracts created
    function getNumberofindex() external view returns (uint256) {
        return indexAddressArray.length;
    }

    /// @notice Will be used to authorize the upgrade
    /// @param newImplementation The address of the new implementation for the factory contract
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
        whenNotPaused
    {}

    /// @notice Will updat the owner of the index contract
    /// @param id The id of the index contrac
    /// @param newOwner The address of the new Owner
    function updateIndexOwner(uint256 id, address newOwner)
        external
        onlyOwner
        idcheck(id)
        whenNotPaused
    {
        IndexInterface(indexAddressArray[id]).updateindexowner(newOwner);
        emit UpdateIndexOwner(id, newOwner);
    }

    /// @notice Will purchase/swap the index tokens in place of ptokens for the index contract
    /// @param id The id of the index contrac
    /// @param amount The amount of p token that we want to use for purchase/swap index tokens
    /// @param slippageallowed The array of slippage percentages
    function purchase(
        uint256 id,
        uint256 amount,
        uint256[] calldata slippageallowed
    )
        external
        onlyOwner
        idcheck(id)
        amountcheck(amount)
        slippagearraycheck(slippageallowed)
        whenNotPaused
    {
        IndexInterface(indexAddressArray[id]).purchase(amount, slippageallowed);
        emit Purchased(id, amount, slippageallowed);
    }

    /// @notice Will sell/swap the index tokens to get ptokens for the index contract
    /// @param id The id of the index contrac
    /// @param amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param slippageallowed The array of slippage percentages
    function sell(
        uint256 id,
        uint256[] calldata amounts,
        uint256[] calldata slippageallowed
    ) external onlyOwner idcheck(id) whenNotPaused {
        IndexInterface(indexAddressArray[id]).sell(amounts, slippageallowed);
        emit Sold(id, amounts, slippageallowed);
    }

    /// @notice Will sell/swap the reward tokens in place of ptokens for the index contract
    /// @param id The id of the index contrac
    /// @param amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param slippageallowed The array of slippage percentages
    function sellRewardTokens(
        uint256 id,
        uint256[] calldata amounts,
        uint256[] calldata slippageallowed
    ) external onlyOwner idcheck(id) whenNotPaused {
        IndexInterface(indexAddressArray[id]).sellrewardtokens(
            amounts,
            slippageallowed
        );
    }

    /// @notice Will purchase/swap the updated index tokens in place of ptokens for the index contract
    /// @param id The id of the index contrac
    /// @param amount The amount of p token that we want to use for purchase/swap index tokens
    /// @param slippageallowed The array of slippage percentages
    function rebalancePurchase(
        uint256 id,
        uint256 amount,
        uint256[] calldata slippageallowed
    ) external onlyOwner idcheck(id) whenNotPaused {
        IndexInterface(indexAddressArray[id]).rebalancepurchase(
            amount,
            slippageallowed
        );
        emit RebalancePurchase(id, amount, slippageallowed);
    }

    /// @notice Will sell/swap the previous index tokens for ptokens for the index contract
    /// @param id The id of the index contrac
    /// @param amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param slippageallowed The array of slippage percentages
    function rebalanceSell(
        uint256 id,
        uint256[] calldata amounts,
        uint256[] calldata slippageallowed
    ) external onlyOwner idcheck(id) whenNotPaused {
        IndexInterface(indexAddressArray[id]).rebalancesell(
            amounts,
            slippageallowed
        );
        emit RebalanceSell(id, amounts, slippageallowed);
    }

    /// @notice Will deposit the ptokens in the index contract
    /// @param id The id of the index contract
    /// @param amount the amount of ptoken
    function deposit(uint256 id, uint256 amount)
        external
        payable
        idcheck(id)
        whenNotPaused
    {
        require(
            (msg.value > 0 && amount == 0) || (amount > 0 && msg.value == 0),
            "eth or tokenamount should be zero"
        );

        address ptoken;
        (ptoken) = IndexInterface(indexAddressArray[id]).getpurchasetoken();

        if (ptoken == WETH && (msg.value > 0)) {
            uint256 _ethamount = msg.value;

            IWETH(WETH).deposit{value: _ethamount}();
            IWETH(WETH).transfer(indexAddressArray[id], _ethamount);
            IndexInterface(indexAddressArray[id]).deposit(
                _ethamount,
                msg.sender
            );
            emit Deposit(id, _ethamount);
        } else {
            IERC20(ptoken).transferFrom(
                msg.sender,
                indexAddressArray[id],
                amount
            );

            IndexInterface(indexAddressArray[id]).deposit(amount, msg.sender);
            emit Deposit(id, amount);
        }
    }

    ///@notice will return the token balance of current tokens of the index
    /// @param id The id of the index contract
    function currentTokenBalance(uint256 id)
        external
        view
        idcheck(id)
        returns (uint256[] memory)
    {
        return IndexInterface(indexAddressArray[id]).currenttokenbalance();
    }

    ///@notice will return the token balance of previous tokens of the index
    /// @param id The id of the index contract
    function previousTokenBalance(uint256 id)
        external
        view
        idcheck(id)
        returns (uint256[] memory)
    {
        return IndexInterface(indexAddressArray[id]).previoustokenbalance();
    }

    ///@notice will return the token balance of ptokens tokens of the index
    /// @param id The id of the index contract
    function pTokenBalance(uint256 id)
        external
        view
        idcheck(id)
        returns (uint256)
    {
        return IndexInterface(indexAddressArray[id]).ptokenbalance();
    }

    ///@notice will return the token balance of reward tokens of the index
    /// @param id The id of the index contract
    function rewardTokenBalance(uint256 id)
        external
        view
        idcheck(id)
        returns (uint256[] memory)
    {
        return IndexInterface(indexAddressArray[id]).rewardtokenbalance();
    }

    ///@notice will add reward token in the reward tokens array in the index
    /// @param id The id of the index contract
    ///@param token The address of the token
    function addRewardToken(uint256 id, address token)
        external
        idcheck(id)
        whenNotPaused
    {
        IndexInterface(indexAddressArray[id]).addrewardtokens(token);
        emit AddRewardToken(id, token);
    }

    ///@notice will set/update the management fee treasury address in the index contract
    /// @param id The id of the index contract
    ///@param managementfeeaddress The address of the management fee treasury
    function setManagementFeeAddress(uint256 id, address managementfeeaddress)
        external
        onlyOwner
        whenNotPaused
        idcheck(id)
        zeroaddresscheck(managementfeeaddress)
    {
        IndexInterface(indexAddressArray[id]).setmanagementfeeaddress(
            managementfeeaddress
        );
        emit SetManagementFeeAddress(id, managementfeeaddress);
    }

    ///@notice will set/update performance fee treasury address in the index contract
    /// @param id The id of the index contract
    ///@param performancefeeaddress The address of the management fee treasury
    function setPerformanceFeeAddress(uint256 id, address performancefeeaddress)
        external
        onlyOwner
        idcheck(id)
        zeroaddresscheck(performancefeeaddress)
        whenNotPaused
    {
        IndexInterface(indexAddressArray[id]).setperformancefeeaddress(
            performancefeeaddress
        );
        emit SetPerformanceFeeAddress(id, performancefeeaddress);
    }

    ///@notice will distribute the ptokens after sell and reward sell
    /// @param id The id of the index contract
    function distributeamount(uint256 id)
        external
        onlyOwner
        idcheck(id)
        whenNotPaused
    {
        IndexInterface(indexAddressArray[id]).distributeamount();
        emit distributeamountEvent(id);
    }

    ///@notice will stake the token in the staking contract
    /// @param id The id of the index contract
    /// @param _token The index token that we want to stake
    /// @param _stakingcontract The address of the staking contract
    /// @param _data call data for calling function in staking contract
    function stake(
        uint256 id,
        address _token,
        address _stakingcontract,
        bytes memory _data
    ) external onlyOwner idcheck(id) whenNotPaused {
        IndexInterface(indexAddressArray[id]).stakewithapprove(
            _token,
            _stakingcontract,
            _data
        );
        emit Stake(id, _token, _stakingcontract);
    }

    ///@notice will unstake the token in the staking contract
    /// @param id The id of the index contract
    /// @param _token The index token that we want to stake
    /// @param _stakingcontract The address of the staking contract
    /// @param _data call data for calling function in staking contract
    function unstake(
        uint256 id,
        address _token,
        address _stakingcontract,
        bytes memory _data
    ) external onlyOwner idcheck(id) whenNotPaused {
        IndexInterface(indexAddressArray[id]).unstake(
            _token,
            _stakingcontract,
            _data
        );
        emit UnStake(id, _token, _stakingcontract);
    }

    ///@notice will approve the index token for an address
    /// @param id The id of the index contract
    /// @param stakingContract The address of the staking contract
    ///@param token The address of the index token that we want to approve
    ///@param amount the amount of the index token that we want to approve
    function approvetoken(
        uint256 id,
        address stakingContract,
        address token,
        uint256 amount
    ) external onlyOwner idcheck(id) whenNotPaused {
        IndexInterface(indexAddressArray[id]).approvetoken(
            stakingContract,
            token,
            amount
        );
        emit ApproveToken(id, token, stakingContract);
    }

    ///@notice will execute any function on the target contract through the index contract
    /// @param id The id of the index contract throu
    /// @param target The address of the contract of which we want to execute function of
    /// @param _func The name of the function that we want to execute
    /// @param _data call data for calling function in staking contract
    function execute(
        uint256 id,
        address target,
        string calldata _func,
        bytes calldata _data
    ) external onlyOwner idcheck(id) whenNotPaused {
        IndexInterface(indexAddressArray[id]).anycontractcall(
            target,
            _func,
            _data
        );
        emit Execute(id, target, _func);
    }

    ///@notice will return the states of the index contract
    /// @param id The id of the index contract that wwant state of
    function returnstates(uint256 id) external view returns (bool[5] memory) {
        return IndexInterface(indexAddressArray[id]).returnstates();
    }

    ///@notice will return the total deposit of ptokens in the index contract
    /// @param id The id of the index contract
    function gettotaldeposit(uint256 id) public view returns (uint256) {
        return IndexInterface(indexAddressArray[id]).gettotaldeposit();
    }

    ///@notice will return the  deposit of ptokens by the user in the index contract
    /// @param id The id of the index contract
    function getdepositbyuser(uint256 id, address user)
        public
        view
        returns (uint256)
    {
        return IndexInterface(indexAddressArray[id]).getdepositbyuser(user);
    }
}
