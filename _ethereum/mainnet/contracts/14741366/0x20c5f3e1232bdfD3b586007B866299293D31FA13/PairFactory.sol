// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./IPairFactory.sol";
import "./IPair.sol";
import "./Context.sol";
import "./Pair.sol";
import "./IManager.sol";

contract PairFactory is Context, IPairFactory {
    bytes32 private constant _INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(Pair).creationCode));

    address public override router;

    address public override feeTo;
    uint256 public PRECISION = 10000;
    uint256 public swapFeeForLP = 20;
    uint256 public swapFeeForAdmin = 5;
    IManager public manager;

    mapping(address => mapping(address => address)) public override getPair;

    address[] public override allPairs;

    modifier onlyAdmin() {
        require(manager.isAdmin(_msgSender()), "Pool::onlyAdmin");
        _;
    }

    modifier onlyGovernance() {
        require(manager.isGorvernance(_msgSender()), "Pool::onlyGovernance");
        _;
    }

    constructor(address _treasury, address _manager) {
        feeTo = _treasury;
        manager = IManager(_manager);
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function getInfoAdminFee()
        public
        view
        override
        returns (
            address,
            uint256,
            uint256
        )
    {
        return (feeTo, swapFeeForAdmin, PRECISION);
    }

    function getFeeSwap() public view override returns (uint256, uint256) {
        uint256 _swapFeeForAdmin = swapFeeForAdmin;
        if (feeTo == address(0)) {
            _swapFeeForAdmin = 0;
        }
        return (swapFeeForLP + _swapFeeForAdmin, PRECISION);
    }

    function getAllPairs() public view returns (address[] memory) {
        return allPairs;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "PairFactory::createPair: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "PairFactory::createPair: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PairFactory::createPair: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address feeTo_) external override onlyGovernance {
        feeTo = feeTo_;
        emit ChangeFeeTo(feeTo_);
    }

    function setSwapFee(uint256 adminFee, uint256 lpFee) external override onlyGovernance {
        swapFeeForAdmin = adminFee;
        swapFeeForLP = lpFee;
        emit ChangeSwapFee(adminFee, lpFee);
    }

    // set a router address to permission critical incoming calls to Pair contracts
    function setRouter(address router_) external override onlyAdmin {
        router = router_;
    }
}
