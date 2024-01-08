// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
import "./Ownable.sol";
import "./ITgas.sol";
import "./ITomiFactory.sol";
import "./IERC20.sol";
import "./ITomiPair.sol";
import "./TomiSwapLibrary.sol";
import "./SafeMath.sol";

contract TomiTransferListener is Ownable {
    uint256 public version = 1;
    address public TGAS;
    address public PLATFORM;
    address public WETH;
    address public FACTORY;
    address public admin;

    mapping(address => uint) public pairWeights;

    event Transfer(address indexed from, address indexed to, address indexed token, uint256 amount);
    event WeightChanged(address indexed pair, uint weight);

    function initialize(
        address _TGAS,
        address _FACTORY,
        address _WETH,
        address _PLATFORM,
        address _admin
    ) external onlyOwner {
        require(
            _FACTORY != address(0) && _WETH != address(0) && _PLATFORM != address(0),
            'TOMI TRANSFER LISTENER : INPUT ADDRESS IS ZERO'
        );
        TGAS = _TGAS;
        FACTORY = _FACTORY;
        WETH = _WETH;
        PLATFORM = _PLATFORM;
        admin = _admin;
    }

    function changeAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function updateTGASImpl(address _newImpl) external onlyOwner {
        ITgas(TGAS).upgradeImpl(_newImpl);
    }

    function updatePairPowers(address[] calldata _pairs, uint[] calldata _weights) external {
        require(msg.sender == admin, 'TOMI TRANSFER LISTENER: ADMIN PERMISSION');
        require(_pairs.length == _weights.length, "TOMI TRANSFER LISTENER: INVALID PARAMS");

        for(uint i = 0;i < _weights.length;i++) {
            pairWeights[_pairs[i]] = _weights[i];
            _setProdutivity(_pairs[i]);
            emit WeightChanged(_pairs[i], _weights[i]);
        }
    }


    function _setProdutivity(address _pair) internal {
        (uint256 lastProdutivity, ) = ITgas(TGAS).getProductivity(_pair);
        address token0 = ITomiPair(_pair).token0();
        address token1 = ITomiPair(_pair).token1();
        (uint reserve0, uint reserve1, ) = ITomiPair(_pair).getReserves();
        uint currentProdutivity = 0;
        if(token0 == TGAS) {
            currentProdutivity = reserve0 * pairWeights[_pair];
        } else if(token1 == TGAS) {
            currentProdutivity = reserve1 * pairWeights[_pair];
        }

        if(lastProdutivity != currentProdutivity) {
            if(lastProdutivity > 0) {
                ITgas(TGAS).decreaseProductivity(_pair, lastProdutivity);
            } 

            if(currentProdutivity > 0) {
                ITgas(TGAS).increaseProductivity(_pair, currentProdutivity);
            }
        }
    }

    function upgradeProdutivity(address fromPair, address toPair) external {
        require(msg.sender == PLATFORM, 'TOMI TRANSFER LISTENER: PERMISSION');
        (uint256 fromPairPower, ) = ITgas(TGAS).getProductivity(fromPair);
        (uint256 toPairPower, ) = ITgas(TGAS).getProductivity(toPair);
        if(fromPairPower > 0 && toPairPower == 0) {
            ITgas(TGAS).decreaseProductivity(fromPair, fromPairPower);
            ITgas(TGAS).increaseProductivity(toPair, fromPairPower);
        }
    }

    function transferNotify(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == PLATFORM, 'TOMI TRANSFER LISTENER: PERMISSION');
        if(ITomiFactory(FACTORY).isPair(from) && token == TGAS) {
            _setProdutivity(from);
        }

        if(ITomiFactory(FACTORY).isPair(to) && token == TGAS) {
            _setProdutivity(to);
        }

        emit Transfer(from, to, token, amount);
        return true;
    }
}