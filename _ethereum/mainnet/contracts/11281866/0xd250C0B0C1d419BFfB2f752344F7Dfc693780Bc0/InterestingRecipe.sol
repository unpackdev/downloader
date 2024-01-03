pragma solidity 0.6.4;

import "./UniswapV2BalRecipe.sol";

import "./IAaveLendingPool.sol";
import "./IAaveLendingPoolAddressProvider.sol";
import "./ICompoundCToken.sol";
import "./IERC20.sol";

import "./SafeMath.sol";

contract InterestingRecipe is UniswapV2BalRecipe {
    using SafeMath for uint256;
    // IDEA: current token supports are hard coded.
    // Use calldata to create a more generalized protocol

    // map A/C token to underlying asset
    mapping(address => address) public wrappedToUnderlying;
    // map underlying asset to A/C token.

    // map to Aave LendingPoolAddressesProvider
    // map to Compound comptroller (not being used in contract)
    mapping(address => address) public wrappedToProtocol;

    // map Aave lendingpool to aave.protocol
    // map Compound comptroller to compound.protocol
    mapping(address => bytes32) public protocolIdentifier;

    function updateProtocolIdentifier(address _protocol, bytes32 _identifier)
        external
        onlyOwner
    {
        protocolIdentifier[_protocol] = _identifier;
    }

    function updateMapping(
        address[] calldata _wrapped,
        address[] calldata _underlying,
        address[] calldata _protocol
    ) external onlyOwner {
        require(_wrapped.length == _underlying.length, "UNEQUAL_LENGTH");
        require(_wrapped.length == _protocol.length, "UNEQUAL_LENGTH");
        for (uint256 i = 0; i < _wrapped.length; i++) {
            wrappedToUnderlying[_wrapped[i]] = _underlying[i];
            wrappedToProtocol[_wrapped[i]] = _protocol[i];
        }
    }

    function _swapToToken(
        address _wrapped,
        uint256 _amount,
        address _pie
    ) internal override {
        address underlying = wrappedToUnderlying[_wrapped];
        address protocol = wrappedToProtocol[_wrapped];
        bytes32 identifier = protocolIdentifier[protocol];

        if (identifier == keccak256("aave.protocol")) {
            // Aave is 1 to 1 exchange rate
            IAaveLendingPoolAddressesProvider aaveProvider = IAaveLendingPoolAddressesProvider(protocol);

            super._swapToToken(underlying, _amount, address(aaveProvider.getLendingPoolCore()));
            IAaveLendingPool aave = IAaveLendingPool(
                aaveProvider.getLendingPool()
            );
            aave.deposit(underlying, _amount, 0);

            IERC20(_wrapped).safeApprove(_pie, _amount);
        } else if (identifier == keccak256("compound.protocol")) {
            ICompoundCToken cToken = ICompoundCToken(_wrapped);
            uint256 exchangeRate = cToken.exchangeRateCurrent(); // wrapped to underlying
            uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18).add(1);

            super._swapToToken(underlying, underlyingAmount, address(cToken));
            // https://compound.finance/docs/ctokens#mint
            assert(cToken.mint(underlyingAmount) == 0);

            IERC20(_wrapped).safeApprove(_pie, _amount);
        } else {
            super._swapToToken(_wrapped, _amount, _pie);
        }
    }

    function calcEthAmount(address _wrapped, uint256 _buyAmount)
        internal
        override
        returns (uint256)
    {
        address underlying = wrappedToUnderlying[_wrapped];
        address protocol = wrappedToProtocol[_wrapped];
        bytes32 identifier = protocolIdentifier[protocol];

        if (identifier == keccak256("aave.protocol")) {
            // Aave: 1 to 1
            return super.calcEthAmount(underlying, _buyAmount);
        } else if (identifier == keccak256("compound.protocol")) {
            // convert _buyAmount of comp to underlying token
            // convert get price of underlying token with uni/bpool

            ICompoundCToken cToken = ICompoundCToken(_wrapped);
            uint256 exchangeRate = cToken.exchangeRateCurrent(); // wrapped to underlying
            uint256 underlyingAmount = _buyAmount.mul(exchangeRate).div(10**18).add(1);
            return super.calcEthAmount(underlying, underlyingAmount);
        } else {
            return super.calcEthAmount(_wrapped, _buyAmount);
        }
    }

    function calcToPie(address _pie, uint256 _poolAmount)
        public
        override
        returns (uint256)
    {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);

        uint256 totalEth = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (wrappedToUnderlying[tokens[i]] != address(0)) {
                totalEth += calcEthAmount(tokens[i], amounts[i]);
            } else if (tokenToBPool[tokens[i]] != address(0)) {
                totalEth += calcEthAmount(tokens[i], amounts[i]);
            } else if (registry.inRegistry(tokens[i])) {
                totalEth += calcToPie(tokens[i], amounts[i]);
            } else {
                (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                    address(uniswapFactory),
                    address(WETH),
                    tokens[i]
                );
                totalEth += UniLib.getAmountIn(amounts[i], reserveA, reserveB);
            }
        }

        return totalEth;
    }
}
