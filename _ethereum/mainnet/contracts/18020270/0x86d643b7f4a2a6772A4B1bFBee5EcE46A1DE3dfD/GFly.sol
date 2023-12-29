// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IGFlyL1.sol";
import "./ICustomGateway.sol";

//MMMMWKl.                                            .:0WMMMM//
//MMMWk,                                                .dNMMM//
//MMNd.                                                  .lXMM//
//MWd.    .','''....                         .........    .lXM//
//Wk.     ';......'''''.                ..............     .dW//
//K;     .;,         ..,'.            ..'..         ...     'O//
//d.     .;;.           .''.        ..'.            .'.      c//
//:       .','.           .''.    ..'..           ....       '//
//'         .';.            .''...'..           ....         .//
//.           ';.             .''..             ..           .//
//.            ';.                             ...           .//
//,            .,,.                           .'.            .//
//c             .;.                           '.             ;//
//k.            .;.             .             '.            .d//
//Nl.           .;.           .;;'            '.            :K//
//MK:           .;.          .,,',.           '.           'OW//
//MM0;          .,,..       .''  .,.       ...'.          'kWM//
//MMMK:.          ..'''.....'..   .'..........           ,OWMM//
//MMMMXo.             ..'...        ......             .cKMMMM//
//MMMMMWO:.                                          .,kNMMMMM//
//MMMMMMMNk:.                                      .,xXMMMMMMM//
//MMMMMMMMMNOl'.                                 .ckXMMMMMMMMM//

contract GFly is AccessControlUpgradeable, ERC20Upgradeable, IGFlyL1 {
    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    /// @dev The identifier of the role which allows accounts to mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    address public l1GatewayAddress;
    address public routerAddress;
    bool private shouldRegisterGateway;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address dao, address l1GatewayAddress_, address routerAddress_) external initializer {
        __AccessControl_init();
        __ERC20_init("gFLY", "GFLY");

        require(dao != address(0), "GFly:INVALID_ADDRESS");
        require(l1GatewayAddress_ != address(0), "GFly:INVALID_ADDRESS");
        require(routerAddress_ != address(0), "GFly:INVALID_ADDRESS");

        l1GatewayAddress = l1GatewayAddress_;
        routerAddress = routerAddress_;

        _setupRole(MINTER_ROLE, l1GatewayAddress);
        _setupRole(ADMIN_ROLE, dao);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "GFly:MINT_OR_BURN_DENIED");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFly:ACCESS_DENIED");
        _;
    }

    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled() external view override returns (uint8) {
        require(shouldRegisterGateway, "NOT_EXPECTED_CALL");
        return uint8(0xb1);
    }

    /**
     * @dev See {ICustomToken-registerTokenOnL2}
     * In this case, we don't need to call IL1CustomGateway.registerTokenToL2, because our
     * custom gateway works for a single token it already knows.
     */
    function registerTokenOnL2(
        address, /* l2CustomTokenAddress */
        uint256, /* maxSubmissionCostForCustomGateway */
        uint256 maxSubmissionCostForRouter,
        uint256, /*  maxGasForCustomGateway */
        uint256 maxGasForRouter,
        uint256 gasPriceBid,
        uint256, /* valueForGateway */
        uint256 valueForRouter,
        address creditBackAddress
    ) public override payable onlyAdmin {
        // we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = shouldRegisterGateway;
        shouldRegisterGateway = true;

        IL1GatewayRouter(routerAddress).setGateway{ value: valueForRouter }(
            l1GatewayAddress,
            maxGasForRouter,
            gasPriceBid,
            maxSubmissionCostForRouter,
            creditBackAddress
        );

        shouldRegisterGateway = prev;
    }

    /**
    * Should increase token supply by amount, and should only be callable by the Minter (L1Gateway).
    */
    function bridgeMint(address account, uint256 amount) external override onlyMinter {
        _mint(account, amount);
    }

    /**
     * Should decrease token supply by amount, and should only be callable by the Minter (L1Gateway).
     */
    function bridgeBurn(address account, uint256 amount) external override onlyMinter {
        _burn(account, amount);
    }

    /// @dev See {ERC20-transferFrom}
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(IGFlyL1, ERC20Upgradeable) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /// @dev See {ERC20-balanceOf}
    function balanceOf(address account) public view override(IGFlyL1, ERC20Upgradeable) returns (uint256) {
        return super.balanceOf(account);
    }
}
