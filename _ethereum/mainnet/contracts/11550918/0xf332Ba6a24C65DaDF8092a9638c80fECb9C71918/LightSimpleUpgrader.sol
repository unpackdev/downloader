pragma solidity ^0.6.12;

interface IWallet {
    function authoriseModule(address _module, bool _value) external;
}

interface IModule {
    /**
     * @notice Inits a module for a wallet by e.g. setting some wallet specific parameters in storage.
     * @param _wallet The wallet.
     */
    function init(address _wallet) external;

    /**	
     * @notice Adds a module to a wallet. Cannot execute when wallet is locked (or under recovery)	
     * @param _wallet The target wallet.	
     * @param _module The modules to authorise.	
     */	
    function addModule(address _wallet, address _module) external;
}

contract LightSimpleUpgrader is IModule {

    address[] public toDisable;
    address[] public toEnable;

    // *************** Constructor ********************** //

    constructor(
        address[] memory _toDisable,
        address[] memory _toEnable
    )
        public
    {
        toDisable = _toDisable;
        toEnable = _toEnable;
    }

    // *************** External/Public Functions ********************* //

    /**
     * @notice Perform the upgrade for a wallet. This method gets called when SimpleUpgrader is temporarily added as a module.
     * @param _wallet The target wallet.
     */
    function init(address _wallet) external override {
        require(msg.sender == _wallet, "SU: only wallet can call init");

        uint256 i = 0;
        //add new modules
        for (; i < toEnable.length; i++) {
            IWallet(_wallet).authoriseModule(toEnable[i], true);
        }
        //remove old modules
        for (i = 0; i < toDisable.length; i++) {
            IWallet(_wallet).authoriseModule(toDisable[i], false);
        }
        // SimpleUpgrader did its job, we no longer need it as a module
        IWallet(_wallet).authoriseModule(address(this), false);
    }

    /**
     * @inheritdoc IModule
     */
    function addModule(address _wallet, address _module) external override {}
}