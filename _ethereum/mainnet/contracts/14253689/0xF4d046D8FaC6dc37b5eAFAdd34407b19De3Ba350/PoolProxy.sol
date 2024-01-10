pragma solidity 0.8.10;

/***
 *@title PoolProxy
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice Ownership proxy for Insurance Pools
 */

//dao-contracts
import "./IDistributor.sol";

//pool-contracts
import "./ICDSTemplate.sol";
import "./IFactory.sol";
import "./IIndexTemplate.sol";
import "./IOwnership.sol";
import "./IParameters.sol";
import "./IPoolTemplate.sol";
import "./IPremiumModel.sol";
import "./IRegistry.sol";
import "./IUniversalMarket.sol";
import "./IVault.sol";

//libraries
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract PoolProxy is ReentrancyGuard {
    using SafeERC20 for IERC20;

    event CommitAdmins(
        address ownership_admin,
        address parameter_admin,
        address emergency_admin
    );
    event ApplyAdmins(
        address ownership_admin,
        address parameter_admin,
        address emergency_admin
    );
    event CommitDefaultReportingAdmin(address default_reporting_admin);
    event AcceptDefaultReportingAdmin(address default_reporting_admin);
    event SetReportingAdmin(address pool, address reporter);

    event AddDistributor(address distributor);

    address public ownership_admin;
    address public parameter_admin;
    address public emergency_admin;
    address public default_reporting_admin; //default reporting module address when arbitrary reporting module is not set.
    mapping(address => address) public reporting_admin; //Pool => Payout Decision Maker's address. (ex. ReportingDAO)

    address parameters; //pool-contracts Parameters.sol

    address public future_ownership_admin;
    address public future_parameter_admin;
    address public future_emergency_admin;
    address public future_default_reporting_admin;

    struct Distributor {
        string name;
        address addr;
    }

    /***
    USDC
    id 0 = dev
    id 1 = buy back and burn
    id 2 = reporting member
    */

    mapping(address => mapping(uint256 => Distributor)) public distributors; // token distibutor contracts. token => ID => Distributor / (ex. USDC => 1 => FeeDistributorV1)
    mapping(address => uint256) public n_distributors; //token => distrobutor#
    mapping(address => mapping(uint256 => uint256)) public distributor_weight; // token => ID => weight
    mapping(address => mapping(uint256 => uint256)) public distributable; //distributor => allocated amount
    mapping(address => uint256) public total_weights; //token => total allocation point

    bool public distributor_kill;

    constructor(
        address _ownership_admin,
        address _parameter_admin,
        address _emergency_admin
    ) {
        ownership_admin = _ownership_admin;
        parameter_admin = _parameter_admin;
        emergency_admin = _emergency_admin;
    }

    //==================================[Fee Distributor]==================================//
    /***
     *@notice add new distributor.
     *@dev distributor weight is 0 at the moment of addition.
     *@param _token address of fee token
     *@param _name FeeDistributor name
     *@param _addr FeeDistributor address
     */
    function add_distributor(
        address _token,
        string memory _name,
        address _addr
    ) external returns(bool) {
        require(msg.sender == ownership_admin, "only ownership admin");
        require(_token != address(0), "_token cannot be zero address");

        Distributor memory new_distributor = Distributor({
            name: _name,
            addr: _addr
        });
        uint256 id = n_distributors[_token];
        distributors[_token][id] = new_distributor;
        n_distributors[_token] += 1;

        return true;
    }

    /***
     *@notice overwrites new distributor to distributor already existed;
     *@dev new distributor takes over the old distributor's weight and distributable state;
     */
    function _set_distributor(
        address _token,
        uint256 _id,
        Distributor memory _distributor
    ) internal {
        require(_id < n_distributors[_token], "distributor not added yet");

        //if Distributor set to ZERO_ADDRESS, set the weight to 0.
        if (_distributor.addr == address(0)) {
            _set_distributor_weight(_token, _id, 0);
        }

        distributors[_token][_id] = _distributor;
    }

    /***
     *@notice Set new distributor or name or both.
     *@dev id has to be added already.
     *@param _token Fee Token address
     *@param _id Distributor id
     *@param _name Distributor name
     *@param _distributor Distributor address
     */
    function set_distributor(
        address _token,
        uint256 _id,
        string memory _name,
        address _distributor
    ) external {
        require(msg.sender == ownership_admin, "only ownership admin");

        Distributor memory new_distributor = Distributor(_name, _distributor);

        _set_distributor(_token, _id, new_distributor);
    }

    /***
     *@notice set new weight to a distributor
     *@param _token fee token address
     *@param _id distributor id
     *@param _weight new weight of the distributor
     */
    function _set_distributor_weight(
        address _token,
        uint256 _id,
        uint256 _weight
    ) internal {
        require(_id < n_distributors[_token], "distributor not added yet");
        require(
            distributors[_token][_id].addr != address(0),
            "distributor not set"
        );

        uint256 new_weight = _weight;
        uint256 old_weight = distributor_weight[_token][_id];

        //update distibutor weight and total_weight
        distributor_weight[_token][_id] = new_weight;
        total_weights[_token] = total_weights[_token] + new_weight - old_weight;
    }

    /***
     *@notice set new weight to a distributor
     *@param _token fee token address
     *@param _id distributor id
     *@param _weight new weight of the distributor
     */
    function set_distributor_weight(
        address _token,
        uint256 _id,
        uint256 _weight
    ) external returns(bool) {
        require(msg.sender == parameter_admin, "only parameter admin");

        _set_distributor_weight(_token, _id, _weight);

        return true;
    }

    /***
     *@notice set new weights to distributors[20]
     *@param _tokens fee token addresses[20]
     *@param _ids distributor ids[20]
     *@param _weights new weights of the distributors[20]
     *@dev [20] 20 is ramdomly decided and has no meaning.
     */
    function set_distributor_weight_many(
        address[20] memory _tokens,
        uint256[20] memory _ids,
        uint256[20] memory _weights
    ) external {
        require(msg.sender == parameter_admin, "only parameter admin");

        for (uint256 i; i < 20;) {
            if (_tokens[i] == address(0)) {
                break;
            }
            _set_distributor_weight(_tokens[i], _ids[i], _weights[i]);
            unchecked {
                ++i;
            }
        }
    }

    /***
     *@notice Get Function for distributor's name
     *@param _token fee token address
     *@param _id distributor id
     */
    function get_distributor_name(address _token, uint256 _id)
    external
    view
    returns(string memory) {
        return distributors[_token][_id].name;
    }

    /***
     *@notice Get Function for distributor's address
     *@param _token fee token address
     *@param _id distributor id
     */
    function get_distributor_address(address _token, uint256 _id)
    external
    view
    returns(address) {
        return distributors[_token][_id].addr;
    }

    //==================================[Fee Distribution]==================================//
    /***
     *@notice Withdraw admin fees from `_vault`
     *@dev any account can execute this function
     *@param _token fee token address to withdraw and allocate to the token's distributors
     */
    function withdraw_admin_fee(address _token) external nonReentrant {
        require(_token != address(0), "_token cannot be zero address");

        address _vault = IParameters(parameters).getVault(_token); //dev: revert when parameters not set
        uint256 amount = IVault(_vault).withdrawAllAttribution(address(this));

        if (amount != 0) {
            //allocate the fee to corresponding distributors
            uint256 _distributors = n_distributors[_token];
            for (uint256 id; id < _distributors;) {
                uint256 aloc_point = distributor_weight[_token][id];

                uint256 aloc_amount = (amount * aloc_point) /
                    total_weights[_token]; //round towards zero.
                distributable[_token][id] += aloc_amount; //count up the allocated fee
                unchecked {
                    ++id;
                }
            }
        }
    }

    /***
     *@notice Re_allocate _token in this contract with the latest allocation. For token left after rounding down or switched to zero_address
     */
    /**
    function re_allocate(address _token)external{
        //re-allocate the all fee token in this contract with the current allocation.

        require(msg.sender == ownership_admin, "Access denied");

        uint256 amount = IERC20(_token).balanceOf(address(this));

        //allocate the fee to corresponding distributors
        for(uint256 id=0; id<n_distributors[_token]; id++){
            uint256 aloc_point = distributor_weight[_token][id];

            uint256 aloc_amount = amount.mul(aloc_point).div(total_weights[_token]); //round towards zero.
            distributable[_token][id] = aloc_amount;
        }
    }
    */

    /***
     *@notice distribute accrued `_token` via a preset distributor
     *@param _token fee token to be distributed
     *@param _id distributor id
     */
    function _distribute(address _token, uint256 _id) internal {
        require(_id < n_distributors[_token], "distributor not added yet");

        address _addr = distributors[_token][_id].addr;
        uint256 amount = distributable[_token][_id];
        distributable[_token][_id] = 0;

        IERC20(_token).safeApprove(_addr, amount);
        require(
            IDistributor(_addr).distribute(_token),
            "dev: should implement distribute()"
        );
    }

    /***
     *@notice distribute accrued `_token` via a preset distributor
     *@dev Only callable by an EOA to prevent
     *@param _token fee token to be distributed
     *@param _id distributor id
     */
    function distribute(address _token, uint256 _id) external nonReentrant {
        require(tx.origin == msg.sender); //only EOA
        require(!distributor_kill, "distributor is killed");

        _distribute(_token, _id);
    }

    /***
     *@notice distribute accrued admin fees from multiple coins
     *@dev Only callable by an EOA to prevent flashloan exploits
     *@param _id List of distributor id
     */
    function distribute_many(
        address[20] memory _tokens,
        uint256[20] memory _ids
    ) external nonReentrant {
        //any EOA
        require(tx.origin == msg.sender);
        require(!distributor_kill, "distribution killed");

        for (uint256 i; i < 20;) {
            if (_tokens[i] == address(0)) {
                break;
            }
            _distribute(_tokens[i], _ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /***
    @notice Kill or unkill `distribute` functionality
    @param _is_killed Distributor kill status
    */
    function set_distributor_kill(bool _is_killed) external {
        require(
            msg.sender == emergency_admin || msg.sender == ownership_admin,
            "Access denied"
        );
        distributor_kill = _is_killed;
    }

    //==================================[Configuration]==================================//
    // admins
    function commit_set_admins(
        address _o_admin,
        address _p_admin,
        address _e_admin
    ) external {
        /***
         *@notice Set ownership admin to `_o_admin`, parameter admin to `_p_admin` and emergency admin to `_e_admin`
         *@param _o_admin Ownership admin
         *@param _p_admin Parameter admin
         *@param _e_admin Emergency admin
         */
        require(msg.sender == ownership_admin, "Access denied");

        future_ownership_admin = _o_admin;
        future_parameter_admin = _p_admin;
        future_emergency_admin = _e_admin;

        emit CommitAdmins(_o_admin, _p_admin, _e_admin);
    }

    /***
     *@notice Accept the effects of `commit_set_admins`
     */
    function accept_set_admins() external {
        require(msg.sender == future_ownership_admin, "Access denied");

        ownership_admin = future_ownership_admin;
        parameter_admin = future_parameter_admin;
        emergency_admin = future_emergency_admin;

        emit ApplyAdmins(ownership_admin, parameter_admin, emergency_admin);
    }

    //==================================[Reporting Module]==================================//
    /***
     *@notice Set reporting admin to `_r_admin`
     *@param _pool Target address
     *@param _r_admin Reporting admin
     */
    function commit_set_default_reporting_admin(address _r_admin) external {
        require(msg.sender == ownership_admin, "Access denied");

        future_default_reporting_admin = _r_admin;

        emit CommitDefaultReportingAdmin(future_default_reporting_admin);
    }

    /***
     *@notice Accept the effects of `commit_set_default_reporting_admin`
     */
    function accept_set_default_reporting_admin() external {
        require(msg.sender == future_default_reporting_admin, "Access denied");

        default_reporting_admin = future_default_reporting_admin;

        emit AcceptDefaultReportingAdmin(default_reporting_admin);
    }

    /***
     *@notice set arbitrary reporting module for specific _pool.
     *@notice "ownership_admin" or "default_reporting_admin" can execute this function.
     */
    function set_reporting_admin(address _pool, address _reporter)
    external
    returns(bool) {
        require(
            address(msg.sender) == ownership_admin ||
            address(msg.sender) == default_reporting_admin,
            "Access denied"
        );

        reporting_admin[_pool] = _reporter;

        emit SetReportingAdmin(_pool, _reporter);

        return true;
    }

    /***
     *@notice get reporting module set for the _pool. If none is set, default_reporting_admin will be returned.
     *@dev public function
     */
    function get_reporter(address _pool) public view returns(address) {

        address reporter = reporting_admin[_pool] != address(0) ?
            reporting_admin[_pool] :
            default_reporting_admin;

        return reporter;
    }

    //==================================[Pool Contracts]==================================//
    /***
     * pool-contracts' owner is this contract.
     * For the detail of each function, see the pool-contracts repository.
     */
    //ownership
    function ownership_accept_transfer_ownership(address _ownership_contract)
    external {
        require(msg.sender == ownership_admin, "Access denied");

        IOwnership(_ownership_contract).acceptTransferOwnership();
    }

    function ownership_commit_transfer_ownership(
        address _ownership_contract,
        address newOwner
    ) external {
        require(msg.sender == ownership_admin, "Access denied");

        IOwnership(_ownership_contract).commitTransferOwnership(newOwner);
    }

    //Factory
    function factory_approve_template(
        address _factory,
        address _template_addr,
        bool _approval,
        bool _isOpen,
        bool _duplicate
    ) external {
        require(msg.sender == ownership_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).approveTemplate(
            _template,
            _approval,
            _isOpen,
            _duplicate
        );
    }

    function factory_approve_reference(
        address _factory,
        address _template_addr,
        uint256 _slot,
        address _target,
        bool _approval
    ) external {
        require(msg.sender == ownership_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).approveReference(
            _template,
            _slot,
            _target,
            _approval
        );
    }

    function factory_set_condition(
        address _factory,
        address _template_addr,
        uint256 _slot,
        uint256 _target
    ) external {
        require(msg.sender == ownership_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).setCondition(_template, _slot, _target);
    }

    function factory_create_market(
        address _factory,
        address _template_addr,
        string memory _metaData,
        uint256[] memory _conditions,
        address[] memory _references
    ) external returns(address) {
        require(msg.sender == ownership_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        address _market = IFactory(_factory).createMarket(
            _template,
            _metaData,
            _conditions,
            _references
        );

        return _market;
    }

    //Premium model
    function pm_set_premium(
        address _premium,
        uint256 _multiplierPerYear,
        uint256 _initialBaseRatePerYear,
        uint256 _finalBaseRatePerYear,
        uint256 _goalTVL
    ) external {
        require(msg.sender == parameter_admin, "Access denied");
        IPremiumModel(_premium).setPremiumParameters(
            _multiplierPerYear,
            _initialBaseRatePerYear,
            _finalBaseRatePerYear,
            _goalTVL
        );
    }

    //Universal(Pool/Index/CDS)
    function pm_set_paused(address _pool, bool _state) external nonReentrant {
        require(
            msg.sender == emergency_admin || msg.sender == ownership_admin,
            "Access denied"
        );
        IUniversalMarket(_pool).setPaused(_state);
    }

    function pm_change_metadata(address _pool, string calldata _metadata)
    external {
        require(msg.sender == parameter_admin, "Access denied");
        IUniversalMarket(_pool).changeMetadata(_metadata);
    }

    //Pool
    function pool_apply_cover(
        address _pool,
        uint256 _pending,
        uint256 _payoutNumerator,
        uint256 _payoutDenominator,
        uint256 _incidentTimestamp,
        bytes32 _merkleRoot,
        string calldata _rawdata,
        string calldata _memo
    ) external {
        require(msg.sender == default_reporting_admin || msg.sender == reporting_admin[_pool], "Access denied");

        IPoolTemplate(_pool).applyCover(
            _pending,
            _payoutNumerator,
            _payoutDenominator,
            _incidentTimestamp,
            _merkleRoot,
            _rawdata,
            _memo
        );
    }

    function pool_apply_bounty(
        address _pool,
        uint256 _amount,
        address _contributor,
        uint256[] calldata _ids
    ) external {
        require(msg.sender == default_reporting_admin || msg.sender == reporting_admin[_pool], "Access denied");

        IPoolTemplate(_pool).applyBounty(
            _amount,
            _contributor,
            _ids
        );
    }

    //Index
    function index_set_leverage(address _index, uint256 _target) external {
        require(msg.sender == parameter_admin, "Access denied");

        IIndexTemplate(_index).setLeverage(_target);
    }

    function index_set(
        address _index_address,
        uint256 _indexA,
        uint256 _indexB,
        address _pool,
        uint256 _allocPoint
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IIndexTemplate(_index_address).set(_indexA, _indexB, _pool, _allocPoint);
    }

    //CDS
    function defund(address _cds, address _to, uint256 _amount) external {
        require(msg.sender == ownership_admin, "Access denied");

        ICDSTemplate(_cds).defund(_to, _amount);
    }

    //Vault
    function vault_withdraw_redundant(
        address _vault,
        address _token,
        address _to
    ) external {
        require(msg.sender == ownership_admin, "Access denied");
        IVault(_vault).withdrawRedundant(_token, _to);
    }

    function vault_set_keeper(address _vault, address _keeper) external {
        require(msg.sender == ownership_admin, "Access denied");
        IVault(_vault).setKeeper(_keeper);
    }

    function vault_set_controller(address _vault, address _controller)
    external {
        require(msg.sender == ownership_admin, "Access denied");
        IVault(_vault).setController(_controller);
    }

    //Parameters
    function set_parameters(address _parameters) external {
        /***
         * @notice set parameter contract
         */

        require(msg.sender == ownership_admin, "Access denied");
        parameters = _parameters;
    }

    function parameters_set_vault(
        address _parameters,
        address _token,
        address _vault
    ) external {
        require(msg.sender == ownership_admin, "Access denied");

        IParameters(_parameters).setVault(_token, _vault);
    }

    function parameters_set_lockup(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setLockup(_address, _target);
    }

    function parameters_set_grace(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setGrace(_address, _target);
    }

    function parameters_set_mindate(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setMinDate(_address, _target);
    }

    function parameters_set_upper_slack(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setUpperSlack(_address, _target);
    }

    function parameters_set_lower_slack(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setLowerSlack(_address, _target);
    }

    function parameters_set_withdrawable(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setWithdrawable(_address, _target);
    }

    function parameters_set_premium_model(
        address _parameters,
        address _address,
        address _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setPremiumModel(_address, _target);
    }

    function setFeeRate(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setFeeRate(_address, _target);
    }

    function parameters_set_max_list(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setMaxList(_address, _target);
    }

    function parameters_set_condition_parameters(
        address _parameters,
        bytes32 _reference,
        bytes32 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setCondition(_reference, _target);
    }

    //Registry
    function registry_set_factory(address _registry, address _factory)
    external {
        require(msg.sender == ownership_admin, "Access denied");

        IRegistry(_registry).setFactory(_factory);
    }

    function registry_support_market(address _registry, address _market)
    external {
        require(msg.sender == ownership_admin, "Access denied");

        IRegistry(_registry).supportMarket(_market);
    }

    function registry_set_existence(
        address _registry,
        address _template,
        address _target
    ) external {
        require(msg.sender == ownership_admin, "Access denied");

        IRegistry(_registry).setExistence(_template, _target);
    }

    function registry_set_cds(
        address _registry,
        address _address,
        address _target
    ) external {
        require(msg.sender == ownership_admin, "Access denied");

        IRegistry(_registry).setCDS(_address, _target);
    }
}