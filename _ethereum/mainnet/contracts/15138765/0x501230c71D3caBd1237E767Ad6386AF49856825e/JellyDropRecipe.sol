pragma solidity 0.8.6;

import "IJellyFactory.sol";
import "IJellyContract.sol";
import "IJellyAccessControls.sol";
import "SafeERC20.sol";
import "SafeMath.sol";

/**
* @title JellyDrop Recipe:
*
*              ,,,,
*            g@@@@@@K
*           l@@@@@@@@P
*            $@@@@@@@"                   l@@@  l@@@
*             "*NNM"                     l@@@  l@@@
*                                        l@@@  l@@@
*             ,g@@@g        ,,gg@gg,     l@@@  l@@@ ,ggg          ,ggg
*            @@@@@@@@p    g@@@EEEEE@@W   l@@@  l@@@  $@@g        ,@@@Y
*           l@@@@@@@@@   @@@P      ]@@@  l@@@  l@@@   $@@g      ,@@@Y
*           l@@@@@@@@@  $@@D,,,,,,,,]@@@ l@@@  l@@@   '@@@p     @@@Y
*           l@@@@@@@@@  @@@@EEEEEEEEEEEE l@@@  l@@@    "@@@p   @@@Y
*           l@@@@@@@@@  l@@K             l@@@  l@@@     '@@@, @@@Y
*            @@@@@@@@@   %@@@,    ,g@@@  l@@@  l@@@      ^@@@@@@Y
*            "@@@@@@@@    "N@@@@@@@@E'   l@@@  l@@@       "*@@@Y
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
*  - Wrapper deployment of all the JellyDrop contracts.
*  - JellyDrop allows for a group of users to claim tokens from a list.
*  - Supports Merkle proofs using the JellyList interface.
*
*/


contract JellyDropRecipe {

    using SafeMath for uint256;
    using SafeERC20 for OZIERC20;

    IJellyFactory public jellyFactory;
    uint256 public feePercentage; 
    address jellyVault;
    bool public locked;

    /// @notice Address that manages approvals.
    IJellyAccessControls public accessControls;

    /// @notice Jelly template id for the pool factory.
    uint256 public constant TEMPLATE_TYPE = 4;
    bytes32 public constant TEMPLATE_ID = keccak256("JELLY_DROP_RECIPE");

    bytes32 public constant AIRDROP_ID = keccak256("JELLY_DROP");
    bytes32 public constant LIST_ID = keccak256("MERKLE_LIST");
    bytes32 public constant ACCESS_ID = keccak256("OPERATOR_ACCESS");
    uint256 private constant PERCENTAGE_PRECISION = 10000;

    event JellyDropDeployed(address airdrop, address token);
    event Recovered(address indexed token, uint256 amount);
    event LockSet(bool locked);
    event FeeSet(uint256 feePercentage);


    /** 
     * @notice Jelly Airdrop Recipe
     * @param _jellyFactory - A factory that makes fresh Jelly
    */
    constructor(
        address _accessControls,
        address _jellyFactory,
        address _jellyVault,
        uint256 _feePercentage
    ) {
        require(_feePercentage < PERCENTAGE_PRECISION, "Fee percentage too high");
        accessControls = IJellyAccessControls(_accessControls);
        jellyFactory = IJellyFactory(_jellyFactory);
        jellyVault = _jellyVault;
        feePercentage = _feePercentage;
        locked = true;
    }

    /**
     * @notice Sets the recipe to be locked or unlocked.
     * @param _locked bool.
     */
    function setLocked(bool _locked) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setLocked: Sender must be admin"
        );
        locked = _locked;
        emit LockSet(_locked);
    }

    /**
     * @notice Sets the vault address.
     * @param _vault Jelly Vault address.
     */
    function setVault(address _vault) external {
        require(accessControls.hasAdminRole(msg.sender), "setVault: Sender must be admin");
        require(_vault != address(0));
        jellyVault = _vault;
    }

    /**
     * @notice Sets the access controls address.
     * @param _accessControls Access controls address.
     */
    function setAccessControls(address _accessControls) external {
        require(accessControls.hasAdminRole(msg.sender), "setAccessControls: Sender must be admin");
        require(_accessControls != address(0));
        accessControls = IJellyAccessControls(_accessControls);
    }

    /**
     * @notice Sets the current fee percentage to deploy.
     * @param _feePercentage The fee percentage to 2 decimals, 2.5% = 250
     */
    function setFeePercentage(uint256 _feePercentage) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "setFeePercentage: Sender must be admin"
        );
        require(_feePercentage < PERCENTAGE_PRECISION, "Fee percentage too high");
        feePercentage = _feePercentage;
        emit FeeSet(_feePercentage);
    }

    function jellyDropTemplate() external view returns (address) {
        return jellyFactory.getContractTemplate(AIRDROP_ID);
    }

    /** 
     * @dev prepare Jelly recipe
     *   
    */
    function prepareJellyDrop(
        address _airdropAdmin,
        address _rewardToken,
        bytes32 _merkleRoot,
        string memory _merkleURI
    )
        external
        returns (address)
    {
        require(_airdropAdmin != address(0), "Admin address not set");
        require(_rewardToken != address(0), "Token address not set");
 
        /// @dev If the contract is locked, only admin and minters can deploy. 
        if (locked) {
            require(accessControls.hasAdminRole(msg.sender) 
                    || accessControls.hasMinterRole(msg.sender),
                "prepareJellyFarm: Sender must be minter if locked"
            );
        }

        // Clone contracts from factory
        address access_controls = jellyFactory.deployContract(
            ACCESS_ID,
            payable(jellyVault), 
            "");
        IJellyAccessControls(access_controls).initAccessControls(address(this));

        address list = jellyFactory.deployContract(
            LIST_ID,
            payable(jellyVault), 
            "");
        IJellyContract(list).initContract(abi.encode(access_controls, _merkleRoot, _merkleURI)); 

        address airdrop = jellyFactory.deployContract(
            AIRDROP_ID,
            payable(jellyVault), 
            "");

        IJellyContract(airdrop).initContract(abi.encode(access_controls, _rewardToken, 0, list, jellyVault, feePercentage)); 
        
        // Set access controls
        IJellyAccessControls(access_controls).addAdminRole(_airdropAdmin);
        IJellyAccessControls(access_controls).addOperatorRole(airdrop);
        IJellyAccessControls(access_controls).removeAdminRole(address(this));

        emit JellyDropDeployed(airdrop, _rewardToken);
        return airdrop;
    }

    receive() external payable {
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
        // OZIERRC20 uses SafeERC20.sol, which hasn't overriden `transfer` method of OZIERC20. Shifting to `safeTransfer` may help
        OZIERC20(tokenAddress).transfer(jellyVault, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

}