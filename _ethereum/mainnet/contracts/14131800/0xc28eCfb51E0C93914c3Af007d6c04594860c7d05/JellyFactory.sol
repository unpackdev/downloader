pragma solidity 0.8.6;

import "IBentoBoxFactory.sol";
import "IJellyContract.sol";
import "IERC20.sol";

import "BoringMath.sol";
import "JellyAccessControls.sol";

/**
* @title Jelly Factory:
*
*              ,,,,
*            g@@@@@@K
*           l@@@@@@@@P
*            $@@@@@@@"                   l@@@  l@@@
*             "*NNM"                     l@@@  l@@@
*                                        l@@@  l@@@
*             ,g@@@g        ,,gg@gg,     l@@@  l@@@ ,ggg          ,ggg
*            @@@@@@@@p    g@@@EEEEE@@W   l@@@  l@@@  $@@@        ,@@@Y
*           l@@@@@@@@@   @@@P      ]@@@  l@@@  l@@@   $@@g      ,@@@Y
*           l@@@@@@@@@  $@@D,,,,,,,,]@@@ l@@@  l@@@   '@@@p     @@@Y
*           l@@@@@@@@@  @@@@EEEEEEEEEEEE l@@@  l@@@    "@@@p   @@@Y
*           l@@@@@@@@@  l@@K             l@@@  l@@@     '@@@, @@@Y
*            @@@@@@@@@   %@@@,    ,g@@@  l@@@  l@@@      ^@@@@@@Y
*            "@@@@@@@@    "N@@@@@@@@E*   l@@@  l@@@       "*@@@Y
*             "J@@@@@@        "**""       '''   '''        @@@Y
*    ,gg@@g    "J@@@P                                     @@@Y
*   @@@@@@@@p    J@@'                                    @@@Y
*   @@@@@@@@P    J@h                                    RNNY
*   'B@@@@@@     $P
*       "JE@@@p"'
*
*
*/

/**
* @author ProfWobble
* @dev
*  - Generalised smart contract template factory
*  - Supports contracts with the IJellyContract interface
*  - Fees can be set at the template level.
*
*/

contract JellyFactory  {

    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;

    /// @notice Responsible for access rights to the contract.
    JellyAccessControls public accessControls;

    /// PW: Give people the chance to use Spell factory, or a whitelist of bentoboxes.
    IBentoBoxFactory public bentoBox;

    bytes32 public constant CONTRACT_MINTER_ROLE = keccak256("CONTRACT_MINTER_ROLE");

    /// @notice Struct to track Contract template.
    struct Contract {
        bool active;
        uint64 templateType;
        uint64 contractIndex;
        bytes32 templateId;
    }

    /// @notice Mapping from contract created through this contract to Contract struct.
    mapping(address => Contract) public contractInfo;

    /// @notice Contracts created using factory.
    address[] public contracts;

    /// @notice Struct to track Contract template.
    struct Template {
        uint64 currentTemplateId;
        uint128 minimumFee;
        uint32 integratorFeePct;
        bool locked;
        address feeAddress;
        uint64[] contractIds;
    }

    // /// @notice mapping from template type to template id
    mapping(bytes32 => Template) public templateInfo;

    /// @notice Template id to track respective contract template.
    uint256 public contractTemplateCount;

    /// @notice Mapping from template id to contract template
    mapping(bytes32 => address) private contractTemplates;

    ///@notice Any donations if set are sent here.
    address payable public jellyWallet;

    /// @notice New JellyFactory address.
    address public newAddress;

    /// @notice Event emitted when template is added to factory.
    event ContractTemplateAdded(address newContract, bytes32 templateId);

    /// @notice Event emitted when contract template is removed.
    event ContractTemplateRemoved(address contractAddr, bytes32 templateId);

    /// @notice Event emitted when contract is created using template id.
    event ContractCreated(address indexed owner, address indexed addr, address contractTemplate);

    /// @notice Event emitted when factory is deprecated.
    event FactoryDeprecated(address newAddress);

    /// @notice Event emitted when tokens are recovered.
    event Recovered(address indexed token, uint256 amount);

    /// @notice Event emitted when template fee changes.
    event SetFee(bytes32 indexed templateId, uint256 amount);

    /// @notice Event emitted when templates are locked.
    event SetLock(bytes32 indexed templateId, bool lock);

    /**
     * @notice Initializes the factory.
     * @param _accessControls Sets address to get the access controls from.
     */
    constructor(address _accessControls, address _bentoBox) {
        require(_accessControls != address(0), "accessControls cannot be set to zero");
        require(_bentoBox != address(0), "bentoBox cannot be set to zero");

        accessControls = JellyAccessControls(_accessControls);
        bentoBox = IBentoBoxFactory(_bentoBox);

        contractTemplateCount = 0;
    }


    /**
     * @notice Sets the minimum fee.
     * @param _amount Fee amount.
     */
    function setMinimumFee(bytes32 _templateId, uint256 _amount) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyFactory: Sender must be operator"
        );
        templateInfo[_templateId].minimumFee = BoringMath.to128(_amount);
        emit SetFee(_templateId, _amount);
    }

    /**
     * @notice Sets the minimum fee.
     * @param _amount Fee amount.
     */
    function setIntegratorFeePct(bytes32 _templateId, uint256 _amount) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyFactory: Sender must be operator"
        );
        require(_amount <= 1000, "Percentage is out of 1000");
        templateInfo[_templateId].integratorFeePct = BoringMath.to32(_amount);
    }

    /**
     * @notice Sets the factory to be locked or unlocked.
     * @param _locked bool.
     */
    function setLocked(bytes32 _templateId, bool _locked) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyFactory: Sender must be admin"
        );
        templateInfo[_templateId].locked = _locked;
        emit SetLock(_templateId, _locked);

    }

    /**
     * @notice Sets dividend address.
     * @param _wallet Dividend address.
     */
    function setWallet(address payable _wallet) external {
        require(accessControls.hasAdminRole(msg.sender), "JellyFactory: Sender must be admin");
        require(_wallet != address(0));
        jellyWallet = _wallet;
    }

    /**
     * @notice Sets Bentobox address.
     * @param _bentoBox Bentobox address.
     */
    function setBentoBox(address payable _bentoBox) external {
        require(accessControls.hasAdminRole(msg.sender), "JellyFactory: Sender must be admin");
        require(_bentoBox != address(0), "bentoBox cannot be set to zero");
        bentoBox = IBentoBoxFactory(_bentoBox);
    }

    /**
     * @notice Sets the current template ID for any type.
     * @param _templateId ID of template.
     * @param _feeAddr The address fees are denominated.
     */
    function setTemplateFeeAddr(bytes32 _templateId, address _feeAddr) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "JellyFactory: Sender must be admin"
        );
        templateInfo[_templateId].feeAddress = _feeAddr;
    }


    /**
     * @notice Used to check whether an address has the minter role
     * @param _address EOA or contract being checked
     * @return bool True if the account has the role or false if it does not
     */
    function hasContractMinterRole(address _address) public view returns (bool) {
        return accessControls.hasRole(CONTRACT_MINTER_ROLE, _address);
    }

    /**
     * @notice Used to get array indexes for a template ID
     * @param _templateId Template ID being checked
     */
    function getContractIds(bytes32 _templateId) public view returns (uint64[] memory) {
        return templateInfo[_templateId].contractIds;
    }


    /**
     * @notice Creates a new contract cloned from template.
     * @param _templateId Id of the template to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @return newContract Contract address.
     */
    function deployContract(
        bytes32 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    )
        external payable returns (address newContract)
    {
        newContract = _deployContract(_templateId, _integratorFeeAccount, _data, false);
        return newContract;
    }

    /**
     * @notice Creates a new JellyFactory from template using CREATE2.
     * @param _templateId Id of the template to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @return newContract Contract address.
     */
    function deploy2Contract(
        bytes32 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    )
        external payable returns (address newContract)
    {
        newContract = _deployContract(_templateId, _integratorFeeAccount, _data, true);
        return newContract;
    }


    /**
     * @notice Creates a new JellyFactory from template _templateId and transfers fees.
     * @param _templateId Id of the template to create.
     * @param _integratorFeeAccount Address to pay the fee to.
     * @return newContract Contract address.
     */
    function _deployContract(
        bytes32 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data,
        bool _useCreate2
    )
        internal returns (address newContract)
    {

        Template memory template = templateInfo[_templateId];

        /// @dev If the contract is locked, only admin and minters can deploy.
        if (template.locked) {
            require(accessControls.hasAdminRole(msg.sender)
                    || accessControls.hasMinterRole(msg.sender)
                    || hasContractMinterRole(msg.sender),
                "JellyFactory: Sender must be minter if locked"
            );
        }

        // PW: Convert this to erc20 transfers based on feeAddress
        address contractTemplate = contractTemplates[_templateId];
        require(contractTemplate != address(0), "JellyFactory: Contract template doesn't exist");
        require(msg.value >= uint256(template.minimumFee), "JellyFactory: Failed to transfer minimumFee");
        uint256 integratorFee = 0;
        uint256 jellyFee = msg.value;
        if (_integratorFeeAccount != address(0) && _integratorFeeAccount != jellyWallet) {
            integratorFee = jellyFee * uint256(template.integratorFeePct) / 1000;
            jellyFee = jellyFee - integratorFee;
        }
        if (jellyFee > 0) {
            jellyWallet.transfer(jellyFee);
        }
        if (integratorFee > 0) {
            _integratorFeeAccount.transfer(integratorFee);
        }

        /// @dev Deploy using the BentoBox factory.
        newContract = bentoBox.deploy(contractTemplate, _data, _useCreate2);

        uint256 templateType = IJellyContract(newContract).TEMPLATE_TYPE();
        uint64 contractCount = BoringMath.to64(contracts.length);
        contractInfo[address(newContract)] = Contract(true, BoringMath.to64(templateType), contractCount, _templateId);
        templateInfo[_templateId].contractIds.push(contractCount);
        contracts.push(address(newContract));
        emit ContractCreated(msg.sender, address(newContract), contractTemplate);
    }



    /**
     * @notice Function to add an contract template to create through factory.
     * @dev Should have operator access.
     * @param _template Contract template to create an contract.
     */
    function addContractTemplate(address _template) external {
        require(
            accessControls.hasAdminRole(msg.sender) ||
            accessControls.hasOperatorRole(msg.sender),
            "JellyFactory: Sender must be operator"
        );
        require(_template != address(0), "JellyFactory: No template address");

        uint256 templateType = IJellyContract(_template).TEMPLATE_TYPE();
        bytes32 templateId = IJellyContract(_template).TEMPLATE_ID();

        require(templateType > 0, "JellyFactory: Incorrect template code");

        /// @dev If template type doesnt yet exist, set it to locked
        if (templateInfo[templateId].currentTemplateId == 0) {
            templateInfo[templateId].locked = true;
        }
        contractTemplateCount++;

        contractTemplates[templateId] = _template;
        templateInfo[templateId].currentTemplateId = BoringMath.to64(contractTemplateCount);
        emit ContractTemplateAdded(_template, templateId);
    }

    /**
     * @dev Function to remove an contract template.
     * @dev Should have operator access.
     * @param _templateId Refers to template that is to be deleted.
     */
    function removeContractTemplate(bytes32 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) ||
            accessControls.hasOperatorRole(msg.sender),
            "JellyFactory: Sender must be operator"
        );
        address template = contractTemplates[_templateId];
        contractTemplates[_templateId] = address(0);

        emit ContractTemplateRemoved(template, _templateId);
    }


    /**
     * @notice Deprecates factory.
     * @param _newAddress Blank address.
     */
    function deprecateFactory(address _newAddress) external {
        require(accessControls.hasAdminRole(msg.sender), "JellyFactory: Sender must be admin");
        require(newAddress == address(0));
        emit FactoryDeprecated(_newAddress);
        newAddress = _newAddress;
    }

    /**
     * @notice Get the address based on template ID.
     * @param _templateId Contract template ID.
     * @return Address of the required template ID.
     */
    function getContractTemplate(bytes32 _templateId) external view returns (address) {
        return contractTemplates[_templateId];
    }

    /**
     * @notice Get the ID based on template address.
     * @param _contractTemplate Contract template address.
     * @return ID of the required template address.
     */
    function getTemplateId(address _contractTemplate) external view returns (bytes32) {
        return contractInfo[_contractTemplate].templateId;
    }

    /**
     * @notice Get contracts based on template ID.
     * @param _templateId Contract template ID.
     * @return Contracts with a specific template ID.
     */
    function getContractsByTemplateId(bytes32 _templateId) external view returns (address[] memory) {
        uint64[] memory contractIds = templateInfo[_templateId].contractIds;
        address[] memory _contracts = new address[](contractIds.length);
        for (uint256 i = 0;i < contractIds.length; i++) {
            _contracts[i] = contracts[i];
        }
        return _contracts;
    }

    /**
     * @notice Get the total number of contracts in the factory.
     * @return Contract count.
     */
    function numberOfDeployedContracts() external view returns (uint) {
        return contracts.length;
    }

    function minimumFee(bytes32 _templateId) external view returns(uint128) {
        return templateInfo[_templateId].minimumFee;
    }

    function getContracts() external view returns(address[] memory) {
        return contracts;
    }

    function getContractTemplateId(address _contract) external view returns(bytes32) {
        return contractInfo[_contract].templateId;
    }

    // Token recovery
    receive () external payable {
        revert();
    }

    /// @notice allows for the recovery of incorrect ERC20 tokens sent to contract
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "recoverERC20: Sender must be admin"
        );
        IERC20(tokenAddress).transfer(jellyWallet, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

}