// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Address.sol";

import "./SafeERC20.sol";

import "./ICErc20.sol";
import "./IComptroller.sol";

/**
 * @title Wrapped Token of compound c tokens
 */
contract WrappedToken is ERC20, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    uint8 private immutable _decimals;

    address private immutable ctoken;
    address public immutable comp; // compound comp token
    address public immutable comptroller; //compound controller

    address public controller; // st comp
    modifier onlyController() {
        require(msg.sender == controller, "caller is not controller");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin && !address(msg.sender).isContract(), "Not EOA");
        _;
    }

    event ControllerUpdated(address controller);

    constructor(
        address _ctoken,
        address _controller,
        address _comptroller,
        address _comp
    ) ERC20(string(abi.encodePacked("Wrapped ", ICErc20(_ctoken).name())), string(abi.encodePacked("W", ICErc20(_ctoken).symbol()))) {
        _decimals = ICErc20(_ctoken).decimals();
        ctoken = _ctoken;
        controller = _controller;
        comptroller = _comptroller;
        comp = _comp;
    }
    
    function mint(uint _amount) external onlyController {
        require(_amount > 0, "invalid amount");
        IERC20(ctoken).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }
    
    function burn(uint _amount) external {
        require(_amount > 0, "invalid amount");
        require(totalSupply() >= _amount, "not enough supply");
        
        // distribute harvested comp proportional
        uint256 compBalance = IERC20(comp).balanceOf(address(this));
        if (compBalance > 0) {
            IERC20(comp).safeTransfer(msg.sender, compBalance * _amount / totalSupply());
        }

        _burn(msg.sender, _amount);
        IERC20(ctoken).safeTransfer(msg.sender, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function underlyingCToken() public view returns (address) {
        return ctoken;
    }

    function harvest() external onlyEOA {
        // Claim COMP token.
        address[] memory holders = new address[](1);
        holders[0] = address(this);
        ICErc20[] memory cTokens = new ICErc20[](1);
        cTokens[0] = ICErc20(ctoken);
        IComptroller(comptroller).claimComp(holders, cTokens, false, true);
    }

    function updateController(address _controller) external onlyOwner {
        controller = _controller;
        emit ControllerUpdated(_controller);
    }
}