// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AccessController.sol";
import "./IERC20Mintable.sol";
import "./IAquaPremium.sol";
import "./IHandler.sol";
import "./IAuqaPrimary.sol";
import "./IOracle.sol";
import "./SafeERC20.sol";

contract AquaProtocol is IAuqaPrimary, AccessController {
    using SafeERC20 for IERC20Mintable;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20Mintable public constant aquaToken = IERC20Mintable(0xD34a24006b862f4E9936c506691539D6433aD297);

    struct Stake {
        uint256 lpValue;
        uint256 depositTime;
        address staker;
        address handler;
        address contractAddress;
    }

    mapping(bytes32 => Stake) public stakes;

    event Staked(
        bytes32 id,
        uint256 lpValue,
        uint256 depositTime,
        address staker,
        address handler,
        address contractAddress,
        bytes data
    );
    event Unstaked(
        bytes32 id,
        uint256 tokenIdOrAmount,
        uint256 aquaPremium,
        uint256 aquaAmount,
        address[] token,
        uint128[] tokenDiff,
        uint256 amount
    );

    constructor(
        address timelock,
        address feeReceiver,
        address aquaPremiumContract,
        address oracleContract,
        uint256 fee
    ) AccessController(timelock, feeReceiver, aquaPremiumContract, oracleContract, fee) {}

    function stake(
        uint256 tokenIdOrAmount,
        address handler,
        address contractAddress,
        bytes calldata data
    ) external override {
        require(handlerToContract[handler][contractAddress] == true, "Aqua primary :: Invalid pool");

        require(tokenIdOrAmount > 0, "Aqua primary :: Invalid stake amount");

        address staker = msg.sender;

        IERC20Mintable(contractAddress).safeTransferFrom(staker, handler, tokenIdOrAmount);

        _stake(tokenIdOrAmount, staker, handler, contractAddress, data);
    }

    function _stake(
        uint256 tokenValue,
        address staker,
        address handler,
        address contractAddress,
        bytes calldata data
    ) internal {
        uint256 depositTime = block.timestamp;

        (, address decodedStaker) = abi.decode(data, (address, address));

        require(staker == decodedStaker, "Aqua Primary :: Different staker");

        bytes32 id = keccak256(abi.encodePacked(tokenValue, depositTime, staker, contractAddress, handler));

        require(stakes[id].staker == address(0), "Aqua Primary :: stake already exists");

        stakes[id] = Stake(tokenValue, depositTime, staker, handler, contractAddress);

        IHandler(handler).update(id, tokenValue, contractAddress, data);

        emit Staked(id, tokenValue, depositTime, staker, handler, contractAddress, data);
    }

    function unstake(bytes32[] calldata id, uint256[] calldata tokenValue) external override {
        uint256 amount = 0;

        for (uint8 i = 0; i < id.length; i++) {
            amount = amount + _unstake(id[i], tokenValue[i]);
        }

        aquaToken.mint(msg.sender, amount);
        mintProtocolFee(amount);
    }

    function unstakeSingle(bytes32 id, uint256 tokenValue) external override {
        uint256 amount = _unstake(id, tokenValue);
        aquaToken.mint(msg.sender, amount);
        mintProtocolFee(amount);
    }

    function _unstake(bytes32 id, uint256 tokenValue) private returns (uint256 aquaAmount) {
        Stake memory s = stakes[id];

        require(block.timestamp > s.depositTime, "Aqua primary :: INVALID TIMESTAMP");
        require(s.staker == msg.sender, "Aqua primary :: Invalid stake");
        require(tokenValue <= s.lpValue, "Aqua Primary :: Invalid token amount");

        address[] memory token = new address[](2);
        uint128[] memory tokenDiff = new uint128[](2);

        bytes memory data;
        uint256 aquaPoolPremium;

        (token, aquaPoolPremium, tokenDiff, data) = IHandler(s.handler).withdraw(id, tokenValue, s.contractAddress);

        uint256 aquaFees;

        for (uint8 i = 0; i < token.length; i++) {
            if (token[i] == WETH) {
                uint256 AQUAPerEth = IOracle(oracleContract).fetchAquaPrice();
                aquaAmount += (tokenDiff[i] * AQUAPerEth) / 1e18;
            } else if (token[i] != address(aquaToken)) {
                uint256 AQUAperToken = IOracle(oracleContract).fetch(token[i], data);
                aquaAmount += (tokenDiff[i] * AQUAperToken) / 1e18;
            } else {
                aquaAmount += tokenDiff[i];
            }
        }

        {
            (aquaFees, aquaPoolPremium) = IAquaPremium(aquaPremiumContract).calculatePremium(
                s.depositTime,
                IAquaPremium(aquaPremiumContract).getAquaPremium(),
                aquaPoolPremium,
                aquaAmount
            );
        }

        if (s.lpValue == tokenValue) {
            delete stakes[id];
        } else {
            stakes[id].lpValue -= tokenValue;
        }

        emit Unstaked(id, tokenValue, aquaPoolPremium, aquaFees, token, tokenDiff, aquaFees + aquaAmount);

        return aquaAmount += aquaFees;
    }

    function mintProtocolFee(uint256 aquaAmount) private {
        uint256 protocolFee = (aquaAmount * fee) / 1e18;
        aquaToken.mint(feeReceiver, protocolFee);
    }
}
