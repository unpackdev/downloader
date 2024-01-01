// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./InverseBondingCurveProxy.sol";
import "./InverseBondingCurveToken.sol";
import "./IWETH9.sol";
import "./Errors.sol";
import "./CurveLibrary.sol";

contract InverseBondingCurveFactory {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    IInverseBondingCurveAdmin private _admin;

    mapping(address => address) private _curveMap;
    address[] public curves;

    event CurveCreated(address curveContract, address tokenContract, address proxyContract, uint256 iniitalReserve);

    constructor(address adminContract) {
        _admin = IInverseBondingCurveAdmin(adminContract);
    }

    /**
     * @notice  Deploys IBC proxy contract, and the relevant ibAsset token contract for the specified reserve asset.
     * @dev
     * @param   initialReserves : Amount of initial reserves to supply to curve
     * @param   reserveTokenAddress : Contract address of the reserve asset token contract
     * @param   recipient: Account to hold initial LP position
     */
    function createCurve(uint256 initialReserves, address reserveTokenAddress, address recipient) external payable {
        string memory tokenSymbol = "";
        uint256 leftReserve = msg.value;
        address reserveFromAccount = msg.sender;
        uint8 tokenDecimals = 18;
        if (reserveTokenAddress == address(0) && msg.value > 0) {
            if (msg.value != initialReserves) {
                revert InputBalanceNotMatch();
            }
            // Ignore reserve parameter passed in, use all msg.value as reserve
            initialReserves = msg.value;
            leftReserve = 0;

            // convert eth to weth
            reserveTokenAddress = _admin.weth();
            IWETH9(reserveTokenAddress).deposit{value: msg.value}();
            IWETH9(reserveTokenAddress).approve(address(this), initialReserves);
            tokenSymbol = "ibETH";
            reserveFromAccount = address(this);
        } else {
            tokenSymbol = string(abi.encodePacked("ib", IERC20Metadata(reserveTokenAddress).symbol()));
            tokenDecimals = IERC20Metadata(reserveTokenAddress).decimals();
        }

        if (_curveMap[reserveTokenAddress] != address(0)) {
            revert PoolAlreadyExist();
        }

        _createCurve(initialReserves, tokenSymbol, reserveFromAccount, reserveTokenAddress, tokenDecimals, recipient);

        if (leftReserve > 0) {
            payable(msg.sender).sendValue(leftReserve);
        }
    }

    /**
     * @notice  Deploys IBC proxy contract, and the relevant ibAsset token contract for the specified reserve asset.
     * @dev
     * @param   initialReserves : Amount of initial reserves to supply to curve
     * @param   inverseTokenSymbol : IBC token symbol
     * @param   reserveFromAccount : The account to transfer reserve token from
     * @param   reserveTokenAddress : Contract address of the reserve asset token contract
     * @param   tokenDecimals: Reserve token decimals
     * @param   recipient: Account to hold initial LP position
     */
    function _createCurve(
        uint256 initialReserves,
        string memory inverseTokenSymbol,
        address reserveFromAccount,
        address reserveTokenAddress,
        uint8 tokenDecimals,
        address recipient
    ) private {
        address _curveContract = _admin.curveImplementation();

        InverseBondingCurveToken tokenContract =
            new InverseBondingCurveToken(inverseTokenSymbol, inverseTokenSymbol);

        address proxyContract = address(new InverseBondingCurveProxy(address(_admin), _curveContract, ""));
        _curveMap[reserveTokenAddress] = proxyContract;
        curves.push(proxyContract);
        emit CurveCreated(_curveContract, address(tokenContract), proxyContract, CurveLibrary.scaleFrom(initialReserves, tokenDecimals));

        // Initialize Curve contract
        IERC20(reserveTokenAddress).safeTransferFrom(reserveFromAccount, address(proxyContract), initialReserves);
        bytes memory data = abi.encodeWithSignature( "initialize(address,address,address,address,address,uint256)",
            _admin, _admin.router(), tokenContract, reserveTokenAddress, recipient, initialReserves);
        proxyContract.functionCall(data);

        // Change owner to external owner
        address(tokenContract).functionCall(abi.encodeWithSignature("transferOwnership(address)", proxyContract));
    }

    /**
     * @notice  Query the IBC implementation of specific reverse token
     * @dev     .
     * @param   reserveToken : Reserve token of curve
     * @return  address : Contract address of the specified reserve asset's IBC implemenation
     */
    function getCurve(address reserveToken) public view returns (address) {
        return _curveMap[reserveToken == address(0)? _admin.weth() : reserveToken];
    }

    /**
     * @notice  Query total curves count
     * @dev
     * @return  uint256 : Total number of IBC curves created by Factory
     */
    function allCurvesLength() public view returns (uint256) {
        return curves.length;
    }
}
