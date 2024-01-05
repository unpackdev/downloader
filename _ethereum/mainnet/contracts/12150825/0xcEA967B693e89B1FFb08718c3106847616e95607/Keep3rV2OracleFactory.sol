// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Keep3rV2Oracle.sol";

contract Keep3rV2OracleFactory {
    function pairForSushi(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            0xc35DADB65012eC5796536bD9864eD8773aBc74C4,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                        )
                    )
                )
            )
        );
    }

    function pairForUni(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    modifier keeper() {
        require(KP3R.keepers(msg.sender), "!K");
        _;
    }

    modifier upkeep() {
        uint256 _gasUsed = gasleft();
        require(KP3R.keepers(msg.sender), "!K");
        _;
        uint256 _received = KP3R.KPRH().getQuoteLimit(_gasUsed - gasleft());
        KP3R.receipt(address(KP3R), msg.sender, _received);
    }

    address public governance;
    address public pendingGovernance;

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!G");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!pG");
        governance = pendingGovernance;
    }

    IKeep3rV1 public constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    address[] internal _pairs;
    mapping(address => Keep3rV2Oracle) public feeds;

    function pairs() external view returns (address[] memory) {
        return _pairs;
    }

    constructor() {
        governance = msg.sender;
    }

    function update(address pair) external keeper returns (bool) {
        return feeds[pair].update();
    }

    function byteCode(address pair) external pure returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(type(Keep3rV2Oracle).creationCode, abi.encode(pair));
    }

    function deploy(address pair) external returns (address feed) {
        require(msg.sender == governance, "!G");
        require(address(feeds[pair]) == address(0), "PE");
        bytes memory bytecode = abi.encodePacked(type(Keep3rV2Oracle).creationCode, abi.encode(pair));
        bytes32 salt = keccak256(abi.encodePacked(pair));
        assembly {
            feed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(feed)) {
                revert(0, 0)
            }
        }
        feeds[pair] = Keep3rV2Oracle(feed);
        _pairs.push(pair);
    }

    function work() external upkeep {
        require(workable(), "!W");
        for (uint256 i = 0; i < _pairs.length; i++) {
            feeds[_pairs[i]].update();
        }
    }

    function work(address pair) external upkeep {
        require(feeds[pair].update(), "!W");
    }

    function workForFree() external keeper {
        for (uint256 i = 0; i < _pairs.length; i++) {
            feeds[_pairs[i]].update();
        }
    }

    function workForFree(address pair) external keeper {
        feeds[pair].update();
    }

    function cache(uint256 size) external {
        for (uint256 i = 0; i < _pairs.length; i++) {
            feeds[_pairs[i]].cache(size);
        }
    }

    function cache(address pair, uint256 size) external {
        feeds[pair].cache(size);
    }

    function workable() public view returns (bool canWork) {
        canWork = true;
        for (uint256 i = 0; i < _pairs.length; i++) {
            if (!feeds[_pairs[i]].updateable()) {
                canWork = false;
            }
        }
    }

    function workable(address pair) public view returns (bool) {
        return feeds[pair].updateable();
    }

    function sample(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 points,
        uint256 window,
        bool sushiswap
    ) external view returns (uint256[] memory prices, uint256 lastUpdatedAgo) {
        address _pair = sushiswap ? pairForSushi(tokenIn, tokenOut) : pairForUni(tokenIn, tokenOut);
        return feeds[_pair].sample(tokenIn, amountIn, tokenOut, points, window);
    }

    function sample(
        address pair,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 points,
        uint256 window
    ) external view returns (uint256[] memory prices, uint256 lastUpdatedAgo) {
        return feeds[pair].sample(tokenIn, amountIn, tokenOut, points, window);
    }

    function quote(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 points,
        bool sushiswap
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo) {
        address _pair = sushiswap ? pairForSushi(tokenIn, tokenOut) : pairForUni(tokenIn, tokenOut);
        return feeds[_pair].quote(tokenIn, amountIn, tokenOut, points);
    }

    function quote(
        address pair,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 points
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo) {
        return feeds[pair].quote(tokenIn, amountIn, tokenOut, points);
    }

    function current(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        bool sushiswap
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo) {
        address _pair = sushiswap ? pairForSushi(tokenIn, tokenOut) : pairForUni(tokenIn, tokenOut);
        return feeds[_pair].current(tokenIn, amountIn, tokenOut);
    }

    function current(
        address pair,
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo) {
        return feeds[pair].current(tokenIn, amountIn, tokenOut);
    }
}
