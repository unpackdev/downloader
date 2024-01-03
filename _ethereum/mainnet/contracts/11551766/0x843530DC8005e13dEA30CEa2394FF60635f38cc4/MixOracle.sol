/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * https://github.com/OriginProtocol/origin-dollar
 *
 * Copyright 2020 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
// File: contracts/interfaces/IPriceOracle.sol

pragma solidity 0.5.11;

interface IPriceOracle {
    /**
     * @dev returns the asset price in USD, 6 decimal digits.
     * Compatible with the Open Price Feed.
     */
    function price(string calldata symbol) external view returns (uint256);
}

// File: contracts/interfaces/IEthUsdOracle.sol

pragma solidity 0.5.11;

interface IEthUsdOracle {
    /**
     * @notice Returns ETH price in USD.
     * @return Price in USD with 6 decimal digits.
     */
    function ethUsdPrice() external view returns (uint256);

    /**
     * @notice Returns token price in USD.
     * @param symbol. Asset symbol. For ex. "DAI".
     * @return Price in USD with 6 decimal digits.
     */
    function tokUsdPrice(string calldata symbol)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the asset price in ETH.
     * @param symbol. Asset symbol. For ex. "DAI".
     * @return Price in ETH with 8 decimal digits.
     */
    function tokEthPrice(string calldata symbol)
        external
        view
        returns (uint256);
}

interface IViewEthUsdOracle {
    /**
     * @notice Returns ETH price in USD.
     * @return Price in USD with 6 decimal digits.
     */
    function ethUsdPrice() external view returns (uint256);

    /**
     * @notice Returns token price in USD.
     * @param symbol. Asset symbol. For ex. "DAI".
     * @return Price in USD with 6 decimal digits.
     */
    function tokUsdPrice(string calldata symbol)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the asset price in ETH.
     * @param symbol. Asset symbol. For ex. "DAI".
     * @return Price in ETH with 8 decimal digits.
     */
    function tokEthPrice(string calldata symbol)
        external
        view
        returns (uint256);
}

// File: contracts/interfaces/IMinMaxOracle.sol

pragma solidity 0.5.11;

interface IMinMaxOracle {
    //Assuming 8 decimals
    function priceMin(string calldata symbol) external view returns (uint256);

    function priceMax(string calldata symbol) external view returns (uint256);
}

// File: contracts/governance/Governable.sol

pragma solidity 0.5.11;

/**
 * @title OUSD Governable Contract
 * @dev Copy of the openzeppelin Ownable.sol contract with nomenclature change
 *      from owner to governor and renounce methods removed. Does not use
 *      Context.sol like Ownable.sol does for simplification.
 * @author Origin Protocol Inc
 */
contract Governable {
    // Storage position of the owner and pendingOwner of the contract
    // keccak256("OUSD.governor");
    bytes32
        private constant governorPosition = 0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;

    // keccak256("OUSD.pending.governor");
    bytes32
        private constant pendingGovernorPosition = 0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;

    // keccak256("OUSD.reentry.status");
    bytes32
        private constant reentryStatusPosition = 0x53bf423e48ed90e97d02ab0ebab13b2a235a6bfbe9c321847d5c175333ac4535;

    // See OpenZeppelin ReentrancyGuard implementation
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    constructor() internal {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function governor() public view returns (address) {
        return _governor();
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    /**
     * @dev Returns the address of the pending Governor.
     */
    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }

    /**
     * @dev Throws if called by any account other than the Governor.
     */
    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Governor.
     */
    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bytes32 position = reentryStatusPosition;
        uint256 _reentry_status;
        assembly {
            _reentry_status := sload(position)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_reentry_status != _ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(position, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(position, _NOT_ENTERED)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Transfers Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the current Governor. Must be claimed for this to complete
     * @param _newGovernor Address of the new Governor
     */
    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }

    /**
     * @dev Claim Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the new Governor.
     */
    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }

    /**
     * @dev Change Governance of the contract to a new account (`newGovernor`).
     * @param _newGovernor Address of the new Governor
     */
    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}

// File: contracts/oracle/MixOracle.sol

pragma solidity 0.5.11;

/**
 * @title OUSD MixOracle Contract
 * @notice The MixOracle pulls exchange rate from multiple oracles and returns
 *         min and max values.
 * @author Origin Protocol Inc
 */




contract MixOracle is IMinMaxOracle, Governable {
    event DriftsUpdated(uint256 _minDrift, uint256 _maxDrift);
    event EthUsdOracleRegistered(address _oracle);
    event EthUsdOracleDeregistered(address _oracle);
    event TokenOracleRegistered(
        string symbol,
        address[] ethOracles,
        address[] usdOracles
    );

    address[] public ethUsdOracles;

    struct MixConfig {
        address[] usdOracles;
        address[] ethOracles;
    }

    mapping(bytes32 => MixConfig) configs;

    uint256 constant MAX_INT = 2**256 - 1;
    uint256 public maxDrift;
    uint256 public minDrift;

    constructor(uint256 _maxDrift, uint256 _minDrift) public {
        maxDrift = _maxDrift;
        minDrift = _minDrift;
        emit DriftsUpdated(_minDrift, _maxDrift);
    }

    function setMinMaxDrift(uint256 _minDrift, uint256 _maxDrift)
        public
        onlyGovernor
    {
        minDrift = _minDrift;
        maxDrift = _maxDrift;
        emit DriftsUpdated(_minDrift, _maxDrift);
    }

    /**
     * @notice Adds an oracle to the list of oracles to pull data from.
     * @param oracle Address of an oracle that implements the IEthUsdOracle interface.
     **/
    function registerEthUsdOracle(address oracle) public onlyGovernor {
        for (uint256 i = 0; i < ethUsdOracles.length; i++) {
            require(ethUsdOracles[i] != oracle, "Oracle already registered.");
        }
        ethUsdOracles.push(oracle);
        emit EthUsdOracleRegistered(oracle);
    }

    /**
     * @notice Removes an oracle to the list of oracles to pull data from.
     * @param oracle Address of an oracle that implements the IEthUsdOracle interface.
     **/
    function unregisterEthUsdOracle(address oracle) public onlyGovernor {
        for (uint256 i = 0; i < ethUsdOracles.length; i++) {
            if (ethUsdOracles[i] == oracle) {
                // swap with the last element of the array, and then delete last element (could be itself)
                ethUsdOracles[i] = ethUsdOracles[ethUsdOracles.length - 1];
                delete ethUsdOracles[ethUsdOracles.length - 1];
                emit EthUsdOracleDeregistered(oracle);
                ethUsdOracles.pop();
                return;
            }
        }
        revert("Oracle not found");
    }

    /**
     * @notice Adds an oracle to the list of oracles to pull data from.
     * @param ethOracles Addresses of oracles that implements the IEthUsdOracle interface and answers for this asset
     * @param usdOracles Addresses of oracles that implements the IPriceOracle interface and answers for this asset
     **/
    function registerTokenOracles(
        string calldata symbol,
        address[] calldata ethOracles,
        address[] calldata usdOracles
    ) external onlyGovernor {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        config.ethOracles = ethOracles;
        config.usdOracles = usdOracles;
        emit TokenOracleRegistered(symbol, ethOracles, usdOracles);
    }

    /**
     * @notice Returns the min price of an asset in USD.
     * @return symbol Asset symbol. Example: "DAI"
     * @return price Min price from all the oracles, in USD with 8 decimal digits.
     **/
    function priceMin(string calldata symbol)
        external
        view
        returns (uint256 price)
    {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        uint256 ep;
        uint256 p; //holder variables
        price = MAX_INT;
        if (config.ethOracles.length > 0) {
            ep = MAX_INT;
            for (uint256 i = 0; i < config.ethOracles.length; i++) {
                p = IEthUsdOracle(config.ethOracles[i]).tokEthPrice(symbol);
                if (ep > p) {
                    ep = p;
                }
            }
            price = ep;
            ep = MAX_INT;
            for (uint256 i = 0; i < ethUsdOracles.length; i++) {
                p = IEthUsdOracle(ethUsdOracles[i]).ethUsdPrice();
                if (ep > p) {
                    ep = p;
                }
            }
            if (price != MAX_INT && ep != MAX_INT) {
                // tokEthPrice has precision of 8 which ethUsdPrice has precision of 6
                // we want precision of 8
                price = (price * ep) / 1e6;
            }
        }

        if (config.usdOracles.length > 0) {
            for (uint256 i = 0; i < config.usdOracles.length; i++) {
                // upscale by 2 since price oracles are precision 6
                p = IPriceOracle(config.usdOracles[i]).price(symbol) * 1e2;
                if (price > p) {
                    price = p;
                }
            }
        }
        require(price <= maxDrift, "Price exceeds maxDrift");
        require(price >= minDrift, "Price below minDrift");
        require(
            price != MAX_INT,
            "None of our oracles returned a valid min price!"
        );
    }

    /**
     * @notice Returns max price of an asset in USD.
     * @return symbol Asset symbol. Example: "DAI"
     * @return price Max price from all the oracles, in USD with 8 decimal digits.
     **/
    function priceMax(string calldata symbol)
        external
        view
        returns (uint256 price)
    {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        uint256 ep;
        uint256 p; //holder variables
        price = 0;
        if (config.ethOracles.length > 0) {
            ep = 0;
            for (uint256 i = 0; i < config.ethOracles.length; i++) {
                p = IEthUsdOracle(config.ethOracles[i]).tokEthPrice(symbol);
                if (ep < p) {
                    ep = p;
                }
            }
            price = ep;
            ep = 0;
            for (uint256 i = 0; i < ethUsdOracles.length; i++) {
                p = IEthUsdOracle(ethUsdOracles[i]).ethUsdPrice();
                if (ep < p) {
                    ep = p;
                }
            }
            if (price != 0 && ep != 0) {
                // tokEthPrice has precision of 8 which ethUsdPrice has precision of 6
                // we want precision of 8
                price = (price * ep) / 1e6;
            }
        }

        if (config.usdOracles.length > 0) {
            for (uint256 i = 0; i < config.usdOracles.length; i++) {
                // upscale by 2 since price oracles are precision 6
                p = IPriceOracle(config.usdOracles[i]).price(symbol) * 1e2;
                if (price < p) {
                    price = p;
                }
            }
        }

        require(price <= maxDrift, "Price exceeds maxDrift");
        require(price >= minDrift, "Price below minDrift");
        require(price != 0, "None of our oracles returned a valid max price!");
    }

    /**
     * @notice Returns the length of the usdOracles array for a given token
     * @param symbol Asset symbol. Example: "DAI"
     * @return length of the USD oracles array
     **/
    function getTokenUSDOraclesLength(string calldata symbol)
        external
        view
        returns (uint256)
    {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        return config.usdOracles.length;
    }

    /**
     * @notice Returns the address of a specific USD oracle
     * @param symbol Asset symbol. Example: "DAI"
     * @param idx Index of the array value to return
     * @return address of the oracle
     **/
    function getTokenUSDOracle(string calldata symbol, uint256 idx)
        external
        view
        returns (address)
    {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        return config.usdOracles[idx];
    }

    /**
     * @notice Returns the length of the ethOracles array for a given token
     * @param symbol Asset symbol. Example: "DAI"
     * @return length of the ETH oracles array
     **/
    function getTokenETHOraclesLength(string calldata symbol)
        external
        view
        returns (uint256)
    {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        return config.ethOracles.length;
    }

    /**
     * @notice Returns the address of a specific ETH oracle
     * @param symbol Asset symbol. Example: "DAI"
     * @param idx Index of the array value to return
     * @return address of the oracle
     **/
    function getTokenETHOracle(string calldata symbol, uint256 idx)
        external
        view
        returns (address)
    {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        return config.ethOracles[idx];
    }
}
