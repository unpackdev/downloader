// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :5@@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          P@@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? P@@@@@@    .
.   @@@@@G          5@@@@@:     :B@@@@@BJG@@@@@@@@@&B5?~:^7YG#@@@@@@@@BJP@@@ @@&!!     #@@@@@@@@@@@@@? P@@@@@@    .
.   @@@@@G          5@@@@@:    .B@@@@#!!J@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^G@@@@@~.   ^~~~~~^J@ @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. 5@@@@@:   J@@@@&^   G@7?@@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   .B@@@@P           !@@@@@?            .
.   @@@@@@@@@@@@@@! 5@@@@@:   5@@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     Y@@@@#.           !@@@@@?            .
.   @@@@@@@@@@@@@@! P@@@@@:   ?@@@@&^    !YPGPY!  !@@@@@Y&@@@@Y  ~YPGP57.    .B@@@@P           !@@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   .B@@@@&7           ?&@@@@P ?@@@@@5.          ~B@@@@&^            !@@@@@?            .
.   @@@@@G          ^~~~~~.    :G@@@@@BY7~^^~75#@@@@@5.    J@@@@@&P?~^^^!JG@@@@@#~             !@@@@@?            .
.   @@@@@G          5@@@@@:      ?B@@@@@@@@@@@@@@@@B!!      ^P@@@@@@@@@@@@@@@@&Y               !@@@@@?            .
.   @@@@@G.         P@@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                !@@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      ?@@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          ~@@@@@~    :&@@@@7           ~@@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@G?JJJJJJJJ?5@@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   G@@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ !@@@@@~    :&@@@@7            ~@@@&.                         !@@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          !@@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          !@@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          !@@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC165.sol";

contract HootBase is ReentrancyGuard, Pausable, Ownable {
    event PermissionChanged(address indexed addr, uint8 permission);

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event ContractParsed();
    event ContractUnparsed();
    event ContractSealed();

    uint8 public constant NO_PERMISSION = 0;
    uint8 public constant MANAGER = 1;
    uint8 public constant MAINTAINER = 2;
    uint8 public constant OPERATOR = 3;

    mapping(address => uint8) private _permissions;
    address[] maintainers;

    bool public contractSealed = false;

    /***********************************|
    |               Config              |
    |__________________________________*/
    /**
     * @notice setManagerAddress is used to allow the issuer to modify the maintainerAddress
     */
    function setPermission(address address_, uint8 permission_)
        external
        onlyOwner
    {
        if (permission_ == NO_PERMISSION) {
            delete _permissions[address_];
        } else {
            _permissions[address_] = permission_;
        }

        emit PermissionChanged(address_, permission_);
    }

    function getPermissions()
        external
        view
        atLeastManager
        returns (address[] memory, uint8[] memory)
    {
        uint8[] memory permissions = new uint8[](maintainers.length);
        unchecked {
            for (uint256 i = 0; i < maintainers.length; i++) {
                permissions[i] = _permissions[maintainers[i]];
            }
        }
        return (maintainers, permissions);
    }

    function getPermission(address address_) external view returns (uint8) {
        return _permissions[address_];
    }

    /***********************************|
    |               Core                |
    |__________________________________*/
    /**
     * @notice issuer deposit ETH into the contract. only issuer have permission
     */
    function deposit() external payable atLeastMaintainer nonReentrant {
        emit Deposit(_msgSender(), msg.value);
    }

    /**
     * issuer withdraws the ETH temporarily stored in the contract through this method.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |               Basic               |
    |__________________________________*/
    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external atLeastManager notSealed {
        _pause();
        emit ContractParsed();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external atLeastManager notSealed {
        _unpause();
        emit ContractUnparsed();
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner {
        contractSealed = true;
        emit ContractSealed();
    }

    /***********************************|
    |               Modifier            |
    |__________________________________*/
    /**
     * @notice only owner or manager has the permission to call this method
     */
    modifier atLeastManager() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() || permission == MANAGER,
            "not authorized"
        );
        _;
    }
    /**
     * @notice only owner, manager or maintainer has the permission to call this method
     */
    modifier atLeastMaintainer() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() ||
                permission == MAINTAINER ||
                permission == MANAGER,
            "not authorized"
        );
        _;
    }
    /**
     * @notice only owner, manager or maintainer or operator has the permission to call this method
     */
    modifier atLeastOperator() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() ||
                permission == MAINTAINER ||
                permission == MANAGER ||
                permission == OPERATOR,
            "not authorized"
        );
        _;
    }

    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
}
