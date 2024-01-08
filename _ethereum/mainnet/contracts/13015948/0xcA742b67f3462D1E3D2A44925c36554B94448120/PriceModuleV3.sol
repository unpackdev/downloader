// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "./ChainlinkService.sol";
import "./IAddressProvider.sol";
import "./IRegistry.sol";
import "./IVault.sol";
import "./IYieldsterVault.sol";
import "./IYieldsterStrategy.sol";
import "./SafeMath.sol";
import "./Initializable.sol";

contract PriceModuleV3 is ChainlinkService, Initializable {
    using SafeMath for uint256;

    address public priceModuleManager;

    address public curveAddressProvider;

    struct Token {
        address feedAddress;
        uint256 tokenType;
        bool created;
    }

    mapping(address => Token) tokens;

    function initialize() public {
        priceModuleManager = msg.sender;
        curveAddressProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;
    }

    function changeCurveAddressProvider(address _crvAddressProvider) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        curveAddressProvider = _crvAddressProvider;
    }

    function setManager(address _manager) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        priceModuleManager = _manager;
    }

    function addToken(
        address _tokenAddress,
        address _feedAddress,
        uint256 _tokenType
    ) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        Token memory newToken = Token({
            feedAddress: _feedAddress,
            tokenType: _tokenType,
            created: true
        });
        tokens[_tokenAddress] = newToken;
    }

    function addTokenInBatches(
        address[] memory _tokenAddress,
        address[] memory _feedAddress,
        uint256[] memory _tokenType
    ) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            Token memory newToken = Token({
                feedAddress: address(_feedAddress[i]),
                tokenType: _tokenType[i],
                created: true
            });
            tokens[address(_tokenAddress[i])] = newToken;
        }
    }

    function getPriceFromChainlink(address _feedAddress)
        internal
        view
        returns (uint256)
    {
        (int256 price, , uint8 decimals) = getLatestPrice(_feedAddress);
        if (decimals < 18) {
            return (uint256(price)).mul(10**uint256(18 - decimals));
        } else if (decimals > 18) {
            return (uint256(price)).div(uint256(decimals - 18));
        } else {
            return uint256(price);
        }
    }

    function getUSDPrice(address _tokenAddress) public view returns (uint256) {
        require(tokens[_tokenAddress].created, "Token not present");

        if (tokens[_tokenAddress].tokenType == 1) {
            return getPriceFromChainlink(tokens[_tokenAddress].feedAddress);
        } else if (tokens[_tokenAddress].tokenType == 2) {
            return
                IRegistry(IAddressProvider(curveAddressProvider).get_registry())
                    .get_virtual_price_from_lp_token(_tokenAddress);
        } else if (tokens[_tokenAddress].tokenType == 3) {
            address token = IVault(_tokenAddress).token();
            uint256 tokenPrice = getUSDPrice(token);
            return
                (tokenPrice.mul(IVault(_tokenAddress).pricePerShare())).div(
                    1e18
                );
        } else if (tokens[_tokenAddress].tokenType == 4) {
            return IYieldsterStrategy(_tokenAddress).tokenValueInUSD();
        } else if (tokens[_tokenAddress].tokenType == 5) {
            return IYieldsterVault(_tokenAddress).tokenValueInUSD();
        } else if (tokens[_tokenAddress].tokenType == 6) {
            uint256 priceInEther = getPriceFromChainlink(
                tokens[_tokenAddress].feedAddress
            );
            uint256 etherToUSD = getUSDPrice(address(0));
            return (priceInEther.mul(etherToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 7) {
            uint256 lpPriceEuro = IRegistry(
                IAddressProvider(curveAddressProvider).get_registry()
            ).get_virtual_price_from_lp_token(_tokenAddress);
            uint256 euroToUSD = getUSDPrice(
                address(0xb49f677943BC038e9857d61E7d053CaA2C1734C1)
            );
            return (lpPriceEuro.mul(euroToUSD)).div(1e18);
        }
        else if (tokens[_tokenAddress].tokenType ==8) {
            uint256 lpPriceBTC = IRegistry(
                IAddressProvider(curveAddressProvider).get_registry()
            ).get_virtual_price_from_lp_token(_tokenAddress);
            uint256 btcToUSD = getUSDPrice(
                address(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c)
            );
            return (lpPriceBTC.mul(btcToUSD)).div(1e18);
        } else revert("Token not present");
    }
}
