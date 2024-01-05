pragma solidity >=0.8.0;

import "./Base.sol";
import "./IConfig.sol";
import "./IFund.sol";
import "./IFundManager.sol";
import "./Fund.sol";

import "./TransferHelper.sol";

interface INameRegistry {
    function isRegistered(address _owner) external returns (bool);
}

contract FundManager is Base {
    event FundCreated(address indexed from, address fund, address manager, uint256 _managerInvestAmount);

    event FundChanged(address indexed fund);

    event ConfigChanged(address indexed from, address config, address newConfig);

    event LibChanged(address indexed lib);

    address public uniswapV2Router;

    address[] public funds; // fund list

    address lib;

    modifier ready() {
        require(lib != address(0), "lib is unset");
        _;
    }

    constructor(
        address _config,
        address _router,
        address _lib
    ) Base(_config) {
        require(_router != address(0), "router address = 0");
        uniswapV2Router = _router;
        require(_lib != address(0), "lib address = 0");
        lib = _lib;
    }

    function allFunds() external view returns (address[] memory) {
        return funds;
    }

    function fundCount() external view returns (uint256) {
        return funds.length;
    }

    function updateLib(address _lib) external onlyCEO() {
        require(_lib != address(0), "lib address = 0");
        lib = _lib;
        emit LibChanged(lib);
    }

    function invest(address _fund, uint256 _amount) external {
        IFund fund = IFund(_fund);
        address baseToken = fund.getToken(0);
        TransferHelper.safeTransferFrom(baseToken, msg.sender, _fund, _amount);
        fund.invest(msg.sender, _amount);
    }

    function feeTo() external view returns (address) {
        return config.feeTo();
    }

    function createFund(
        string memory _title,
        uint128 _minSize,
        uint256[2] memory _dates, // start date, end date
        uint16[4] memory _rates, // hurdle rate, roe, maxDrawdown
        uint256 _amountOfManager,
        address[] memory _tokens
    ) external returns (address) {
        string memory symbol = string(abi.encodePacked("DF_", toString(funds.length)));
        require(INameRegistry(config.nameRegistry()).isRegistered(msg.sender), "address not registered");
        uint8 decimals = IERC20(_tokens[0]).decimals();
        for (uint256 i; i < _tokens.length; i++) {
            uint256 minAmount = config.tokenMinFundSize(_tokens[i]);
            require(minAmount > 0, "not in whitelist");
            if (i == 0) {
                require(_minSize >= minAmount, "size < minimal size");
            }
        }
        address fundAddr = clone(lib);
        address manager = msg.sender;
        TransferHelper.safeTransferFrom(_tokens[0], manager, fundAddr, _amountOfManager);
        funds.push(fundAddr);
        IFund(fundAddr).initialize(
            _title,
            symbol,
            decimals,
            _minSize,
            _dates,
            _rates,
            manager,
            _amountOfManager,
            _tokens
        );
        emit FundCreated(msg.sender, fundAddr, msg.sender, _amountOfManager);
        config.notify(IConfig.EventType.FUND_CREATED, fundAddr);
        return fundAddr;
    }

    function broadcast() external {
        emit FundChanged(msg.sender);
    }

    function toString(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (i != 0) {
            bstr[k] = bytes1(uint8(48 + (i % 10)));
            if (k > 0) {
                i /= 10;
                k--;
            } else {
                break;
            }
        }
        return string(bstr);
    }

    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
}
