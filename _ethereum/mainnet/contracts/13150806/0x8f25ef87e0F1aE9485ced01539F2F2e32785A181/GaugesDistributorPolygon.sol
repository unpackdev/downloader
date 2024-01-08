pragma solidity 0.8.2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

import "./GaugePolygon.sol";

interface IMinter {
    function collect() external;
}

contract GaugesDistributorPolygon {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable NEURON;
    address public governance;
    address public admin;

    uint256 public pid;
    uint256 public totalWeight;
    IMinter public minter;

    address[] internal _tokens;
    mapping(address => address) public gauges; // token => gauge
    mapping(address => uint256) public weights; // token => weight
    mapping(address => mapping(address => uint256)) public votes; // msg.sender => votes

    constructor(
        address _minter,
        address _neuronToken,
        address _governance,
        address _admin
    ) {
        minter = IMinter(_minter);
        NEURON = IERC20(_neuronToken);
        governance = _governance;
        admin = _admin;
    }

    function setMinter(address _minter) public {
        require(msg.sender == governance, "!admin and !governance");
        minter = IMinter(_minter);
    }

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    function getGauge(address _token) external view returns (address) {
        return gauges[_token];
    }

    function setWeights(
        address[] memory _tokensToVote,
        uint256[] memory _weights
    ) external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Set weights function can only be executed by admin or governance"
        );
        require(
            _tokensToVote.length == _weights.length,
            "Number Tokens to vote should be the same as weights number"
        );

        uint256 _tokensCnt = _tokensToVote.length;
        uint256 _totalWeight = 0;
        for (uint256 i = 0; i < _tokensCnt; i++) {
            address _token = _tokensToVote[i];
            address _gauge = gauges[_token];
            uint256 _tokenWeight = _weights[i];

            if (_gauge != address(0x0)) {
                _totalWeight = _totalWeight.add(_tokenWeight);
                weights[_token] = _tokenWeight;
            }
        }
        totalWeight = _totalWeight;
    }

    function addGauge(address _token) external {
        require(msg.sender == governance, "!governance");
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = address(new GaugePolygon(_token, address(NEURON)));
        _tokens.push(_token);
    }

    // Fetches Neurons
    function collect() internal {
        minter.collect();
    }

    function length() external view returns (uint256) {
        return _tokens.length;
    }

    function distribute() external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Distribute function can only be executed by admin or governance"
        );
        collect();
        uint256 _balance = NEURON.balanceOf(address(this));
        if (_balance > 0 && totalWeight > 0) {
            for (uint256 i = 0; i < _tokens.length; i++) {
                address _token = _tokens[i];
                address _gauge = gauges[_token];
                uint256 _reward = _balance.mul(weights[_token]).div(
                    totalWeight
                );
                if (_reward > 0) {
                    NEURON.safeApprove(_gauge, 0);
                    NEURON.safeApprove(_gauge, _reward);
                    GaugePolygon(_gauge).notifyRewardAmount(_reward);
                }
            }
        }
    }

    function setAdmin(address _admin) external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Only governance or admin can set admin"
        );

        admin = _admin;
    }
}
