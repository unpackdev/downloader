
// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/utils/EIP1167/CloneFactory.sol

pragma solidity ^0.5.0;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly


contract CloneFactory {

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query) internal view returns (bool result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
            eq(mload(clone), mload(other)),
            eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// File: contracts/upgradable/OwnableUpgradable.sol

pragma solidity ^0.5.16;

// import "./Initializable.sol";


contract OwnableUpgradable is Initializable {
    address payable public owner;
    address payable internal newOwnerCandidate;


    modifier onlyOwner {
        require(msg.sender == owner, "Permission denied");
        _;
    }


    // ** INITIALIZERS – Constructors for Upgradable contracts **

    function initialize() public initializer {
        owner = msg.sender;
    }

    function initialize(address payable newOwner) public initializer {
        owner = newOwner;
    }


    function changeOwner(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate, "Permission denied");
        owner = newOwnerCandidate;
    }


    uint256[50] private ______gap;
}

// File: contracts/tokenizedStrategy/interfaces/IDfTokenizedStrategy.sol

pragma solidity ^0.5.16;


interface IDfTokenizedStrategy {

    function initialize(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        address payable _owner,
        address _issuer,
        bool _onlyWithProfit,
        bool _transferDepositToOwner,
        uint[5] calldata _params,     // extraCoef [0], profitPercent [1], usdcToBuyEth [2], ethType [3], closingType [4]
        bytes calldata _exchangeData
    ) external payable;

    function profitToken() external returns(address);

}

// File: contracts/tokenizedStrategy/interfaces/IDfTokenizedAdmin.sol

pragma solidity ^0.5.16;


interface IDfTokenizedAdmin {

    function initialize(
        address _dfTokenizedStrategy
    ) external;

}

// File: contracts/tokenizedStrategy/DfTokenizedStrategyFactory.sol

pragma solidity ^0.5.16;







contract DfTokenizedStrategyFactory is Initializable, OwnableUpgradable, CloneFactory {

    // Minimal Proxy Contract – DfTokenizedStrategy Source
    address public dfTokenizedStrategySource;

    // Minimal Proxy Contract – DfTokenizedAdmin Source
    address public dfTokenizedAdminSource;


    // ** EVENTS **

    event TokenizedStrategyCreated(
        address indexed tokenizedStrategy
    );

    event TokenizedAdminCreated(
        address indexed tokenizedAdmin
    );


    // INITIALIZER – Constructor for Upgradable contracts

    function initialize() public initializer {
        OwnableUpgradable.initialize();  // Initialize Parent Contract

        dfTokenizedStrategySource = address(0x04F1a848dD8f7b0fF170D99fad8825631b0102B9);  // TODO: set address
        dfTokenizedAdminSource = address(0);  // TODO: set address
    }


    // ** ONLY_OWNER functions **

    function setDfTokenizedStrategySource(address _dfTokenizedStrategySource) public onlyOwner {
        dfTokenizedStrategySource = _dfTokenizedStrategySource;
    }

    function setDfTokenizedAdminSource(address _dfTokenizedAdminSource) public onlyOwner {
        dfTokenizedAdminSource = _dfTokenizedAdminSource;
    }


    // ** PUBLIC PAYABLE functions **

    function launchStrategy(
        string memory _tokenName,
        string memory _tokenSymbol,
        bool _onlyWithProfit,       // can only be closed with enough profit
        uint[5] memory _params,     // extraCoef [0], profitPercent [1], usdcToBuyEth [2],
                                    // ethType [3], closingType [4] (0 – ANY TYPE, 1 - ETH, 2 - USDC, 3 - ETH+USDC)
        bytes memory _exchangeData
    ) public payable returns(
        address dfTokenizedStrategy
    ) {
        address payable userAddr = msg.sender;

        dfTokenizedStrategy = _launchStrategy(
            _tokenName,
            _tokenSymbol,
            userAddr,       // DfTokenizedStrategy owner
            userAddr,       // issuer of tokens
            _onlyWithProfit,
            true,           // transfer deposit to issuer address after closing
            _params,
            _exchangeData
        );

    }

    function launchStrategyWithProxyAdmin(
        string memory _tokenName,
        string memory _tokenSymbol,
        bool _onlyWithProfit,       // can only be closed with enough profit
        uint[5] memory _params,     // extraCoef [0], profitPercent [1], usdcToBuyEth [2],
                                    // ethType [3], closingType [4] (0 – ANY TYPE, 1 - ETH, 2 - USDC, 3 - ETH+USDC)
        bytes memory _exchangeData
    ) public payable returns(
        address dfTokenizedStrategy,
        address payable dfTokenizedAdmin
    ) {
        dfTokenizedAdmin = address(uint160(_createTokenizedAdmin()));

        dfTokenizedStrategy = _launchStrategy(
            _tokenName,
            _tokenSymbol,
            dfTokenizedAdmin,   // DfTokenizedStrategy owner
            msg.sender,         // issuer of tokens
            _onlyWithProfit,
            false,              // do not transfer deposit to issuer address after closing
            _params,
            _exchangeData
        );

        // set dfTokenizedStrategy address
        IDfTokenizedAdmin(dfTokenizedAdmin).initialize(
            dfTokenizedStrategy
        );
    }


    // ** INTERNAL functions **

    function _launchStrategy(
        string memory _tokenName,
        string memory _tokenSymbol,
        address payable _owner,
        address _issuer,
        bool _onlyWithProfit,
        bool _transferDepositToOwner,
        uint[5] memory _params,     // extraCoef [0], profitPercent [1], usdcToBuyEth [2], ethType [3], closingType [4]
        bytes memory _exchangeData
    ) internal returns(
        address dfTokenizedStrategy
    ) {
        dfTokenizedStrategy = createClone(dfTokenizedStrategySource);

        IDfTokenizedStrategy(dfTokenizedStrategy)
            .initialize
            .value(msg.value)
            (
                _tokenName,
                _tokenSymbol,
                _owner,
                _issuer,
                _onlyWithProfit,
                _transferDepositToOwner,
                _params,
                _exchangeData
            );

        emit TokenizedStrategyCreated(dfTokenizedStrategy);
    }

    function _createTokenizedAdmin() internal returns(
        address dfTokenizedAdmin
    ) {
        dfTokenizedAdmin = createClone(dfTokenizedAdminSource);

        emit TokenizedAdminCreated(dfTokenizedAdmin);
    }

}
